#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""PostToolUse hook: run flutter analyze in background, write results to logs/analyze_last.log.
Claude checks this log before committing. Does not block editing."""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
file_path = tool_input.get('file_path', '')

if not file_path.endswith('.dart'):
    sys.exit(0)

# Find project root (directory containing pubspec.yaml)
path = Path(file_path).resolve()
project_root = None
for parent in [path] + list(path.parents):
    if (parent / 'pubspec.yaml').exists():
        project_root = parent
        break

if project_root is None:
    sys.exit(0)

log_dir = project_root / 'logs'
log_dir.mkdir(exist_ok=True)
log_file = log_dir / 'analyze_last.log'

fvm = shutil.which('fvm') or '/opt/homebrew/bin/fvm'

# Spawn analyze in background — does not block
subprocess.Popen(
    [fvm, 'flutter', 'analyze', '--no-pub'],
    cwd=str(project_root),
    stdout=open(log_file, 'w'),
    stderr=subprocess.STDOUT,
    start_new_session=True,
)

print(
    f'flutter analyze running in background → check logs/analyze_last.log before committing',
    file=sys.stderr,
)

sys.exit(0)
