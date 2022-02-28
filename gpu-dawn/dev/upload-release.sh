#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

# Prepare tarball, headers.json.gz, etc.
./dev/bundle-release.sh

if [[ "${UPLOAD_HEADERS:-"false"}" == "true" ]]; then
    # Upload headers.json.gz
    gh release upload "release-$(git rev-parse --short HEAD)" headers.json.gz
fi

# Upload static library individually.
cp zig-out/lib/libdawn.a "libdawn_$RELEASE_NAME.a"
gzip -9 "libdawn_$RELEASE_NAME.a"
gh release upload "release-$(git rev-parse --short HEAD)" "libdawn_$RELEASE_NAME.a"

# Upload tarball of static library + headers.
mv out.tar.gz "$RELEASE_NAME.tar.gz"
gh release upload "release-$(git rev-parse --short HEAD)" "$RELEASE_NAME.tar.gz"
