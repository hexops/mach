# Known issues

If you're trying the commands [on the homepage](https://hexops.com/mach/) and running into issues, it may be one of these known issues.

## Windows: File not found

If you encounter an error like this:

![image](https://user-images.githubusercontent.com/3173176/160296281-0f68cfb9-65b0-4c0a-9623-2b2132f96a4b.png)

Windows does not have symlinks enabled, or Git is not configured to use them. This is very annoying and [has been reported to Microsoft](https://twitter.com/slimsag/status/1508114938933362688).

**Two solutions:**

1. (recommended) Build a native Windows binary by cross-compiling from WSL -> Windows:
  * `cd mach/gpu`
  * `zig build -Dtarget=x86_64-windows`
  * Run the exe in `zig-out/bin/` outside of WSL.
2. Enable symlinks in Windows:
  * [Turn on Development Mode](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development)
  * [Ensure symlinks are installed in Git](https://stackoverflow.com/a/59761201) `git config --global core.symlinks true`
  * Re-clone the repository and try again.

3. Use `git clone --recursive`

## Windows: "SSL certificate problem: unable to get local issuer certificate"

This is a curl SSL CA issue, you may want to Google for proper solutions on your system. That said, you can `set CURL_INSECURE=true` and retry to disable SSL verification if you want to workaround the issue.

## Linux: `Error: vkCreateInstance failed with VK_ERROR_INCOMPATIBLE_DRIVER`

Some distros require packages to be installed to support the Vulkan graphics API.

For instance, Arch Linux has [specific packages](https://wiki.archlinux.org/title/Vulkan#Installation) for Nvidia, Intel and AMD GPUs.

You may also try using OpenGL using the env var `MACH_GPU_BACKEND=opengl`.

## Linux: `Error: Couldn't load Vulkan. Searched /tmp/mach/gpu/zig-out/bin/libvulkan.so.1`

We're aware of a bug failing to find `libvulkan.so` on some Linux distros such as [Guix](https://guix.gnu.org/).

```
Error: Couldn't load Vulkan. Searched /tmp/mach/gpu/zig-out/bin/libvulkan.so.1, /tmp/mach/gpu/zig-out/bin/libvulkan.so.1, libvulkan.so.1.
    at operator() (/home/runner/work/mach-gpu-dawn/mach-gpu-dawn/libs/dawn/src/dawn/native/vulkan/BackendVk.cpp:198)
    at Initialize (/home/runner/work/mach-gpu-dawn/mach-gpu-dawn/libs/dawn/src/dawn/native/vulkan/BackendVk.cpp:203)
    at Create (/home/runner/work/mach-gpu-dawn/mach-gpu-dawn/libs/dawn/src/dawn/native/vulkan/BackendVk.cpp:165)
    at operator() (/home/runner/work/mach-gpu-dawn/mach-gpu-dawn/libs/dawn/src/dawn/native/vulkan/BackendVk.cpp:420)

found Null backend on CPU adapter: Null backend,
```

This is [a bug in Dawn](https://github.com/NixOS/nixpkgs/issues/150398), you can workaround it for now by specifying the path to `libvulkan.so` on your system `LD_PRELOAD` like e.g.:

```
LD_PRELOAD=/run/current-system/profile/lib/libvulkan.so zig-out/bin/gpu-hello-triangle
```

## Choosing a different GitHub download mirror (Chinese users)

**Background**: `zig build` on the first time around will download a 20-30MB file of Dawn (Google's WebGPU implementation) from https://github.com/hexops/mach-gpu-dawn/releases - the build system uses `curl` to do this automatically. You can of course build Dawn from source using the `-Ddawn-from-source=true` flag, but this will require a clone of the Dawn sources which are a larger download and takes a few minutes to build as it is a large C++ codebase.

Users in Chinese mainland may find that download speeds to github.com are too slow (hours to download a 30 MB file), and apparently it is common to use GitHub mirror sites like https://fastgit.org to download files from GitHub.

You can have Mach use such websites by setting an environment variable e.g.:

```sh
MACH_GITHUB_BASE_URL=https://download.fastgit.org
```
