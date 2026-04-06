const builtin = @import("builtin");

pub usingnamespace @cImport({
    if (builtin.target.os.tag == .windows) {
        @cInclude("windows.h");
        @cInclude("GL/glcorearb.h");
        @cInclude("GL/glext.h");
        @cInclude("GL/wglext.h");
    } else if (builtin.target.os.tag == .linux) {
        @cInclude("GL/glcorearb.h");
        @cInclude("GL/glext.h");
    }
});
