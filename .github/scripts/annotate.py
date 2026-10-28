#!/usr/bin/env python3
"""Turn Flutter analyze / test output into GitHub annotations.

Used by CI so that failures are visible through the Checks API, not only in the
raw job log. Usage:
  annotate.py analyze <analyze-output.txt>
  annotate.py test <test-json-output.txt>
"""
import json
import os
import re
import sys

LEVEL = {"error": "error", "warning": "warning", "info": "notice"}
# Matches e.g. "  error • Message • lib/a.dart:12:5 • rule_name"
ANALYZE_LINE = re.compile(
    r"^\s*(error|warning|info)\s+[•\-]\s+(.*?)\s+[•\-]\s+(\S+?):(\d+):(\d+)\s+[•\-]\s+(\S+)\s*$"
)


def escape(text: str) -> str:
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def annotate_analyze(path: str) -> int:
    count = 0
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            match = ANALYZE_LINE.match(line)
            if match:
                level, message, file_path, row, col, rule = match.groups()
                print(
                    f"::{LEVEL[level]} file={file_path},line={row},col={col},title={rule}::"
                    f"{escape(message)}"
                )
                count += 1
            elif re.match(r"^\s*(error|warning)\s+[•\-]", line):
                level = "error" if "error" in line.split("•")[0] else "warning"
                print(f"::{LEVEL[level]}::{escape(line.strip())}")
                count += 1
    print(f"Annotated {count} analyzer issue(s).")
    return count


def annotate_tests(path: str) -> int:
    cwd_prefix = "file://" + os.getcwd() + "/"
    names: dict[int, str] = {}
    files: dict[int, str] = {}
    lines: dict[int, int] = {}
    failures = 0
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            raw = raw.strip()
            if not raw.startswith("{"):
                continue
            try:
                event = json.loads(raw)
            except json.JSONDecodeError:
                continue
            kind = event.get("type")
            if kind == "testStart":
                test = event.get("test", {})
                tid = test.get("id")
                names[tid] = test.get("name", "?")
                url = test.get("url") or ""
                files[tid] = url.replace(cwd_prefix, "")
                lines[tid] = test.get("line") or 1
            elif kind == "error":
                tid = event.get("testID")
                failures += 1
                file_path = files.get(tid, "test")
                if file_path.startswith("file://"):
                    file_path = "test"
                print(
                    f"::error file={file_path},line={lines.get(tid, 1)},title=test failed::"
                    f"{escape(names.get(tid, '?'))}: {escape(str(event.get('error', ''))[:1500])}"
                    f"%0A{escape(str(event.get('stackTrace', ''))[:1500])}"
                )
    print(f"Annotated {failures} test failure(s).")
    return failures


if __name__ == "__main__":
    mode, target = sys.argv[1], sys.argv[2]
    if mode == "analyze":
        annotate_analyze(target)
    elif mode == "test":
        annotate_tests(target)
    else:
        raise SystemExit(f"unknown mode {mode}")
