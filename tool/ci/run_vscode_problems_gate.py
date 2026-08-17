#!/usr/bin/env python3
import argparse
import hashlib
import json
import sys
import time
import socket
import urllib.error
import urllib.parse
import urllib.request


def fetch_json(url: str, timeout_seconds: int) -> dict:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        return json.loads(response.read().decode("utf-8"))


def fetch_json_with_retries(
    *,
    url: str,
    timeout_seconds: int,
    retry_count: int,
    retry_delay_seconds: float,
) -> dict:
    last_error: BaseException | None = None
    for attempt in range(1, retry_count + 1):
        try:
            return fetch_json(url, timeout_seconds)
        except (urllib.error.URLError, TimeoutError, socket.timeout) as error:
            last_error = error
            if attempt >= retry_count:
                break
            print(
                f"INFO: bridge request retry {attempt}/{retry_count - 1} after error: {error}"
            )
            time.sleep(retry_delay_seconds)

    assert last_error is not None
    raise last_error


def diagnostics_hash(payload: dict) -> str:
    return hashlib.sha256(
        json.dumps(payload.get("diagnostics", []), sort_keys=True).encode("utf-8")
    ).hexdigest()


def scoped_snapshot_hash(payload: dict) -> str:
    scoped_state = {
        "scope": payload.get("scope"),
        "workspaceFolders": payload.get("workspaceFolders", []),
        "diagnostics": payload.get("diagnostics", []),
    }
    return hashlib.sha256(json.dumps(scoped_state, sort_keys=True).encode("utf-8")).hexdigest()


def severity_counts(payload: dict) -> dict[str, int]:
    counts: dict[str, int] = {}
    for diagnostic in payload.get("diagnostics", []):
        severity = diagnostic.get("severity", "Unknown")
        counts[severity] = counts.get(severity, 0) + 1
    return counts


def workspace_matches(workspace_folders: list[str], scope: str, workspace_root: str) -> bool:
    for folder in workspace_folders:
        normalized = folder.rstrip("/")
        if normalized == workspace_root.rstrip("/"):
            return True
        prefix = normalized + "/"
        if scope == normalized or scope.startswith(prefix):
            return True
    return False


def summarize_snapshot(prefix: str, health: dict, payload: dict) -> dict:
    counts = severity_counts(payload)
    summary = {
        "capturedAt": payload.get("capturedAt"),
        "revision": payload.get("diagnosticsRevision"),
        "lastDiagnosticsChangeAt": health.get("lastDiagnosticsChangeAt"),
        "workspaceFolders": payload.get("workspaceFolders", []),
        "scope": payload.get("scope"),
        "diagnosticCount": payload.get("diagnosticCount", 0),
        "severityCounts": counts,
        "diagnosticsSha256": diagnostics_hash(payload),
        "scopedSnapshotSha256": scoped_snapshot_hash(payload),
    }
    print(
        f"{prefix}: capturedAt={summary['capturedAt']} revision={summary['revision']} "
        f"lastDiagnosticsChangeAt={summary['lastDiagnosticsChangeAt']} "
        f"diagnosticCount={summary['diagnosticCount']} "
        f"diagnosticsSha256={summary['diagnosticsSha256']} "
        f"scopedSnapshotSha256={summary['scopedSnapshotSha256']}"
    )
    print(f"{prefix}: severityCounts={summary['severityCounts']}")
    print(f"{prefix}: workspaceFolders={summary['workspaceFolders']}")
    return summary


def scoped_snapshot_is_stable(before: dict, after: dict) -> bool:
    return before["scopedSnapshotSha256"] == after["scopedSnapshotSha256"]


