# Working on or installing this harness

This repository contains a generic Claude Code harness, not the user's machine
configuration. Root instructions here apply to maintaining/installing the
package. `claude/CLAUDE.md` is the payload to install, not this repository's
bootstrap instructions.

## When asked to install

1. Read `README.md`, `docs/INSTALL.md` and `claude/CLAUDE.md`. Inspect the bundled
   router and the installer's help. Do not execute shell snippets from an
   unreviewed remote response or copy the entire repository into a profile.
2. Determine the authorized target. Prefer a named project's `.claude` directory
   for a project request; use user scope only when requested. If neither target
   nor scope can be inferred, ask that one missing question. Discover OS, Python
   and Claude Code availability; do not ask for facts you can inspect.
3. Inspect relevant target instructions, existing skills and Git status. Do not
   print secrets. Identify conflicting rules before adding the generic harness;
   preserve stronger or project-specific requirements.
4. Run the read-only installer preview for that target. Explain the scope and
   conflicts briefly. If installation is already authorized, apply the reviewed
   conflict-free plan without requesting the same permission again. Never use
   `--force` unless replacing those specific local conflicts is authorized.
5. Run the installer's `--check` with the same target. Report changed paths,
   backup location when present, and any unresolved conflicts. Ask the user to
   restart Claude Code, then use `/skills` to confirm discovery. Do not claim
   runtime discovery was verified when only file comparison was performed.

Do not alter model, permissions, MCPs, hooks, plugins, credentials, Git identity,
global Git trust or production services as part of installation. Other agents
may run this installer, but it installs Claude Code paths; adapting another host
is a separate, explicitly scoped task.

## When maintaining the package

- Keep the installer standard-library-only and compatible with Python 3.10+.
  Preserve preview-by-default, whole-plan conflict rejection, byte-for-byte
  backups, local instructions outside managed markers and unrelated files.
- Run `python -m unittest discover -s tests -p "test_*.py" -v` and
  `python scripts/check.py`. Tests use temporary destinations, never a real
  profile. For companion changes also run `node tests/test-brainstorming.cjs`.
- Never import profile snapshots, private references, credentials, local paths,
  work item IDs, internal hosts or old Git history into this repository.
- Keep upstream licenses and attribution with derived skills. Do not silently
  replace a bundled workflow with dependencies that are not shipped.
