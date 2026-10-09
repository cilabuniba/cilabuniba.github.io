#!/usr/bin/env bash
# deploy.sh - Build and deploy the Hugo site to the gh-pages branch

set -euo pipefail

PUBLISH_DIR="./public"
PUBLISH_BRANCH="gh-pages"

echo "==> Checking out submodules..."
git submodule update --init --recursive

echo "==> Building Hugo site..."
hugo --minify

echo "==> Deploying to '${PUBLISH_BRANCH}' branch..."

# Get the current repo remote URL
REMOTE_URL=$(git remote get-url origin)

# Create a temporary directory for the gh-pages branch
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Clone only the gh-pages branch (orphan if it doesn't exist yet)
if git ls-remote --exit-code --heads origin "${PUBLISH_BRANCH}" &>/dev/null; then
    git clone --branch "${PUBLISH_BRANCH}" --single-branch "${REMOTE_URL}" "${TMP_DIR}"
    # Wipe existing content (force_orphan behaviour)
    rm -rf "${TMP_DIR:?}"/*
else
    git clone "${REMOTE_URL}" "${TMP_DIR}"
    cd "${TMP_DIR}"
    git checkout --orphan "${PUBLISH_BRANCH}"
    git rm -rf . &>/dev/null || true
    cd - >/dev/null
fi

# Copy built site into the temp clone
cp -r "${PUBLISH_DIR}"/. "${TMP_DIR}/"

cd "${TMP_DIR}"
git config user.email "$(git -C - config user.email 2>/dev/null || echo 'deploy@cilab')"
git config user.name  "$(git -C - config user.name  2>/dev/null || echo 'Deploy Script')"
git add --all
git commit -m "Deploy: $(date -u '+%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to commit."
git push origin "${PUBLISH_BRANCH}"

echo "==> Done! Site deployed to '${PUBLISH_BRANCH}'."
