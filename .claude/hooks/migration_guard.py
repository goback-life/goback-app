#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""PreToolUse hook: warn when editing Supabase model/DTO files without a recent migration."""

import json
import sys
from pathlib import Path

data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
file_path = tool_input.get('file_path', '')

# Patterns that suggest a schema-coupled file
SCHEMA_PATTERNS = [
    '/data/dtos/',
    '/data/mappers/',
]

if not any(p in file_path for p in SCHEMA_PATTERNS):
    sys.exit(0)

if file_path.endswith('.g.dart') or file_path.endswith('.freezed.dart'):
    sys.exit(0)

# Find migrations directory
path = Path(file_path).resolve()
project_root = None
for parent in path.parents:
    if (parent / 'pubspec.yaml').exists():
        project_root = parent
        break

if project_root is None:
    sys.exit(0)

migrations_dir = project_root / 'supabase' / 'migrations'
has_migrations = migrations_dir.exists() and any(migrations_dir.iterdir())

if not has_migrations:
    print(
        'REMINDER: You are editing a DTO/mapper file (schema-coupled).\n'
        'If this change reflects a schema update, run /new-migration first.\n'
        'Supabase migrations directory is empty — ensure your schema change is tracked.',
        file=sys.stderr,
    )
    # exit 0 = reminder only, does not block
    sys.exit(0)

sys.exit(0)
