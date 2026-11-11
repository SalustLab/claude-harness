# claude-harness

My portable development harness for Claude Code: nine reusable skills, a small
instruction file and an agent-friendly installer. Clone it, ask your agent to
review and apply it to a project or user profile, and keep your existing setup.

No API keys, paid MCPs, plugins, model presets or permission overrides are
needed. The core installer uses **Python 3.10+ and its standard library** on
Windows, macOS and Linux. Claude Code must be installed separately.

## Install with an agent

```sh
git clone https://github.com/SalustLab/claude-harness.git
cd claude-harness
```

Open this checkout with your agent and send:

> Read AGENTS.md and docs/INSTALL.md. Inspect my existing setup and install this
> harness into the project at `<absolute project path>`. Preview the changes,
> preserve my instructions and skills, apply the conflict-free plan, and verify
> the result. Do not change permissions or install optional integrations.

Em português:

> Leia AGENTS.md e docs/INSTALL.md. Inspecione minha configuração e instale este
> harness no projeto em `<caminho absoluto do projeto>`. Mostre a prévia,
> preserve minhas instruções e skills, aplique o plano sem conflitos e verifique
> o resultado. Não altere permissões nem instale integrações opcionais.

For all projects, ask explicitly for a **user-level installation** instead.
Agents other than Claude can perform the installation; the installed paths and
discovery conventions target Claude Code, not every agent product.

## Install directly

```sh
# Preview only; the target project must already exist.
python scripts/install.py --project /path/to/project

# Apply, then verify. A conflict aborts the whole install without changing files.
python scripts/install.py --project /path/to/project --apply
python scripts/install.py --project /path/to/project --check

# Alternatively, install into the current user's Claude configuration.
python scripts/install.py --user
python scripts/install.py --user --apply
python scripts/install.py --user --check
```

Use quoted paths with spaces. On Windows, `py -3` can replace `python`; on
macOS/Linux the command may be `python3`. `--user` respects `CLAUDE_CONFIG_DIR`;
`--config-dir PATH` provides an explicit override for user scope.

Restart Claude Code and check `/skills`. Read [the installation guide](docs/INSTALL.md)
for collisions, upgrades, backup recovery, removal and optional tools.

## Included workflows

| Skill | Purpose |
|---|---|
| `coding-skill-router` | Select workflows by scope and intent; skip ceremony for mechanical changes. |
| `zoom-out` | Map unfamiliar code, callers and data flow before editing. |
| `tdd` | Test observable behavior in small RED/GREEN slices. |
| `diagnose` | Reproduce, minimise and investigate an unclear bug. |
| `brainstorming` | Resolve open product/design choices without reopening settled requirements. |
| `grill-with-docs` | Stress-test domain decisions and maintain glossaries/ADRs when useful. |
| `improve-codebase-architecture` | Identify grounded structural improvements. |
| `agent-doctor` | Audit agent documentation and navigation. |
| `caveman` | Optional concise communication style, only when requested. |

The harness reuses the project's language, conventions and authorization.
Skills can be selected automatically or invoked explicitly. They are guidance,
not enforcement of permissions or a guarantee of correct agent behavior.

## What gets installed

```text
<project>/.claude/          # or the user config directory
  CLAUDE.md                # managed block; existing text stays outside it
  skills/<name>/           # skill instructions, references, helpers and licenses
  .harness-backups/         # only when existing files change; ignored by Git
```

Existing settings, MCPs, hooks, plugins, model choices, credentials and unrelated
skills are left alone. There is no command that snapshots your profile back into
this public repository. Optional visual brainstorming uses bundled Node/Bash
helpers only after user acceptance; the core harness works without them.

## Development

```sh
python -m unittest discover -s tests -p "test_*.py" -v
python scripts/check.py
node tests/test-brainstorming.cjs  # optional companion integration test
```

CI runs installer checks on Windows, macOS and Linux. Local validation does not
replace a Claude Code session check in the recipient's environment.

## Sources and licensing

Original harness code is MIT licensed. Adapted skills retain their upstream MIT
or Apache-2.0 notices. See [ATTRIBUTION.md](ATTRIBUTION.md), [LICENSE](LICENSE) and
[LICENSES/](LICENSES). No third-party plugin is vendored or installed.

Installation paths and discovery follow the official
[skills](https://code.claude.com/docs/en/skills) and
[memory](https://code.claude.com/docs/en/memory) documentation.
