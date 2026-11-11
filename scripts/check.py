#!/usr/bin/env python3
"""Check distributable files and skill references without third-party packages.

This is a baseline pattern scan, not proof that arbitrary secrets are absent.
Only paths, line numbers and finding types are printed, never matched values.
"""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    "credential token": r"(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,})",
    "private key": r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----",
    "JWT": r"eyJ[A-Za-z0-9_-]{15,}\.eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]+",
    "private network address": r"\b(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})\b",
    "personal profile path": r"(?i)[A-Z]:[\\/]+Users[\\/]+[A-Za-z0-9_.-]+",
    "email address": r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
}
# The SSRF reference documents the private ranges a validator must block.
ALLOWED = {("claude/skills/security-audit/references/ssrf.md", "private network address")}


def files():
    if (ROOT / ".git").exists():
        result = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                                cwd=ROOT, capture_output=True, check=True)
        return [ROOT / name.decode("utf-8") for name in result.stdout.split(b"\0") if name]
    return [p for p in ROOT.rglob("*") if p.is_file()
            and not {".git", "__pycache__", "node_modules"}.intersection(p.parts)]


def main():
    errors = []
    for path in files():
        relative = path.relative_to(ROOT)
        if path.is_symlink():
            errors.append(f"{relative}: linked distribution file")
            continue
        if path.name == ".env" or path.name.startswith(".credentials"):
            errors.append(f"{relative}: private configuration file")
        try:
            text = path.read_bytes().decode("utf-8")
        except (UnicodeError, OSError):
            errors.append(f"{relative}: unexpected binary, unreadable or non-UTF-8 file")
            continue
        for number, line in enumerate(text.splitlines(), 1):
            for kind, pattern in PATTERNS.items():
                if (relative.as_posix(), kind) not in ALLOWED and re.search(pattern, line):
                    errors.append(f"{relative}:{number}: {kind}")
        if path.name == "SKILL.md":
            front = re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
            if not front:
                errors.append(f"{relative}: missing frontmatter")
                continue
            name = re.search(r"^name:\s*([a-z0-9-]+)\s*$", front[1], re.M)
            description = re.search(r"^description:\s*\S.+$", front[1], re.M)
            if not name or name[1] != path.parent.name or not description:
                errors.append(f"{relative}: invalid skill name or description")
            if not (path.parent / "LICENSE").is_file():
                errors.append(f"{relative}: missing redistribution license")
        if path.suffix == ".md":
            for link in re.findall(r"\]\(([^)]+)\)", text):
                if "://" not in link and not link.startswith("#"):
                    if not (path.parent / link.split("#")[0]).exists():
                        errors.append(f"{relative}: broken local link")
    if errors:
        print("\n".join(errors))
        return 1
    print("PASS: distribution patterns, UTF-8, skill metadata, licenses and local links")
    return 0


if __name__ == "__main__":
    sys.exit(main())
