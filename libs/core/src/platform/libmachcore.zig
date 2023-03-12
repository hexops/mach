const std = @import("std");
const testing = std.testing;
const gpu = @import("gpu");
const ecs = @import("ecs");
const glfw = @import("glfw");
const Core = @import("../Core.zig");
const native = @import("native.zig");

pub const GPUInterface = gpu.dawn.Interface;

const _ = gpu.Export(GPUInterface);

// Current Limitations:
// 1. Currently, ecs seems to be using some weird compile-time type trickery, so I'm not exactly sure how
// `engine` should be integrated into the C API
// 2. Core might need to expose more state so more API functions can be exposed (for example, the WebGPU API)
// 3. Be very careful about arguments, types, memory, etc - any mismatch will result in undefined behavior

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const MachCoreInstance = anyopaque;

// Returns a pointer to a newly allocated Core
// Will return a null pointer if an error occurred while initializing Core
pub export fn mach_core_init() ?*MachCoreInstance {
    if (!@import("builtin").is_test) gpu.Impl.init();

    // TODO(libmach): eliminate this allocation
    var core = allocator.create(native.Core) catch {
        return null;
    };
    // TODO(libmach): allow passing init options
    core.init(allocator, .{}) catch {
        // TODO(libmach): better error handling
        return null;
    };
    return core;
}

pub export fn mach_core_deinit(_core: *MachCoreInstance) void {
    var core = @ptrCast(*native.Core, @alignCast(@alignOf(@TypeOf(_core)), _core));
    native.Core.deinit(core);
}

pub const MachCoreEventIterator = extern struct {
    _data: [8]u8,
};

pub const MachCoreEvent = Core.Event;

pub export fn mach_core_poll_events(_core: *MachCoreInstance) MachCoreEventIterator {
    var core = @ptrCast(*native.Core, @alignCast(@alignOf(@TypeOf(_core)), _core));
    var iter = native.Core.pollEvents(core);
    return @ptrCast(*MachCoreEventIterator, &iter).*;
}

pub export fn mach_core_event_iterator_next(_iter: *MachCoreEventIterator, event: *MachCoreEvent) bool {
    var iter = @ptrCast(*native.Core.EventIterator, @alignCast(@alignOf(@TypeOf(_iter)), _iter));
    var value = iter.next() orelse return false;
    event.* = value;
    return true;
}

const MachStatus = enum(c_int) {
    Success = 0x00000000,
    Error = 0x00000001,
};

test "C sizes" {
    const c_header = @cImport({
        @cInclude("libmachcore.h");
    });

    // Core.EventIterator can have different sizes depending on the platform,
    // so we ensure we always use the maximum size in our C API.
    if (@sizeOf(Core.EventIterator) > @sizeOf(MachCoreEventIterator)) {
        try testing.expectEqual(@sizeOf(Core.EventIterator), @sizeOf(MachCoreEventIterator));
    }

    try testing.expectEqual(@sizeOf(c_header.MachCoreEventIterator), @sizeOf(MachCoreEventIterator));
}
