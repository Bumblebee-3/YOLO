import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class DeployTests(unittest.TestCase):
    def test_untracked_manifest_file_updates_and_local_edits_are_preserved(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            repo = root / "repo"
            home = root / "home"
            source = repo / "configs/.config/hypr/modules/plugins.lua"
            target = home / ".config/hypr/modules/plugins.lua"
            source.parent.mkdir(parents=True)
            target.parent.mkdir(parents=True)
            (repo / "lib").mkdir()
            (repo / "lib/deploy.py").write_bytes(
                (Path(__file__).resolve().parents[1] / "lib/deploy.py").read_bytes()
            )
            (repo / "manifest.psv").write_text(
                "core|home|configs/.config|.config\n"
            )
            target.write_text("pre-existing config\n")
            source.write_text("framework version 1\n")

            def deploy(run):
                return subprocess.run(
                    [
                        sys.executable,
                        "-I",
                        str(repo / "lib/deploy.py"),
                        "--scope",
                        "home",
                        "--root",
                        str(home),
                        "--home",
                        str(home),
                        "--uid",
                        "1000",
                        "--run",
                        run,
                        "core",
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                )

            deploy("first")
            self.assertEqual(target.read_text(), "framework version 1\n")
            backup = home / ".config/cfg_backups/first/.config/hypr/modules/plugins.lua"
            self.assertEqual(backup.read_text(), "pre-existing config\n")

            source.write_text("framework version 2\n")
            deploy("second")
            self.assertEqual(target.read_text(), "framework version 2\n")

            target.write_text("user customization\n")
            source.write_text("framework version 3\n")
            result = deploy("third")
            self.assertEqual(target.read_text(), "user customization\n")
            self.assertIn("preserve home/.config/hypr/modules/plugins.lua", result.stdout)


if __name__ == "__main__":
    unittest.main()
