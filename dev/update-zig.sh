#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

update_zig() {
    gsed -i 's|\(Currently tested with: \).*|\1'"$1"'|' $2
    gsed -i 's|\(https://ziglang.org/builds/zig-[^/ -]*-[^/ -]*-\)[^/ ]*\(\(\.tar\.xz\)[^/ ]*\)|\1'"$1"'\2|' $2
    gsed -i 's|\(https://ziglang.org/builds/zig-[^/ -]*-[^/ -]*-\)[^/ ]*\(\(\.zip\)[^/ ]*\)|\1'"$1"'\2|' $2
}

if [ -n "${ZIG_VERSION:-}" ]; then
    version="${ZIG_VERSION:-}"

    update_zig "$version" README.md

    sources=$(find . | grep './.github/workflows' | grep -v 'third_party/' | grep -v 'DirectXShaderCompiler' | grep -v '/libs/' | grep '\.yml')
    echo "$sources" | while read line ; do update_zig "$version" "$line" ; done
else
    echo "must specify e.g. ZIG_VERSION=0.10.0-dev.2017+a0a2ce92c"
    exit 0
fi
