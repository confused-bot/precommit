#!/bin/bash
set -e

# Run Gitleaks and store output
TMPFILE=$(mktemp)
gitleaks detect --source . --report-format json --report-path "$TMPFILE" --verbose || true

# Extract potential secrets (grab only the secret strings)
secrets=$(jq -r '.[].Secret' "$TMPFILE" | sort -u)

# Check if there are any secrets
if [[ -z "$secrets" ]]; then
  echo "✅ No secrets found by Gitleaks"
  exit 0
fi

echo "🔍 Verifying ${#secrets[@]} secrets with TruffleHog..."

# Loop over secrets and verify them
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

