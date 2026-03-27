#!/bin/bash
# Parsing Test Harness runner — use from project root:
#   bash Tools/ParsingTestHarness/run-harness.sh [args]
#
# Examples:
#   bash Tools/ParsingTestHarness/run-harness.sh                    # 50 recipes, local only
#   bash Tools/ParsingTestHarness/run-harness.sh --count 5          # quick 5-recipe test
#   bash Tools/ParsingTestHarness/run-harness.sh --rerun-last       # retest same URLs
#   ANTHROPIC_API_KEY=sk-... bash Tools/ParsingTestHarness/run-harness.sh  # with AI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

swift run ParsingHarness "$@"
