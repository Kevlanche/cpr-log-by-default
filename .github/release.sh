#!/bin/sh

set -e

sh build.sh

echo "Finished building, dumping some env variables for debugging purposes:"
echo "sha: $GITHUB_SHA"
echo "ref: $GITHUB_REF"
echo "ore: $OWNER_REPO"
echo "ctx: $GITHUB_CONTEXT"

# sha: cce18976f438d961f559e7f022ad7c2db5b0893f
# ref: refs/tags/0.0.2

if [ ! -f code-prober.jar ]; then
  echo "Missing code-prober.jar. Did the build silently fail?"
  exit 1
fi

# curl -L \
#   -X POST \
#   -H "Accept: application/vnd.github+json" \
#   -H "Authorization: Bearer $GH_TOKEN" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   -H "Content-Type: application/octet-stream" \
#   "https://uploads.github.com/repos/$OWNER_REPO/releases/RELEASE_ID/assets?name=CodeProber.jar" \
#   --data-binary "@code-prober.jar"
