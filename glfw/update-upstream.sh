#!/usr/bin/env bash
set -ex

rm -rf upstream/
mkdir upstream/
cd upstream/
git clone https://github.com/glfw/glfw
cd glfw/
git checkout 3.3.4

# Remove non-C files
rm -rf .appveyor.yml .git .gitattributes .gitignore .mailmap .travis.yml
rm cmake_uninstall.cmake.in README.md
rm -r CMake* deps/ examples/ tests/ docs/
rm src/CMakeLists.txt src/*.in
