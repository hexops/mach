#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"/..

push_subrepo() {
    local project=$1

    echo "    ----------------------------------------------------------------------------"
    echo "    | 🚀🐒 Preparing: mach-$project"
    echo "    ----------------------------------------------------------------------------"
    cp -R staging-clean staging/
    cd staging/

    # Rewrite e.g. libs/freetype/ -> freetype/ so we have Git history for that subrepo in one path
    # only (git subtree cannot follow renames.) For glfw, gpu-dawn, and freetype they were in the
    # root before being under libs/ and so this is required to generate the proper history.
    if [[ "$project" == "glfw" ]]; then
        # glfw has an unfortunately non-linear history, and so we can't preserve commit hashes
        # or else the subtree push cannot rebuild history properly.
        git filter-repo --force \
            --path $project \
            --path "libs/$project" \
            --path-rename libs/$project:$project
    else
        git filter-repo --force \
            --preserve-commit-hashes \
            --path $project \
            --path "libs/$project" \
            --path-rename libs/$project:$project
    fi

    # Push changes to the external subrepo.
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
        git remote add -f "mach-$project" "https://slimsag:$ACCESS_TOKEN@github.com/hexops/mach-$project" || true
    else
        git remote add -f "mach-$project" "git@github.com:hexops/mach-$project" || true
    fi
    git fetch "mach-$project"

    echo "    ----------------------------------------------------------------------------"
    echo "    | 🚀🐒 Pushing: mach-$project"
    echo "    ----------------------------------------------------------------------------"
    git subtree push --prefix "$project" "mach-$project" main

    cd ..
    rm -rf staging/
    echo "    ----------------------------------------------------------------------------"
    echo "    | 🚀🐒 Finished: mach-$project"
    echo "    ----------------------------------------------------------------------------"
}

rm -rf staging-clean/ staging/
git clone https://github.com/hexops/mach staging-clean

push_subrepo 'basisu'
push_subrepo 'core'
push_subrepo 'dusk'
push_subrepo 'earcut'
push_subrepo 'ecs'
push_subrepo 'freetype'
push_subrepo 'gamemode'
push_subrepo 'glfw'
push_subrepo 'gpu'
push_subrepo 'gpu-dawn'
push_subrepo 'model3d'
push_subrepo 'sysaudio'
push_subrepo 'sysjs'

rm -rf staging-clean
