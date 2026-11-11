---
name: skill-creator
description: Create, improve, review and evaluate this harness's skills - local conventions for frontmatter and descriptions, trigger quality, overlap detection, router registration, static validation, behavioral evals that show whether a skill was activated, ignored or used together with another, baseline comparison and blind A/B grading. Use when creating a new skill, changing or tuning an existing SKILL.md, checking why a skill does or does not trigger, or writing skill eval scenarios; PT - "cria uma skill", "melhora essa skill", "a skill nao esta sendo acionada", "testa as skills", "revisa a description". Imported external skills are scanned with skill-scanner first. Does not route tasks - coding-skill-router stays the only router.
license: LICENSE
metadata:
  short-description: Create, validate and evaluate harness skills
  source: anthropics/skills skill-creator @2c5958e (Apache-2.0), adapted 2026-11-11
  invokes: [skill-scanner]
---

# Skill Creator

Create skills and improve them iteratively: decide what the skill does, draft it, validate it, run realistic prompts with and without it, compare, refine. Find where the user is in that loop and help from there. If they just want a quick edit without evals, do that, but run the static validation anyway.

## Local Conventions

A skill in this harness:

- Lives in `claude/skills/<name>/` of the harness repository; the harness installer installs it into a project or user `skills/` directory. Files are UTF-8 without BOM, LF line endings, with a `LICENSE` in the skill folder.
- `name` = directory name, kebab-case, at most 64 characters. Avoid built-in names: a personal skill named `code-review`, `security-review`, `review`, `init`, ... replaces the built-in command.
- `description` (at most 1024 characters, no angle brackets) says **what** it does, **when** to use it (including phrases users actually type, in their languages), and **when not** (anti-triggers naming the neighbouring skill). The listing truncates description + `when_to_use` at 1536 characters.
- Body under 500 lines. Details go in `references/` files, one level deep, each referenced from SKILL.md with when to read it.
- `metadata.invokes: [a, b]` lists the skills it may invoke. The graph must stay acyclic, and `coding-skill-router` and `release-readiness` are never targets. `metadata.vcs: git` marks Git-only skills.
- No `allowed-tools` (it pre-approves tools; it does not restrict them) and no frontmatter `hooks` without a stated reason and the user's agreement. No load-time shell expansion (an exclamation mark directly followed by a backtick-quoted command). Use `disable-model-invocation: true` for manual-only workflows.
- Scripts: Python standard library, PowerShell, Node or Bash, with dependencies documented as optional and a manual fallback. Never write into a project's `.claude/` folder or global config from a script.
- Respect the global invariants: Git/SVN detection, no automatic commit/push/deploy/ticket updates, evidence-based statuses.
- External origin: keep the `LICENSE`, record source URL, commit and adaptations in `ATTRIBUTION.md`, and run `skill-scanner` before importing.

**Descriptions and the router.** The upstream advice is to make descriptions "pushy" because models tend to under-trigger skills. Here, a strong description must also coexist with `coding-skill-router`. Be explicit about triggers, and equally explicit about anti-triggers and the neighbouring skill, so two skills do not compete for the same request.

## Creating a Skill

1. **Capture intent**: what it enables, when it should trigger (example phrases), expected output, how success is verified. Extract answers from the conversation first; ask only about material gaps.
2. **Check overlap** before writing: list existing skills (`scripts/validate-skills.ps1 -List`), read the router packages, and decide whether to extend an existing skill or add a new one. A new skill that duplicates a package or a step of another skill needs a stated reason.
3. **Draft SKILL.md** following the conventions. Explain the *why* behind rules instead of piling up MUSTs; keep it lean and cut instructions that do not change behavior.
4. **Register** it in `coding-skill-router` (package row, intent, trigger example), `README.md` and, for external sources, `ATTRIBUTION.md`. This is skill registration, not a second routing mechanism.
5. **Validate statically**, then **evaluate behaviorally** (below).
6. Install with the harness installer (preview first, then `--apply`) after the user has reviewed the change.

## Improving a Skill

Snapshot the current version first (copy the skill folder to a scratch directory). Use it as the baseline for evals, change the skill, re-run the same evals against both versions, and compare. Read the transcripts, not just the final answers. If several runs reinvent the same helper, bundle it as a script. If a section makes the model waste effort, remove it and re-test.

## Static Validation

