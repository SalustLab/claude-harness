---
name: using-git-worktrees
description: Optional isolated workspace for Git repositories only - detect existing isolation, prefer the harness's native worktree tools, fall back to git worktree with explicit consent, and clean up safely. Use only when the user explicitly asks for isolation, a worktree or parallel work on another branch; PT - "cria um worktree", "trabalha isolado num worktree", "quero isolar essa feature num worktree". Never for SVN working copies or folders without Git (detect the VCS first), never automatic for simple tasks, and never a prerequisite for implementing features.
license: LICENSE
metadata:
  short-description: Opt-in Git worktree isolation
  source: obra/superpowers using-git-worktrees @22f0b46 (MIT), adapted 2026-11-11
  vcs: git
---

# Using Git Worktrees

Worktrees isolate work in a separate directory that shares the same Git repository. They are **opt-in**: work in place unless the user asked for isolation.

## Step 0: Confirm Git, Then Detect Existing Isolation

Check the VCS before anything else:

```bash
git rev-parse --show-toplevel        # must succeed
svn info --show-item wc-root         # if this answers (and Git does not, or SVN's root is closer), stop
```

**SVN working copy, or no Git repository: stop.** Worktrees are a Git concept. Do not run Git commands there and do not simulate branches or worktrees with SVN commands. Say so plainly. An SVN-native alternative, such as a separate checkout, is a different task that needs its own explicit request.

In Git, check whether you are already isolated:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
git rev-parse --show-superproject-working-tree   # non-empty = submodule, treat as a normal checkout
git branch --show-current
git worktree list
```

- `GIT_DIR != GIT_COMMON` and not a submodule: already in a linked worktree. Do not create another. Report the path and branch, or "detached HEAD, externally managed".
- Otherwise you are in the main checkout. Proceed only if the user asked for a worktree. If the request was only "work isolated", confirm that a worktree is what they want.

## Step 1: Create the Workspace

### 1a. Native tools first

If the harness offers native isolation, use it and skip 1b: `EnterWorktree` / `ExitWorktree` tools, a `--worktree` flag, or subagents started with worktree isolation. Native tools own placement, branching and cleanup. A manual `git worktree add` beside them creates state the harness cannot see.

### 1b. Git fallback, with consent

State the plan and get agreement on **location** and **branch** before running anything:

- **Location**: the user's declared preference, otherwise an existing ignored `.worktrees/` or `worktrees/` directory, otherwise a sibling directory outside the repository (`../<repo>.worktrees/<branch>`). A sibling directory needs no ignore rule.
- **Never** edit `.gitignore` or create a commit just to prepare a worktree. If the user wants a project-local directory that is not ignored, propose a local-only entry in `.git/info/exclude` and wait for consent.
- **Branch**: creating a branch requires authorization. Propose a name. Never check out a branch that is already checked out elsewhere. `--detach` avoids creating a branch when the user only needs a scratch copy.

```bash
git worktree add "<path>" -b "<branch>"     # or: git worktree add --detach "<path>" <commit>
```

If creation fails because of sandbox or permissions, say so and continue in place only if the user agrees.

**Local changes stay where they are.** A new worktree starts from a commit, so uncommitted and untracked files of the main checkout are not in it. Tell the user. Never stash, move, reset or clean them to make the worktree "complete".

## Step 2: Project Setup

Dependency installation (`npm ci`, `dotnet restore`, `pip install`, ...) downloads packages and may run install scripts. Ask before running it, prefer lockfile-respecting commands, and never modify lockfiles as a side effect.

## Step 3: Baseline

Run the project's known test command in the worktree when it is safe, meaning no real databases, deploys or external side effects. Report the result. On failures, report them and let the user decide whether to proceed or investigate.

```
Worktree ready at <path> (branch <name> | detached at <sha>)
Baseline: <command> -> <result> | NOT_RUN: <reason>
```

## Cleanup (after the work is finished)

Cleanup is never automatic. With the user's authorization:

1. In the worktree: `git -C "<path>" status --short` must be clean. Otherwise the remaining changes are committed, moved or discarded only as the user decides.
2. Native tool: `ExitWorktree`. Git fallback: `git worktree remove "<path>"`. It refuses dirty trees; do not add `--force` without explicit approval.
3. `git worktree prune` to drop stale entries.
4. Delete the branch only if asked, with `git branch -d <branch>` (refuses unmerged work). Never use `-D` without explicit approval.

## Quick Reference

| Situation | Action |
| --- | --- |
| SVN working copy or no Git | Stop; explain worktrees are Git-only |
| Simple task, no isolation requested | Work in place; do not use this skill |
| Already in a linked worktree | Do not create another |
| Submodule | Treat as a normal checkout |
| Native worktree tool available | Use it |
| Fallback | Confirm location + branch first; sibling directory by default |
| Directory not ignored | Never edit `.gitignore`; propose `.git/info/exclude` |
| Uncommitted work in main checkout | Leave it; tell the user it is not in the worktree |
| Cleanup | Only with authorization; `remove` without `--force`, `branch -d` not `-D` |

## Handoffs

Called by the user or the router for explicit isolation requests. It invokes no other skill. The implementation work inside the worktree is routed normally by `coding-skill-router`.
