import contextlib
import importlib.util
import io
import pathlib
import unittest


MODULE_PATH = pathlib.Path(__file__).resolve().parents[1] / "run_vscode_problems_gate.py"
SPEC = importlib.util.spec_from_file_location("run_vscode_problems_gate", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
GATE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GATE)


class RunVsCodeProblemsGateTest(unittest.TestCase):
    def _summary(self, payload: dict, *, last_change_at: str) -> dict:
        with contextlib.redirect_stdout(io.StringIO()):
            return GATE.summarize_snapshot(
                "TEST",
                {"lastDiagnosticsChangeAt": last_change_at},
                payload,
            )

    def test_scoped_snapshot_stability_ignores_global_health_churn(self) -> None:
        payload = {
            "capturedAt": "2026-08-17T10:00:00Z",
            "diagnosticsRevision": 10,
            "workspaceFolders": ["/workspace/root"],
            "scope": "/workspace/root/flutter-app",
            "diagnosticCount": 1,
            "diagnostics": [
                {
                    "path": "/workspace/root/flutter-app/lib/example.dart",
                    "severity": "Information",
                    "code": "todo",
                    "message": "TODO",
                }
            ],
        }
        before = self._summary(payload, last_change_at="2026-08-17T10:00:00Z")
        after = self._summary(payload, last_change_at="2026-08-17T10:00:30Z")

        self.assertTrue(GATE.scoped_snapshot_is_stable(before, after))

    def test_scoped_snapshot_stability_detects_workspace_or_diagnostic_change(self) -> None:
        before = self._summary(
            {
                "capturedAt": "2026-08-17T10:00:00Z",
                "diagnosticsRevision": 10,
                "workspaceFolders": ["/workspace/root"],
                "scope": "/workspace/root/flutter-app",
                "diagnosticCount": 1,
                "diagnostics": [
                    {
                        "path": "/workspace/root/flutter-app/lib/example.dart",
                        "severity": "Information",
                        "code": "todo",
                        "message": "TODO",
                    }
                ],
            },
            last_change_at="2026-08-17T10:00:00Z",
        )
        after = self._summary(
            {
                "capturedAt": "2026-08-17T10:00:30Z",
                "diagnosticsRevision": 11,
                "workspaceFolders": ["/workspace/other-root"],
                "scope": "/workspace/root/flutter-app",
                "diagnosticCount": 1,
                "diagnostics": [
                    {
                        "path": "/workspace/root/flutter-app/lib/example.dart",
                        "severity": "Warning",
                        "code": "warn",
                        "message": "Changed",
                    }
                ],
            },
            last_change_at="2026-08-17T10:00:45Z",
        )

        self.assertFalse(GATE.scoped_snapshot_is_stable(before, after))


if __name__ == "__main__":
    unittest.main()
