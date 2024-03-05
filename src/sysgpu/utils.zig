const std = @import("std");
const limits = @import("limits.zig");
const shader = @import("shader.zig");
const sysgpu = @import("sysgpu/main.zig");

pub fn Manager(comptime T: type) type {
    return struct {
        count: u32 = 1,

        pub fn reference(manager: *@This()) void {
            _ = @atomicRmw(u32, &manager.count, .Add, 1, .Monotonic);
        }

        pub fn release(manager: *@This()) void {
            if (@atomicRmw(u32, &manager.count, .Sub, 1, .Release) == 1) {
                @fence(.Acquire);
                const parent = @fieldParentPtr(T, "manager", manager);
                parent.deinit();
            }
        }
    };
}

pub fn findChained(comptime T: type, next_in_chain: ?*const sysgpu.ChainedStruct) ?*const T {
    const search = @as(*align(1) const sysgpu.ChainedStruct, @ptrCast(std.meta.fieldInfo(T, .chain).default_value.?));
    var chain = next_in_chain;
    while (chain) |c| {
        if (c.s_type == search.s_type) {
            return @as(*const T, @ptrCast(c));
        }
        chain = c.next;
    }
    return null;
}

pub fn alignUp(x: usize, a: usize) usize {
    return (x + a - 1) / a * a;
}

pub const FormatType = enum {
    float,
    unorm,
    unorm_srgb,
    snorm,
    uint,
    sint,
    depth,
    stencil,
    depth_stencil,
};

pub fn vertexFormatType(format: sysgpu.VertexFormat) FormatType {
    return switch (format) {
        .undefined => unreachable,
        .uint8x2 => .uint,
        .uint8x4 => .uint,
        .sint8x2 => .sint,
        .sint8x4 => .sint,
        .unorm8x2 => .unorm,
        .unorm8x4 => .unorm,
        .snorm8x2 => .snorm,
        .snorm8x4 => .snorm,
        .uint16x2 => .uint,
        .uint16x4 => .uint,
        .sint16x2 => .sint,
        .sint16x4 => .sint,
        .unorm16x2 => .unorm,
        .unorm16x4 => .unorm,
        .snorm16x2 => .snorm,
        .snorm16x4 => .snorm,
        .float16x2 => .float,
        .float16x4 => .float,
        .float32 => .float,
        .float32x2 => .float,
        .float32x3 => .float,
        .float32x4 => .float,
        .uint32 => .uint,
        .uint32x2 => .uint,
        .uint32x3 => .uint,
        .uint32x4 => .uint,
        .sint32 => .sint,
        .sint32x2 => .sint,
        .sint32x3 => .sint,
        .sint32x4 => .sint,
    };
}

