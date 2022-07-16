const ChainedStruct = @import("types.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;

pub const PipelineLayout = enum(usize) {
    _,

    // TODO: verify there is a use case for nullable value of this type.
    pub const none: PipelineLayout = @intToEnum(PipelineLayout, 0);

    pub const Descriptor = extern struct {
        next_in_chain: *const ChainedStruct,
        label: ?[*:0]const u8 = null,
        bind_group_layout_count: u32,
        bind_group_layouts: [*]const BindGroupLayout,
    };
};
