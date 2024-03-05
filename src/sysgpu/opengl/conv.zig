const sysgpu = @import("../sysgpu/main.zig");
const utils = @import("../utils.zig");
const c = @import("c.zig");

fn stencilEnable(stencil: sysgpu.StencilFaceState) bool {
    return stencil.compare != .always or stencil.fail_op != .keep or stencil.depth_fail_op != .keep or stencil.pass_op != .keep;
}

pub fn glAttributeCount(format: sysgpu.VertexFormat) c.GLint {
    return switch (format) {
        .undefined => unreachable,
        .uint8x2 => 2,
        .uint8x4 => 4,
        .sint8x2 => 2,
        .sint8x4 => 4,
        .unorm8x2 => 2,
        .unorm8x4 => 4,
        .snorm8x2 => 2,
        .snorm8x4 => 4,
        .uint16x2 => 2,
        .uint16x4 => 4,
        .sint16x2 => 2,
        .sint16x4 => 4,
        .unorm16x2 => 2,
        .unorm16x4 => 4,
        .snorm16x2 => 2,
        .snorm16x4 => 4,
        .float16x2 => 2,
        .float16x4 => 4,
        .float32 => 1,
        .float32x2 => 2,
        .float32x3 => 3,
        .float32x4 => 4,
        .uint32 => 1,
        .uint32x2 => 2,
        .uint32x3 => 3,
        .uint32x4 => 4,
        .sint32 => 1,
        .sint32x2 => 2,
        .sint32x3 => 3,
        .sint32x4 => 4,
    };
}

pub fn glAttributeIsNormalized(format_type: utils.FormatType) c.GLboolean {
    return switch (format_type) {
        .unorm, .unorm_srgb, .snorm => c.GL_TRUE,
        else => c.GL_FALSE,
    };
}

pub fn glAttributeIsInt(format_type: utils.FormatType) bool {
    return switch (format_type) {
        .uint, .sint => true,
        else => false,
    };
}

pub fn glAttributeType(format: sysgpu.VertexFormat) c.GLenum {
    return switch (format) {
        .undefined => unreachable,
        .uint8x2 => c.GL_UNSIGNED_BYTE,
        .uint8x4 => c.GL_UNSIGNED_BYTE,
        .sint8x2 => c.GL_BYTE,
        .sint8x4 => c.GL_BYTE,
        .unorm8x2 => c.GL_UNSIGNED_BYTE,
        .unorm8x4 => c.GL_UNSIGNED_BYTE,
        .snorm8x2 => c.GL_BYTE,
        .snorm8x4 => c.GL_BYTE,
        .uint16x2 => c.GL_UNSIGNED_SHORT,
        .uint16x4 => c.GL_UNSIGNED_SHORT,
        .sint16x2 => c.GL_SHORT,
        .sint16x4 => c.GL_SHORT,
        .unorm16x2 => c.GL_UNSIGNED_SHORT,
        .unorm16x4 => c.GL_UNSIGNED_SHORT,
        .snorm16x2 => c.GL_SHORT,
        .snorm16x4 => c.GL_SHORT,
        .float16x2 => c.GL_HALF_FLOAT,
        .float16x4 => c.GL_HALF_FLOAT,
        .float32 => c.GL_FLOAT,
        .float32x2 => c.GL_FLOAT,
        .float32x3 => c.GL_FLOAT,
        .float32x4 => c.GL_FLOAT,
        .uint32 => c.GL_UNSIGNED_INT,
        .uint32x2 => c.GL_UNSIGNED_INT,
        .uint32x3 => c.GL_UNSIGNED_INT,
        .uint32x4 => c.GL_UNSIGNED_INT,
        .sint32 => c.GL_INT,
        .sint32x2 => c.GL_INT,
        .sint32x3 => c.GL_INT,
        .sint32x4 => c.GL_INT,
    };
}

pub fn glBlendFactor(factor: sysgpu.BlendFactor, color: bool) c.GLenum {
    return switch (factor) {
        .zero => c.GL_ZERO,
        .one => c.GL_ONE,
        .src => c.GL_SRC_COLOR,
        .one_minus_src => c.GL_ONE_MINUS_SRC_COLOR,
        .src_alpha => c.GL_SRC_ALPHA,
        .one_minus_src_alpha => c.GL_ONE_MINUS_SRC_ALPHA,
        .dst => c.GL_DST_COLOR,
        .one_minus_dst => c.GL_ONE_MINUS_DST_COLOR,
        .dst_alpha => c.GL_DST_ALPHA,
        .one_minus_dst_alpha => c.GL_ONE_MINUS_DST_ALPHA,
        .src_alpha_saturated => c.GL_SRC_ALPHA_SATURATE,
        .constant => if (color) c.GL_CONSTANT_COLOR else c.GL_CONSTANT_ALPHA,
        .one_minus_constant => if (color) c.GL_ONE_MINUS_CONSTANT_COLOR else c.GL_ONE_MINUS_CONSTANT_ALPHA,
        .src1 => c.GL_SRC1_COLOR,
        .one_minus_src1 => c.GL_ONE_MINUS_SRC1_COLOR,
        .src1_alpha => c.GL_SRC1_ALPHA,
        .one_minus_src1_alpha => c.GL_ONE_MINUS_SRC1_ALPHA,
    };
}

pub fn glBlendOp(op: sysgpu.BlendOperation) c.GLenum {
    return switch (op) {
        .add => c.GL_FUNC_ADD,
        .subtract => c.GL_FUNC_SUBTRACT,
        .reverse_subtract => c.GL_FUNC_REVERSE_SUBTRACT,
        .min => c.GL_MIN,
        .max => c.GL_MAX,
    };
}

