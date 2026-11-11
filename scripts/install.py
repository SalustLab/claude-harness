#!/usr/bin/env python3
"""Preview, install or check the harness. Python 3.10+, standard library only."""
import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import sys
import tempfile
import uuid

SOURCE = Path(__file__).resolve().parents[1] / "claude"
START = b"<!-- claude-harness:start -->"
END = b"<!-- claude-harness:end -->"


def reject_links(path):
    """Do not follow a destination symlink or Windows directory junction."""
    for node in (path, *path.parents):
        if node.is_symlink() or getattr(node, "is_junction", lambda: False)():
            raise ValueError(f"Refusing linked destination: {node}")


def instruction_content(existing, content):
    existing.decode("utf-8-sig")  # Refuse to silently re-encode another format.
    if existing.count(START) != existing.count(END) or existing.count(START) > 1:
        raise ValueError("Malformed harness markers in existing CLAUDE.md")
    block = START + b"\n" + content.rstrip() + b"\n" + END
    if START in existing:
        first = existing.index(START)
        last = existing.index(END)
        if last < first:
            raise ValueError("Reversed harness markers in existing CLAUDE.md")
        return existing[:first] + block + existing[last + len(END):]
    separator = b"\n\n" if existing and not existing.endswith(b"\n") else b"\n" if existing else b""
    return existing + separator + block + b"\n"


def plan_install(destination):
    reject_links(destination)
    sources = sorted(p for p in SOURCE.rglob("*") if p.is_file())
    if not sources or not (SOURCE / "CLAUDE.md").is_file():
        raise ValueError("Harness payload missing")
    plan = []
    for source in sources:
        if source.is_symlink():
            raise ValueError(f"Refusing linked source: {source}")
        relative = source.relative_to(SOURCE)
        target = destination / relative
        reject_links(target)
        for ancestor in target.parents:
            if ancestor.exists() and not ancestor.is_dir():
                raise ValueError(f"Destination parent is not a directory: {ancestor}")
        if target.exists() and not target.is_file():
            raise ValueError(f"Destination is not a regular file: {target}")
        before = target.read_bytes() if target.exists() else None
        after = source.read_bytes()
        if relative == Path("CLAUDE.md"):
            after = instruction_content(before or b"", after)
        if before == after:
            action = "SAME"
        elif before is None:
            action = "ADD"
        elif relative == Path("CLAUDE.md") and START not in before:
            action = "APPEND"
        else:
            action = "CONFLICT"
        plan.append((relative, target, before, after, action))
    return plan


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".harness-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def apply_plan(destination, plan):
    # Reconcile before any write: a stale preview must not overwrite local work.
    for _, target, before, _, _ in plan:
        reject_links(target)
        current = target.read_bytes() if target.exists() else None
        if current != before:
            raise ValueError(f"Destination changed since planning: {target}")
    changed = [item for item in plan if item[4] != "SAME"]
    replaced = [item for item in changed if item[2] is not None]
    backup = None
    if replaced:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
        backup = destination / ".harness-backups" / stamp
        reject_links(backup)
        atomic_write(backup.parent / ".gitignore", b"*\n")
        for relative, _, before, _, _ in replaced:
            atomic_write(backup / relative, before)
        print(f"Backup: {backup}")
    written = []
    try:
        for _, target, before, after, _ in changed:
            reject_links(target)
            current = target.read_bytes() if target.exists() else None
            if current != before:
                raise ValueError(f"Destination changed during installation: {target}")
            atomic_write(target, after)
            written.append((target, before, after))
    except (OSError, ValueError):
        # Roll back only files still containing exactly what this run wrote.
        for target, before, after in reversed(written):
            reject_links(target)
            if target.read_bytes() == after:
                if before is None:
                    target.unlink()
                else:
                    atomic_write(target, before)
        raise
    return len(changed), backup


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    scope = parser.add_mutually_exclusive_group(required=True)
    scope.add_argument("--project", type=Path, help="Target project; installs into its .claude directory")
    scope.add_argument("--user", action="store_true", help="Install for the current user")
    parser.add_argument("--config-dir", type=Path, help="Override user config directory (only with --user)")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Write the displayed plan")
    mode.add_argument("--check", action="store_true", help="Read-only verification; exit 1 if files differ")
    parser.add_argument("--force", action="store_true", help="Allow replacement of conflicts; backs up existing bytes")
    args = parser.parse_args(argv)
    if args.config_dir and not args.user:
        parser.error("--config-dir requires --user")
    if args.project:
        project = args.project.expanduser().absolute()
        if not project.is_dir():
            parser.error("--project must be an existing directory")
        destination = project / ".claude"
    else:
        destination = (args.config_dir or Path(os.environ.get("CLAUDE_CONFIG_DIR") or Path.home() / ".claude")).expanduser().absolute()
    try:
        if destination.resolve().is_relative_to(SOURCE.parent) or SOURCE.parent.is_relative_to(destination.resolve()):
            raise ValueError("Target must be separate from the harness checkout")
        plan = plan_install(destination)
        print(f"Target: {destination}")
        for relative, _, _, _, action in plan:
            if action != "SAME":
                print(f"{action:8} {relative.as_posix()}")
        changed = sum(item[4] != "SAME" for item in plan)
        conflicts = sum(item[4] == "CONFLICT" for item in plan)
        print(f"SUMMARY changes={changed} conflicts={conflicts} same={len(plan) - changed}")
        if args.check:
            return int(changed > 0)
        if conflicts and not args.force:
            print("Conflicts preserved. Review them; use --force only for authorized replacement.")
            return 1
        if not args.apply:
            print("Preview only. Add --apply to write; no files were changed.")
            return 0
        count, _ = apply_plan(destination, plan)
        print(f"Applied {count} file changes. Restart Claude Code to load installed skills.")
        return 0
    except (OSError, ValueError, UnicodeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
