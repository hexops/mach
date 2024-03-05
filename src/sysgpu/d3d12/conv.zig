const sysgpu = @import("../sysgpu/main.zig");
const utils = @import("../utils.zig");
const c = @import("c.zig");

fn stencilEnable(stencil: sysgpu.StencilFaceState) bool {
    return stencil.compare != .always or stencil.fail_op != .keep or stencil.depth_fail_op != .keep or stencil.pass_op != .keep;
}

pub fn winBool(b: bool) c.BOOL {
    return if (b) c.TRUE else c.FALSE;
}

pub fn d3d12Blend(factor: sysgpu.BlendFactor) c.D3D12_BLEND {
    return switch (factor) {
        .zero => c.D3D12_BLEND_ZERO,
        .one => c.D3D12_BLEND_ONE,
        .src => c.D3D12_BLEND_SRC_COLOR,
        .one_minus_src => c.D3D12_BLEND_INV_SRC_COLOR,
        .src_alpha => c.D3D12_BLEND_SRC_ALPHA,
        .one_minus_src_alpha => c.D3D12_BLEND_INV_SRC_ALPHA,
        .dst => c.D3D12_BLEND_DEST_COLOR,
        .one_minus_dst => c.D3D12_BLEND_INV_DEST_COLOR,
        .dst_alpha => c.D3D12_BLEND_DEST_ALPHA,
        .one_minus_dst_alpha => c.D3D12_BLEND_INV_DEST_ALPHA,
        .src_alpha_saturated => c.D3D12_BLEND_SRC_ALPHA_SAT,
        .constant => c.D3D12_BLEND_BLEND_FACTOR,
        .one_minus_constant => c.D3D12_BLEND_INV_BLEND_FACTOR,
        .src1 => c.D3D12_BLEND_SRC1_COLOR,
        .one_minus_src1 => c.D3D12_BLEND_INV_SRC1_COLOR,
        .src1_alpha => c.D3D12_BLEND_SRC1_ALPHA,
        .one_minus_src1_alpha => c.D3D12_BLEND_INV_SRC1_ALPHA,
    };
}

pub fn d3d12BlendDesc(desc: *const sysgpu.RenderPipeline.Descriptor) c.D3D12_BLEND_DESC {
    var d3d12_targets = [_]c.D3D12_RENDER_TARGET_BLEND_DESC{d3d12RenderTargetBlendDesc(null)} ** 8;
    if (desc.fragment) |frag| {
        for (0..frag.target_count) |i| {
            const target = frag.targets.?[i];
            d3d12_targets[i] = d3d12RenderTargetBlendDesc(target);
        }
    }

    return .{
        .AlphaToCoverageEnable = winBool(desc.multisample.alpha_to_coverage_enabled == .true),
        .IndependentBlendEnable = c.TRUE,
        .RenderTarget = d3d12_targets,
    };
}

pub fn d3d12BlendOp(op: sysgpu.BlendOperation) c.D3D12_BLEND_OP {
    return switch (op) {
        .add => c.D3D12_BLEND_OP_ADD,
        .subtract => c.D3D12_BLEND_OP_SUBTRACT,
        .reverse_subtract => c.D3D12_BLEND_OP_REV_SUBTRACT,
        .min => c.D3D12_BLEND_OP_MIN,
        .max => c.D3D12_BLEND_OP_MAX,
    };
}

pub fn d3d12ComparisonFunc(func: sysgpu.CompareFunction) c.D3D12_COMPARISON_FUNC {
    return switch (func) {
        .undefined => unreachable,
        .never => c.D3D12_COMPARISON_FUNC_NEVER,
        .less => c.D3D12_COMPARISON_FUNC_LESS,
        .less_equal => c.D3D12_COMPARISON_FUNC_LESS_EQUAL,
        .greater => c.D3D12_COMPARISON_FUNC_GREATER,
        .greater_equal => c.D3D12_COMPARISON_FUNC_GREATER_EQUAL,
        .equal => c.D3D12_COMPARISON_FUNC_EQUAL,
        .not_equal => c.D3D12_COMPARISON_FUNC_NOT_EQUAL,
        .always => c.D3D12_COMPARISON_FUNC_ALWAYS,
    };
}

pub fn d3d12CullMode(mode: sysgpu.CullMode) c.D3D12_CULL_MODE {
    return switch (mode) {
        .none => c.D3D12_CULL_MODE_NONE,
        .front => c.D3D12_CULL_MODE_FRONT,
        .back => c.D3D12_CULL_MODE_BACK,
    };
}

pub fn d3d12DepthStencilDesc(depth_stencil: ?*const sysgpu.DepthStencilState) c.D3D12_DEPTH_STENCIL_DESC {
    return if (depth_stencil) |ds| .{
        .DepthEnable = winBool(ds.depth_compare != .always or ds.depth_write_enabled == .true),
        .DepthWriteMask = if (ds.depth_write_enabled == .true) c.D3D12_DEPTH_WRITE_MASK_ALL else c.D3D12_DEPTH_WRITE_MASK_ZERO,
        .DepthFunc = d3d12ComparisonFunc(ds.depth_compare),
        .StencilEnable = winBool(stencilEnable(ds.stencil_front) or stencilEnable(ds.stencil_back)),
        .StencilReadMask = @intCast(ds.stencil_read_mask & 0xff),
        .StencilWriteMask = @intCast(ds.stencil_write_mask & 0xff),
        .FrontFace = d3d12DepthStencilOpDesc(ds.stencil_front),
        .BackFace = d3d12DepthStencilOpDesc(ds.stencil_back),
    } else .{
        .DepthEnable = c.FALSE,
        .DepthWriteMask = c.D3D12_DEPTH_WRITE_MASK_ZERO,
        .DepthFunc = c.D3D12_COMPARISON_FUNC_LESS,
        .StencilEnable = c.FALSE,
        .StencilReadMask = 0xff,
        .StencilWriteMask = 0xff,
        .FrontFace = d3d12DepthStencilOpDesc(null),
        .BackFace = d3d12DepthStencilOpDesc(null),
    };
}

