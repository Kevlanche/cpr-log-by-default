#!/bin/sh

set -e

sh build.sh

echo "Finished building, dumping some env variables for debugging purposes:"
echo "sha: $GITHUB_SHA"
echo "ref: $GITHUB_REF"

