---
name: (dev) Release checklist
about: The checklist we follow to perform a Mach release
title: 'all: Mach 0.3 release checklist'
labels: all, zig-update
assignees: 'emidoots'

---

This is a tracking issue for preparing the next Mach release.

## Checklist

* [ ] In `mach` repository, the release has been tagged (`git tag v0.3.0 && git push origin v0.3.0`)
* [ ] In `machengine.org` repository `static/zig` folder, `wrench script nominate-zig-index-update tag 2024.1.0-mach 0.3.0-mach` has been ran to tag the Zig version that the Mach release will use, and the [`index.json`](https://machengine.org/zig/index.json) shows the new version.
* [ ] In `machengine.org` main branch, `deploy.yml` has a new `hugo --minify` entry for the version to be released
* [ ] In `machengine.org` main branch, `zig-version.md` has been updated with a new `Supported Zig versions` entry
* [ ] 
* [ ] In `machengine.org` repository, a branch for the major release has been created `git checkout -B v0.3 && git push --set-upstream origin v0.3`
* [ ] In `machengine.org` repository's new major release branch `v0.3`, `config.toml`'s `branch = 'main'` has been changed to `branch = 'v0.3'` and https://machengine.org/v0.3 now loads fine
