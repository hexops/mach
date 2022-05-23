#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

./dev/update-subrepos.sh
git subtree push --prefix glfw mach-glfw main
git subtree push --prefix gpu-dawn mach-gpu-dawn main
git subtree push --prefix freetype mach-freetype main
