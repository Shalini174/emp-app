#!/usr/bin/env python3
"""
fix_cobol_columns.py

Fixes column positioning in fixed-format COBOL source files.

Rules applied:
  - A normal (non-comment) line whose first non-blank character appears
    before column 8 is re-indented so that content starts at column 8
    (Area A), exactly as it was written from that point on (nothing after
    the leading whitespace is touched/reflowed).
  - A comment line (first non-blank character is '*') whose '*' does not
    sit exactly at column 7 is re-indented so the '*' sits at column 7.
  - Lines that already start ON or AFTER column 8 are left completely
    untouched, whether they are code or comments.
  - Blank / whitespace-only lines are left untouched.

Column numbering below is 1-based, matching COBOL conventions
(column 1 = first character of the line).

Usage:
    python fix_cobol_columns.py [INPUT.cbl] [-o OUTPUT.cbl] [--report]

INPUT.cbl is optional. If omitted, the script derives the target file
from environment variables (as set by the Jenkins pipeline):

    PROGRAM_NAME   - required if INPUT.cbl is not given. Name of the
                     COBOL program without the .cbl extension.
    SRC_DIR        - optional, defaults to "src". Directory (relative
                     to the current working directory / repo checkout)
                     that holds the COBOL source files.

    -> resolves to: {SRC_DIR}/{PROGRAM_NAME}.cbl

If -o/--output is omitted, the resolved input file is fixed in place
(a .bak backup of the original is written alongside it unless
--no-backup is given).
"""

import argparse
import os
import sys
from pathlib import Path

AREA_A_COL = 8          # normal code must start here (1-based)
COMMENT_COL = 7          # '*' of a comment line must sit here (1-based)
DEFAULT_SRC_DIR = "src"


def fix_line(line: str):
    """
    Returns (new_line, changed: bool, reason: str|None)
    Preserves the original line ending (if any) exactly.
    """
    # Split off the line ending so we don't disturb \n / \r\n handling
    if line.endswith("\r\n"):
        body, ending = line[:-2], "\r\n"
    elif line.endswith("\n"):
        body, ending = line[:-1], "\n"
    else:
        body, ending = line, ""

    stripped = body.lstrip(" ")
    if stripped == "":
        # blank / whitespace-only line -> leave untouched
        return line, False, None

    leading_spaces = len(body) - len(stripped)
    first_char_col = leading_spaces + 1  # 1-based column of first non-blank char

    is_comment = stripped[0] == "*"

    if is_comment:
        target_col = COMMENT_COL
    else:
        target_col = AREA_A_COL

    # Only touch lines whose content starts BEFORE column 8.
    # Lines starting on/after column 8 are never disturbed (per spec),
    # even if a comment's '*' happens to land past column 7.
    if first_char_col >= AREA_A_COL:
        return line, False, None

    if first_char_col == target_col:
        # Already correctly positioned (e.g. comment already at col 7)
        return line, False, None

    new_body = (" " * (target_col - 1)) + stripped
    new_line = new_body + ending
    reason = (
        f"comment '*' moved from col {first_char_col} to col {target_col}"
        if is_comment
        else f"code moved from col {first_char_col} to col {target_col}"
    )
    return new_line, True, reason


def process_file(input_path: Path, output_path: Path, report: bool):
    with open(input_path, "r", encoding="utf-8", errors="replace", newline="") as f:
        lines = f.readlines()

    changes = []
    new_lines = []
    for idx, line in enumerate(lines, start=1):
        new_line, changed, reason = fix_line(line)
        new_lines.append(new_line)
        if changed:
            changes.append((idx, reason, line.rstrip("\r\n"), new_line.rstrip("\r\n")))

    with open(output_path, "w", encoding="utf-8", newline="") as f:
        f.writelines(new_lines)

    if report:
        if changes:
            print(f"[INFO] {len(changes)} line(s) adjusted in {output_path}:")
            for lineno, reason, before, after in changes:
                print(f"  Line {lineno}: {reason}")
                print(f"    before: {before!r}")
                print(f"    after : {after!r}")
        else:
            print(f"[INFO] No column issues found. {output_path} unchanged in content.")

    return changes


def resolve_input_path(explicit_input: str | None) -> Path:
    """
    Determines which COBOL file to operate on.

    If an explicit path was given on the command line, use it as-is.
    Otherwise, build the path from the PROGRAM_NAME (required) and
    SRC_DIR (optional, defaults to "src") environment variables, e.g.
    src/PAYPROC.cbl - matching how the Jenkins pipeline already
    exposes PROGRAM_NAME via withEnv().
    """
    if explicit_input:
        return Path(explicit_input)

    program_name = os.environ.get("PROGRAM_NAME", "").strip()
    if not program_name:
        print(
            "[ERROR] No input file given and PROGRAM_NAME environment variable is not set. "
            "Either pass a file path as an argument or set PROGRAM_NAME (and optionally SRC_DIR).",
            file=sys.stderr,
        )
        sys.exit(2)

    src_dir = os.environ.get("SRC_DIR", DEFAULT_SRC_DIR).strip() or DEFAULT_SRC_DIR
    return Path(src_dir) / f"{program_name}.cbl"


def main():
    parser = argparse.ArgumentParser(description="Fix COBOL fixed-format column indentation.")
    parser.add_argument(
        "input",
        nargs="?",
        default=None,
        help=(
            "Path to the COBOL source file to check/fix. Optional - if omitted, resolved "
            "from the PROGRAM_NAME (required) and SRC_DIR (optional, default 'src') "
            "environment variables as {SRC_DIR}/{PROGRAM_NAME}.cbl"
        ),
    )
    parser.add_argument("-o", "--output", help="Path to write the fixed file (default: overwrite input in place)")
    parser.add_argument("--no-backup", action="store_true", help="When fixing in place, skip writing a .bak backup")
    parser.add_argument("--report", action="store_true", default=True, help="Print a summary of changes (default on)")
    parser.add_argument("--check-only", action="store_true",
                         help="Do not write any output; just report problems and exit non-zero if any are found")
    args = parser.parse_args()

    input_path = resolve_input_path(args.input)
    print(f"[INFO] Target COBOL file: {input_path}")

    if not input_path.is_file():
        print(f"[ERROR] Input file not found: {input_path}", file=sys.stderr)
        sys.exit(2)

    if args.check_only:
        # Dry run: compute changes against a throwaway path, write nothing
        with open(input_path, "r", encoding="utf-8", errors="replace", newline="") as f:
            lines = f.readlines()
        problems = []
        for idx, line in enumerate(lines, start=1):
            _, changed, reason = fix_line(line)
            if changed:
                problems.append((idx, reason))
        if problems:
            print(f"[FAIL] {len(problems)} column issue(s) found in {input_path}:")
            for lineno, reason in problems:
                print(f"  Line {lineno}: {reason}")
            sys.exit(1)
        else:
            print(f"[PASS] No column issues found in {input_path}.")
            sys.exit(0)

    if args.output:
        output_path = Path(args.output)
        process_file(input_path, output_path, args.report)
    else:
        # Fix in place, with a .bak backup unless disabled
        if not args.no_backup:
            backup_path = input_path.with_suffix(input_path.suffix + ".bak")
            backup_path.write_bytes(input_path.read_bytes())
            print(f"[INFO] Backup written to {backup_path}")
        process_file(input_path, input_path, args.report)


if __name__ == "__main__":
    main()