pub fn d3d12DepthStencilOpDesc(opt_stencil: ?sysgpu.StencilFaceState) c.D3D12_DEPTH_STENCILOP_DESC {
    return if (opt_stencil) |stencil| .{
        .StencilFailOp = d3d12StencilOp(stencil.fail_op),
        .StencilDepthFailOp = d3d12StencilOp(stencil.depth_fail_op),
        .StencilPassOp = d3d12StencilOp(stencil.pass_op),
        .StencilFunc = d3d12ComparisonFunc(stencil.compare),
    } else .{
        .StencilFailOp = c.D3D12_STENCIL_OP_KEEP,
        .StencilDepthFailOp = c.D3D12_STENCIL_OP_KEEP,
        .StencilPassOp = c.D3D12_STENCIL_OP_KEEP,
        .StencilFunc = c.D3D12_COMPARISON_FUNC_ALWAYS,
    };
}

pub fn d3d12DescriptorRangeType(entry: sysgpu.BindGroupLayout.Entry) c.D3D12_DESCRIPTOR_RANGE_TYPE {
    if (entry.buffer.type != .undefined) {
        return switch (entry.buffer.type) {
            .undefined => unreachable,
            .uniform => c.D3D12_DESCRIPTOR_RANGE_TYPE_CBV,
            .storage => c.D3D12_DESCRIPTOR_RANGE_TYPE_UAV,
            .read_only_storage => c.D3D12_DESCRIPTOR_RANGE_TYPE_SRV,
        };
    } else if (entry.sampler.type != .undefined) {
        return c.D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
    } else if (entry.texture.sample_type != .undefined) {
        return c.D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
    } else {
        // storage_texture
        return c.D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
    }

    unreachable;
}

pub fn d3d12FilterType(filter: sysgpu.FilterMode) c.D3D12_FILTER_TYPE {
    return switch (filter) {
        .nearest => c.D3D12_FILTER_TYPE_POINT,
        .linear => c.D3D12_FILTER_TYPE_LINEAR,
    };
}

pub fn d3d12FilterTypeForMipmap(filter: sysgpu.MipmapFilterMode) c.D3D12_FILTER_TYPE {
    return switch (filter) {
        .nearest => c.D3D12_FILTER_TYPE_POINT,
        .linear => c.D3D12_FILTER_TYPE_LINEAR,
    };
}

pub fn d3d12Filter(
    mag_filter: sysgpu.FilterMode,
    min_filter: sysgpu.FilterMode,
    mipmap_filter: sysgpu.MipmapFilterMode,
    max_anisotropy: u16,
) c.D3D12_FILTER {
    var filter: c.D3D12_FILTER = 0;
    filter |= d3d12FilterType(min_filter) << c.D3D12_MIN_FILTER_SHIFT;
    filter |= d3d12FilterType(mag_filter) << c.D3D12_MAG_FILTER_SHIFT;
    filter |= d3d12FilterTypeForMipmap(mipmap_filter) << c.D3D12_MIP_FILTER_SHIFT;
    filter |= c.D3D12_FILTER_REDUCTION_TYPE_STANDARD << c.D3D12_FILTER_REDUCTION_TYPE_SHIFT;
    if (max_anisotropy > 1)
        filter |= c.D3D12_ANISOTROPIC_FILTERING_BIT;
    return filter;
}

pub fn d3d12FrontCounterClockwise(face: sysgpu.FrontFace) c.BOOL {
    return switch (face) {
        .ccw => c.TRUE,
        .cw => c.FALSE,
    };
}

pub fn d3d12HeapType(usage: sysgpu.Buffer.UsageFlags) c.D3D12_HEAP_TYPE {
    return if (usage.map_write)
        c.D3D12_HEAP_TYPE_UPLOAD
    else if (usage.map_read)
        c.D3D12_HEAP_TYPE_READBACK
    else
        c.D3D12_HEAP_TYPE_DEFAULT;
}

pub fn d3d12IndexBufferStripCutValue(strip_index_format: sysgpu.IndexFormat) c.D3D12_INDEX_BUFFER_STRIP_CUT_VALUE {
    return switch (strip_index_format) {
        .undefined => c.D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_DISABLED,
        .uint16 => c.D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_0xFFFF,
        .uint32 => c.D3D12_INDEX_BUFFER_STRIP_CUT_VALUE_0xFFFFFFFF,
    };
}

pub fn d3d12InputClassification(mode: sysgpu.VertexStepMode) c.D3D12_INPUT_CLASSIFICATION {
    return switch (mode) {
        .vertex => c.D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA,
        .instance => c.D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA,
        .vertex_buffer_not_used => undefined,
    };
}

