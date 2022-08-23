#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

./dev/update-subrepos.sh
git subtree push --prefix libs/glfw mach-glfw main
git subtree push --prefix libs/gpu-dawn mach-gpu-dawn main
git subtree push --prefix libs/freetype mach-freetype main
