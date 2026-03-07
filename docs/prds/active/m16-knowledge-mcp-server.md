# PRD: M16 — Forager Knowledge MCP Server

**Status**: DRAFT
**Created**: March 7, 2026
**Author**: Rich + Claude
**Estimated Effort**: 6-10 hours
**Location**: `Tools/mcp-knowledge/`

---

## 1. Problem Statement

The forager project has accumulated ~5.3 MB of structured knowledge across 185+ files:

- 38 learning notes documenting implementation patterns and lessons
- 12 Architecture Decision Records (ADRs)
- 7 core project docs (current-story, roadmap, requirements, etc.)
- Development journal with session narratives
- Insights log with technical discoveries
- PRDs (active, complete, archived)
- Import research documents
- UX research
- 6 newsletter articles (.docx) covering the project's story

This knowledge is too large to load into Claude Desktop's context window at once (~200K+ tokens). The result is either:
1. Context not available — Claude Desktop can't reference project history
2. Manual cherry-picking — user must copy/paste relevant sections
3. Context bundle exports — user manually curates bundles for other AI tools (Gemini)

An MCP server that indexes and serves this knowledge on-demand solves all three problems.

## 2. Goals

1. **Search and retrieve** any project knowledge from Claude Desktop without manual file management
2. **Newsletter drafting** — pull relevant project context to help write weekly newsletter articles
3. **Zero external dependencies** — no vector database, no cloud service, no API keys
4. **Fast startup** — index all content in <2 seconds
5. **In-repo** — lives at `Tools/mcp-knowledge/`, versioned with the project

## 3. Non-Goals

- Real-time file watching (restart server to re-index)
- Embedding-based semantic search (BM25/TF-IDF is sufficient at this scale)
- Serving content to non-Claude clients
- Modifying project files (read-only access)
- Indexing source code (`.swift` files) — this is for documentation/knowledge only

## 4. Content Sources

### 4.1 Repository Documentation (`docs/`)

| Category | Path | Files | Description |
|----------|------|-------|-------------|
| Core docs | `docs/*.md` | 7 | current-story, roadmap, requirements, project-index, insights-log, development-journal, next-prompt |
| Learning notes | `docs/learning-notes/*.md` | 38 | Implementation patterns, lessons learned |
| ADRs | `docs/architecture/*.md` | 12 | Architecture Decision Records |
| PRDs | `docs/prds/**/*.md` | ~15 | Product Requirements Documents |
| Import research | `docs/import-research/*.md` | ~7 | Spike research for recipe import |
| UX research | `docs/ux-research/*.md` | TBD | User experience research |
| Guidelines | `docs/development-guidelines.md`, etc. | ~5 | Process and workflow docs |

### 4.2 Newsletter Articles (`docs/newsletters/`)

| File | Title |
|------|-------|
| 001 | Building With AI When "Vibe Coding" Isn't Enough |
| 002 | The Architecture of No |
| 003 | The Two-Week Investment (And the First Line of Code) |
| 004 | Public Beta Is Live |
| 005 | The Hardest Decision Was to Stop |
| 006 | The Self-Referencing System |

Currently at `~/Desktop/forager/Newsletter/Articles/`. Will be moved to `docs/newsletters/` in the repo.

Context bundles at `~/Desktop/forager/Newsletter/Context Bundles/` will also be moved to `docs/newsletters/context-bundles/` for reference.

## 5. Architecture

### 5.1 Technology Stack

- **Runtime**: Python 3.10+
- **MCP SDK**: `mcp` (Python SDK)
- **Search**: BM25 via `rank_bm25` library (or simple TF-IDF with scikit-learn, or hand-rolled TF-IDF to stay dependency-light)
- **DOCX parsing**: `python-docx`
- **Markdown parsing**: Built-in text processing (no heavy parser needed)
- **No database**: In-memory index rebuilt on startup

### 5.2 Directory Structure

```
Tools/mcp-knowledge/
  README.md
  pyproject.toml          # Dependencies + entry point
  src/
    __init__.py
    server.py             # MCP server definition + tool handlers
    indexer.py            # Document indexing + chunking
    search.py             # BM25 search engine
    documents.py          # Document loading (markdown + docx)
    newsletter.py         # Newsletter-specific helpers
```

### 5.3 Indexing Strategy

On startup, the server:
1. Walks `docs/` recursively for `.md` files
2. Walks `docs/newsletters/` for `.docx` files
3. Extracts text content from each file
4. Chunks documents into passages (~500-1000 tokens each, preserving section boundaries)
5. Builds BM25 index over all chunks
6. Categorizes each document by type (learning-note, adr, prd, newsletter, core-doc, etc.)

**Estimated index time**: <1 second for 5.3 MB of text.

### 5.4 Chunking Rules

- Split on `## ` headers (H2) as primary boundaries
- Keep chunks under ~1000 tokens
- Preserve document metadata (title, category, file path) on every chunk
- For newsletters (.docx): split on paragraph breaks or section headers
- Never split mid-paragraph

## 6. MCP Tools

### 6.1 `search_knowledge`

Search across all indexed project knowledge.

**Parameters:**
- `query` (string, required) — Search query
- `category` (string, optional) — Filter by category: `learning-note`, `adr`, `prd`, `newsletter`, `core-doc`, `journal`, `insight`, `research`, `guideline`
- `max_results` (int, optional, default 5) — Number of results to return

