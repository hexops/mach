pub const c = if (@import("builtin").zig_backend == .stage1)
    @cImport({
        @cDefine("GLFW_INCLUDE_VULKAN", "1");
        @cInclude("GLFW/glfw3.h");
    })
else
    // TODO(self-hosted): HACK: workaround https://github.com/ziglang/zig/issues/12483
    //
    // Extracted from a build using stage1 from zig-cache/ (`cimport.zig`)
    // Then find+replace `= ?fn` -> `= ?*const fn`
    @import("cimport2.zig");
