// TODO(important): review all code in this file in-depth
const mach = @import("mach");
const gpu = mach.gpu;
const std = @import("std");
const assets = @import("assets");

pub const name = .offscreen;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .prepare = .{ .handler = prepare },
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pipeline: *gpu.RenderPipeline,
texture: *gpu.Texture,
view: *gpu.TextureView,
buffer: *gpu.Buffer,
buffer_mapped: bool = false,
buffer_width: u32 = 0,
buffer_height: u32 = 0,
buffer_unpadded_bytes_per_row: u32 = 0,
buffer_padded_bytes_per_row: u32 = 0,
allocator: std.mem.Allocator,

fn deinit(offscreen: *Mod) !void {
    const state = offscreen.state();

    state.texture.release();
    state.view.release();
    state.buffer.release();
}

fn init(
    core: *mach.Core.Mod,
    offscreen: *Mod,
) !void {
    const device: *mach.gpu.Device = core.state().device;
    const allocator = gpa.allocator();

    const img_size = gpu.Extent3D{ .width = mach.core.size().width, .height = mach.core.size().height };

    // Create a GPU texture
    const label = @tagName(name) ++ ".init";
    const texture = device.createTexture(&.{
        .label = label,
        .size = img_size,
        .format = .bgra8_unorm,
        .usage = .{
            .texture_binding = true,
            .copy_dst = true,
            .copy_src = true,
            .render_attachment = true,
        },
    });

    const view = texture.createView(&.{
        .format = .bgra8_unorm,
        .dimension = .dimension_2d,
    });

    const buffer = device.createBuffer(&.{
        .usage = .{ .map_read = true, .copy_dst = true },
        .size = @sizeOf([4]u8) * img_size.width * img_size.height,
    });

    offscreen.init(.{
        .texture = texture,
        .view = view,
        .buffer = buffer,
        .buffer_width = img_size.width,
        .buffer_height = img_size.height,
        .buffer_padded_bytes_per_row = @sizeOf([4]u8) * img_size.width,
        .allocator = allocator,
        .pipeline = undefined,
    });
}

fn prepare(core: *mach.Core.Mod, offscreen: *Mod) !void {
    _ = core;

    const state: *@This() = offscreen.state();
    _ = state; // autofix
}
