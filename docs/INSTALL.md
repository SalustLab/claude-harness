# Installation and adaptation

## Choose scope

Project scope installs into `<project>/.claude`. User scope installs into
`CLAUDE_CONFIG_DIR` when set, otherwise `~/.claude`. The default invocation writes
nothing and requires an explicit target. Preview and apply use the same options.

Review `claude/CLAUDE.md` and the router first. Adapt rules to the recipient's
actual environment and project requirements. Do not infer tracker names,
deployment flow, database access or permissions from this package.

The installer adds a managed block to the destination's `.claude/CLAUDE.md` (or
user-config `CLAUDE.md`), and copies nine skill directories including licenses.
It does not replace a project-root `CLAUDE.md` or `AGENTS.md`. Existing root and
nested instructions may both load: inspect their compatibility before applying.

## Preview, apply and check

```sh
python scripts/install.py --project /path/to/existing-project
python scripts/install.py --project /path/to/existing-project --apply
python scripts/install.py --project /path/to/existing-project --check
```

The output reports paths and actions, not file contents or credentials:

- `ADD`: a missing file.
- `APPEND`: add the managed instruction block without changing existing bytes.
- `CONFLICT`: an existing skill file or managed instruction block differs.
- `SAME`: already installed; counted in the summary.

`--check` is read-only: exit 0 means the installed payload matches, exit 1 means
differences or an error. A preview with unresolved conflicts also exits 1. Nothing
is applied until every conflict has been resolved or its replacement authorized.

No existing skill file is silently overwritten. Inspect conflicts locally, merge
intentional customizations yourself, or authorize `--force` for replacements:

```sh
python scripts/install.py --project /path/to/project --force
python scripts/install.py --project /path/to/project --force --apply
```

`--force` never removes unrelated files or discards instruction text outside the
managed block. Backups are saved before existing files change, including the
first append to an existing instruction file. A preflight check detects changes
since planning; interrupted writes attempt to restore only this run's own bytes.
Avoid editing target files concurrently with installation.

## Updates and local changes

Pull updates in this checkout, inspect them, then preview against the same target.
Unchanged files are a no-op; changed existing payload files are conflicts until
reviewed. Preserve local rules or reapply customizations from a backup. The
installer does not fetch network content or execute bundled helper scripts.

The backup location is `<config>/.harness-backups/<UTC timestamp>-<id>/`.
It contains the previous bytes at their relative paths and a parent `.gitignore`
keeps backups out of normal Git staging. Backups can contain private local
instructions: do not publish them or bypass their ignore rule.

For recovery, inspect the printed backup and restore only the chosen files to
the same target. Stop the agent first; do not replace a whole profile directory.
To remove the harness, delete only its marked block and the installed skill
directories you have confirmed belong to it. Keep local text, unrelated skills
and any customizations. Recover earlier same-named skills from the backups.

## Runtime verification

Restart Claude Code and run `/skills`. Check the nine names, then try a small
read-only request to map part of your project. `--check` proves files match; it
does not authenticate Claude Code, prove tool availability or test model behavior.
Where the host provides a different skill-loading tool, adapt the invocation
instead of inventing tool names.

## Optional integrations

- Context7 can help look up versioned library docs. Official docs and installed
  sources are valid fallbacks; no API key is included or needed for installation.
- Browser MCPs may help UI tests when the user authorizes them. They are not
  configured by this package.
- A simplicity plugin can complement the built-in minimal-change guidance.
  The router does not assume one is installed or active.
- The bundled visual companion needs Node.js and Bash (Git Bash on Windows),
  and runs only after the user accepts it. Read its `visual-companion.md` before
  starting it. Without those tools, use text sketches and normal design dialogue.
- `caveman` is an optional style, not an execution workflow.

Do not weaken permissions, set a paid model, install MCP servers or log in to
services to make the basic harness work. Those are separate choices for the user.
