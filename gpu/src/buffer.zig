const std = @import("std");
const ChainedStruct = @import("types.zig").ChainedStruct;

pub const Buffer = enum(usize) {
    _,

    pub const none: Buffer = @intToEnum(Buffer, 0);

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

    pub const Usage = packed struct {
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

        pub const none = Usage{};

        pub fn equal(a: Usage, b: Usage) bool {
            return @truncate(u10, @bitCast(u32, a)) == @truncate(u10, @bitCast(u32, b));
        }
    };

    pub const BindingLayout = extern struct {
        next_in_chain: *const ChainedStruct,
        type: BindingType,
        has_dynamic_offset: bool = false,
        min_binding_size: u64 = 0,
    };

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        usage: Usage,
        size: u64,
        mapped_at_creation: bool,
    };
};
