#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""PostToolUse hook: auto-format changed Dart files."""

import json
import shutil
import subprocess
import sys
from pathlib import Path

data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
file_path = tool_input.get('file_path', '')

if not file_path.endswith('.dart'):
    sys.exit(0)

if not Path(file_path).exists():
    sys.exit(0)

fvm = shutil.which('fvm') or '/opt/homebrew/bin/fvm'

result = subprocess.run(
    [fvm, 'dart', 'format', file_path],
    capture_output=True,
    text=True,
)

if result.returncode != 0:
    print(f'dart format failed: {result.stderr}', file=sys.stderr)
    sys.exit(1)

sys.exit(0)