pub fn textureFormatType(format: sysgpu.Texture.Format) FormatType {
    return switch (format) {
        .undefined => unreachable,
        .r8_unorm => .unorm,
        .r8_snorm => .snorm,
        .r8_uint => .uint,
        .r8_sint => .sint,
        .r16_uint => .uint,
        .r16_sint => .sint,
        .r16_float => .float,
        .rg8_unorm => .unorm,
        .rg8_snorm => .snorm,
        .rg8_uint => .uint,
        .rg8_sint => .sint,
        .r32_float => .float,
        .r32_uint => .uint,
        .r32_sint => .sint,
        .rg16_uint => .uint,
        .rg16_sint => .sint,
        .rg16_float => .float,
        .rgba8_unorm => .unorm,
        .rgba8_unorm_srgb => .unorm_srgb,
        .rgba8_snorm => .snorm,
        .rgba8_uint => .uint,
        .rgba8_sint => .sint,
        .bgra8_unorm => .unorm,
        .bgra8_unorm_srgb => .unorm_srgb,
        .rgb10_a2_unorm => .unorm,
        .rg11_b10_ufloat => .float,
        .rgb9_e5_ufloat => .float,
        .rg32_float => .float,
        .rg32_uint => .uint,
        .rg32_sint => .sint,
        .rgba16_uint => .uint,
        .rgba16_sint => .sint,
        .rgba16_float => .float,
        .rgba32_float => .float,
        .rgba32_uint => .uint,
        .rgba32_sint => .sint,
        .stencil8 => .stencil,
        .depth16_unorm => .depth,
        .depth24_plus => .depth,
        .depth24_plus_stencil8 => .depth_stencil,
        .depth32_float => .depth,
        .depth32_float_stencil8 => .depth_stencil,
        .bc1_rgba_unorm => .unorm,
        .bc1_rgba_unorm_srgb => .unorm_srgb,
        .bc2_rgba_unorm => .unorm,
        .bc2_rgba_unorm_srgb => .unorm_srgb,
        .bc3_rgba_unorm => .unorm,
        .bc3_rgba_unorm_srgb => .unorm_srgb,
        .bc4_runorm => .unorm,
        .bc4_rsnorm => .snorm,
        .bc5_rg_unorm => .unorm,
        .bc5_rg_snorm => .snorm,
        .bc6_hrgb_ufloat => .float,
        .bc6_hrgb_float => .float,
        .bc7_rgba_unorm => .unorm,
        .bc7_rgba_unorm_srgb => .snorm,
        .etc2_rgb8_unorm => .unorm,
        .etc2_rgb8_unorm_srgb => .unorm_srgb,
        .etc2_rgb8_a1_unorm => .unorm_srgb,
        .etc2_rgb8_a1_unorm_srgb => .unorm,
        .etc2_rgba8_unorm => .unorm,
        .etc2_rgba8_unorm_srgb => .unorm_srgb,
        .eacr11_unorm => .unorm,
        .eacr11_snorm => .snorm,
        .eacrg11_unorm => .unorm,
        .eacrg11_snorm => .snorm,
        .astc4x4_unorm => .unorm,
        .astc4x4_unorm_srgb => .unorm_srgb,
        .astc5x4_unorm => .unorm,
        .astc5x4_unorm_srgb => .unorm_srgb,
        .astc5x5_unorm => .unorm,
        .astc5x5_unorm_srgb => .unorm_srgb,
        .astc6x5_unorm => .unorm,
        .astc6x5_unorm_srgb => .unorm_srgb,
        .astc6x6_unorm => .unorm,
        .astc6x6_unorm_srgb => .unorm_srgb,
        .astc8x5_unorm => .unorm,
        .astc8x5_unorm_srgb => .unorm_srgb,
        .astc8x6_unorm => .unorm,
        .astc8x6_unorm_srgb => .unorm_srgb,
        .astc8x8_unorm => .unorm,
        .astc8x8_unorm_srgb => .unorm_srgb,
        .astc10x5_unorm => .unorm,
        .astc10x5_unorm_srgb => .unorm_srgb,
        .astc10x6_unorm => .unorm,
        .astc10x6_unorm_srgb => .unorm_srgb,
        .astc10x8_unorm => .unorm,
        .astc10x8_unorm_srgb => .unorm_srgb,
        .astc10x10_unorm => .unorm,
        .astc10x10_unorm_srgb => .unorm_srgb,
        .astc12x10_unorm => .unorm,
        .astc12x10_unorm_srgb => .unorm_srgb,
        .astc12x12_unorm => .unorm,
        .astc12x12_unorm_srgb => .unorm_srgb,
        .r8_bg8_biplanar420_unorm => .unorm,
    };
}

pub fn formatHasDepthOrStencil(format: sysgpu.Texture.Format) bool {
    return switch (textureFormatType(format)) {
        .depth, .stencil, .depth_stencil => true,
        else => false,
    };
}

