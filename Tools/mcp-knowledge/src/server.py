"""Forager Knowledge MCP Server.

Indexes all project documentation for search and retrieval via Claude Desktop.
"""

from __future__ import annotations

import json
import re
import time
from datetime import date
from pathlib import Path

from mcp.server.fastmcp import FastMCP

from .documents import LoadedDocument, load_all_documents
from .indexer import build_chunks
from .search import KnowledgeSearch


# Resolve repo root (Tools/mcp-knowledge/../../ = repo root)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent

mcp = FastMCP("forager-knowledge")

# Global state — initialized on first tool call
_search_engine: KnowledgeSearch | None = None
_documents: list[LoadedDocument] = []
_index_time: float = 0.0


def _ensure_indexed() -> KnowledgeSearch:
    """Build index on first use (lazy init)."""
    global _search_engine, _documents, _index_time
    if _search_engine is not None:
        return _search_engine

    start = time.time()
    _documents = load_all_documents(REPO_ROOT)
    chunks = build_chunks(_documents)
    _search_engine = KnowledgeSearch(chunks)
    _index_time = time.time() - start
    return _search_engine


VALID_CATEGORIES = [
    "core-doc", "learning-note", "adr", "prd", "newsletter",
    "research", "guideline", "journal", "insight", "testing",
    "test-corpus", "mockup", "project-config", "other",
]


@mcp.tool()
def search_knowledge(
    query: str,
    category: str | None = None,
    max_results: int = 5,
) -> str:
    """Search across all forager project knowledge — docs, learning notes, ADRs, newsletters, journals.

    Args:
        query: Search query (e.g., "CloudKit sharing challenges", "ingredient parsing")
        category: Optional filter — one of: core-doc, learning-note, adr, prd, newsletter, research, guideline, testing, project-config, other
        max_results: Number of results to return (default 5, max 20)
    """
    engine = _ensure_indexed()

    if category and category not in VALID_CATEGORIES:
        return f"Invalid category '{category}'. Valid: {', '.join(VALID_CATEGORIES)}"

    max_results = min(max(1, max_results), 20)
    results = engine.search(query, category=category, max_results=max_results)

    if not results:
        return f"No results found for '{query}'" + (f" in category '{category}'" if category else "")

    output_parts = [f"Found {len(results)} results for '{query}':\n"]
    for i, r in enumerate(results, 1):
        # Truncate excerpt to ~800 chars
        excerpt = r.chunk.text[:800]
        if len(r.chunk.text) > 800:
            excerpt += "..."

        output_parts.append(
            f"--- Result {i} (score: {r.score:.2f}) ---\n"
            f"Title: {r.chunk.display_title}\n"
            f"Category: {r.chunk.doc_category}\n"
            f"File: {r.chunk.doc_path}\n"
            f"\n{excerpt}\n"
        )

    return "\n".join(output_parts)


@mcp.tool()
def read_document(path: str) -> str:
    """Read a full document by path or name substring.

    Args:
        path: Relative path from repo root (e.g., "docs/learning-notes/29-m7-cloudkit-household-journey.md") or a name substring to fuzzy match
    """
    _ensure_indexed()

    # Try exact path match first
    for doc in _documents:
        if doc.file_path == path:
            return _format_document(doc)

    # Try substring match on path or title
    query_lower = path.lower()
    matches = [
        doc for doc in _documents
        if query_lower in doc.file_path.lower() or query_lower in doc.title.lower()
    ]

    if not matches:
        return f"No document found matching '{path}'"

    if len(matches) == 1:
        return _format_document(matches[0])

    # Multiple matches — list them
    lines = [f"Multiple documents match '{path}'. Be more specific:\n"]
    for doc in matches[:15]:
        lines.append(f"  [{doc.category}] {doc.file_path} — {doc.title}")
    return "\n".join(lines)


def _format_document(doc: LoadedDocument) -> str:
    """Format a full document for output."""
    return (
        f"Title: {doc.title}\n"
        f"Category: {doc.category}\n"
        f"File: {doc.file_path}\n"
        f"Size: {doc.size_bytes:,} bytes\n"
        f"{'=' * 60}\n\n"
        f"{doc.content}"
    )


