const ChainedStruct = @import("main.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const Impl = @import("interface.zig").Impl;

pub const PipelineLayout = opaque {
    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        bind_group_layout_count: usize = 0,
        bind_group_layouts: ?[*]const *BindGroupLayout = null,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: ?*const ChainedStruct = null,
            label: ?[*:0]const u8 = null,
            bind_group_layouts: ?[]const *BindGroupLayout = null,
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .bind_group_layout_count = if (v.bind_group_layouts) |e| e.len else 0,
                .bind_group_layouts = if (v.bind_group_layouts) |e| e.ptr else null,
            };
        }
    };

    pub inline fn setLabel(pipeline_layout: *PipelineLayout, label: [*:0]const u8) void {
        Impl.pipelineLayoutSetLabel(pipeline_layout, label);
    }

    pub inline fn reference(pipeline_layout: *PipelineLayout) void {
        Impl.pipelineLayoutReference(pipeline_layout);
    }

    pub inline fn release(pipeline_layout: *PipelineLayout) void {
        Impl.pipelineLayoutRelease(pipeline_layout);
    }
};