pub fn d3d12InputElementDesc(
    buffer_index: usize,
    layout: sysgpu.VertexBufferLayout,
    attr: sysgpu.VertexAttribute,
) c.D3D12_INPUT_ELEMENT_DESC {
    return .{
        .SemanticName = "ATTR",
        .SemanticIndex = attr.shader_location,
        .Format = dxgiFormatForVertex(attr.format),
        .InputSlot = @intCast(buffer_index),
        .AlignedByteOffset = @intCast(attr.offset),
        .InputSlotClass = d3d12InputClassification(layout.step_mode),
        .InstanceDataStepRate = if (layout.step_mode == .instance) 1 else 0,
    };
}

pub fn d3d12PrimitiveTopology(topology: sysgpu.PrimitiveTopology) c.D3D12_PRIMITIVE_TOPOLOGY {
    return switch (topology) {
        .point_list => c.D3D_PRIMITIVE_TOPOLOGY_POINTLIST,
        .line_list => c.D3D_PRIMITIVE_TOPOLOGY_LINELIST,
        .line_strip => c.D3D_PRIMITIVE_TOPOLOGY_LINESTRIP,
        .triangle_list => c.D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST,
        .triangle_strip => c.D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP,
    };
}

pub fn d3d12PrimitiveTopologyType(topology: sysgpu.PrimitiveTopology) c.D3D12_PRIMITIVE_TOPOLOGY_TYPE {
    return switch (topology) {
        .point_list => c.D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT,
        .line_list, .line_strip => c.D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE,
        .triangle_list, .triangle_strip => c.D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE,
    };
}

pub fn d3d12RasterizerDesc(desc: *const sysgpu.RenderPipeline.Descriptor) c.D3D12_RASTERIZER_DESC {
    const primitive_depth_control = utils.findChained(
        sysgpu.PrimitiveDepthClipControl,
        desc.primitive.next_in_chain.generic,
    );

    return .{
        .FillMode = c.D3D12_FILL_MODE_SOLID,
        .CullMode = d3d12CullMode(desc.primitive.cull_mode),
        .FrontCounterClockwise = d3d12FrontCounterClockwise(desc.primitive.front_face),
        .DepthBias = if (desc.depth_stencil) |ds| ds.depth_bias else 0,
        .DepthBiasClamp = if (desc.depth_stencil) |ds| ds.depth_bias_clamp else 0.0,
        .SlopeScaledDepthBias = if (desc.depth_stencil) |ds| ds.depth_bias_slope_scale else 0.0,
        .DepthClipEnable = winBool(if (primitive_depth_control) |x| x.unclipped_depth == .false else true),
        .MultisampleEnable = winBool(desc.multisample.count > 1),
        .AntialiasedLineEnable = c.FALSE,
        .ForcedSampleCount = 0,
        .ConservativeRaster = c.D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF,
    };
}

pub fn d3d12RenderTargetBlendDesc(opt_target: ?sysgpu.ColorTargetState) c.D3D12_RENDER_TARGET_BLEND_DESC {
    var desc = c.D3D12_RENDER_TARGET_BLEND_DESC{
        .BlendEnable = c.FALSE,
        .LogicOpEnable = c.FALSE,
        .SrcBlend = c.D3D12_BLEND_ONE,
        .DestBlend = c.D3D12_BLEND_ZERO,
        .BlendOp = c.D3D12_BLEND_OP_ADD,
        .SrcBlendAlpha = c.D3D12_BLEND_ONE,
        .DestBlendAlpha = c.D3D12_BLEND_ZERO,
        .BlendOpAlpha = c.D3D12_BLEND_OP_ADD,
        .LogicOp = c.D3D12_LOGIC_OP_NOOP,
        .RenderTargetWriteMask = 0xf,
    };
    if (opt_target) |target| {
        desc.RenderTargetWriteMask = d3d12RenderTargetWriteMask(target.write_mask);
        if (target.blend) |blend| {
            desc.BlendEnable = c.TRUE;
            desc.SrcBlend = d3d12Blend(blend.color.src_factor);
            desc.DestBlend = d3d12Blend(blend.color.dst_factor);
            desc.BlendOp = d3d12BlendOp(blend.color.operation);
            desc.SrcBlendAlpha = d3d12Blend(blend.alpha.src_factor);
            desc.DestBlendAlpha = d3d12Blend(blend.alpha.dst_factor);
            desc.BlendOpAlpha = d3d12BlendOp(blend.alpha.operation);
        }
    }

    return desc;
}

pub fn d3d12RenderTargetWriteMask(mask: sysgpu.ColorWriteMaskFlags) c.UINT8 {
    var writeMask: c.INT = 0;
    if (mask.red)
        writeMask |= c.D3D12_COLOR_WRITE_ENABLE_RED;
    if (mask.green)
        writeMask |= c.D3D12_COLOR_WRITE_ENABLE_GREEN;
    if (mask.blue)
        writeMask |= c.D3D12_COLOR_WRITE_ENABLE_BLUE;
    if (mask.alpha)
        writeMask |= c.D3D12_COLOR_WRITE_ENABLE_ALPHA;
    return @intCast(writeMask);
}

