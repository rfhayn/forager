#!/usr/bin/env python3
from __future__ import annotations

"""
M8.4 Phase 2: Model Architecture & Training
BiLSTM-CRF sequence labeler for ingredient parsing.

Architecture (word-only v1, locked in Phase 0a):
  Word embedding → BiLSTM (2 layers) → Linear → CRF

The CRF cannot convert to CoreML, so the model is split:
  1. BiLSTM emission scorer → CoreML .mlpackage (Phase 3)
  2. CRF parameters → transitions.json (exported here)
  3. Viterbi decoder → Pure Swift (Phase 4)

Usage:
    cd Tools/ml-training
    python train_model.py
"""

import hashlib
import json
import time
from collections import Counter
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from torch.nn.utils.rnn import pack_padded_sequence, pad_packed_sequence, pad_sequence
from torch.utils.data import DataLoader, Dataset
from torchcrf import CRF

# --- Constants ---

LABEL_NAMES = ["QTY", "UNIT", "NAME", "MODIFIER", "PREP", "COMMENT", "OTHER"]
LABEL_TO_ID = {label: idx for idx, label in enumerate(LABEL_NAMES)}
NUM_LABELS = len(LABEL_NAMES)

UNK_ID = 0
PAD_ID = 1
VOCAB_OFFSET = 2  # word tokens start at index 2

# Hyperparameters (from PRD Section 5, Phase 2)
EMBEDDING_DIM = 128
HIDDEN_DIM = 256
NUM_LSTM_LAYERS = 2
DROPOUT = 0.5
BATCH_SIZE = 64
LEARNING_RATE = 0.001
MAX_EPOCHS = 30
PATIENCE = 5
MIN_WORD_FREQ = 2
SEED = 42
GRAD_CLIP = 5.0


# --- Data Loading ---


def load_jsonl(path: Path) -> list[dict]:
    """Load JSONL dataset (one {"tokens": [...], "labels": [...]} per line)."""
    samples = []
    with open(path) as f:
        for line in f:
            samples.append(json.loads(line))
    return samples


