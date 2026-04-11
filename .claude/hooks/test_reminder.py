#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///
"""PreToolUse hook: remind when editing a lib/ file with no corresponding test file."""

import json
import sys
from pathlib import Path

data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
file_path = tool_input.get('file_path', '')

# Only check lib/ Dart files (not generated, not test files themselves)
if '/lib/' not in file_path or not file_path.endswith('.dart'):
    sys.exit(0)

if any(s in file_path for s in ['.g.dart', '.freezed.dart', '.tailor.dart', '.gen.dart']):
    sys.exit(0)

# Skip files unlikely to need tests (routes, pages entry, routable definitions)
SKIP_PATTERNS = ['_routable.dart', '_page.dart', '_routes.dart', '/themes/', '/config/']
if any(p in file_path for p in SKIP_PATTERNS):
    sys.exit(0)

# Derive expected test path
test_path = file_path.replace('/lib/', '/test/', 1).replace('.dart', '_test.dart')

if not Path(test_path).exists():
    print(
        f'REMINDER: No test file found for this file.\n'
        f'Expected: {test_path}\n'
        f'Use /add-tests if coverage is needed.',
        file=sys.stderr,
    )

sys.exit(0)
