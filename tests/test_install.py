"""Isolated integration checks; never read or write the real Claude profile."""
import importlib.util
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "install.py"
spec = importlib.util.spec_from_file_location("harness_install", SCRIPT)
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name) / "project with spaces"
        self.project.mkdir()
        self.config = self.project / ".claude"

    def run_install(self, *args, code=0):
        result = subprocess.run([sys.executable, str(SCRIPT), "--project", str(self.project), *args],
                                capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(result.returncode, code, result.stdout + result.stderr)
        return result

    def snapshot(self):
        return {p.relative_to(self.project): p.read_bytes()
                for p in self.project.rglob("*") if p.is_file()}

    def test_preview_and_check_never_write(self):
        self.run_install()
        self.run_install("--check", code=1)
        self.assertFalse(self.config.exists())

    def test_install_is_idempotent_and_preserves_unmanaged_files(self):
        self.config.mkdir()
        settings = self.config / "settings.json"
        settings.write_bytes(b'{"permissions":{"defaultMode":"default"}}\n')
        other = self.config / "skills" / "my-skill" / "SKILL.md"
        other.parent.mkdir(parents=True)
        other.write_bytes(b"My own skill\n")
        self.run_install("--apply")
        before = self.snapshot()
        self.run_install("--check")
        self.run_install("--apply")
        self.assertEqual(before, self.snapshot())
        self.assertEqual(settings.read_bytes(), b'{"permissions":{"defaultMode":"default"}}\n')
        self.assertEqual(other.read_bytes(), b"My own skill\n")
        self.assertEqual(len(list((self.config / "skills").glob("*/SKILL.md"))), 10)
        self.assertFalse((self.config / ".harness-backups").exists())

    def test_existing_instructions_survive_and_have_exact_backup(self):
        self.config.mkdir()
        own = "# Local rules\r\nNão alterar minhas configurações.\r\n".encode("utf-8")
        instructions = self.config / "CLAUDE.md"
        instructions.write_bytes(own)
        self.run_install("--apply")
        self.assertTrue(instructions.read_bytes().startswith(own))
        self.assertEqual(instructions.read_bytes().count(installer.START), 1)
        backups = list((self.config / ".harness-backups").glob("*/CLAUDE.md"))
        self.assertEqual([p.read_bytes() for p in backups], [own])
        self.run_install("--check")

    def test_conflict_aborts_entire_apply(self):
        skill = self.config / "skills" / "zoom-out" / "SKILL.md"
        skill.parent.mkdir(parents=True)
        skill.write_bytes(b"Local customization")
        before = self.snapshot()
        self.run_install("--apply", code=1)
        self.assertEqual(before, self.snapshot())
        self.assertFalse((self.config / "CLAUDE.md").exists())

    def test_force_backs_up_conflicts_and_preserves_outside_managed_block(self):
        self.run_install("--apply")
        skill = self.config / "skills" / "zoom-out" / "SKILL.md"
        skill.write_bytes(b"Local customization")
        instructions = self.config / "CLAUDE.md"
        customized = b"Before\r\n" + instructions.read_bytes().replace(b"# Development harness", b"# Local edit") + b"After\r\n"
        instructions.write_bytes(customized)
        self.run_install("--apply", code=1)
        self.run_install("--force", "--apply")
        self.assertTrue(instructions.read_bytes().startswith(b"Before\r\n"))
        self.assertTrue(instructions.read_bytes().endswith(b"After\r\n"))
        backups = self.config / ".harness-backups"
        self.assertEqual([p.read_bytes() for p in backups.glob("*/skills/zoom-out/SKILL.md")], [b"Local customization"])
        self.assertEqual([p.read_bytes() for p in backups.glob("*/CLAUDE.md")], [customized])
        self.run_install("--check")

    def test_malformed_markers_fail_without_writes(self):
        self.config.mkdir()
        (self.config / "CLAUDE.md").write_bytes(installer.START + b"\nIncomplete")
        before = self.snapshot()
        self.run_install("--force", "--apply", code=1)
        self.assertEqual(before, self.snapshot())

    def test_user_scope_respects_config_directory_environment(self):
        target = Path(self.temp.name) / "isolated user config"
        environment = dict(os.environ, CLAUDE_CONFIG_DIR=str(target))
        for flag in ("--apply", "--check"):
            result = subprocess.run([sys.executable, str(SCRIPT), "--user", flag], env=environment,
                                    capture_output=True, text=True, encoding="utf-8")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((target / "skills" / "tdd" / "SKILL.md").is_file())

    def test_linked_destination_is_rejected(self):
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        try:
            self.config.symlink_to(outside, target_is_directory=True)
        except OSError:
            self.skipTest("Symlink creation is not available on this host")
        self.run_install("--apply", code=1)
        self.assertEqual(list(outside.iterdir()), [])

    def test_parent_alias_is_resolved_without_following_config_links(self):
        alias = Path(self.temp.name) / "project alias"
        try:
            alias.symlink_to(self.project, target_is_directory=True)
        except OSError:
            self.skipTest("Symlink creation is not available on this host")
        result = subprocess.run([sys.executable, str(SCRIPT), "--project", str(alias), "--apply"],
                                capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.run_install("--check")

    def test_changed_destination_is_not_overwritten(self):
        self.config.mkdir()
        instructions = self.config / "CLAUDE.md"
        instructions.write_bytes(b"Original")
        plan = installer.plan_install(self.config)
        instructions.write_bytes(b"Concurrent edit")
        with self.assertRaises(ValueError):
            installer.apply_plan(self.config, plan)
        self.assertEqual(instructions.read_bytes(), b"Concurrent edit")
        self.assertFalse((self.config / "skills").exists())

    def test_partial_write_failure_restores_existing_bytes(self):
        self.config.mkdir()
        instructions = self.config / "CLAUDE.md"
        instructions.write_bytes(b"Original rules")
        plan = installer.plan_install(self.config)
        real_write = installer.atomic_write
        failed = False

        def fail_once(path, data):
            nonlocal failed
            if "skills" in path.parts and not failed:
                failed = True
                raise OSError("Simulated disk failure")
            real_write(path, data)

        with patch.object(installer, "atomic_write", fail_once):
            with self.assertRaises(OSError):
                installer.apply_plan(self.config, plan)
        self.assertEqual(instructions.read_bytes(), b"Original rules")
        self.assertFalse(list((self.config / "skills").rglob("SKILL.md")) if (self.config / "skills").exists() else [])


if __name__ == "__main__":
    unittest.main()
