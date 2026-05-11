import os
import plistlib
import tempfile
import unittest

import app


class LaunchAgentConfigTests(unittest.TestCase):
    def test_validate_service_name_rejects_invalid(self):
        with self.assertRaises(app.ValidationError):
            app.validate_service_name("")
        with self.assertRaises(app.ValidationError):
            app.validate_service_name("../bad")

    def test_build_payload_contains_expected_fields(self):
        payload = app.build_launch_agent_config(
            "groovy-agent",
            "/opt/homebrew/bin/node",
            "server.js",
            "/Users/agaibadulin/Desktop/projects/vibe/groovy_agent",
        )
        self.assertEqual(payload["Label"], "com.agaibadulin.groovy-agent")
        self.assertEqual(payload["ProgramArguments"], ["/opt/homebrew/bin/node", "server.js"])
        self.assertEqual(payload["WorkingDirectory"], "/Users/agaibadulin/Desktop/projects/vibe/groovy_agent")
        self.assertEqual(payload["StandardOutPath"], os.path.expanduser("~/Library/Logs/groovy-agent/stdout.log"))
        self.assertEqual(payload["StandardErrorPath"], os.path.expanduser("~/Library/Logs/groovy-agent/error.log"))
        self.assertTrue(payload["RunAtLoad"])
        self.assertTrue(payload["KeepAlive"])

    def test_build_payload_omits_working_directory_when_empty(self):
        payload = app.build_launch_agent_config("groovy-agent", "/bin/echo", "hello", "")
        self.assertNotIn("WorkingDirectory", payload)

    def test_create_launch_agent_plist_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            launch_agents_dir = os.path.join(tmp, "LaunchAgents")
            log_root_dir = os.path.join(tmp, "Logs")
            os.makedirs(launch_agents_dir, exist_ok=True)
            existing = os.path.join(launch_agents_dir, "com.agaibadulin.groovy-agent.plist")
            with open(existing, "wb") as fh:
                fh.write(b"already exists")

            old_launch_agents_dir = app.LAUNCH_AGENTS_DIR
            old_log_root_dir = app.LOG_ROOT_DIR
            try:
                app.LAUNCH_AGENTS_DIR = launch_agents_dir
                app.LOG_ROOT_DIR = log_root_dir
                with self.assertRaises(app.ValidationError):
                    app.create_launch_agent_plist("groovy-agent", "/bin/echo", "hello", "")
            finally:
                app.LAUNCH_AGENTS_DIR = old_launch_agents_dir
                app.LOG_ROOT_DIR = old_log_root_dir

    def test_discover_service_labels_reads_matching_plists(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.write_plist(
                tmp,
                "com.agaibadulin.alpha.plist",
                {"Label": "com.agaibadulin.alpha"},
            )
            self.write_plist(
                tmp,
                "com.agaibadulin.other-name.plist",
                {"Label": "com.agaibadulin.payload-name"},
            )

            labels = self.discover_from(tmp)

        self.assertEqual(labels, ["com.agaibadulin.alpha", "com.agaibadulin.payload-name"])

    def test_discover_service_labels_ignores_duplicates_nonmatching_and_bad_plists(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.write_plist(
                tmp,
                "com.agaibadulin.valid.plist",
                {"Label": "com.agaibadulin.valid"},
            )
            self.write_plist(
                tmp,
                "com.agaibadulin.duplicate-a.plist",
                {"Label": "com.agaibadulin.valid"},
            )
            self.write_plist(
                tmp,
                "com.example.foreign.plist",
                {"Label": "com.example.foreign"},
            )
            with open(os.path.join(tmp, "com.agaibadulin.broken.plist"), "wb") as fh:
                fh.write(b"not a plist")

            labels = self.discover_from(tmp)

        self.assertEqual(labels, ["com.agaibadulin.valid"])

    def test_services_menu_launch_agent_uses_applications_bundle(self):
        payload = app.build_services_menu_launch_agent_config()

        self.assertEqual(payload["Label"], "com.agaibadulin.services-menu")
        self.assertEqual(payload["ProgramArguments"], ["open", "/Applications/ServicesMenu.app"])
        self.assertFalse(payload["KeepAlive"])
        self.assertNotIn(
            "/Users/agaibadulin/Desktop/projects/vibe/services_menu.py",
            payload["ProgramArguments"],
        )

    def test_resolve_command_with_which_success(self):
        def fake_runner(args, capture_output, text, env):
            self.assertEqual(args, ["/usr/bin/which", "node"])
            self.assertTrue(capture_output)
            self.assertTrue(text)
            self.assertIn("/opt/homebrew/bin", env["PATH"])

            class Result:
                returncode = 0
                stdout = "/opt/homebrew/bin/node\n"
                stderr = ""

            return Result()

        resolved = app.resolve_command_with_which("node", runner=fake_runner)
        self.assertEqual(resolved, "/opt/homebrew/bin/node")

    def test_resolve_command_with_which_rejects_blank(self):
        with self.assertRaises(app.ValidationError):
            app.resolve_command_with_which("   ", runner=lambda **kwargs: None)

    def test_resolve_command_with_which_not_found(self):
        def fake_runner(args, capture_output, text, env):
            class Result:
                returncode = 1
                stdout = ""
                stderr = "node not found"

            return Result()

        with self.assertRaises(app.ValidationError) as ctx:
            app.resolve_command_with_which("node", runner=fake_runner)
        self.assertIn("Command not found", str(ctx.exception))

    def write_plist(self, directory, filename, payload):
        with open(os.path.join(directory, filename), "wb") as fh:
            plistlib.dump(payload, fh)

    def discover_from(self, launch_agents_dir):
        old_launch_agents_dir = app.LAUNCH_AGENTS_DIR
        try:
            app.LAUNCH_AGENTS_DIR = launch_agents_dir
            return app.discover_service_labels()
        finally:
            app.LAUNCH_AGENTS_DIR = old_launch_agents_dir


if __name__ == "__main__":
    unittest.main()
