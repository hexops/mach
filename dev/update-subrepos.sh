#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

if [ -n "${GITHUB_ACTIONS:-}" ]; then
    git remote add -f mach-glfw "https://slimsag:$ACCESS_TOKEN@github.com/hexops/mach-glfw" || true
    git remote add -f mach-gpu-dawn "https://slimsag:$ACCESS_TOKEN@github.com/hexops/mach-gpu-dawn" || true
    git remote add -f mach-freetype "https://slimsag:$ACCESS_TOKEN@github.com/hexops/mach-freetype" || true
else
    git remote add -f mach-glfw git@github.com:hexops/mach-glfw || true
    git remote add -f mach-gpu-dawn git@github.com:hexops/mach-gpu-dawn || true
    git remote add -f mach-freetype git@github.com:hexops/mach-freetype || true
fi

git fetch mach-glfw
git fetch mach-gpu-dawn
git fetch mach-freetype
