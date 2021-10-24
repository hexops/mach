#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

git remote add -f mach-glfw git@github.com:hexops/mach-glfw || true
git fetch mach-glfw
