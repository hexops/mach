const std = @import("std");
const ChainedStruct = @import("types.zig").ChainedStruct;
const MapModeFlags = @import("types.zig").MapModeFlags;
const Impl = @import("interface.zig").Impl;

pub const Buffer = opaque {
    pub const MapCallback = fn (status: MapAsyncStatus, userdata: ?*anyopaque) callconv(.C) void;

    pub const BindingType = enum(u32) {
        undef = 0x00000000,
        uniform = 0x00000001,
        storage = 0x00000002,
        read_only_storage = 0x00000003,
    };

    pub const MapAsyncStatus = enum(u32) {
        success = 0x00000000,
        err = 0x00000001,
        unknown = 0x00000002,
        device_lost = 0x00000003,
        destroyed_before_callback = 0x00000004,
        unmapped_before_callback = 0x00000005,
    };

    pub const UsageFlags = packed struct {
        map_read: bool = false,
        map_write: bool = false,
        copy_src: bool = false,
        copy_dst: bool = false,
        index: bool = false,
        vertex: bool = false,
        uniform: bool = false,
        storage: bool = false,
        indirect: bool = false,
        query_resolve: bool = false,

        _padding: u22 = 0,

        comptime {
            std.debug.assert(
                @sizeOf(@This()) == @sizeOf(u32) and
                    @bitSizeOf(@This()) == @bitSizeOf(u32),
            );
        }

        pub const none = UsageFlags{};

        pub fn equal(a: UsageFlags, b: UsageFlags) bool {
            return @truncate(u10, @bitCast(u32, a)) == @truncate(u10, @bitCast(u32, b));
        }
    };

    pub const BindingLayout = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        type: BindingType = .undef,
        has_dynamic_offset: bool = false,
        min_binding_size: u64 = 0,
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        usage: UsageFlags,
        size: u64,
        mapped_at_creation: bool = true,
    };

    pub inline fn destroy(buffer: *Buffer) void {
        Impl.bufferDestroy(buffer);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_map_size`
    pub inline fn getConstMappedRange(buffer: *Buffer, offset: usize, size: usize) ?*const anyopaque {
        return Impl.bufferGetConstMappedRange(buffer, offset, size);
    }

    /// Default `offset`: 0
    /// Default `size`: `gpu.whole_map_size`
    pub inline fn getMappedRange(buffer: *Buffer, offset: usize, size: usize) ?*anyopaque {
        return Impl.bufferGetMappedRange(buffer, offset, size);
    }

    pub inline fn getSize(buffer: *Buffer) u64 {
        return Impl.bufferGetSize(buffer);
    }

    pub inline fn getUsage(buffer: *Buffer) Buffer.UsageFlags {
        return Impl.bufferGetUsage(buffer);
    }

    pub inline fn mapAsync(
        buffer: *Buffer,
        mode: MapModeFlags,
        offset: usize,
        size: usize,
        comptime Context: type,
        comptime callback: fn (status: MapAsyncStatus, ctx: Context) callconv(.Inline) void,
        context: Context,
    ) void {
        const Helper = struct {
            pub fn callback(status: MapAsyncStatus, userdata: ?*anyopaque) callconv(.C) void {
                callback(status, if (Context == void) {} else @ptrCast(Context, userdata));
            }
        };
        Impl.bufferMapAsync(buffer, mode, offset, size, Helper.callback, if (Context == void) null else context);
    }

    pub inline fn setLabel(buffer: *Buffer, label: [*:0]const u8) void {
        Impl.bufferSetLabel(buffer, label);
    }

    pub inline fn unmap(buffer: *Buffer) void {
        Impl.bufferUnmap(buffer);
    }

    pub inline fn reference(buffer: *Buffer) void {
        Impl.bufferReference(buffer);
    }

    pub inline fn release(buffer: *Buffer) void {
        Impl.bufferRelease(buffer);
    }
};