pub fn d3d12ResourceSizeForBuffer(size: u64, usage: sysgpu.Buffer.UsageFlags) c.UINT64 {
    var resource_size = size;
    if (usage.uniform)
        resource_size = utils.alignUp(resource_size, 256);
    return resource_size;
}

pub fn d3d12ResourceStatesInitial(heap_type: c.D3D12_HEAP_TYPE, read_state: c.D3D12_RESOURCE_STATES) c.D3D12_RESOURCE_STATES {
    return switch (heap_type) {
        c.D3D12_HEAP_TYPE_UPLOAD => c.D3D12_RESOURCE_STATE_GENERIC_READ,
        c.D3D12_HEAP_TYPE_READBACK => c.D3D12_RESOURCE_STATE_COPY_DEST,
        else => read_state,
    };
}

pub fn d3d12ResourceStatesForBufferRead(usage: sysgpu.Buffer.UsageFlags) c.D3D12_RESOURCE_STATES {
    var states: c.D3D12_RESOURCE_STATES = c.D3D12_RESOURCE_STATE_COMMON;
    if (usage.copy_src)
        states |= c.D3D12_RESOURCE_STATE_COPY_SOURCE;
    if (usage.index)
        states |= c.D3D12_RESOURCE_STATE_INDEX_BUFFER;
    if (usage.vertex or usage.uniform)
        states |= c.D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
    if (usage.storage)
        states |= c.D3D12_RESOURCE_STATE_ALL_SHADER_RESOURCE;
    if (usage.indirect)
        states |= c.D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT;
    return states;
}

pub fn d3d12ResourceStatesForTextureRead(usage: sysgpu.Texture.UsageFlags) c.D3D12_RESOURCE_STATES {
    var states: c.D3D12_RESOURCE_STATES = c.D3D12_RESOURCE_STATE_COMMON;
    if (usage.copy_src)
        states |= c.D3D12_RESOURCE_STATE_COPY_SOURCE;
    if (usage.texture_binding or usage.storage_binding)
        states |= c.D3D12_RESOURCE_STATE_ALL_SHADER_RESOURCE;
    return states;
}

pub fn d3d12ResourceFlagsForBuffer(usage: sysgpu.Buffer.UsageFlags) c.D3D12_RESOURCE_FLAGS {
    var flags: c.D3D12_RESOURCE_FLAGS = c.D3D12_RESOURCE_FLAG_NONE;
    if (usage.storage)
        flags |= c.D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    return flags;
}

pub fn d3d12ResourceFlagsForTexture(
    usage: sysgpu.Texture.UsageFlags,
    format: sysgpu.Texture.Format,
) c.D3D12_RESOURCE_FLAGS {
    var flags: c.D3D12_RESOURCE_FLAGS = c.D3D12_RESOURCE_FLAG_NONE;
    if (usage.render_attachment) {
        if (utils.formatHasDepthOrStencil(format)) {
            flags |= c.D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
        } else {
            flags |= c.D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
        }
    }
    if (usage.storage_binding)
        flags |= c.D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    if (!usage.texture_binding and usage.render_attachment and utils.formatHasDepthOrStencil(format))
        flags |= c.D3D12_RESOURCE_FLAG_DENY_SHADER_RESOURCE;
    return flags;
}

pub fn d3d12ResourceDimension(dimension: sysgpu.Texture.Dimension) c.D3D12_RESOURCE_DIMENSION {
    return switch (dimension) {
        .dimension_1d => c.D3D12_RESOURCE_DIMENSION_TEXTURE1D,
        .dimension_2d => c.D3D12_RESOURCE_DIMENSION_TEXTURE2D,
        .dimension_3d => c.D3D12_RESOURCE_DIMENSION_TEXTURE3D,
    };
}

pub fn d3d12RootParameterType(entry: sysgpu.BindGroupLayout.Entry) c.D3D12_ROOT_PARAMETER_TYPE {
    return switch (entry.buffer.type) {
        .undefined => unreachable,
        .uniform => c.D3D12_ROOT_PARAMETER_TYPE_CBV,
        .storage => c.D3D12_ROOT_PARAMETER_TYPE_UAV,
        .read_only_storage => c.D3D12_ROOT_PARAMETER_TYPE_SRV,
    };
}

pub fn d3d12ShaderBytecode(opt_blob: ?*c.ID3DBlob) c.D3D12_SHADER_BYTECODE {
    return if (opt_blob) |blob| .{
        .pShaderBytecode = blob.lpVtbl.*.GetBufferPointer.?(blob),
        .BytecodeLength = blob.lpVtbl.*.GetBufferSize.?(blob),
    } else .{ .pShaderBytecode = null, .BytecodeLength = 0 };
}

pub fn d3d12SrvDimension(dimension: sysgpu.TextureView.Dimension, sample_count: u32) c.D3D12_SRV_DIMENSION {
    return switch (dimension) {
        .dimension_undefined => unreachable,
        .dimension_1d => c.D3D12_SRV_DIMENSION_TEXTURE1D,
        .dimension_2d => if (sample_count == 1) c.D3D12_SRV_DIMENSION_TEXTURE2D else c.D3D12_SRV_DIMENSION_TEXTURE2DMS,
        .dimension_2d_array => if (sample_count == 1) c.D3D12_SRV_DIMENSION_TEXTURE2DARRAY else c.D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY,
        .dimension_cube => c.D3D12_SRV_DIMENSION_TEXTURECUBE,
        .dimension_cube_array => c.D3D12_SRV_DIMENSION_TEXTURECUBEARRAY,
        .dimension_3d => c.D3D12_SRV_DIMENSION_TEXTURE3D,
    };
}

