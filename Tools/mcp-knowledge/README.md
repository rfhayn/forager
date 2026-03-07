# Forager Knowledge MCP Server

Search and retrieve all forager project knowledge from Claude Desktop — docs, learning notes, ADRs, newsletters, journals, and more.

## Setup

### 1. Install dependencies

```bash
cd Tools/mcp-knowledge
uv sync
```

### 2. Configure Claude Desktop

Add to your Claude Desktop MCP config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "forager-knowledge": {
      "command": "uv",
      "args": ["run", "--directory", "/Users/rich/Development/forager/Tools/mcp-knowledge", "python", "-m", "src.server"]
    }
  }
}
```

### 3. Restart Claude Desktop

The server indexes all docs on first tool call (~0.2s).

## Tools

| Tool | Purpose |
|------|---------|
| `search_knowledge` | Full-text search across all project docs, with optional category filter |
| `read_document` | Read a full document by path or name |
| `list_documents` | Browse available documents by category |
| `get_project_status` | Current milestone, branch, and priorities |
| `get_newsletter_context` | Pull project context + style reference for newsletter writing |
| `draft_newsletter_section` | Context bundle + outline for a newsletter section |
| `create_newsletter_draft` | Generate a .docx newsletter file from markdown content |

## Categories

Filter search results by type:

- `core-doc` — current-story, roadmap, requirements, etc.
- `learning-note` — 38 implementation pattern docs
- `adr` — Architecture Decision Records
- `prd` — Product Requirements Documents
- `newsletter` — Newsletter articles (.docx)
- `research` — Import and UX research
- `guideline` — Process and workflow docs

## Content Stats

- 182 documents indexed
- 2472 searchable chunks
- Index time: ~0.2s
- Search time: <1ms