def sha256_file(path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


# --- Vocabulary ---


def build_vocab(samples: list[dict], min_freq: int = MIN_WORD_FREQ) -> dict[str, int]:
    """Build word-to-index vocabulary from training data.

    Tokens appearing fewer than min_freq times map to <UNK> (ID 0).
    <PAD> (ID 1) is reserved for batch padding.
    """
    word_counts: Counter[str] = Counter()
    for sample in samples:
        for token in sample["tokens"]:
            word_counts[token] += 1

    vocab = {"<UNK>": UNK_ID, "<PAD>": PAD_ID}
    idx = VOCAB_OFFSET
    for word, count in word_counts.most_common():
        if count >= min_freq:
            vocab[word] = idx
            idx += 1

    return vocab


# --- Dataset & DataLoader ---


class IngredientDataset(Dataset):
    """PyTorch dataset for ingredient sequence labeling."""

    def __init__(self, samples: list[dict], vocab: dict[str, int]):
        self.samples = samples
        self.vocab = vocab

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> tuple[torch.Tensor, torch.Tensor]:
        sample = self.samples[idx]
        token_ids = [self.vocab.get(t, UNK_ID) for t in sample["tokens"]]
        label_ids = [LABEL_TO_ID[l] for l in sample["labels"]]
        return (
            torch.tensor(token_ids, dtype=torch.long),
            torch.tensor(label_ids, dtype=torch.long),
        )


def collate_fn(
    batch: list[tuple[torch.Tensor, torch.Tensor]],
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    """Pad variable-length sequences and create attention mask.

    Returns sorted by length descending (required by pack_padded_sequence).
    """
    token_seqs, label_seqs = zip(*batch)
    lengths = torch.tensor([len(s) for s in token_seqs])

    # Sort by length descending
    sorted_indices = lengths.argsort(descending=True)
    token_seqs = [token_seqs[i] for i in sorted_indices]
    label_seqs = [label_seqs[i] for i in sorted_indices]
    lengths = lengths[sorted_indices]

    # Pad sequences
    padded_tokens = pad_sequence(token_seqs, batch_first=True, padding_value=PAD_ID)
    padded_labels = pad_sequence(label_seqs, batch_first=True, padding_value=0)

    # Mask: True where token is real, False where padding
    mask = torch.zeros(padded_tokens.shape, dtype=torch.bool)
    for i, length in enumerate(lengths):
        mask[i, :length] = True

    return padded_tokens, padded_labels, lengths, mask


# --- Model ---


class IngredientTagger(nn.Module):
    """BiLSTM-CRF for ingredient token-level sequence labeling.

    Components:
        1. Word embedding (vocab_size x embedding_dim)
        2. BiLSTM (num_layers, hidden_dim total -- hidden_dim/2 per direction)
        3. Linear projection (hidden_dim -> num_labels)
        4. CRF layer (num_labels x num_labels transitions + start/end)
    """

    def __init__(
        self,
        vocab_size: int,
        embedding_dim: int = EMBEDDING_DIM,
        hidden_dim: int = HIDDEN_DIM,
        num_labels: int = NUM_LABELS,
        num_layers: int = NUM_LSTM_LAYERS,
        dropout: float = DROPOUT,
    ):
        super().__init__()
        self.hidden_dim = hidden_dim

        self.embedding = nn.Embedding(vocab_size, embedding_dim, padding_idx=PAD_ID)
        self.lstm = nn.LSTM(
            embedding_dim,
            hidden_dim // 2,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0,
        )
        self.dropout = nn.Dropout(dropout)
        self.linear = nn.Linear(hidden_dim, num_labels)
        self.crf = CRF(num_labels, batch_first=True)

    def _get_emissions(
        self, token_ids: torch.Tensor, lengths: torch.Tensor
    ) -> torch.Tensor:
        """Compute emission scores: embedding -> BiLSTM -> linear."""
        embedded = self.dropout(self.embedding(token_ids))
        packed = pack_padded_sequence(
            embedded, lengths.cpu(), batch_first=True, enforce_sorted=True
        )
        lstm_out, _ = self.lstm(packed)
        lstm_out, _ = pad_packed_sequence(lstm_out, batch_first=True)
        emissions = self.linear(self.dropout(lstm_out))
        return emissions

    def forward(
        self,
        token_ids: torch.Tensor,
        labels: torch.Tensor,
        lengths: torch.Tensor,
        mask: torch.Tensor,
    ) -> torch.Tensor:
        """Training forward pass -- returns negative log-likelihood loss."""
        emissions = self._get_emissions(token_ids, lengths)
        loss = -self.crf(emissions, labels, mask=mask, reduction="mean")
        return loss

    def predict(
        self, token_ids: torch.Tensor, lengths: torch.Tensor, mask: torch.Tensor
    ) -> list[list[int]]:
        """Inference -- Viterbi decode for best label sequence per sample."""
        emissions = self._get_emissions(token_ids, lengths)
        return self.crf.decode(emissions, mask=mask)


# --- Training & Evaluation ---


def compute_metrics(
    model: IngredientTagger,
    dataloader: DataLoader,
    device: torch.device,
) -> dict:
    """Evaluate model: token accuracy, sentence accuracy, per-class P/R/F1."""
    model.eval()
    total_tokens = 0
    correct_tokens = 0
    total_sentences = 0
    correct_sentences = 0
    tp: Counter[int] = Counter()
    fp: Counter[int] = Counter()
    fn: Counter[int] = Counter()

    with torch.no_grad():
        for token_ids, labels, lengths, mask in dataloader:
            token_ids = token_ids.to(device)
            labels = labels.to(device)
            lengths = lengths.to(device)
            mask = mask.to(device)

            predictions = model.predict(token_ids, lengths, mask)

            for i, (pred_seq, length) in enumerate(zip(predictions, lengths)):
                length = length.item()
                true_seq = labels[i, :length].cpu().tolist()
                pred_seq = pred_seq[:length]

                total_sentences += 1
                sentence_correct = True

                for true_label, pred_label in zip(true_seq, pred_seq):
                    total_tokens += 1
                    if true_label == pred_label:
                        correct_tokens += 1
                        tp[true_label] += 1
                    else:
                        sentence_correct = False
                        fp[pred_label] += 1
                        fn[true_label] += 1

                if sentence_correct:
                    correct_sentences += 1

    token_acc = correct_tokens / total_tokens if total_tokens > 0 else 0
    sentence_acc = correct_sentences / total_sentences if total_sentences > 0 else 0

    per_class = {}
    for label_id, label_name in enumerate(LABEL_NAMES):
        p = tp[label_id] / (tp[label_id] + fp[label_id]) if (tp[label_id] + fp[label_id]) > 0 else 0
        r = tp[label_id] / (tp[label_id] + fn[label_id]) if (tp[label_id] + fn[label_id]) > 0 else 0
        f1 = 2 * p * r / (p + r) if (p + r) > 0 else 0
        per_class[label_name] = {"precision": p, "recall": r, "f1": f1}

    return {
        "token_accuracy": token_acc,
        "sentence_accuracy": sentence_acc,
        "per_class": per_class,
    }


def train_epoch(
    model: IngredientTagger,
    dataloader: DataLoader,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
) -> float:
    """Train for one epoch, return average loss."""
    model.train()
    total_loss = 0.0
    num_batches = 0

    for token_ids, labels, lengths, mask in dataloader:
        token_ids = token_ids.to(device)
        labels = labels.to(device)
        lengths = lengths.to(device)
        mask = mask.to(device)

        optimizer.zero_grad()
        loss = model(token_ids, labels, lengths, mask)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), GRAD_CLIP)
        optimizer.step()

        total_loss += loss.item()
        num_batches += 1

    return total_loss / num_batches


