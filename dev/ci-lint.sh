#!/usr/bin/env bash
set -exuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

# actionlint: https://github.com/rhysd/actionlint
actionlint $(find . | grep -v '\.git/' | grep '\.github/workflows/' | grep '.yml')

# yamlfmt: https://github.com/google/yamlfmt
yamlfmt '**/.github/**/*.yml' '**/.github/**/*.yaml'