pub fn d3d12StencilOp(op: sysgpu.StencilOperation) c.D3D12_STENCIL_OP {
    return switch (op) {
        .keep => c.D3D12_STENCIL_OP_KEEP,
        .zero => c.D3D12_STENCIL_OP_ZERO,
        .replace => c.D3D12_STENCIL_OP_REPLACE,
        .invert => c.D3D12_STENCIL_OP_INVERT,
        .increment_clamp => c.D3D12_STENCIL_OP_INCR_SAT,
        .decrement_clamp => c.D3D12_STENCIL_OP_DECR_SAT,
        .increment_wrap => c.D3D12_STENCIL_OP_INCR,
        .decrement_wrap => c.D3D12_STENCIL_OP_DECR,
    };
}

pub fn d3d12StreamOutputDesc() c.D3D12_STREAM_OUTPUT_DESC {
    return .{
        .pSODeclaration = null,
        .NumEntries = 0,
        .pBufferStrides = null,
        .NumStrides = 0,
        .RasterizedStream = 0,
    };
}

pub fn d3d12TextureAddressMode(address_mode: sysgpu.Sampler.AddressMode) c.D3D12_TEXTURE_ADDRESS_MODE {
    return switch (address_mode) {
        .repeat => c.D3D12_TEXTURE_ADDRESS_MODE_WRAP,
        .mirror_repeat => c.D3D12_TEXTURE_ADDRESS_MODE_MIRROR,
        .clamp_to_edge => c.D3D12_TEXTURE_ADDRESS_MODE_CLAMP,
    };
}

pub fn d3d12UavDimension(dimension: sysgpu.TextureView.Dimension) c.D3D12_UAV_DIMENSION {
    return switch (dimension) {
        .dimension_undefined => unreachable,
        .dimension_1d => c.D3D12_UAV_DIMENSION_TEXTURE1D,
        .dimension_2d => c.D3D12_UAV_DIMENSION_TEXTURE2D,
        .dimension_2d_array => c.D3D12_UAV_DIMENSION_TEXTURE2DARRAY,
        .dimension_3d => c.D3D12_UAV_DIMENSION_TEXTURE3D,
        else => unreachable, // TODO - UAV cube maps?
    };
}

pub fn dxgiFormatForIndex(format: sysgpu.IndexFormat) c.DXGI_FORMAT {
    return switch (format) {
        .undefined => unreachable,
        .uint16 => c.DXGI_FORMAT_R16_UINT,
        .uint32 => c.DXGI_FORMAT_R32_UINT,
    };
}

