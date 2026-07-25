"""Fail when a local Markdown or HTML image target does not exist."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_FILES = [
    *ROOT.glob("*.md"),
    *(ROOT / "pages").glob("*.md"),
    *(ROOT / "scripts").glob("*.md"),
]
PATTERNS = (
    re.compile(r"\]\(([^)]+)\)"),
    re.compile(r'src="([^"]+)"'),
)

missing: list[str] = []

for document in MARKDOWN_FILES:
    content = document.read_text(encoding="utf-8")
    for pattern in PATTERNS:
        for match in pattern.finditer(content):
            reference = match.group(1).split("#", maxsplit=1)[0]
            if not reference or reference.startswith(("http://", "https://", "mailto:")):
                continue
            target = (document.parent / reference).resolve()
            if not target.exists():
                missing.append(f"{document.relative_to(ROOT)} -> {reference}")

if missing:
    print("Missing local targets:", *missing, sep="\n- ")
    sys.exit(1)

print(f"Validated local targets in {len(MARKDOWN_FILES)} Markdown files.")