def print_diagnostics(label: str, payload: dict) -> None:
    diagnostics = payload.get("diagnostics", [])
    if not diagnostics:
        print(f"{label}: no diagnostics in scoped snapshot")
        return
    print(f"{label}: scoped diagnostics")
    for diagnostic in diagnostics:
        start = diagnostic.get("range", {}).get("start", {})
        print(
            f"  - {diagnostic.get('severity')} | {diagnostic.get('path')}:"
            f"{start.get('line')}:{start.get('character')} | "
            f"{diagnostic.get('code')} | {diagnostic.get('message')}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate a stable local VS Code Problems bridge snapshot for the Flutter workspace."
    )
    parser.add_argument("--scope", required=True)
    parser.add_argument("--workspace-root", required=True)
    parser.add_argument("--bridge-url", default="http://127.0.0.1:40361")
    parser.add_argument("--quiet-seconds", type=int, default=30)
    parser.add_argument("--max-attempts", type=int, default=4)
    parser.add_argument("--http-timeout-seconds", type=int, default=30)
    parser.add_argument("--request-retry-count", type=int, default=3)
    parser.add_argument("--request-retry-delay-seconds", type=float, default=2.0)
    args = parser.parse_args()

    scope = args.scope.rstrip("/")
    workspace_root = args.workspace_root.rstrip("/")
    diagnostics_url = (
        f"{args.bridge_url.rstrip('/')}/diagnostics?"
        + urllib.parse.urlencode({"scope": scope})
    )
    health_url = f"{args.bridge_url.rstrip('/')}/health"

    print("INFO: local Flutter architecture gate -> VS Code Problems bridge")
    print(
        "INFO: treating the result as a live Problems snapshot; "
        "the VS Code API does not expose Analysis Server completion."
    )
    print(f"INFO: scope={scope}")
    print(f"INFO: workspace-root={workspace_root}")
    print(f"INFO: bridge-url={args.bridge_url}")

    last_failure = None
    for attempt in range(1, args.max_attempts + 1):
        try:
            health_before = fetch_json_with_retries(
                url=health_url,
                timeout_seconds=args.http_timeout_seconds,
                retry_count=args.request_retry_count,
                retry_delay_seconds=args.request_retry_delay_seconds,
            )
            payload_before = fetch_json_with_retries(
                url=diagnostics_url,
                timeout_seconds=args.http_timeout_seconds,
                retry_count=args.request_retry_count,
                retry_delay_seconds=args.request_retry_delay_seconds,
            )
        except (urllib.error.URLError, TimeoutError, socket.timeout) as error:
            print(f"ERROR: unable to query the VS Code Problems bridge: {error}", file=sys.stderr)
            return 1

        if not workspace_matches(payload_before.get("workspaceFolders", []), scope, workspace_root):
            print(
                "ERROR: bridge workspace folders do not contain the intended Flutter workspace root.",
                file=sys.stderr,
            )
            print(
                f"ERROR: workspaceFolders={payload_before.get('workspaceFolders', [])}",
                file=sys.stderr,
            )
            return 1

        print(f"INFO: bridge stability attempt {attempt}/{args.max_attempts}")
        before = summarize_snapshot("INFO: before", health_before, payload_before)
        time.sleep(args.quiet_seconds)

        try:
            health_after = fetch_json_with_retries(
                url=health_url,
                timeout_seconds=args.http_timeout_seconds,
                retry_count=args.request_retry_count,
                retry_delay_seconds=args.request_retry_delay_seconds,
            )
            payload_after = fetch_json_with_retries(
                url=diagnostics_url,
                timeout_seconds=args.http_timeout_seconds,
                retry_count=args.request_retry_count,
                retry_delay_seconds=args.request_retry_delay_seconds,
            )
        except (urllib.error.URLError, TimeoutError, socket.timeout) as error:
            print(
                f"ERROR: unable to re-query the VS Code Problems bridge after quiet interval: {error}",
                file=sys.stderr,
            )
            return 1

        after = summarize_snapshot("INFO: after", health_after, payload_after)
        # The bridge can republish the same scoped diagnostics snapshot with a newer
        # diagnosticsRevision while Analysis Server churn elsewhere settles. For the
        # local gate, what matters is whether the scoped payload changed during the
        # quiet interval, not whether the bridge reissued the same payload id or
        # observed unrelated churn elsewhere in the workspace.
        stable = scoped_snapshot_is_stable(before, after)
        if stable:
            counts = severity_counts(payload_after)
            errors = counts.get("Error", 0)
            warnings = counts.get("Warning", 0)
            infos = counts.get("Information", 0)
            print(
                f"INFO: stable live Problems snapshot accepted after {args.quiet_seconds}s quiet interval "
                f"(errors={errors}, warnings={warnings}, information={infos})."
            )
            print_diagnostics("INFO", payload_after)
            if errors > 0 or warnings > 0:
                print(
                    "ERROR: local Flutter architecture gate is blocked by Error/Warning diagnostics in the bridge snapshot.",
                    file=sys.stderr,
                )
                return 1
            return 0

        last_failure = (
            f"scoped snapshot changed during quiet interval: before="
            f"{before['revision']}/{before['lastDiagnosticsChangeAt']}/{before['scopedSnapshotSha256']} after="
            f"{after['revision']}/{after['lastDiagnosticsChangeAt']}/{after['scopedSnapshotSha256']}"
        )
        print(f"INFO: bridge snapshot not yet stable ({last_failure}); retrying.")

    print(
        f"ERROR: VS Code Problems bridge did not stabilize within {args.max_attempts} attempts. "
        f"Last observation: {last_failure}",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