@mcp.tool()
def list_documents(
    category: str | None = None,
    query: str | None = None,
) -> str:
    """List available documents, optionally filtered by category or title.

    Args:
        category: Filter by type — one of: core-doc, learning-note, adr, prd, newsletter, research, guideline, testing, project-config, other
        query: Filter by title substring
    """
    _ensure_indexed()

    if category and category not in VALID_CATEGORIES:
        return f"Invalid category '{category}'. Valid: {', '.join(VALID_CATEGORIES)}"

    docs = _documents
    if category:
        docs = [d for d in docs if d.category == category]
    if query:
        q = query.lower()
        docs = [d for d in docs if q in d.title.lower() or q in d.file_path.lower()]

    if not docs:
        return "No documents found matching filters."

    # Group by category
    by_category: dict[str, list[LoadedDocument]] = {}
    for doc in docs:
        by_category.setdefault(doc.category, []).append(doc)

    lines = [f"Found {len(docs)} documents:\n"]
    for cat in sorted(by_category.keys()):
        lines.append(f"\n[{cat}] ({len(by_category[cat])} files)")
        for doc in by_category[cat]:
            size_kb = doc.size_bytes / 1024
            lines.append(f"  {doc.file_path} — {doc.title} ({size_kb:.0f} KB)")

    lines.append(f"\nIndex: {len(_documents)} docs, {len(_search_engine.chunks) if _search_engine else 0} chunks, built in {_index_time:.2f}s")
    return "\n".join(lines)


@mcp.tool()
def get_project_status() -> str:
    """Get current project status — active milestone, branch, and next priorities."""
    _ensure_indexed()

    parts = []
    for doc in _documents:
        if doc.file_path == "docs/current-story.md":
            # First ~150 lines
            lines = doc.content.split("\n")[:150]
            parts.append("=== CURRENT STORY ===\n" + "\n".join(lines))
        elif doc.file_path == "docs/next-prompt.md":
            lines = doc.content.split("\n")[:80]
            parts.append("\n=== NEXT PROMPT ===\n" + "\n".join(lines))

    if not parts:
        return "Could not find current-story.md or next-prompt.md"

    return "\n".join(parts)


@mcp.tool()
def get_newsletter_context(
    topic: str,
    include_previous: bool = True,
) -> str:
    """Pull relevant project knowledge for newsletter writing.

    Searches project docs for the topic and optionally includes excerpts from
    previous newsletters for style reference.

    Args:
        topic: What the newsletter section is about (e.g., "CloudKit sharing", "ML parsing")
        include_previous: Include excerpts from recent newsletters for tone/style (default true)
    """
    engine = _ensure_indexed()

    parts = ["=== PROJECT CONTEXT FOR NEWSLETTER ===\n"]
    parts.append(f"Topic: {topic}\n")

    # Search project docs (excluding newsletters)
    all_results = engine.search(topic, max_results=15)
    project_results = [r for r in all_results if r.chunk.doc_category != "newsletter"][:8]

    if project_results:
        parts.append("\n--- Relevant Project Knowledge ---\n")
        for r in project_results:
            excerpt = r.chunk.text[:600]
            if len(r.chunk.text) > 600:
                excerpt += "..."
            parts.append(
                f"[{r.chunk.doc_category}] {r.chunk.display_title}\n"
                f"File: {r.chunk.doc_path}\n"
                f"{excerpt}\n"
            )

    # Search development journal
    journal_results = engine.search(topic, category="core-doc", max_results=3)
    journal_hits = [r for r in journal_results if "journal" in r.chunk.doc_path.lower()]
    if journal_hits:
        parts.append("\n--- Development Journal Entries ---\n")
        for r in journal_hits:
            excerpt = r.chunk.text[:500]
            if len(r.chunk.text) > 500:
                excerpt += "..."
            parts.append(f"{r.chunk.display_title}\n{excerpt}\n")

    # Include recent newsletter excerpts for style
    if include_previous:
        newsletter_docs = [d for d in _documents if d.category == "newsletter"]
        # Take last 2-3 newsletters
        recent = newsletter_docs[-3:] if len(newsletter_docs) >= 3 else newsletter_docs
        if recent:
            parts.append("\n--- Recent Newsletter Style Reference ---\n")
            for doc in recent:
                # First ~500 chars for style reference
                excerpt = doc.content[:500]
                if len(doc.content) > 500:
                    excerpt += "..."
                parts.append(f"[{doc.title}]\n{excerpt}\n")

    return "\n".join(parts)


