const std = @import("std");
const c = @cImport(@cInclude("m3d.h"));
const testing = std.testing;

pub const Error = error{
    /// memory allocation error
    OutOfMemory,
    /// malformed text file (ASCII import only)
    BadFile,
    /// unimplemented interpreter (procedural surface)
    Unimplemented,
    /// unknown material property record
    Unknown,
    /// unknown mesh record (only triangles supported)
    UnknownMeshRecord,
    /// unknown image format (PNG only)
    UnknownImageFormat,
    /// unknown action or frame or missing bones
    UnknownActionFrame,
    /// unknown shape command record
    UnknownCommand,
    /// no voxel dimension or voxel size defined
    UnknownVoxel,
    /// either the precision or number of bones truncated
    Truncated,
    /// too many or no chunk of color map
    UnexpectedColorMapCount,
    /// too many or no chunk of texture map
    UnexpectedTextureMapCount,
    /// too many or no chunk of vertices
    UnexpectedVerticeCount,
    /// too many or no chunk of bones
    UnexpectedBoneCount,
    /// too many or no chunk of material
    UnexpectedMaterialCount,
    /// too many or no chunk of shape
    UnexpectedShapeCount,
    /// too many or no chunk of voxel
    UnexpectedVoxelCount,
};

const M3d = @This();

handle: *c.m3d_t,

pub fn load(data: [:0]u8, readfile_fn: ?ReadFn, free_fn: ?FreeFn, mtllib: ?M3d) ?M3d {
    return .{
        .handle = c.m3d_load(
            data.ptr,
            readfile_fn,
            free_fn,
            if (mtllib) |m| m.handle else null,
        ) orelse return null,
    };
}

pub fn deinit(self: M3d) void {
    c.m3d_free(self.handle);
}

/// return value must be freed with c_allocator
pub fn save(self: M3d, quality: Quality, flags: Flags) Error![]u8 {
    var size: u32 = 0;
    return if (c.m3d_save(
        self.handle,
        @enumToInt(quality),
        @bitCast(c_int, flags),
        &size,
    )) |res|
        res[0..size]
    else
        return intToError(self.errCode());
}

pub fn frame(self: M3d, action_id: u32, frame_id: u32, skeleton: []Transform) Error![]Transform {
    return if (c.m3d_frame(self.handle, action_id, frame_id, skeleton.ptr)) |res|
        res[0..self.handle.numbone]
    else
        intToError(self.errCode());
}

pub fn pose(self: M3d, action_id: u32, msec: u32) Error![]Bone {
    return if (c.m3d_pose(self.handle, action_id, msec)) |res|
        res[0..self.handle.numbone]
    else
        intToError(self.errCode());
}

pub fn name(self: M3d) [:0]const u8 {
    return std.mem.span(self.handle.name);
}

pub fn license(self: M3d) [:0]const u8 {
    return std.mem.span(self.handle.license);
}

pub fn author(self: M3d) [:0]const u8 {
    return std.mem.span(self.handle.author);
}

pub fn description(self: M3d) [:0]const u8 {
    return std.mem.span(self.handle.desc);
}

pub fn scale(self: M3d) f32 {
    return self.handle.scale;
}

pub fn preview(self: M3d) InlineAsset {
    return self.handle.preview;
}

pub fn textures(self: M3d) []TextureData {
    return self.handle.texture[0..self.handle.numtexture];
}

pub fn materials(self: M3d) []Material {
    return self.handle.material[0..self.handle.nummaterial];
}

pub fn errCode(self: M3d) c_int {
    return self.handle.errcode;
}