pub fn dxgiFormatForTexture(format: sysgpu.Texture.Format) c.DXGI_FORMAT {
    return switch (format) {
        .undefined => unreachable,
        .r8_unorm => c.DXGI_FORMAT_R8_UNORM,
        .r8_snorm => c.DXGI_FORMAT_R8_SNORM,
        .r8_uint => c.DXGI_FORMAT_R8_UINT,
        .r8_sint => c.DXGI_FORMAT_R8_SINT,
        .r16_uint => c.DXGI_FORMAT_R16_UINT,
        .r16_sint => c.DXGI_FORMAT_R16_SINT,
        .r16_float => c.DXGI_FORMAT_R16_FLOAT,
        .rg8_unorm => c.DXGI_FORMAT_R8G8_UNORM,
        .rg8_snorm => c.DXGI_FORMAT_R8G8_SNORM,
        .rg8_uint => c.DXGI_FORMAT_R8G8_UINT,
        .rg8_sint => c.DXGI_FORMAT_R8G8_SINT,
        .r32_float => c.DXGI_FORMAT_R32_FLOAT,
        .r32_uint => c.DXGI_FORMAT_R32_UINT,
        .r32_sint => c.DXGI_FORMAT_R32_SINT,
        .rg16_uint => c.DXGI_FORMAT_R16G16_UINT,
        .rg16_sint => c.DXGI_FORMAT_R16G16_SINT,
        .rg16_float => c.DXGI_FORMAT_R16G16_FLOAT,
        .rgba8_unorm => c.DXGI_FORMAT_R8G8B8A8_UNORM,
        .rgba8_unorm_srgb => c.DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
        .rgba8_snorm => c.DXGI_FORMAT_R8G8B8A8_SNORM,
        .rgba8_uint => c.DXGI_FORMAT_R8G8B8A8_UINT,
        .rgba8_sint => c.DXGI_FORMAT_R8G8B8A8_SINT,
        .bgra8_unorm => c.DXGI_FORMAT_B8G8R8A8_UNORM,
        .bgra8_unorm_srgb => c.DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
        .rgb10_a2_unorm => c.DXGI_FORMAT_R10G10B10A2_UNORM,
        .rg11_b10_ufloat => c.DXGI_FORMAT_R11G11B10_FLOAT,
        .rgb9_e5_ufloat => c.DXGI_FORMAT_R9G9B9E5_SHAREDEXP,
        .rg32_float => c.DXGI_FORMAT_R32G32_FLOAT,
        .rg32_uint => c.DXGI_FORMAT_R32G32_UINT,
        .rg32_sint => c.DXGI_FORMAT_R32G32_SINT,
        .rgba16_uint => c.DXGI_FORMAT_R16G16B16A16_UINT,
        .rgba16_sint => c.DXGI_FORMAT_R16G16B16A16_SINT,
        .rgba16_float => c.DXGI_FORMAT_R16G16B16A16_FLOAT,
        .rgba32_float => c.DXGI_FORMAT_R32G32B32A32_FLOAT,
        .rgba32_uint => c.DXGI_FORMAT_R32G32B32A32_UINT,
        .rgba32_sint => c.DXGI_FORMAT_R32G32B32A32_SINT,
        .stencil8 => c.DXGI_FORMAT_D24_UNORM_S8_UINT,
        .depth16_unorm => c.DXGI_FORMAT_D16_UNORM,
        .depth24_plus => c.DXGI_FORMAT_D24_UNORM_S8_UINT,
        .depth24_plus_stencil8 => c.DXGI_FORMAT_D24_UNORM_S8_UINT,
        .depth32_float => c.DXGI_FORMAT_D32_FLOAT,
        .depth32_float_stencil8 => c.DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
        .bc1_rgba_unorm => c.DXGI_FORMAT_BC1_UNORM,
        .bc1_rgba_unorm_srgb => c.DXGI_FORMAT_BC1_UNORM_SRGB,
        .bc2_rgba_unorm => c.DXGI_FORMAT_BC2_UNORM,
        .bc2_rgba_unorm_srgb => c.DXGI_FORMAT_BC2_UNORM_SRGB,
        .bc3_rgba_unorm => c.DXGI_FORMAT_BC3_UNORM,
        .bc3_rgba_unorm_srgb => c.DXGI_FORMAT_BC3_UNORM_SRGB,
        .bc4_runorm => c.DXGI_FORMAT_BC4_UNORM,
        .bc4_rsnorm => c.DXGI_FORMAT_BC4_SNORM,
        .bc5_rg_unorm => c.DXGI_FORMAT_BC5_UNORM,
        .bc5_rg_snorm => c.DXGI_FORMAT_BC5_SNORM,
        .bc6_hrgb_ufloat => c.DXGI_FORMAT_BC6H_UF16,
        .bc6_hrgb_float => c.DXGI_FORMAT_BC6H_SF16,
        .bc7_rgba_unorm => c.DXGI_FORMAT_BC7_UNORM,
        .bc7_rgba_unorm_srgb => c.DXGI_FORMAT_BC7_UNORM_SRGB,
        .etc2_rgb8_unorm,
        .etc2_rgb8_unorm_srgb,
        .etc2_rgb8_a1_unorm,
        .etc2_rgb8_a1_unorm_srgb,
        .etc2_rgba8_unorm,
        .etc2_rgba8_unorm_srgb,
        .eacr11_unorm,
        .eacr11_snorm,
        .eacrg11_unorm,
        .eacrg11_snorm,
        .astc4x4_unorm,
        .astc4x4_unorm_srgb,
        .astc5x4_unorm,
        .astc5x4_unorm_srgb,
        .astc5x5_unorm,
        .astc5x5_unorm_srgb,
        .astc6x5_unorm,
        .astc6x5_unorm_srgb,
        .astc6x6_unorm,
        .astc6x6_unorm_srgb,
        .astc8x5_unorm,
        .astc8x5_unorm_srgb,
        .astc8x6_unorm,
        .astc8x6_unorm_srgb,
        .astc8x8_unorm,
        .astc8x8_unorm_srgb,
        .astc10x5_unorm,
        .astc10x5_unorm_srgb,
        .astc10x6_unorm,
        .astc10x6_unorm_srgb,
        .astc10x8_unorm,
        .astc10x8_unorm_srgb,
        .astc10x10_unorm,
        .astc10x10_unorm_srgb,
        .astc12x10_unorm,
        .astc12x10_unorm_srgb,
        .astc12x12_unorm,
        .astc12x12_unorm_srgb,
        => unreachable,
        .r8_bg8_biplanar420_unorm => c.DXGI_FORMAT_NV12,
    };
}

pub fn dxgiFormatForTextureResource(
    format: sysgpu.Texture.Format,
    usage: sysgpu.Texture.UsageFlags,
    view_format_count: usize,
) c.DXGI_FORMAT {
    _ = usage;
    return if (view_format_count > 0)
        dxgiFormatTypeless(format)
    else
        dxgiFormatForTexture(format);
}

pub fn dxgiFormatForTextureView(format: sysgpu.Texture.Format, aspect: sysgpu.Texture.Aspect) c.DXGI_FORMAT {
    return switch (aspect) {
        .all => switch (format) {
            .stencil8 => c.DXGI_FORMAT_X24_TYPELESS_G8_UINT,
            .depth16_unorm => c.DXGI_FORMAT_R16_UNORM,
            .depth24_plus => c.DXGI_FORMAT_R24_UNORM_X8_TYPELESS,
            .depth32_float => c.DXGI_FORMAT_R32_FLOAT,
            else => dxgiFormatForTexture(format),
        },
        .stencil_only => switch (format) {
            .stencil8 => c.DXGI_FORMAT_X24_TYPELESS_G8_UINT,
            .depth24_plus_stencil8 => c.DXGI_FORMAT_X24_TYPELESS_G8_UINT,
            .depth32_float_stencil8 => c.DXGI_FORMAT_X32_TYPELESS_G8X24_UINT,
            else => unreachable,
        },
        .depth_only => switch (format) {
            .depth16_unorm => c.DXGI_FORMAT_R16_UNORM,
            .depth24_plus => c.DXGI_FORMAT_R24_UNORM_X8_TYPELESS,
            .depth24_plus_stencil8 => c.DXGI_FORMAT_R24_UNORM_X8_TYPELESS,
            .depth32_float => c.DXGI_FORMAT_R32_FLOAT,
            .depth32_float_stencil8 => c.DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS,
            else => unreachable,
        },
        .plane0_only => unreachable,
        .plane1_only => unreachable,
    };
}

