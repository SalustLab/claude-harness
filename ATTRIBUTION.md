# Sources and redistribution notices

This is an independently adapted harness. It is not an official distribution of
the upstream projects, and their authors do not endorse it. Source links are
attribution, not runtime dependencies. Upstream sources/licenses were reviewed
on 2026-11-11.

| Content | Source | License |
|---|---|---|
| `zoom-out` | [Matt Pocock, historical version](https://github.com/mattpocock/skills/blob/ab45d5e6e1733b7ae27a0795f2a86418c2d451a0/zoom-out/SKILL.md) | MIT |
| `tdd`, including test-quality reference | [Matt Pocock](https://github.com/mattpocock/skills/tree/main/skills/engineering/tdd) | MIT |
| `diagnose` | [Matt Pocock: diagnosing-bugs](https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs) | MIT |
| `grill-with-docs` | [grill-with-docs](https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs), [grilling](https://github.com/mattpocock/skills/tree/main/skills/productivity/grilling), [domain-modeling](https://github.com/mattpocock/skills/tree/main/skills/engineering/domain-modeling) | MIT |
| `improve-codebase-architecture` | [Matt Pocock](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture) | MIT |
| `brainstorming` and visual companion | [Jesse Vincent / obra: Superpowers](https://github.com/obra/superpowers/tree/main/skills/brainstorming) | MIT |
| `caveman` | [Julius Brussee](https://github.com/JuliusBrussee/caveman) | Apache-2.0 |
| `diff-review` | [Matt Pocock: code-review @ 4ae2317](https://github.com/mattpocock/skills/tree/4ae2317ddb22/skills/engineering/code-review) | MIT |
| `security-audit` | [Sentry: security-review @ e94f222](https://github.com/getsentry/skills/tree/e94f22214528/skills/security-review); references derived from the [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/) | Apache-2.0; OWASP-derived references CC BY-SA 4.0 |
| `skill-scanner` | [Sentry: skill-scanner @ e94f222](https://github.com/getsentry/skills/tree/e94f22214528/skills/skill-scanner) | Apache-2.0 |
| `web-design-guidelines` | [Vercel Labs: agent-skills @ 1a2c79d](https://github.com/vercel-labs/agent-skills/tree/1a2c79d4e6c4/skills/web-design-guidelines); rules snapshot from [web-interface-guidelines @ 434b7f9](https://github.com/vercel-labs/web-interface-guidelines/tree/434b7f913646) | MIT |
| `skill-creator`, including grader and comparator agents | [Anthropic: skill-creator @ 2c5958e](https://github.com/anthropics/skills/tree/2c5958ecac7c/skills/skill-creator) | Apache-2.0 |
| `using-git-worktrees` | [Jesse Vincent / obra: Superpowers @ 22f0b46](https://github.com/obra/superpowers/tree/22f0b463e7a5/skills/using-git-worktrees) | MIT |

Adaptations include local names that keep built-in commands available
(`diff-review`, `security-audit`), Git and SVN support, removal of pre-approved
tool grants and automatic installs, pinned offline fallbacks, local workflow
handoffs, generic environment/tool fallbacks,
scoped authorization, evidence guidance, glossary compatibility and opt-in style.
The router, `release-readiness`, agent-readiness checklist, installer, eval and
validation scripts in `skill-creator`, tests and bootstrap documents
include original harness contributions under the root MIT license.

Upstream notices are retained in each derived skill's `LICENSE`, so installation
carries the corresponding terms. Full copies also live in `LICENSES/`.
Apache-licensed skills carry modification notices in their `SKILL.md` metadata or the modified
reference files. The `security-audit` `LICENSE` holds both the Apache-2.0 text
and the OWASP CC BY-SA 4.0 notice; adaptations of those references stay under
CC BY-SA 4.0.
Do not replace these notices with the root license when redistributing.
