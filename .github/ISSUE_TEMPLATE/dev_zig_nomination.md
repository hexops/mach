---
name: (dev) Zig version update
about: The process we follow to perform a Zig version update
title: 'all: nominate Zig YYYY.MM'
labels: all, zig-update
assignees: 'slimsag'

---

Periodically we [nominate a new Zig nightly version](https://machengine.org/about/nominated-zig) to be the version that Mach targets, and begin the meticulous process of updating every Mach project to use that new version.

This is the tracking issue to do that for the next scheduled nomination (see the date in the issue title.)

You may have been linked to this issue because you sent a pull request to update a Mach project to use a new Zig API - if that is the case we do appreciate the PR and will look at merging it once this process begins. In the meantime, your PR may stay open for a while. You can either use a fork of the project, or [use the version of Zig that Mach currently supports.](https://machengine.org/about/zig-version)

## Update process

* [ ] It is time to begin (see date in issue title, we aim to begin this checklist between the 1st-4th of that month.)
* [ ] #wrench automation (`!wrench schedule-now update-zig-version`) has created new pull requests to update the Zig version used in CI of all our projects.
* [ ] The [_Nomination history_](https://machengine.org/about/nominated-zig/#nomination-history) has a new section for the latest nightly Zig version which Wrench used in its PRs, with a warning at the top `**IN-PROGRESS:** This version is currently being nominated, see [the tracking issue](https://github.com/hexops/mach/issues/1135) for details. Once everything looks good, the new Zig version is confirmed to be working with Mach, we will declare success, close the issue, and remove this in-progress warning.`.
* [ ] #general Discord message: `Beginning the process of nominating a new Zig version! (you should wait to upgrade until we've updated everything to confirm it works) $GITHUB_ISSUE`
* [ ] "First-order projects" below (which have zero build.zig.zon dependencies) have been updated, their CI is passing/green using the new version.
* [ ] "Second-order projects" below (which have build.zig.zon dependencies) have been updated, their CI is passing/green using the new version.
* [ ] The `.zigversion` file https://github.com/hexops/mach/blob/main/.zigversion has been updated.
* [ ] The mach build.zig version check has been updated: https://github.com/hexops/mach/blob/main/build.zig#L187-L192
* [ ] The mach-core build.zig version check has been updated: https://github.com/hexops/mach-core/blob/main/build.zig#L222-L227
* [ ] The mach-glfw build.zig version check has been updated: https://github.com/hexops/mach-glfw/blob/main/build.zig
* [ ] https://machengine.org/about/zig-version has been updated
* [ ] The `**IN-PROGRESS**` warning in the _Nomination history_ has been removed.
* [ ] A [new issue](https://github.com/hexops/mach/issues/new?assignees=slimsag&labels=all%2C+zig-update&projects=&template=dev_zig_nomination.md&title=all%3A+nominate+Zig+YYYY.MM) has been filed for the next nomination.
* [ ] A #progress announcement has been made:

> We've just finished updating to the new nominated Zig version 2024.01 (0.12.0-dev.2059+42389cb9c). We encourage you to update your projects to that Zig version now. :)
> $GITHUB_ISSUE

## First-order projects

These projects have zero `build.zig.zon` dependencies, we update them first - and in any order.

* [ ] mach-ecs
* [ ] mach-gamemode
* [ ] mach-model3d
* [ ] mach-sysjs
* [ ] mach-objc-generator
* [ ] fastfilter
* [ ] spirv-cross
* [ ] brotli
* [ ] wayland-headers
* [ ] x11-headers
* [ ] vulkan-headers
* [ ] opengl-headers
* [ ] linux-audio-headers
* [ ] xcode-frameworks
* [ ] basisu
* [ ] vulkan-zig-generated
* [ ] directx-headers
* [ ] direct3d-headers
* [ ] opus
* [ ] flac
* [ ] ogg
* [ ] mach-core-example-assets
* [ ] font-assets

## Second-order projects

These projects have dependencies on other projects. They may only be updated if all their dependencies have been updated first.

* [ ] spirv-tools, which depends on:
  * External package https://github.com/KhronosGroup/SPIRV-Headers 
* [ ] mach-core-starter-project, which depends on:
  * mach-core
* [ ] mach-editor, which depends on:
  * mach
  * mach-sysgpu
  * spirv-cross
  * spirv-tools
* [ ] mach-examples, which depends on:
  * zigimg
  * mach
  * mach-freetype
* [ ] mach, which depends on:
  * .zigversion
  * build.zig version check
  * mach-ecs
  * mach-core
  * mach-basisu
  * mach-sysaudio
  * mach-freetype
  * mach-sysjs
  * font-assets
* [ ] mach-core, which depends on:
  * build.zig version check
  * mach-core-example-assets
  * mach-gamemode
  * mach-sysgpu
  * mach-gpu
  * mach-glfw
* [ ] mach-gpu, which depends on:
  * mach-glfw
  * mach-gpu-dawn
* [ ] mach-gpu-dawn, which depends on:
  * xcode-frameworks
  * direct3d-headers
  * vulkan-headers
  * x11-headers
* [ ] mach-dxcompiler, which depends on:
  * directx-headers
* [ ] mach-basisu, which depends on:
  * basisu
* [ ] mach-freetype, which depends on:
  * freetype
  * harfbuzz
  * font-assets
* [ ] mach-glfw, which depends on:
  * glfw
* [ ] mach-sysgpu, which depends on:
  * vulkan-zig-generated
  * mach-gpu
  * mach-objc
  * direct3d-headers
  * opengl-headers
  * xcode-frameworks
* [ ] mach-sysaudio, which depends on:
  * mach-sysjs
  * linux-audio-headers
  * xcode-frameworks
* [ ] mach-objc, which depends on:
  * xcode-frameworks
* [ ] mach-opus, which depends on:
  * opusfile
  * mach-sysaudio
  * linux-audio-headers
* [ ] mach-flac, which depends on:
  * flac
  * mach-sysaudio
  * linux-audio-headers
* [ ] harfbuzz, which depends on:
  * freetype
  * brotli
* [ ] freetype, which depends on:
  * brotli
* [ ] glfw, which depends on:
  * xcode-frameworks
  * vulkan-headers
  * wayland-headers
  * x11-headers
* [ ] opusfile, which depends on:
  * opus
  * ogg
