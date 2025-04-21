#!/bin/bash
set -e

TMPFILE=$(mktemp)
gitleaks detect --source . --report-format json --report-path "$TMPFILE" --verbose || true

secrets=$(jq -r '.[].Secret' "$TMPFILE" | sort -u)

if [[ -z "$secrets" ]]; then
  echo "✅ No secrets found by Gitleaks"
  exit 0
fi

echo "🔍 Verifying ${#secrets[@]} secrets with TruffleHog..."

verified_found=0
for secret in $secrets; do
  echo "$secret" | trufflehog stdin --only-verified --fail && verified_found=1
done

rm "$TMPFILE"

if [[ "$verified_found" -ne 0 ]]; then
  echo "❌ Verified secret(s) detected by TruffleHog"
  exit 1
fi

echo "✅ No verified secrets"
