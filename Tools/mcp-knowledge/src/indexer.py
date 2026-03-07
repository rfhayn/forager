"""Document chunking and indexing."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .documents import LoadedDocument


@dataclass
class Chunk:
    """A searchable passage from a document."""

    doc_title: str
    doc_category: str
    doc_path: str
    section_title: str | None
    text: str
    chunk_index: int  # position within the document

    @property
    def display_title(self) -> str:
        if self.section_title:
            return f"{self.doc_title} > {self.section_title}"
        return self.doc_title


def chunk_markdown(doc: LoadedDocument, max_tokens: int = 1000) -> list[Chunk]:
    """Split a markdown document into chunks on H2 boundaries."""
    # Split on ## headers
    sections = re.split(r"(?=^## )", doc.content, flags=re.MULTILINE)
    chunks: list[Chunk] = []

    for section in sections:
        section = section.strip()
        if not section:
            continue

        # Extract section title if it starts with ##
        section_title = None
        if section.startswith("## "):
            first_line_end = section.index("\n") if "\n" in section else len(section)
            section_title = section[:first_line_end].lstrip("#").strip()

        # Estimate tokens (~4 chars per token)
        estimated_tokens = len(section) // 4

        if estimated_tokens <= max_tokens:
            chunks.append(Chunk(
                doc_title=doc.title,
                doc_category=doc.category,
                doc_path=doc.file_path,
                section_title=section_title,
                text=section,
                chunk_index=len(chunks),
            ))
        else:
            # Split large sections on paragraph breaks
            paragraphs = section.split("\n\n")
            current_text = ""
            for para in paragraphs:
                if len((current_text + "\n\n" + para).strip()) // 4 > max_tokens and current_text:
                    chunks.append(Chunk(
                        doc_title=doc.title,
                        doc_category=doc.category,
                        doc_path=doc.file_path,
                        section_title=section_title,
                        text=current_text.strip(),
                        chunk_index=len(chunks),
                    ))
                    current_text = para
                else:
                    current_text = (current_text + "\n\n" + para).strip()
            if current_text.strip():
                chunks.append(Chunk(
                    doc_title=doc.title,
                    doc_category=doc.category,
                    doc_path=doc.file_path,
                    section_title=section_title,
                    text=current_text.strip(),
                    chunk_index=len(chunks),
                ))

    # If no chunks were created (no H2 headers), treat whole doc as one chunk
    if not chunks and doc.content.strip():
        chunks.append(Chunk(
            doc_title=doc.title,
            doc_category=doc.category,
            doc_path=doc.file_path,
            section_title=None,
            text=doc.content.strip(),
            chunk_index=0,
        ))

    return chunks


def chunk_docx(doc: LoadedDocument, max_tokens: int = 1000) -> list[Chunk]:
    """Split a docx document into chunks on double-newline boundaries."""
    paragraphs = doc.content.split("\n\n")
    chunks: list[Chunk] = []
    current_text = ""

    for para in paragraphs:
        if len((current_text + "\n\n" + para).strip()) // 4 > max_tokens and current_text:
            chunks.append(Chunk(
                doc_title=doc.title,
                doc_category=doc.category,
                doc_path=doc.file_path,
                section_title=None,
                text=current_text.strip(),
                chunk_index=len(chunks),
            ))
            current_text = para
        else:
            current_text = (current_text + "\n\n" + para).strip()

    if current_text.strip():
        chunks.append(Chunk(
            doc_title=doc.title,
            doc_category=doc.category,
            doc_path=doc.file_path,
            section_title=None,
            text=current_text.strip(),
            chunk_index=len(chunks),
        ))

    return chunks


def build_chunks(documents: list[LoadedDocument]) -> list[Chunk]:
    """Build all chunks from all documents."""
    all_chunks: list[Chunk] = []
    for doc in documents:
        if doc.file_path.endswith(".docx"):
            all_chunks.extend(chunk_docx(doc))
        else:
            all_chunks.extend(chunk_markdown(doc))
    return all_chunks