pub fn calcOrigin(dimension: sysgpu.Texture.Dimension, origin: sysgpu.Origin3D) struct {
    x: u32,
    y: u32,
    z: u32,
    array_slice: u32,
} {
    return .{
        .x = origin.x,
        .y = origin.y,
        .z = if (dimension == .dimension_3d) origin.z else 0,
        .array_slice = if (dimension == .dimension_3d) 0 else origin.z,
    };
}

pub fn calcExtent(dimension: sysgpu.Texture.Dimension, extent: sysgpu.Extent3D) struct {
    width: u32,
    height: u32,
    depth: u32,
    array_count: u32,
} {
    return .{
        .width = extent.width,
        .height = extent.height,
        .depth = if (dimension == .dimension_3d) extent.depth_or_array_layers else 1,
        .array_count = if (dimension == .dimension_3d) 0 else extent.depth_or_array_layers,
    };
}

pub const DefaultPipelineLayoutDescriptor = struct {
    pub const Group = std.ArrayListUnmanaged(sysgpu.BindGroupLayout.Entry);

    allocator: std.mem.Allocator,
    groups: std.BoundedArray(Group, limits.max_bind_groups) = .{},

    pub fn init(allocator: std.mem.Allocator) DefaultPipelineLayoutDescriptor {
        return .{ .allocator = allocator };
    }

    pub fn deinit(desc: *DefaultPipelineLayoutDescriptor) void {
        for (desc.groups.slice()) |*group| {
            group.deinit(desc.allocator);
        }
    }

    pub fn addFunction(
        desc: *DefaultPipelineLayoutDescriptor,
        air: *const shader.Air,
        stage: sysgpu.ShaderStageFlags,
        entry_point: [*:0]const u8,
    ) !void {
        if (air.findFunction(std.mem.span(entry_point))) |fn_inst| {
            const global_var_ref_list = air.refToList(fn_inst.global_var_refs);
            for (global_var_ref_list) |global_var_inst_idx| {
                const var_inst = air.getInst(global_var_inst_idx).@"var";
                if (var_inst.addr_space == .workgroup)
                    continue;

                const var_type = air.getInst(var_inst.type);
                const group: u32 = @intCast(air.resolveInt(var_inst.group) orelse return error.ConstExpr);
                const binding: u32 = @intCast(air.resolveInt(var_inst.binding) orelse return error.ConstExpr);

                var entry: sysgpu.BindGroupLayout.Entry = .{ .binding = binding, .visibility = stage };
                switch (var_type) {
                    .sampler_type => entry.sampler.type = .filtering,
                    .comparison_sampler_type => entry.sampler.type = .comparison,
                    .texture_type => |texture| {
                        switch (texture.kind) {
                            .storage_1d,
                            .storage_2d,
                            .storage_2d_array,
                            .storage_3d,
                            => {
                                entry.storage_texture.access = .undefined; // TODO - write_only
                                entry.storage_texture.format = switch (texture.texel_format) {
                                    .none => unreachable,
                                    .rgba8unorm => .rgba8_unorm,
                                    .rgba8snorm => .rgba8_snorm,
                                    .bgra8unorm => .bgra8_unorm,
                                    .rgba16float => .rgba16_float,
                                    .r32float => .r32_float,
                                    .rg32float => .rg32_float,
                                    .rgba32float => .rgba32_float,
                                    .rgba8uint => .rgba8_uint,
                                    .rgba16uint => .rgba16_uint,
                                    .r32uint => .r32_uint,
                                    .rg32uint => .rg32_uint,
                                    .rgba32uint => .rgba32_uint,
                                    .rgba8sint => .rgba8_sint,
                                    .rgba16sint => .rgba16_sint,
                                    .r32sint => .r32_sint,
                                    .rg32sint => .rg32_sint,
                                    .rgba32sint => .rgba32_sint,
                                };
                                entry.storage_texture.view_dimension = switch (texture.kind) {
                                    .storage_1d => .dimension_1d,
                                    .storage_2d => .dimension_2d,
                                    .storage_2d_array => .dimension_2d_array,
                                    .storage_3d => .dimension_3d,
                                    else => unreachable,
                                };
                            },
                            else => {
                                // sample_type
                                entry.texture.sample_type =
                                    switch (texture.kind) {
                                    .depth_2d,
                                    .depth_2d_array,
                                    .depth_cube,
                                    .depth_cube_array,
                                    => .depth,
                                    else => switch (texture.texel_format) {
                                        .none => .float, // TODO - is this right?
                                        .rgba8unorm,
                                        .rgba8snorm,
                                        .bgra8unorm,
                                        .rgba16float,
                                        .r32float,
                                        .rg32float,
                                        .rgba32float,
                                        => .float, // TODO - unfilterable
                                        .rgba8uint,
                                        .rgba16uint,
                                        .r32uint,
                                        .rg32uint,
                                        .rgba32uint,
                                        => .uint,
                                        .rgba8sint,
                                        .rgba16sint,
                                        .r32sint,
                                        .rg32sint,
                                        .rgba32sint,
                                        => .sint,
                                    },
                                };
                                entry.texture.view_dimension = switch (texture.kind) {
                                    .sampled_1d,
                                    .storage_1d,
                                    => .dimension_1d,
                                    .sampled_2d,
                                    .multisampled_2d,
                                    .multisampled_depth_2d,
                                    .storage_2d,
                                    .depth_2d,
                                    => .dimension_2d,
                                    .sampled_2d_array,
                                    .storage_2d_array,
                                    .depth_2d_array,
                                    => .dimension_2d_array,
                                    .sampled_3d,
                                    .storage_3d,
                                    => .dimension_3d,
                                    .sampled_cube,
                                    .depth_cube,
                                    => .dimension_cube,
                                    .sampled_cube_array,
                                    .depth_cube_array,
                                    => .dimension_cube_array,
                                };
                                entry.texture.multisampled = switch (texture.kind) {
                                    .multisampled_2d,
                                    .multisampled_depth_2d,
                                    => .true,
                                    else => .false,
                                };
                            },
                        }
                    },
                    else => {
                        switch (var_inst.addr_space) {
                            .uniform => entry.buffer.type = .uniform,
                            .storage => {
                                if (var_inst.access_mode == .read) {
                                    entry.buffer.type = .read_only_storage;
                                } else {
                                    entry.buffer.type = .storage;
                                }
                            },
                            else => std.debug.panic("unhandled addr_space\n", .{}),
                        }
                    },
                }

                while (desc.groups.len <= group) {
                    desc.groups.appendAssumeCapacity(.{});
                }

                var append = true;
                var group_entries = &desc.groups.buffer[group];
                for (group_entries.items) |*previous_entry| {
                    if (previous_entry.binding == binding) {
                        // TODO - bitfield or?
                        if (entry.visibility.vertex)
                            previous_entry.visibility.vertex = true;
                        if (entry.visibility.fragment)
                            previous_entry.visibility.fragment = true;
                        if (entry.visibility.compute)
                            previous_entry.visibility.compute = true;

                        if (previous_entry.buffer.min_binding_size < entry.buffer.min_binding_size) {
                            previous_entry.buffer.min_binding_size = entry.buffer.min_binding_size;
                        }
                        if (previous_entry.texture.sample_type != entry.texture.sample_type) {
                            if (previous_entry.texture.sample_type == .unfilterable_float and entry.texture.sample_type == .float) {
                                previous_entry.texture.sample_type = .float;
                            } else if (previous_entry.texture.sample_type == .float and entry.texture.sample_type == .unfilterable_float) {
                                // ignore
                            } else {
                                return error.IncompatibleEntries;
                            }
                        }

                        // TODO - any other differences return error

                        append = false;
                        break;
                    }
                }

                if (append)
                    try group_entries.append(desc.allocator, entry);
            }
        }
    }
};