@mcp.tool()
def draft_newsletter_section(
    topic: str,
    style_notes: str | None = None,
    max_words: int = 500,
) -> str:
    """Get a curated context bundle and outline for drafting a newsletter section.

    Returns relevant facts, quotes, and a suggested structure. Use this context
    to write the actual prose in the conversation.

    Args:
        topic: Section topic (e.g., "the challenge of CloudKit sync debugging")
        style_notes: Optional style guidance (e.g., "more technical", "focus on the human story")
        max_words: Target word count for the section (default 500)
    """
    engine = _ensure_indexed()

    parts = [f"=== NEWSLETTER DRAFT CONTEXT ===\n"]
    parts.append(f"Topic: {topic}")
    parts.append(f"Target: ~{max_words} words")
    if style_notes:
        parts.append(f"Style: {style_notes}")
    parts.append("")

    # Gather relevant project knowledge
    results = engine.search(topic, max_results=10)
    project_results = [r for r in results if r.chunk.doc_category != "newsletter"]

    if project_results:
        parts.append("--- Key Facts & Context ---\n")
        for r in project_results[:6]:
            excerpt = r.chunk.text[:500]
            if len(r.chunk.text) > 500:
                excerpt += "..."
            parts.append(
                f"Source: [{r.chunk.doc_category}] {r.chunk.display_title}\n"
                f"{excerpt}\n"
            )

    # Check for relevant insights
    insight_results = engine.search(topic, category="core-doc", max_results=3)
    insight_hits = [r for r in insight_results if "insight" in r.chunk.doc_path.lower()]
    if insight_hits:
        parts.append("--- Insights Log Entries ---\n")
        for r in insight_hits:
            parts.append(f"{r.chunk.text[:400]}\n")

    # Suggest structure
    parts.append("--- Suggested Structure ---\n")
    parts.append(f"1. Hook — Open with the specific challenge or moment related to '{topic}'")
    parts.append(f"2. Context — What was being built and why it mattered")
    parts.append(f"3. The Turn — What was discovered, decided, or changed")
    parts.append(f"4. Takeaway — The lesson or principle that generalizes beyond forager")
    parts.append(f"\nUse the context above to write ~{max_words} words in the newsletter's established voice.")

    return "\n".join(parts)


@mcp.tool()
def create_newsletter_draft(
    title: str,
    content: str,
    number: int | None = None,
    output_dir: str | None = None,
) -> str:
    """Generate a .docx newsletter file from provided content.

    Args:
        title: Newsletter title (used for filename and document heading)
        content: Newsletter body (markdown-formatted — headings, bold, italic, lists converted to docx)
        number: Issue number (auto-increments from existing newsletters if omitted)
        output_dir: Where to save (default: docs/newsletters/)
    """
    from docx import Document as DocxDocument
    from docx.shared import Pt, Inches
    from docx.enum.text import WD_ALIGN_PARAGRAPH

    target_dir = Path(output_dir) if output_dir else REPO_ROOT / "docs" / "newsletters"
    target_dir.mkdir(parents=True, exist_ok=True)

    # Auto-detect next issue number
    if number is None:
        existing = sorted(target_dir.glob("*.docx"))
        max_num = 0
        for f in existing:
            match = re.search(r"-\s*(\d+)\s*-", f.name)
            if match:
                max_num = max(max_num, int(match.group(1)))
        number = max_num + 1

    # Build filename
    today = date.today().strftime("%Y.%m.%d")
    filename = f"{today} - {number:03d} - {title}.docx"
    filepath = target_dir / filename

    # Create document
    doc = DocxDocument()

    # Title
    title_para = doc.add_heading(title, level=0)
    title_para.alignment = WD_ALIGN_PARAGRAPH.LEFT

    # Convert markdown content to docx
    _markdown_to_docx(doc, content)

    doc.save(str(filepath))

    return f"Newsletter draft created: {filepath.relative_to(REPO_ROOT)}\nAbsolute path: {filepath}"


def _markdown_to_docx(doc: DocxDocument, content: str) -> None:
    """Convert markdown-formatted text to docx paragraphs."""
    from docx.shared import Pt

    lines = content.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]

        # Headings
        if line.startswith("### "):
            doc.add_heading(line[4:].strip(), level=3)
        elif line.startswith("## "):
            doc.add_heading(line[3:].strip(), level=2)
        elif line.startswith("# "):
            doc.add_heading(line[2:].strip(), level=1)
        # Unordered list
        elif line.strip().startswith("- ") or line.strip().startswith("* "):
            text = re.sub(r"^[\s]*[-*]\s+", "", line)
            para = doc.add_paragraph(style="List Bullet")
            _add_inline_formatting(para, text)
        # Numbered list
        elif re.match(r"^\s*\d+\.\s+", line):
            text = re.sub(r"^\s*\d+\.\s+", "", line)
            para = doc.add_paragraph(style="List Number")
            _add_inline_formatting(para, text)
        # Blank line
        elif not line.strip():
            pass  # skip blank lines (paragraph spacing handles this)
        # Regular paragraph
        else:
            para = doc.add_paragraph()
            _add_inline_formatting(para, line)

        i += 1


def _add_inline_formatting(paragraph, text: str) -> None:
    """Handle **bold** and *italic* inline formatting."""
    # Split on bold and italic markers
    parts = re.split(r"(\*\*[^*]+\*\*|\*[^*]+\*)", text)
    for part in parts:
        if part.startswith("**") and part.endswith("**"):
            run = paragraph.add_run(part[2:-2])
            run.bold = True
        elif part.startswith("*") and part.endswith("*"):
            run = paragraph.add_run(part[1:-1])
            run.italic = True
        else:
            paragraph.add_run(part)


def main():
    """Entry point for the MCP server."""
    mcp.run()


if __name__ == "__main__":
    main()
