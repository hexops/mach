#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

# Prepare the `out/` directory that we will bundle.
rm -rf out/
mkdir out/
cp -R libs/dawn/include out/
cp -R libs/dawn/out/Debug/gen/include/* out/include/
cp libs/dawn/LICENSE out/
zig version > out/ZIG_VERSION

# Bundle headers.json.gz
pushd out
python ../dev/dir_to_json.py > ../headers.json
popd
gzip -9 headers.json

# Copy the binary into the out/ directory
cp zig-out/lib/libdawn.a out/

# Create out.tar.gz bundle
pushd out
tar -czvf ../out.tar.gz .
popd
