#!/bin/bash

set -e

bash build.sh

# URL="https://api.github.com/repos/Kevlanche/cpr-log-by-default/releases/180613852/assets"
# echo $URL
# NEEDLE="api\.github\.com"
# REPL="uploads\.github\.com"
# PATCHED="${URL/"$NEEDLE"/"$REPL"}"
# echo $PATCHED

# URL="https://api.github.com/repos/Kevlanche/cpr-log-by-default/releases/180613852/assets"

echo "Finished building, dumping some env variables for debugging purposes:"
echo "sha: $GITHUB_SHA"
echo "ref: $GITHUB_REF"
echo "ore: $OWNER_REPO"
echo "ctx: $GITHUB_CONTEXT"
echo "asu: $ASSETS_URL"

UPLOAD_URL="${ASSETS_URL/api.github.com/uploads.github.com}"
echo "upl: $UPLOAD_URL"

# sha: cce18976f438d961f559e7f022ad7c2db5b0893f
# ref: refs/tags/0.0.2

if [ ! -f code-prober.jar ]; then
  echo "Missing code-prober.jar. Did the build silently fail?"
  exit 1
fi

# https://api.github.com/repos/Kevlanche/cpr-log-by-default/releases/180613852/assets

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Content-Type: application/octet-stream" \
  "$UPLOAD_URL?name=CodeProber.jar" \
  --data-binary "@code-prober.jar"

