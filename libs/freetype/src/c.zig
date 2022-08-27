pub usingnamespace if (@import("builtin").zig_backend == .stage1 or !@import("builtin").target.isDarwin())
    @cImport({
        @cInclude("hb-ft.h");
        @cInclude("freetype/ftadvanc.h");
        @cInclude("freetype/ftbbox.h");
        @cInclude("freetype/ftbitmap.h");
        @cInclude("freetype/ftcolor.h");
        @cInclude("freetype/ftlcdfil.h");
        @cInclude("freetype/ftsizes.h");
        @cInclude("freetype/ftstroke.h");
        @cInclude("freetype/fttrigon.h");
    })
else
    // TODO(self-hosted): HACK: workaround https://github.com/ziglang/zig/issues/12483
    //
    // Extracted from a build using stage1 from zig-cache/ (`cimport.zig`)
    // Then find+replace `= ?fn` -> `= ?*const fn`
    @import("cimport1.zig");