//pub fn glBufferDataUsage(usage: sysgpu.Buffer.UsageFlags, mapped_at_creation: sysgpu.Bool32) c.GLenum {}

pub fn glBufferStorageFlags(usage: sysgpu.Buffer.UsageFlags, mapped_at_creation: sysgpu.Bool32) c.GLbitfield {
    var flags: c.GLbitfield = 0;
    if (mapped_at_creation == .true)
        flags |= c.GL_MAP_WRITE_BIT;
    if (usage.map_read)
        flags |= c.GL_MAP_PERSISTENT_BIT | c.GL_MAP_READ_BIT;
    if (usage.map_write)
        flags |= c.GL_MAP_PERSISTENT_BIT | c.GL_MAP_COHERENT_BIT | c.GL_MAP_WRITE_BIT;
    return flags;
}

pub fn glCompareFunc(func: sysgpu.CompareFunction) c.GLenum {
    return switch (func) {
        .undefined => unreachable,
        .never => c.GL_NEVER,
        .less => c.GL_LESS,
        .less_equal => c.GL_LEQUAL,
        .greater => c.GL_GREATER,
        .greater_equal => c.GL_GEQUAL,
        .equal => c.GL_EQUAL,
        .not_equal => c.GL_NOTEQUAL,
        .always => c.GL_ALWAYS,
    };
}

pub fn glCullEnabled(cull_mode: sysgpu.CullMode) bool {
    return switch (cull_mode) {
        .none => false,
        else => true,
    };
}

pub fn glCullFace(cull_mode: sysgpu.CullMode) c.GLenum {
    return switch (cull_mode) {
        .none => c.GL_BACK,
        .front => c.GL_FRONT,
        .back => c.GL_BACK,
    };
}

pub fn glDepthMask(ds: *const sysgpu.DepthStencilState) c.GLboolean {
    return if (ds.depth_write_enabled == .true) c.GL_TRUE else c.GL_FALSE;
}

pub fn glDepthTestEnabled(ds: *const sysgpu.DepthStencilState) bool {
    return ds.depth_compare != .always or ds.depth_write_enabled == .true;
}

pub fn glFrontFace(front_face: sysgpu.FrontFace) c.GLenum {
    return switch (front_face) {
        .ccw => c.GL_CCW,
        .cw => c.GL_CW,
    };
}

pub fn glIndexType(format: sysgpu.IndexFormat) c.GLenum {
    return switch (format) {
        .undefined => unreachable,
        .uint16 => c.GL_UNSIGNED_SHORT,
        .uint32 => c.GL_UNSIGNED_INT,
    };
}

pub fn glIndexElementSize(format: sysgpu.IndexFormat) usize {
    return switch (format) {
        .undefined => unreachable,
        .uint16 => 2,
        .uint32 => 4,
    };
}

pub fn glMapAccess(usage: sysgpu.Buffer.UsageFlags, mapped_at_creation: sysgpu.Bool32) c.GLbitfield {
    var flags: c.GLbitfield = 0;
    if (mapped_at_creation == .true)
        flags |= c.GL_MAP_WRITE_BIT;
    if (usage.map_read)
        flags |= c.GL_MAP_PERSISTENT_BIT | c.GL_MAP_READ_BIT;
    if (usage.map_write)
        flags |= c.GL_MAP_PERSISTENT_BIT | c.GL_MAP_WRITE_BIT;
    return flags;
}

pub fn glPrimitiveMode(topology: sysgpu.PrimitiveTopology) c.GLenum {
    return switch (topology) {
        .point_list => c.GL_POINTS,
        .line_list => c.GL_LINES,
        .line_strip => c.GL_LINE_STRIP,
        .triangle_list => c.GL_TRIANGLES,
        .triangle_strip => c.GL_TRIANGLE_STRIP,
    };
}

pub fn glStencilOp(op: sysgpu.StencilOperation) c.GLenum {
    return switch (op) {
        .keep => c.GL_KEEP,
        .zero => c.GL_ZERO,
        .replace => c.GL_REPLACE,
        .invert => c.GL_INVERT,
        .increment_clamp => c.GL_INCR,
        .decrement_clamp => c.GL_DECR,
        .increment_wrap => c.GL_INCR_WRAP,
        .decrement_wrap => c.GL_DECR_WRAP,
    };
}

pub fn glStencilTestEnabled(ds: *const sysgpu.DepthStencilState) bool {
    return stencilEnable(ds.stencil_front) or stencilEnable(ds.stencil_back);
}

pub fn glTargetForBuffer(usage: sysgpu.Buffer.UsageFlags) c.GLenum {
    // Not sure if this matters anymore - only get to pick one anyway
    if (usage.index)
        return c.GL_ELEMENT_ARRAY_BUFFER;
    if (usage.vertex)
        return c.GL_ARRAY_BUFFER;
    if (usage.uniform)
        return c.GL_UNIFORM_BUFFER;
    if (usage.storage)
        return c.GL_SHADER_STORAGE_BUFFER;
    if (usage.indirect)
        return c.GL_DRAW_INDIRECT_BUFFER;
    if (usage.query_resolve)
        return c.GL_QUERY_BUFFER;

    return c.GL_ARRAY_BUFFER;
}

pub fn glTargetForBufferBinding(binding_type: sysgpu.Buffer.BindingType) c.GLenum {
    return switch (binding_type) {
        .undefined => unreachable,
        .uniform => c.GL_UNIFORM_BUFFER,
        .storage => c.GL_SHADER_STORAGE_BUFFER,
        .read_only_storage => c.GL_SHADER_STORAGE_BUFFER,
    };
}
