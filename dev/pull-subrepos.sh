#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

./dev/update-subrepos.sh
git subtree pull --prefix glfw mach-glfw main
