#!/usr/bin/env bash
set -ex

# GLFW
rm -rf upstream/
mkdir upstream/
cd upstream/
git clone --depth 1 --branch 3.3.6 https://github.com/glfw/glfw
cd glfw/

# Remove non-C files
rm -rf .appveyor.yml .git .github .gitattributes .gitignore .mailmap .travis.yml
rm cmake_uninstall.cmake.in README.md CONTRIBUTORS.md
rm -r CMake* deps/ examples/ tests/ docs/
rm src/CMakeLists.txt src/*.in

# Vulkan headers
cd ..
git clone --depth 1 https://github.com/KhronosGroup/Vulkan-Headers vulkan_headers/
cd vulkan_headers
rm -rf .git .github registry/ *.gn *.txt *.md cmake/ 
rm -rf include/vk_video
rm .cmake-format.py .gitattributes .gitignore
