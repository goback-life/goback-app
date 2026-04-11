#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""PreToolUse hook: block any direct edits to .env files."""

import json
import sys

data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
file_path = tool_input.get('file_path', '')

# Block .env, .env.stage, .env.production, etc. (but not .env.example)
import os
basename = os.path.basename(file_path)
if basename.startswith('.env') and not basename.endswith('.example'):
    print(
        'BLOCKED: Never edit .env files directly.\n'
        'Environment values are in encrypted .env.<flavor>.gpg files.\n'
        'To change a value: update the source config and re-encrypt.',
        file=sys.stderr,
    )
    sys.exit(2)

sys.exit(0)
