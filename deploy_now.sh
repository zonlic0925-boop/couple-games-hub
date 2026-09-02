#!/usr/bin/env bash
set -e

# Remove corrupted or incomplete .vercel link
rm -rf .vercel

echo "=== 1. Deploying to Vercel Production with clean linking ==="
vercel deploy --prod --yes --name couple-games-hub

echo "=== 2. Enabling GitHub Pages if not already enabled ==="
gh api --method POST /repos/zonlic0925-boop/couple-games-hub/pages -f "source[branch]=main" -f "source[path]=/" || true
gh api /repos/zonlic0925-boop/couple-games-hub/pages || true