pub fn dxgiFormatForVertex(format: sysgpu.VertexFormat) c.DXGI_FORMAT {
    return switch (format) {
        .undefined => unreachable,
        .uint8x2 => c.DXGI_FORMAT_R8G8_UINT,
        .uint8x4 => c.DXGI_FORMAT_R8G8B8A8_UINT,
        .sint8x2 => c.DXGI_FORMAT_R8G8_SINT,
        .sint8x4 => c.DXGI_FORMAT_R8G8B8A8_SINT,
        .unorm8x2 => c.DXGI_FORMAT_R8G8_UNORM,
        .unorm8x4 => c.DXGI_FORMAT_R8G8B8A8_UNORM,
        .snorm8x2 => c.DXGI_FORMAT_R8G8_SNORM,
        .snorm8x4 => c.DXGI_FORMAT_R8G8B8A8_SNORM,
        .uint16x2 => c.DXGI_FORMAT_R16G16_UINT,
        .uint16x4 => c.DXGI_FORMAT_R16G16B16A16_UINT,
        .sint16x2 => c.DXGI_FORMAT_R16G16_SINT,
        .sint16x4 => c.DXGI_FORMAT_R16G16B16A16_SINT,
        .unorm16x2 => c.DXGI_FORMAT_R16G16_UNORM,
        .unorm16x4 => c.DXGI_FORMAT_R16G16B16A16_UNORM,
        .snorm16x2 => c.DXGI_FORMAT_R16G16_SNORM,
        .snorm16x4 => c.DXGI_FORMAT_R16G16B16A16_SNORM,
        .float16x2 => c.DXGI_FORMAT_R16G16_FLOAT,
        .float16x4 => c.DXGI_FORMAT_R16G16B16A16_FLOAT,
        .float32 => c.DXGI_FORMAT_R32_FLOAT,
        .float32x2 => c.DXGI_FORMAT_R32G32_FLOAT,
        .float32x3 => c.DXGI_FORMAT_R32G32B32_FLOAT,
        .float32x4 => c.DXGI_FORMAT_R32G32B32A32_FLOAT,
        .uint32 => c.DXGI_FORMAT_R32_UINT,
        .uint32x2 => c.DXGI_FORMAT_R32G32_UINT,
        .uint32x3 => c.DXGI_FORMAT_R32G32B32_UINT,
        .uint32x4 => c.DXGI_FORMAT_R32G32B32A32_UINT,
        .sint32 => c.DXGI_FORMAT_R32_SINT,
        .sint32x2 => c.DXGI_FORMAT_R32G32_SINT,
        .sint32x3 => c.DXGI_FORMAT_R32G32B32_SINT,
        .sint32x4 => c.DXGI_FORMAT_R32G32B32A32_SINT,
    };
}