**Returns:** Array of results, each with:
- `title` — Document title
- `category` — Document type
- `file_path` — Relative path from repo root
- `excerpt` — Relevant passage (~500-1000 tokens)
- `score` — Relevance score

### 6.2 `read_document`

Read a full document by path or name.

**Parameters:**
- `path` (string, required) — Relative path from repo root (e.g., `docs/learning-notes/29-m7-cloudkit-household-journey.md`) or document name substring for fuzzy match

**Returns:** Full document content with metadata.

### 6.3 `list_documents`

List available documents, optionally filtered.

**Parameters:**
- `category` (string, optional) — Filter by category
- `query` (string, optional) — Filter by title substring

**Returns:** Array of document summaries (title, category, path, size).

### 6.4 `get_project_status`

Get current project status — a curated summary for quick orientation.

**Parameters:** None

**Returns:** Content from `current-story.md` (first 100 lines) + `next-prompt.md` header + active milestone info.

### 6.5 `get_newsletter_context`

Pull relevant project knowledge for newsletter writing.

**Parameters:**
- `topic` (string, required) — What the newsletter section is about (e.g., "CloudKit sharing challenges", "ML ingredient parsing")
- `include_previous` (bool, optional, default true) — Include excerpts from previous newsletters for tone/style reference

**Returns:**
- Relevant passages from project docs (search results for the topic)
- Relevant development journal entries
- Relevant insights log entries
- If `include_previous` is true: excerpts from the most recent 2-3 newsletters for style matching

### 6.6 `draft_newsletter_section`

Generate a newsletter section draft using project context.

**Parameters:**
- `topic` (string, required) — Section topic
- `style_notes` (string, optional) — Any specific style guidance (e.g., "more technical", "focus on the human story")
- `max_words` (int, optional, default 500) — Target word count

**Returns:**
- Curated context bundle (what was found relevant)
- Suggested section draft outline
- Key facts/quotes from project docs that could be referenced

Note: This tool provides the *context and structure* for drafting — the actual prose generation happens in the Claude Desktop conversation using this context.

### 6.7 `create_newsletter_draft`

Generate a .docx file from provided content.

**Parameters:**
- `title` (string, required) — Newsletter title (used for filename and document heading)
- `content` (string, required) — Newsletter body content (markdown-formatted; converted to docx structure)
- `number` (int, optional) — Issue number (auto-increments from existing newsletters if omitted)
- `output_dir` (string, optional, default `docs/newsletters/`) — Where to save the .docx

**Returns:**
- `file_path` — Absolute path to the generated .docx file

**Behavior:**
- Filename format: `YYYY.MM.DD - NNN - Title.docx` (matches existing naming convention)
- Converts markdown headings, bold, italic, lists to docx formatting via `python-docx`
- Preserves the style/structure of existing newsletter .docx files

## 7. Claude Desktop Configuration

The MCP server will be registered in Claude Desktop's config:

```json
{
  "mcpServers": {
    "forager-knowledge": {
      "command": "python",
      "args": ["-m", "src.server"],
      "cwd": "/Users/rich/Development/forager/Tools/mcp-knowledge"
    }
  }
}
```

Or if using `uv`:

```json
{
  "mcpServers": {
    "forager-knowledge": {
      "command": "uv",
      "args": ["run", "python", "-m", "src.server"],
      "cwd": "/Users/rich/Development/forager/Tools/mcp-knowledge"
    }
  }
}
```

## 8. Implementation Plan

### M16.1: Foundation (2-3h)

1. Set up `Tools/mcp-knowledge/` with `pyproject.toml`
2. Implement `documents.py` — markdown + docx file loading
3. Implement `indexer.py` — chunking + categorization
4. Implement `search.py` — BM25 search engine
5. Implement `server.py` — MCP server with `search_knowledge`, `read_document`, `list_documents`
6. Move newsletter files to `docs/newsletters/`
7. Verify server starts and tools work in Claude Desktop

### M16.2: Project Status + Newsletter Tools (2-3h)

1. Implement `get_project_status` tool
2. Implement `newsletter.py` — newsletter-specific helpers
3. Implement `get_newsletter_context` tool
4. Implement `draft_newsletter_section` tool
5. Test newsletter drafting workflow end-to-end

### M16.3: Polish + Documentation (1-2h)

1. README with setup instructions
2. Fine-tune chunking and search quality
3. Test with real newsletter writing session
4. Add to CLAUDE.md if warranted

## 9. Dependencies

Python packages (minimal):
- `mcp` — MCP Python SDK
- `python-docx` — DOCX file reading
- `rank-bm25` — BM25 search (or hand-roll TF-IDF to avoid this)

No external services, no API keys, no database.

## 10. Success Criteria

- [ ] Claude Desktop can search all 185+ project docs via natural language queries
- [ ] Newsletter articles (.docx) are indexed and searchable
- [ ] `get_newsletter_context` returns relevant project context for a given topic
- [ ] `draft_newsletter_section` provides useful structure + context for writing
- [ ] Server starts in <2 seconds
- [ ] Search returns results in <100ms
- [ ] Works offline — no network required
- [ ] Zero maintenance — just restart server if docs change

## 11. Resolved Decisions

1. **Milestone number**: M16 confirmed
2. **Context bundles**: Not migrating — MCP replaces that workflow entirely
3. **Search algorithm**: BM25 via `rank_bm25`
4. **DOCX generation**: Yes — `draft_newsletter_section` will generate a .docx file, not just return text
