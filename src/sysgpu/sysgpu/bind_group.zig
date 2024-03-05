const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const TextureView = @import("texture_view.zig").TextureView;
const ChainedStruct = @import("main.zig").ChainedStruct;
const BindGroupLayout = @import("bind_group_layout.zig").BindGroupLayout;
const ExternalTexture = @import("external_texture.zig").ExternalTexture;
const Impl = @import("interface.zig").Impl;

pub const BindGroup = opaque {
    pub const Entry = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            external_texture_binding_entry: *const ExternalTexture.BindingEntry,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        binding: u32,
        buffer: ?*Buffer = null,
        offset: u64 = 0,
        size: u64,
        elem_size: u32 = 0, // TEMP - using StructuredBuffer until we switch to DXC for templatized raw buffers
        sampler: ?*Sampler = null,
        texture_view: ?*TextureView = null,

        /// Helper to create a buffer BindGroup.Entry.
        pub fn buffer(binding: u32, buf: *Buffer, offset: u64, size: u64, elem_size: u32) Entry {
            return .{
                .binding = binding,
                .buffer = buf,
                .offset = offset,
                .size = size,
                .elem_size = elem_size,
            };
        }

        /// Helper to create a sampler BindGroup.Entry.
        pub fn sampler(binding: u32, _sampler: *Sampler) Entry {
            return .{
                .binding = binding,
                .sampler = _sampler,
                .size = 0,
            };
        }

        /// Helper to create a texture view BindGroup.Entry.
        pub fn textureView(binding: u32, texture_view: *TextureView) Entry {
            return .{
                .binding = binding,
                .texture_view = texture_view,
                .size = 0,
            };
        }
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        layout: *BindGroupLayout,
        entry_count: usize = 0,
        entries: ?[*]const Entry = null,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: ?*const ChainedStruct = null,
            label: ?[*:0]const u8 = null,
            layout: *BindGroupLayout,
            entries: ?[]const Entry = null,
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .layout = v.layout,
                .entry_count = if (v.entries) |e| e.len else 0,
                .entries = if (v.entries) |e| e.ptr else null,
            };
        }
    };

    pub inline fn setLabel(bind_group: *BindGroup, label: [*:0]const u8) void {
        Impl.bindGroupSetLabel(bind_group, label);
    }

    pub inline fn reference(bind_group: *BindGroup) void {
        Impl.bindGroupReference(bind_group);
    }

    pub inline fn release(bind_group: *BindGroup) void {
        Impl.bindGroupRelease(bind_group);
    }
};