def validate_epoch(
    model: IngredientTagger,
    dataloader: DataLoader,
    device: torch.device,
) -> float:
    """Compute average validation loss."""
    model.eval()
    total_loss = 0.0
    num_batches = 0

    with torch.no_grad():
        for token_ids, labels, lengths, mask in dataloader:
            token_ids = token_ids.to(device)
            labels = labels.to(device)
            lengths = lengths.to(device)
            mask = mask.to(device)

            loss = model(token_ids, labels, lengths, mask)
            total_loss += loss.item()
            num_batches += 1

    return total_loss / num_batches


# --- Export ---


def export_crf_params(model: IngredientTagger, path: Path) -> None:
    """Export CRF parameters for Swift Viterbi decoder."""
    crf_params = {
        "transitions": model.crf.transitions.detach().cpu().tolist(),
        "start_transitions": model.crf.start_transitions.detach().cpu().tolist(),
        "end_transitions": model.crf.end_transitions.detach().cpu().tolist(),
        "label_names": LABEL_NAMES,
    }
    with open(path, "w") as f:
        json.dump(crf_params, f, indent=2)


def export_checkpoint(
    model: IngredientTagger,
    vocab_size: int,
    best_epoch: int,
    metrics: dict,
    path: Path,
) -> None:
    """Save model checkpoint with metadata."""
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "vocab_size": vocab_size,
            "embedding_dim": EMBEDDING_DIM,
            "hidden_dim": HIDDEN_DIM,
            "num_labels": NUM_LABELS,
            "num_layers": NUM_LSTM_LAYERS,
            "dropout": DROPOUT,
            "epoch": best_epoch,
            "metrics": metrics,
        },
        path,
    )


def update_model_card(
    model_card_path: Path,
    vocab_size: int,
    total_params: int,
    total_sentences: int,
    unique_sentences: int,
    dataset_hash: str,
    split_hash: str,
    best_epoch: int,
    training_duration: float,
    metrics: dict,
) -> None:
    """Fill in MODEL_CARD.md template with training results."""
    text = model_card_path.read_text()

    replacements = {
        "**Version**: (filled after training)": "**Version**: 1.0",
        "**Date Trained**: (filled after training)": "**Date Trained**: {}".format(
            time.strftime("%Y-%m-%d")
        ),
        "| Vocabulary size | (filled after training) |": "| Vocabulary size | {:,} |".format(
            vocab_size
        ),
        "| Total parameters | (filled after training) |": "| Total parameters | {:,} |".format(
            total_params
        ),
        "| Total sentences | (filled after training) |": "| Total sentences | {:,} |".format(
            total_sentences
        ),
        "| Unique sentences (after dedup) | (filled after training) |": "| Unique sentences (after dedup) | {:,} |".format(
            unique_sentences
        ),
        "| Dataset snapshot SHA-256 | (filled after training) |": "| Dataset snapshot SHA-256 | `{}...` |".format(
            dataset_hash[:16]
        ),
        "| Split hash | (filled after training) |": "| Split hash | `{}...` |".format(
            split_hash[:16]
        ),
        "| Random seed | (filled after training) |": "| Random seed | {} |".format(SEED),
        "| Training duration | (filled after training) |": "| Training duration | {:.0f}s ({:.1f} min) |".format(
            training_duration, training_duration / 60
        ),
    }

    # Metrics
    ta = metrics["token_accuracy"]
    sa = metrics["sentence_accuracy"]
    replacements["| Token-level accuracy (test) | (filled after training) |"] = (
        "| Token-level accuracy (test) | {:.2f}% |".format(ta * 100)
    )
    replacements["| Sentence-level accuracy (test) | (filled after training) |"] = (
        "| Sentence-level accuracy (test) | {:.2f}% |".format(sa * 100)
    )
    for label in LABEL_NAMES:
        f1 = metrics["per_class"][label]["f1"]
        # MODEL_CARD.md uses em dash (\u2014) between "F1" and label name
        old_key = "| Per-class F1 \u2014 {} | (filled after training) |".format(label)
        new_val = "| Per-class F1 \u2014 {} | {:.4f} |".format(label, f1)
        replacements[old_key] = new_val

    for old, new in replacements.items():
        text = text.replace(old, new)

    model_card_path.write_text(text)


