#!/usr/bin/env bash
set -e

# Rename branch to main
git branch -M main

# Create repo on GitHub if not exists
gh repo create couple-games-hub --public --source=. --remote=origin --push || true

# Push main
git push -u origin main || true

# Enable Pages via GitHub API
gh api --method POST /repos/:owner/couple-games-hub/pages -f "source[branch]=main" -f "source[path]=/" || true

echo "DEPLOY_FINISHED"