The helper scripts need PowerShell: Windows PowerShell 5.1, or PowerShell 7 (`pwsh`) on macOS/Linux. Without it, check the conventions above by hand and report the scripts as `NOT_RUN`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-creator>\scripts\validate-skills.ps1 -Root <skills-folder>
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-creator>\scripts\validate-skills.ps1 -Root <skills-folder> -List
```

It checks frontmatter (name/dir match, kebab-case, description length and characters, known fields), BOM/CRLF, hidden Unicode, load-time shell expansion, broken local file references, body length, `allowed-tools`/`hooks` grants, built-in name collisions, and the `metadata.invokes` graph (existing targets, no cycles, router and `release-readiness` never targets). Exit code 1 on errors. A well-formed SKILL.md proves nothing about behavior.

## Behavioral Evals

Evals answer whether the skill is **activated** when it should be, **ignored** when it should not run, and **used together** with the expected companions, plus whether its output and commands follow the rules.

Eval file (JSON array):

```json
[
  {
    "id": "svn-review-routing",
    "covers": ["Git vs SVN routing"],
    "fixture": { "vcs": "svn", "base": { "src/a.js": "..." }, "change": { "src/a.js": "..." } },
    "prompt": "revisa as alteracoes locais desse working copy",
    "allow_bash": ["svn status", "svn diff", "svn info", "svn log"],
    "expect": {
      "skills_invoked": ["diff-review"],
      "skills_not_invoked": ["using-git-worktrees", "release-readiness"],
      "commands_required": ["svn (diff|status)"],
      "commands_forbidden": ["(^|[;&|(]\\s*)git\\s"],
      "output_must_match": ["(?i)standards"],
      "output_must_not_match": []
    }
  }
]
```

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-creator>\scripts\run-evals.ps1 -EvalFile <file.json> -SkillsRoot <skills-folder> [-InstructionsFile <CLAUDE.md>] [-Model sonnet] [-Only id1,id2] [-Runs 1] [-Parallel 3]
```

The runner creates each fixture (Git repo, SVN working copy via `svnadmin` + `file://`, or plain folder) in a temp directory. It copies the skills under test into a project `.claude/skills` and runs `claude -p` with `--setting-sources project`, so installed personal skills do not interfere. Claude Code stops looking for project skills at the Git root, so Git fixtures get `.claude/` inside the repo, hidden by `.git/info/exclude`. Only `Skill, Read, Grep, Glob, Bash` are available (no Edit/Write unless the eval lists them in `extra_tools`, for scenarios where the model implements inside the fixture), the eval's `allow_bash` prefixes are pre-approved, and the permission mode is `auto`, so its classifier still blocks risky commands (`-PermissionMode dontAsk` allows nothing beyond the prefixes). A run fails if an asserted skill was not even loaded, so a skill missing from the session cannot produce a vacuous pass. From the `stream-json` transcript the runner records skill activations (Skill tool, or a Read of a `SKILL.md`), attempted commands (including denied ones) and the final answer. Per expected skill it reports `ACTIVATED`, `IGNORED` or `UNEXPECTED`, and `CO-ACTIVATED` when several expected skills ran together. Each eval is `PASS` only if every assertion holds. Transcripts are kept in the reported results folder.

Limits to keep in mind:

- Each eval is a real model run and costs tokens and minutes. Use `-Only` while iterating and `-Runs 3` to measure a trigger rate for flaky cases.
- The user's global `~/.claude/CLAUDE.md` is still loaded as user memory. Pass `-InstructionsFile` with the version under test so it is layered on top. Plugins and user hooks are not loaded. The routing hook can be added with `-HookScript`.
- Results are model- and version-dependent. Record model and date with the results.

For outputs that need judgment, grade with a subagent using `agents/grader.md`. To compare two versions without bias, use `agents/comparator.md` (blind A/B), then explain the winner.

## Description Tuning

Write 8-10 should-trigger and 8-10 should-not-trigger prompts. Make them realistic and specific: file paths, the user's languages, typos. Near-misses that share keywords with the skill but belong to a neighbour are the most valuable negatives. Run them through `run-evals.ps1` with `skills_invoked` / `skills_not_invoked` assertions. Adjust the description, re-run, and keep the version with the best held-out results. Upstream's automated optimizer (`run_loop.py`) was not imported.

## Reference Files

- `scripts/validate-skills.ps1`: static validation (local)
- `scripts/run-evals.ps1`: behavioral eval runner (local)
- `agents/grader.md`: grading expectations against transcripts and outputs (upstream)
- `agents/comparator.md`: blind A/B comparison of two outputs (upstream)
