#!/usr/bin/env bash
# Run locally on your Mac if Cloud Agent can't access GITHUB_TOKEN yet.
set -euo pipefail

REPO="${1:-wearther}"
OWNER="${2:-shafkatsaruwar}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Set GITHUB_TOKEN first, e.g.: export GITHUB_TOKEN=ghp_..."
  exit 1
fi

cd "$(dirname "$0")/.."

git checkout main 2>/dev/null || git checkout -B main

if ! git remote get-url origin &>/dev/null; then
  git remote add origin "https://github.com/${OWNER}/${REPO}.git"
fi

# Create repo if missing
curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/user/repos" \
  -d "{\"name\":\"${REPO}\",\"private\":false,\"description\":\"What should I wear today based on the weather?\"}" \
  | grep -q '"full_name"' || true

git push -u origin main

echo "Done: https://github.com/${OWNER}/${REPO}"
