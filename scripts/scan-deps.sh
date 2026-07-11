#!/usr/bin/env bash
# scan-deps.sh
# Audits Python dependencies (requirements.txt) for known CVEs using pip-audit.
#
# Usage: ./scan-deps.sh <output-dir>
# Exit codes: 0 = no known vulnerabilities, 1 = vulnerabilities found, 2 = tool failed to run

set -uo pipefail

OUTPUT_DIR="${1:-./security-reports}"
mkdir -p "$OUTPUT_DIR"

REQ_FILE="requirements.txt"

if ! command -v pip-audit >/dev/null 2>&1; then
  echo "==> Installing pip-audit..."
  if ! pip install --quiet pip-audit; then
    echo "❌ Failed to install pip-audit"
    exit 2
  fi
fi

if [ ! -f "$REQ_FILE" ]; then
  echo "==> No requirements.txt found in this repo — skipping dependency scan."
  echo '{"dependencies": [], "note": "no requirements.txt present in target repo"}' > "$OUTPUT_DIR/deps-report.json"
  exit 0
fi

echo "==> Auditing $REQ_FILE for known vulnerabilities..."
set +e
pip-audit -r "$REQ_FILE" -f json -o "$OUTPUT_DIR/deps-report.json"
AUDIT_EXIT=$?
set -e

if [ "$AUDIT_EXIT" -eq 0 ]; then
  echo "✅ No known vulnerabilities in dependencies."
else
  echo "⚠️  Vulnerable dependencies detected — see $OUTPUT_DIR/deps-report.json"
fi

exit "$AUDIT_EXIT"