pub fn dxgiFormatTypeless(format: sysgpu.Texture.Format) c.DXGI_FORMAT {
    return switch (format) {
        .undefined => unreachable,
        .r8_unorm, .r8_snorm, .r8_uint, .r8_sint => c.DXGI_FORMAT_R8_TYPELESS,
        .r16_uint, .r16_sint, .r16_float => c.DXGI_FORMAT_R16_TYPELESS,
        .rg8_unorm, .rg8_snorm, .rg8_uint, .rg8_sint => c.DXGI_FORMAT_R8G8_TYPELESS,
        .r32_float, .r32_uint, .r32_sint => c.DXGI_FORMAT_R32_TYPELESS,
        .rg16_uint, .rg16_sint, .rg16_float => c.DXGI_FORMAT_R16G16_TYPELESS,
        .rgba8_unorm, .rgba8_unorm_srgb, .rgba8_snorm, .rgba8_uint, .rgba8_sint => c.DXGI_FORMAT_R8G8B8A8_TYPELESS,
        .bgra8_unorm, .bgra8_unorm_srgb => c.DXGI_FORMAT_B8G8R8A8_TYPELESS,
        .rgb10_a2_unorm => c.DXGI_FORMAT_R10G10B10A2_TYPELESS,
        .rg11_b10_ufloat => c.DXGI_FORMAT_R11G11B10_FLOAT,
        .rgb9_e5_ufloat => c.DXGI_FORMAT_R9G9B9E5_SHAREDEXP,
        .rg32_float, .rg32_uint, .rg32_sint => c.DXGI_FORMAT_R32G32_TYPELESS,
        .rgba16_uint, .rgba16_sint, .rgba16_float => c.DXGI_FORMAT_R16G16B16A16_TYPELESS,
        .rgba32_float, .rgba32_uint, .rgba32_sint => c.DXGI_FORMAT_R32G32B32A32_TYPELESS,
        .stencil8 => c.DXGI_FORMAT_R24G8_TYPELESS,
        .depth16_unorm => c.DXGI_FORMAT_R16_TYPELESS,
        .depth24_plus => c.DXGI_FORMAT_R24G8_TYPELESS,
        .depth24_plus_stencil8 => c.DXGI_FORMAT_R24G8_TYPELESS,
        .depth32_float => c.DXGI_FORMAT_R32_TYPELESS,
        .depth32_float_stencil8 => c.DXGI_FORMAT_R32G8X24_TYPELESS,
        .bc1_rgba_unorm, .bc1_rgba_unorm_srgb => c.DXGI_FORMAT_BC1_TYPELESS,
        .bc2_rgba_unorm, .bc2_rgba_unorm_srgb => c.DXGI_FORMAT_BC2_TYPELESS,
        .bc3_rgba_unorm, .bc3_rgba_unorm_srgb => c.DXGI_FORMAT_BC3_TYPELESS,
        .bc4_runorm, .bc4_rsnorm => c.DXGI_FORMAT_BC4_TYPELESS,
        .bc5_rg_unorm, .bc5_rg_snorm => c.DXGI_FORMAT_BC5_TYPELESS,
        .bc6_hrgb_ufloat, .bc6_hrgb_float => c.DXGI_FORMAT_BC6H_TYPELESS,
        .bc7_rgba_unorm, .bc7_rgba_unorm_srgb => c.DXGI_FORMAT_BC7_TYPELESS,
        .etc2_rgb8_unorm,
        .etc2_rgb8_unorm_srgb,
        .etc2_rgb8_a1_unorm,
        .etc2_rgb8_a1_unorm_srgb,
        .etc2_rgba8_unorm,
        .etc2_rgba8_unorm_srgb,
        .eacr11_unorm,
        .eacr11_snorm,
        .eacrg11_unorm,
        .eacrg11_snorm,
        .astc4x4_unorm,
        .astc4x4_unorm_srgb,
        .astc5x4_unorm,
        .astc5x4_unorm_srgb,
        .astc5x5_unorm,
        .astc5x5_unorm_srgb,
        .astc6x5_unorm,
        .astc6x5_unorm_srgb,
        .astc6x6_unorm,
        .astc6x6_unorm_srgb,
        .astc8x5_unorm,
        .astc8x5_unorm_srgb,
        .astc8x6_unorm,
        .astc8x6_unorm_srgb,
        .astc8x8_unorm,
        .astc8x8_unorm_srgb,
        .astc10x5_unorm,
        .astc10x5_unorm_srgb,
        .astc10x6_unorm,
        .astc10x6_unorm_srgb,
        .astc10x8_unorm,
        .astc10x8_unorm_srgb,
        .astc10x10_unorm,
        .astc10x10_unorm_srgb,
        .astc12x10_unorm,
        .astc12x10_unorm_srgb,
        .astc12x12_unorm,
        .astc12x12_unorm_srgb,
        => unreachable,
        .r8_bg8_biplanar420_unorm => c.DXGI_FORMAT_NV12,
    };
}

pub fn dxgiFormatIsTypeless(format: c.DXGI_FORMAT) bool {
    return switch (format) {
        c.DXGI_FORMAT_R32G32B32A32_TYPELESS,
        c.DXGI_FORMAT_R32G32B32_TYPELESS,
        c.DXGI_FORMAT_R16G16B16A16_TYPELESS,
        c.DXGI_FORMAT_R32G32_TYPELESS,
        c.DXGI_FORMAT_R32G8X24_TYPELESS,
        c.DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS,
        c.DXGI_FORMAT_R10G10B10A2_TYPELESS,
        c.DXGI_FORMAT_R8G8B8A8_TYPELESS,
        c.DXGI_FORMAT_R16G16_TYPELESS,
        c.DXGI_FORMAT_R32_TYPELESS,
        c.DXGI_FORMAT_R24G8_TYPELESS,
        c.DXGI_FORMAT_R8G8_TYPELESS,
        c.DXGI_FORMAT_R16_TYPELESS,
        c.DXGI_FORMAT_R8_TYPELESS,
        c.DXGI_FORMAT_BC1_TYPELESS,
        c.DXGI_FORMAT_BC2_TYPELESS,
        c.DXGI_FORMAT_BC3_TYPELESS,
        c.DXGI_FORMAT_BC4_TYPELESS,
        c.DXGI_FORMAT_BC5_TYPELESS,
        c.DXGI_FORMAT_B8G8R8A8_TYPELESS,
        c.DXGI_FORMAT_BC6H_TYPELESS,
        c.DXGI_FORMAT_BC7_TYPELESS,
        => true,
        else => false,
    };
}

pub fn dxgiUsage(usage: sysgpu.Texture.UsageFlags) c.DXGI_USAGE {
    var dxgi_usage: c.DXGI_USAGE = 0;
    if (usage.texture_binding)
        dxgi_usage |= c.DXGI_USAGE_SHADER_INPUT;
    if (usage.storage_binding)
        dxgi_usage |= c.DXGI_USAGE_UNORDERED_ACCESS;
    if (usage.render_attachment)
        dxgi_usage |= c.DXGI_USAGE_RENDER_TARGET_OUTPUT;
    return dxgi_usage;
}
