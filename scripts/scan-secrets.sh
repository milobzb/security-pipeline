#!/usr/bin/env bash
# scan-secrets.sh
# Runs gitleaks against the current working directory and writes a JSON report.
#
# Usage: ./scan-secrets.sh <output-dir>
# Exit codes: 0 = no secrets found, 1 = secrets found, 2 = tool failed to run

set -uo pipefail

OUTPUT_DIR="${1:-./security-reports}"
mkdir -p "$OUTPUT_DIR"

GITLEAKS_VERSION="8.30.1"
GITLEAKS_BIN=""

if command -v gitleaks >/dev/null 2>&1; then
  GITLEAKS_BIN="$(command -v gitleaks)"
  echo "==> Using existing gitleaks install: $GITLEAKS_BIN"
else
  echo "==> Installing gitleaks v${GITLEAKS_VERSION}..."
  TMP_TAR="$(mktemp)"
  if ! curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" -o "$TMP_TAR"; then
    echo "❌ Failed to download gitleaks"
    exit 2
  fi
  tar -xzf "$TMP_TAR" -C /tmp gitleaks
  chmod +x /tmp/gitleaks
  GITLEAKS_BIN="/tmp/gitleaks"
  rm -f "$TMP_TAR"
fi

echo "==> Scanning for hardcoded secrets..."
set +e
"$GITLEAKS_BIN" detect --source . --no-git --report-format json --report-path "$OUTPUT_DIR/secrets-report.json" -v
SCAN_EXIT=$?
set -e

case "$SCAN_EXIT" in
  0)
    echo "✅ No secrets detected."
    ;;
  1)
    echo "⚠️  Potential secrets detected — see $OUTPUT_DIR/secrets-report.json"
    ;;
  *)
    echo "❌ gitleaks failed to run (exit code $SCAN_EXIT)"
    ;;
esac

exit "$SCAN_EXIT"
