#!/usr/bin/env bash
set -e
git add index.html
git commit -m "fix(mobile): resolve touch conflicts, multi-touch paddles, and viewport scaling"
git push origin main
echo "PUSH_SUCCESS"
