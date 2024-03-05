const Bool32 = @import("main.zig").Bool32;
const ChainedStruct = @import("main.zig").ChainedStruct;
const ShaderStageFlags = @import("main.zig").ShaderStageFlags;
const Buffer = @import("buffer.zig").Buffer;
const Sampler = @import("sampler.zig").Sampler;
const Texture = @import("texture.zig").Texture;
const TextureView = @import("texture_view.zig").TextureView;
const StorageTextureBindingLayout = @import("main.zig").StorageTextureBindingLayout;
const StorageTextureAccess = @import("main.zig").StorageTextureAccess;
const ExternalTexture = @import("external_texture.zig").ExternalTexture;
const Impl = @import("interface.zig").Impl;

pub const BindGroupLayout = opaque {
    pub const Entry = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStruct,
            external_texture_binding_layout: *const ExternalTexture.BindingLayout,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        binding: u32,
        visibility: ShaderStageFlags,
        buffer: Buffer.BindingLayout = .{},
        sampler: Sampler.BindingLayout = .{},
        texture: Texture.BindingLayout = .{},
        storage_texture: StorageTextureBindingLayout = .{},

        /// Helper to create a buffer BindGroupLayout.Entry.
        pub fn buffer(
            binding: u32,
            visibility: ShaderStageFlags,
            binding_type: Buffer.BindingType,
            has_dynamic_offset: bool,
            min_binding_size: u64,
        ) Entry {
            return .{
                .binding = binding,
                .visibility = visibility,
                .buffer = .{
                    .type = binding_type,
                    .has_dynamic_offset = Bool32.from(has_dynamic_offset),
                    .min_binding_size = min_binding_size,
                },
            };
        }

        /// Helper to create a sampler BindGroupLayout.Entry.
        pub fn sampler(
            binding: u32,
            visibility: ShaderStageFlags,
            binding_type: Sampler.BindingType,
        ) Entry {
            return .{
                .binding = binding,
                .visibility = visibility,
                .sampler = .{ .type = binding_type },
            };
        }

        /// Helper to create a texture BindGroupLayout.Entry.
        pub fn texture(
            binding: u32,
            visibility: ShaderStageFlags,
            sample_type: Texture.SampleType,
            view_dimension: TextureView.Dimension,
            multisampled: bool,
        ) Entry {
            return .{
                .binding = binding,
                .visibility = visibility,
                .texture = .{
                    .sample_type = sample_type,
                    .view_dimension = view_dimension,
                    .multisampled = Bool32.from(multisampled),
                },
            };
        }

        /// Helper to create a storage texture BindGroupLayout.Entry.
        pub fn storageTexture(
            binding: u32,
            visibility: ShaderStageFlags,
            access: StorageTextureAccess,
            format: Texture.Format,
            view_dimension: TextureView.Dimension,
        ) Entry {
            return .{
                .binding = binding,
                .visibility = visibility,
                .storage_texture = .{
                    .access = access,
                    .format = format,
                    .view_dimension = view_dimension,
                },
            };
        }
    };

    pub const Descriptor = extern struct {
        next_in_chain: ?*const ChainedStruct = null,
        label: ?[*:0]const u8 = null,
        entry_count: usize = 0,
        entries: ?[*]const Entry = null,

        /// Provides a slightly friendlier Zig API to initialize this structure.
        pub inline fn init(v: struct {
            next_in_chain: ?*const ChainedStruct = null,
            label: ?[*:0]const u8 = null,
            entries: ?[]const Entry = null,
        }) Descriptor {
            return .{
                .next_in_chain = v.next_in_chain,
                .label = v.label,
                .entry_count = if (v.entries) |e| e.len else 0,
                .entries = if (v.entries) |e| e.ptr else null,
            };
        }
    };

    pub inline fn setLabel(bind_group_layout: *BindGroupLayout, label: [*:0]const u8) void {
        Impl.bindGroupLayoutSetLabel(bind_group_layout, label);
    }

    pub inline fn reference(bind_group_layout: *BindGroupLayout) void {
        Impl.bindGroupLayoutReference(bind_group_layout);
    }

    pub inline fn release(bind_group_layout: *BindGroupLayout) void {
        Impl.bindGroupLayoutRelease(bind_group_layout);
    }
};
