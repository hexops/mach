const std = @import("std");
const App = @import("app");
const Engine = @import("Engine.zig");
const structs = @import("structs.zig");
const enums = @import("enums.zig");

const js = struct {};

pub const CoreWasm = struct {
    pub fn init(_: std.mem.Allocator, _: *Engine) !CoreWasm {
        return CoreWasm{};
    }

    pub fn setShouldClose(_: *CoreWasm, _: bool) void {}

    pub fn getFramebufferSize(_: *CoreWasm) !structs.Size {
        return structs.Size{ .width = 0, .height = 0 };
    }

    pub fn setSizeLimits(_: *CoreWasm, _: structs.SizeOptional, _: structs.SizeOptional) !void {}

    pub fn pollEvent(_: *CoreWasm) ?structs.Event {
        return null;
    }
};

pub const GpuDriverWeb = struct {
    pub fn init(_: std.mem.Allocator, _: *Engine) !GpuDriverWeb {
        return GpuDriverWeb{};
    }
};

var app: App = undefined;
var engine: Engine = undefined;

export fn wasmInit() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const options = if (@hasDecl(App, "options")) App.options else structs.Options{};
    engine = Engine.init(allocator, options) catch unreachable;

    app.init(&engine) catch {};
}

export fn wasmUpdate() bool {
    return app.update(&engine) catch false;
}

export fn wasmDeinit() void {
    app.deinit(&engine);
}
