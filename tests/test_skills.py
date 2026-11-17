"""Static checks for routing and readiness invariants that frontmatter checks miss.

They assert stable phrases in the bundled skills, not model behavior.
"""
from pathlib import Path
import re
import unittest

SKILLS = Path(__file__).resolve().parents[1] / "claude" / "skills"
ROUTER = "coding-skill-router"


def read(name):
    return (SKILLS / name / "SKILL.md").read_text(encoding="utf-8")


def frontmatter(name):
    return re.match(r"\A---\r?\n(.*?)\r?\n---", read(name), re.S)[1]


def invokes(name):
    match = re.search(r"^\s+invokes:\s*\[([^\]]*)\]", frontmatter(name), re.M)
    return {s.strip() for s in match[1].split(",") if s.strip()} if match else set()


class SkillInvariants(unittest.TestCase):
    def setUp(self):
        self.skills = sorted(p.parent.name for p in SKILLS.glob("*/SKILL.md"))
        self.router = " ".join(read(ROUTER).split())  # router is hard-wrapped

    def test_router_references_every_skill(self):
        missing = [s for s in self.skills if s != ROUTER and f"`{s}`" not in self.router]
        self.assertEqual(missing, [])

    def test_no_skill_shadows_builtin_commands(self):
        self.assertFalse({"code-review", "security-review", "review"} & set(self.skills))

    def test_call_graph_is_one_way(self):
        for skill in self.skills:
            with self.subTest(skill=skill):
                self.assertFalse({ROUTER, "release-readiness"} & invokes(skill))
        self.assertEqual(invokes("release-readiness"),
                         {"diff-review", "security-audit", "web-design-guidelines"})
        self.assertIn("none of them calls back into the router or `release-readiness`", self.router)

    def test_release_readiness_levels_stay_separate_and_read_only(self):
        rr = read("release-readiness")
        for phrase in ("**Readiness Check**", "**Pre-Release Gate**",
                       "A Task Readiness `GO` never implies a Release Readiness `GO`",
                       "Without a ticket, the user's request in the session",
                       "<TASK READINESS | RELEASE READINESS>", "Decision: GO",
                       "two lines stay literal English", "This skill never edits files."):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, rr)

    def test_router_task_readiness_gate_by_size_and_intent(self):
        for phrase in ("Mechanical edits: never", "Small local changes: only on request or relevant risk",
                       "`bug`: the original symptom is gone",
                       "`refactor`: behavior preserved",
                       "`architecture`: the structural goals",
                       "Fixes after a review or an on-demand readiness report are a new routed task"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, self.router)

    def test_diff_review_labels_follow_conversation_language(self):
        dr = read("diff-review")
        self.assertIn("(STD)", dr)
        self.assertIn("(SPEC)", dr)
        self.assertNotRegex(dr, r"(?m)^(## Standards|## Spec|Spec source:|Standards sources:|Summary:)")
        for token in ("STD-", "SPEC-", "BUG", "RISK", "SUGGESTION", "MISSING", "PARTIAL", "WRONG", "SCOPE-CREEP"):
            with self.subTest(token=token):
                self.assertIn(token, dr)

    def test_git_only_skills_are_fenced_off_from_svn(self):
        self.assertRegex(frontmatter("using-git-worktrees"), r"(?m)^\s+vcs: git$")
        self.assertIn("**SVN working copy, or no Git repository: stop.**", read("using-git-worktrees"))
        self.assertIn("Skills marked `metadata.vcs: git` are not selected for SVN", self.router)
        for skill in ("diff-review", "release-readiness", "security-audit"):
            with self.subTest(skill=skill):
                text = read(skill)
                self.assertIn("git rev-parse --show-toplevel", text)
                self.assertIn("svn info --show-item wc-root", text)


if __name__ == "__main__":
    unittest.main()