pub const TextureIndex = c.m3d_texturedata_t;
pub const TextureData = c.m3d_texturedata_t;
pub const Weight = c.m3d_weight_t;
pub const Skin = c.m3d_skin_t;
pub const Bone = c.m3d_bone_t;
pub const Vertex = c.m3d_vertex_t;
pub const Material = c.m3d_material_t;
pub const Face = c.m3d_face_t;
pub const VoxelItem = c.m3d_voxelitem_t;
pub const VoxelType = c.m3d_voxeltype_t;
pub const Voxel = c.m3d_voxel_t;
pub const ShapeCommand = c.m3d_shapecommand_t;
pub const Shape = c.m3d_shape_t;
pub const Label = c.m3d_label_t;
pub const Transform = c.m3d_transform_t;
pub const Frame = c.m3d_frame_t;
pub const Action = c.m3d_action_t;
pub const InlineAsset = c.m3d_inlinedasset_t;
pub const ReadFn = *const fn (filename: [*c]u8, size: [*c]c_uint) callconv(.C) [*c]u8;
pub const FreeFn = *const fn (ptr: ?*anyopaque) callconv(.C) void;

pub const Quality = enum(u2) {
    // export with -128 to 127 coordinate precision
    int8 = c.M3D_EXP_INT8,
    // export with -32768 to 32767 precision
    int16 = c.M3D_EXP_INT16,
    // export with 32 bit floating point precision
    float = c.M3D_EXP_FLOAT,
    // export with 64 bit floatint point precision
    double = c.M3D_EXP_DOUBLE,
};

pub const Flags = packed struct {
    // don't export color map
    nocmap: bool = false,
    // don't export materials
    nomaterial: bool = false,
    // don't export model face
    noface: bool = false,
    // don't export normal vectors
    nonormal: bool = false,
    // don't export texture UV
    notxtcrd: bool = false,
    // flip V in texture UVs
    fliptxtcrd: bool = false,
    // don't recalculate coordinates
    norecalc: bool = false,
    // the input is left-handed
    idosuck: bool = false,
    // don't export skeleton
    nobone: bool = false,
    // no animation nor skeleton saved
    noaction: bool = false,
    // inline assets into the model
    inline_assets: bool = false,
    // export unknown chunks too
    extra: bool = false,
    // export into uncompressed binary
    nozlib: bool = false,
    // export into ASCII format
    ascii: bool = false,
    // don't export maximum vertex
    novrtmax: bool = false,

    _padding: u17 = 0,
};

fn intToError(int: c_int) Error {
    return switch (int) {
        c.M3D_SUCCESS => unreachable,
        c.M3D_ERR_ALLOC => error.OutOfMemory,
        c.M3D_ERR_BADFILE => error.BadFile,
        c.M3D_ERR_UNIMPL => error.Unimplemented,
        c.M3D_ERR_UNKPROP => error.Unknown,
        c.M3D_ERR_UNKMESH => error.UnknownMeshRecord,
        c.M3D_ERR_UNKIMG => error.UnknownImageFormat,
        c.M3D_ERR_UNKFRAME => error.UnknownActionFrame,
        c.M3D_ERR_UNKCMD => error.UnknownCommand,
        c.M3D_ERR_UNKVOX => error.UnknownVoxel,
        c.M3D_ERR_TRUNC => error.Truncated,
        c.M3D_ERR_CMAP => error.UnexpectedColorMapCount,
        c.M3D_ERR_TMAP => error.UnexpectedTextureMapCount,
        c.M3D_ERR_VRTS => error.UnexpectedVerticeCount,
        c.M3D_ERR_BONE => error.UnexpectedBoneCount,
        c.M3D_ERR_MTRL => error.UnexpectedMaterialCount,
        c.M3D_ERR_SHPE => error.UnexpectedShapeCount,
        c.M3D_ERR_VOXT => error.UnexpectedVoxelCount,
        else => unreachable,
    };
}

test {
    testing.refAllDeclsRecursive(@This());

    var model_file = try std.fs.cwd().openFile( thisDir("/../assets/cube.m3d"), .{});
    defer model_file.close();
    var model_data = try model_file.readToEndAllocOptions(testing.allocator, 1024, 119, @alignOf(u8), 0);
    defer testing.allocator.free(model_data);

    const model = M3d.load(model_data, null, null, null) orelse return error.Fail;
    defer model.deinit();
    try testing.expectEqualStrings(model.name(), "cube.obj");

    var out = try model.save(.float, .{});
    defer std.heap.c_allocator.free(out);
    try testing.expect(out.len >= 119);
}

fn thisDir(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}
