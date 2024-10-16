---
name: (dev) Zig version update
about: The process we follow to perform a Zig version update
title: 'all: nominate Zig YYYY.MM.0-mach'
labels: all, zig-update
assignees: 'slimsag'

---

Periodically we [nominate a new Zig nightly version](https://machengine.org/about/nominated-zig) to be the version that Mach targets, and begin the meticulous process of updating every Mach project to use that new version.

This is the tracking issue to do that for the next scheduled nomination (see the date in the issue title.)

You may have been linked to this issue because you sent a pull request to update a Mach project to use a new Zig API - if that is the case we do appreciate the PR and will look at merging it once this process begins. In the meantime, your PR may stay open for a while. You can either use a fork of the project, or [use the version of Zig that Mach currently supports.](https://machengine.org/about/zig-version)

## Update process

* [ ] It is time to begin (see date in issue title, we aim to begin this checklist between the 1st-4th of that month.)
* [ ] In `machengine.org` repository `static/zig` folder, `wrench script nominate-zig-index-update nominate 2024.1.0-mach-wip` has been ran and the [`index.json`](https://machengine.org/zig/index.json) has been updated.
* [ ] #wrench automation (`!wrench schedule-now update-zig-version`) has created new pull requests to update the Zig version used in CI of all our projects, and it matches index.json.
* [ ] The [_Nomination history_](https://machengine.org/about/nominated-zig/#nomination-history) has a new section for the latest nightly Zig version which Wrench used in its PRs, with a warning at the top `**IN-PROGRESS:** This version is currently being nominated, see [the tracking issue](https://github.com/hexops/mach/issues/1135) for details. Once everything looks good, the new Zig version is confirmed to be working with Mach, we will declare success, close the issue, and remove this in-progress warning.`.
* [ ] #contributing Discord message: `Beginning the process of nominating a new Zig version; $GITHUB_ISSUE`
* [ ] #wrench automation (`!wrench script-all install-zig`) has updated the Zig version used by self-hosted GitHub actions runners.
* [ ] "First-order projects" below (which have zero build.zig.zon dependencies) have been updated, their CI is passing/green using the new version.
* [ ] "Second-order projects" below (which have build.zig.zon dependencies) have been updated, their CI is passing/green using the new version.
* [ ] The `.zigversion` file https://github.com/hexops/mach/blob/main/.zigversion has been updated.
* [ ] The mach build.zig version check has been updated: https://github.com/hexops/mach/blob/main/build.zig#L427-L432
* [ ] https://machengine.org/docs/zig-version has been updated
* [ ] In `machengine.org` repository `static/zig` folder, `wrench script nominate-zig-index-update finalize 2024.1.0-mach-wip` has been ran and the [`index.json`](https://machengine.org/zig/index.json) has had `-wip` removed and the `mach-latest` entry has been updated.
* [ ] The `**IN-PROGRESS**` warning in the _Nomination history_ has been removed.
* [ ] A [new issue](https://github.com/hexops/mach/issues/new?assignees=slimsag&labels=all%2C+zig-update&projects=&template=dev_zig_nomination.md&title=all%3A+nominate+Zig+YYYY.MM) has been filed for the next nomination.
* [ ] A #progress announcement has been made:

> We've just finalized nominating and updating to Zig 2024.1.0-mach. We encourage you to update your projects to that Zig version now. :)
>
> * Get the new Zig version: https://machengine.org/about/nominated-zig/#202410-mach
> * Tips on upgrading your own Zig code: https://github.com/hexops/mach/issues/1135#issuecomment-1891175749
> * Nomination tracking issue: $GITHUB_ISSUE

## First-order projects

These projects have zero `build.zig.zon` dependencies, we update them first - and in any order.

* [ ] [fastfilter](https://github.com/hexops/fastfilter)
* [ ] [spirv-cross](https://github.com/hexops/spirv-cross)
* [ ] [brotli](https://github.com/hexops/brotli)
* [ ] [wayland-headers](https://github.com/hexops/wayland-headers)
* [ ] [x11-headers](https://github.com/hexops/x11-headers)
* [ ] [vulkan-headers](https://github.com/hexops/vulkan-headers)
* [ ] [opengl-headers](https://github.com/hexops/opengl-headers)
* [ ] [linux-audio-headers](https://github.com/hexops/linux-audio-headers)
* [ ] [xcode-frameworks](https://github.com/hexops/xcode-frameworks)
* [ ] [vulkan-zig-generated](https://github.com/hexops/vulkan-zig-generated)
* [ ] [directx-headers](https://github.com/hexops/directx-headers)
* [ ] [direct3d-headers](https://github.com/hexops/direct3d-headers)
* [ ] [opus](https://github.com/hexops/opus)
* [ ] [flac](https://github.com/hexops/flac)
* [ ] [ogg](https://github.com/hexops/ogg)
* [ ] [mach-example-assets](https://github.com/hexops/mach-example-assets)
* [ ] [font-assets](https://github.com/hexops/font-assets)

## Second-order projects

These projects have dependencies on other projects. We update them in the exact order below, top-to-bottom.

* [ ] [spirv-tools](https://github.com/hexops/spirv-tools), which depends on:
  * External package https://github.com/KhronosGroup/SPIRV-Headers
* [ ] [opusenc](https://github.com/hexops/opusenc), which depends on:
  * opus
* [ ] [freetype](https://github.com/hexops/freetype), which depends on:
  * brotli
* [ ] [opusfile](https://github.com/hexops/opusfile), which depends on:
  * opus
  * ogg
* [ ] [harfbuzz](https://github.com/hexops/harfbuzz), which depends on:
  * freetype
  * brotli
* [ ] [mach-dxcompiler](https://github.com/hexops/mach-dxcompiler), which depends on:
* [ ] [mach-objc](https://github.com/hexops/mach-objc), which depends on:
  * xcode-frameworks
* [ ] [mach-freetype](https://github.com/hexops/mach-freetype), which depends on:
  * freetype
  * harfbuzz
  * font-assets
* [ ] [mach-flac](https://github.com/hexops/mach-flac), which depends on:
  * flac
  * mach-sysaudio
  * linux-audio-headers
* [ ] [mach-opus](https://github.com/hexops/mach-opus), which depends on:
  * opusfile
  * opusenc 
  * mach-sysaudio
  * linux-audio-headers
* [ ] [mach](https://github.com/hexops/mach), which depends on:
  * .zigversion
  * build.zig version check
  * mach-freetype
  * font-assets
  * mach-objc
  * mach-example-assets
  * spirv-cross
  * spirv-tools
  * xcode-frameworks
  * vulkan-zig-generated
  * direct3d-headers
  * opengl-headers
  * x11-headers
  * linux-audio-headers
  * wayland-headers