# --- Main ---


def main():
    print("=" * 60)
    print("M8.4 Phase 2: Model Architecture & Training")
    print("=" * 60)

    torch.manual_seed(SEED)
    np.random.seed(SEED)

    # Device selection: prefer MPS (Apple Silicon GPU), fall back to CPU
    if torch.backends.mps.is_available():
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    print("\nDevice: {}".format(device))

    data_dir = Path(__file__).parent / "data"
    models_dir = Path(__file__).parent / "models"
    models_dir.mkdir(exist_ok=True)

    # --- 1. Load datasets ---
    print("\n[1/6] Loading datasets...")
    train_samples = load_jsonl(data_dir / "training_data.jsonl")
    val_samples = load_jsonl(data_dir / "validation_data.jsonl")
    test_samples = load_jsonl(data_dir / "test_data.jsonl")
    print("  Train: {:,}".format(len(train_samples)))
    print("  Val:   {:,}".format(len(val_samples)))
    print("  Test:  {:,}".format(len(test_samples)))

    # Dataset hashes for model card
    train_hash = sha256_file(data_dir / "training_data.jsonl")
    val_hash = sha256_file(data_dir / "validation_data.jsonl")
    test_hash = sha256_file(data_dir / "test_data.jsonl")
    split_hash = hashlib.sha256(
        "{}:{}:{}".format(train_hash, val_hash, test_hash).encode()
    ).hexdigest()

    # --- 2. Build vocabulary ---
    print("\n[2/6] Building vocabulary...")
    vocab = build_vocab(train_samples)
    vocab_size = len(vocab)
    print("  Vocabulary size: {:,} (min_freq={})".format(vocab_size, MIN_WORD_FREQ))

    # Count UNK rate on validation set
    val_tokens = sum(len(s["tokens"]) for s in val_samples)
    val_unk = sum(1 for s in val_samples for t in s["tokens"] if t not in vocab)
    print("  Val UNK rate: {}/{} ({:.2f}%)".format(val_unk, val_tokens, 100 * val_unk / val_tokens))

    vocab_path = models_dir / "vocabulary.json"
    with open(vocab_path, "w") as f:
        json.dump(vocab, f, ensure_ascii=False)
    print("  Saved: {}".format(vocab_path))

    # --- 3. Create model ---
    print("\n[3/6] Creating model...")
    print("  Architecture: BiLSTM-CRF (word-only v1)")
    print("  Embedding: {}, Hidden: {}, Layers: {}".format(EMBEDDING_DIM, HIDDEN_DIM, NUM_LSTM_LAYERS))
    print("  Dropout: {}, Labels: {}".format(DROPOUT, NUM_LABELS))

    model = IngredientTagger(vocab_size=vocab_size).to(device)

    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print("  Total parameters: {:,}".format(total_params))
    print("  Trainable: {:,}".format(trainable_params))

    # --- 4. Train ---
    train_dataset = IngredientDataset(train_samples, vocab)
    val_dataset = IngredientDataset(val_samples, vocab)
    test_dataset = IngredientDataset(test_samples, vocab)

    train_loader = DataLoader(
        train_dataset, batch_size=BATCH_SIZE, shuffle=True,
        collate_fn=collate_fn, num_workers=0,
    )
    val_loader = DataLoader(
        val_dataset, batch_size=BATCH_SIZE, shuffle=False,
        collate_fn=collate_fn, num_workers=0,
    )
    test_loader = DataLoader(
        test_dataset, batch_size=BATCH_SIZE, shuffle=False,
        collate_fn=collate_fn, num_workers=0,
    )

    optimizer = torch.optim.Adam(model.parameters(), lr=LEARNING_RATE)

    print("\n[4/6] Training (max {} epochs, patience={})...".format(MAX_EPOCHS, PATIENCE))
    best_val_loss = float("inf")
    patience_counter = 0
    best_epoch = 0
    best_model_path = models_dir / "ingredient_tagger_best.pt"
    train_start = time.time()

    for epoch in range(1, MAX_EPOCHS + 1):
        epoch_start = time.time()

        avg_train_loss = train_epoch(model, train_loader, optimizer, device)
        avg_val_loss = validate_epoch(model, val_loader, device)

        epoch_time = time.time() - epoch_start
        marker = ""

        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            best_epoch = epoch
            patience_counter = 0
            torch.save(model.state_dict(), best_model_path)
            marker = " *"
        else:
            patience_counter += 1

        print(
            "  Epoch {:2d}/{} | Train: {:.4f} | Val: {:.4f} | {:.1f}s{}".format(
                epoch, MAX_EPOCHS, avg_train_loss, avg_val_loss, epoch_time, marker
            )
        )

        if patience_counter >= PATIENCE:
            print("\n  Early stopping at epoch {} (best: epoch {})".format(epoch, best_epoch))
            break

    training_duration = time.time() - train_start
    print("\n  Training complete: {:.0f}s ({:.1f} min)".format(training_duration, training_duration / 60))
    print("  Best epoch: {} (val loss: {:.4f})".format(best_epoch, best_val_loss))

    # Load best model for evaluation
    model.load_state_dict(
        torch.load(best_model_path, map_location=device, weights_only=True)
    )

    # --- 5. Evaluate ---
    print("\n[5/6] Evaluating on test set...")
    metrics = compute_metrics(model, test_loader, device)

    print("  Token accuracy:    {:.2f}%".format(metrics["token_accuracy"] * 100))
    print("  Sentence accuracy: {:.2f}%".format(metrics["sentence_accuracy"] * 100))
    print("\n  Per-class metrics:")
    print("  {:10s}  {:>9s}  {:>9s}  {:>9s}".format("Label", "Precision", "Recall", "F1"))
    print("  {}".format("-" * 42))
    for label in LABEL_NAMES:
        s = metrics["per_class"][label]
        print("  {:10s}  {:9.4f}  {:9.4f}  {:9.4f}".format(label, s["precision"], s["recall"], s["f1"]))

    # --- 6. Export ---
    print("\n[6/6] Exporting artifacts...")

    # Checkpoint
    checkpoint_path = models_dir / "ingredient_tagger.pt"
    export_checkpoint(model, vocab_size, best_epoch, metrics, checkpoint_path)
    model_size_mb = checkpoint_path.stat().st_size / (1024 * 1024)
    print("  Checkpoint: {} ({:.1f} MB)".format(checkpoint_path, model_size_mb))

    # CRF parameters
    transitions_path = models_dir / "transitions.json"
    export_crf_params(model, transitions_path)
    print("  CRF params: {}".format(transitions_path))

    # Update MODEL_CARD.md
    model_card_path = Path(__file__).parent / "MODEL_CARD.md"
    if model_card_path.exists():
        update_model_card(
            model_card_path,
            vocab_size=vocab_size,
            total_params=total_params,
            total_sentences=81316,  # original strangetom count
            unique_sentences=len(train_samples) + len(val_samples) + len(test_samples),
            dataset_hash=train_hash,
            split_hash=split_hash,
            best_epoch=best_epoch,
            training_duration=training_duration,
            metrics=metrics,
        )
        print("  Model card: {} (updated)".format(model_card_path))

    # --- Summary ---
    print("\n" + "=" * 60)
    print("Training Summary")
    print("=" * 60)
    print("  Vocabulary:        {:,} words".format(vocab_size))
    print("  Parameters:        {:,}".format(total_params))
    print("  Best epoch:        {}".format(best_epoch))
    print("  Token accuracy:    {:.2f}%".format(metrics["token_accuracy"] * 100))
    print("  Sentence accuracy: {:.2f}%".format(metrics["sentence_accuracy"] * 100))
    print("  Model size:        {:.1f} MB".format(model_size_mb))

    print("\n  Acceptance Criteria:")
    ta = metrics["token_accuracy"]
    sa = metrics["sentence_accuracy"]
    key_f1 = {l: metrics["per_class"][l]["f1"] for l in ["QTY", "UNIT", "NAME"]}

    checks = [
        ("Token accuracy >= 96%", ta >= 0.96, "{:.2f}%".format(ta * 100)),
        ("Sentence accuracy >= 92%", sa >= 0.92, "{:.2f}%".format(sa * 100)),
    ]
    for label, f1 in key_f1.items():
        checks.append(("{} F1 >= 0.90".format(label), f1 >= 0.90, "{:.4f}".format(f1)))
    checks.append(("Model size < 10 MB", model_size_mb < 10, "{:.1f} MB".format(model_size_mb)))

    all_pass = True
    for desc, passed, value in checks:
        status = "PASS" if passed else "FAIL"
        icon = "+" if passed else "X"
        if not passed:
            all_pass = False
        print("    [{}] {:30s} {} ({})".format(icon, desc, value, status))

    if all_pass:
        print("\n  Overall: ALL TARGETS MET")
    else:
        print("\n  Overall: SOME TARGETS MISSED")
    print("=" * 60)


if __name__ == "__main__":
    main()
