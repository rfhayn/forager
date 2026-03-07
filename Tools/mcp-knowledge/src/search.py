"""BM25 search engine over document chunks."""

from __future__ import annotations

import re
from dataclasses import dataclass

from rank_bm25 import BM25Okapi

from .indexer import Chunk


@dataclass
class SearchResult:
    """A single search result with score."""

    chunk: Chunk
    score: float


def tokenize(text: str) -> list[str]:
    """Simple tokenizer: lowercase, split on non-alphanumeric, remove short tokens."""
    tokens = re.findall(r"[a-z0-9]+", text.lower())
    return [t for t in tokens if len(t) > 1]


class KnowledgeSearch:
    """BM25 search engine over chunked documents."""

    def __init__(self, chunks: list[Chunk]) -> None:
        self.chunks = chunks
        # Tokenize all chunks for BM25
        corpus = [tokenize(c.text) for c in chunks]
        self.bm25 = BM25Okapi(corpus)

    def search(
        self,
        query: str,
        category: str | None = None,
        max_results: int = 5,
    ) -> list[SearchResult]:
        """Search chunks, optionally filtered by category."""
        query_tokens = tokenize(query)
        if not query_tokens:
            return []

        scores = self.bm25.get_scores(query_tokens)

        # Pair chunks with scores and filter
        results: list[SearchResult] = []
        for chunk, score in zip(self.chunks, scores):
            if score <= 0:
                continue
            if category and chunk.doc_category != category:
                continue
            results.append(SearchResult(chunk=chunk, score=float(score)))

        # Sort by score descending
        results.sort(key=lambda r: r.score, reverse=True)
        return results[:max_results]
