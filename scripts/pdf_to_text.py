#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pypdf>=4.0.0",
# ]
# ///
"""Convert PDF files to plain text.

Usage:
    ./pdf_to_text.py <input.pdf> [output.txt]

If output is not specified, writes to stdout.
"""

import sys
from pathlib import Path

from pypdf import PdfReader


def extract_text_from_pdf(pdf_path: Path) -> str:
    """Extract all text from a PDF file."""
    reader = PdfReader(pdf_path)
    text_parts = []

    for page_num, page in enumerate(reader.pages, 1):
        page_text = page.extract_text()
        if page_text:
            text_parts.append(f"--- Page {page_num} ---\n{page_text}")

    return "\n\n".join(text_parts)


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    input_path = Path(sys.argv[1])
    if not input_path.exists():
        print(f"Error: {input_path} not found", file=sys.stderr)
        sys.exit(1)

    text = extract_text_from_pdf(input_path)

    if len(sys.argv) >= 3:
        output_path = Path(sys.argv[2])
        output_path.write_text(text, encoding="utf-8")
        print(f"Wrote {len(text)} characters to {output_path}", file=sys.stderr)
    else:
        print(text)


if __name__ == "__main__":
    main()
