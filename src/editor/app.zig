const std = @import("std");
const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

pub const name = .editor;
pub const modules = .{ mach.Engine, @This() };
pub const App = mach.App;

const UniformBufferObject = struct {
    resolution: @Vector(2, f32),
    time: f32,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

timer: mach.Timer,
pipeline: *gpu.RenderPipeline,
queue: *gpu.Queue,
uniform_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,

fragment_shader_file: std.fs.File,
fragment_shader_code: [:0]const u8,
last_mtime: i128,

pub fn init(editor: *mach.Mod(.editor)) !void {
    core.setTitle("Mach editor");

    var fragment_file: std.fs.File = undefined;
    var last_mtime: i128 = undefined;

    // TODO: there is no guarantee we are in the mach project root
    if (std.fs.cwd().openFile("src/editor/frag.wgsl", .{ .mode = .read_only })) |file| {
        fragment_file = file;
        if (file.stat()) |stat| {
            last_mtime = stat.mtime;
        } else |err| {
            std.debug.print("Something went wrong when attempting to stat file: {}\n", .{err});
            return;
        }
    } else |e| {
        std.debug.print("Something went wrong when attempting to open file: {}\n", .{e});
        return;
    }
    var code = try fragment_file.readToEndAllocOptions(allocator, std.math.maxInt(u16), null, 1, 0);

    const queue = core.device.getQueue();

    // We need a bgl to bind the UniformBufferObject, but it is also needed for creating
    // the RenderPipeline, so we pass it to recreatePipeline as a pointer
    var bgl: *gpu.BindGroupLayout = undefined;
    const pipeline = recreatePipeline(code, &bgl);

    const uniform_buffer = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
        .mapped_at_creation = .false,
    });
    const bind_group = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = bgl,
            .entries = &.{
                gpu.BindGroup.Entry.buffer(0, uniform_buffer, 0, @sizeOf(UniformBufferObject)),
            },
        }),
    );

    editor.state.timer = try mach.Timer.start();

    editor.state.pipeline = pipeline;
    editor.state.queue = queue;
    editor.state.uniform_buffer = uniform_buffer;
    editor.state.bind_group = bind_group;

    editor.state.fragment_shader_file = fragment_file;
    editor.state.fragment_shader_code = code;
    editor.state.last_mtime = last_mtime;

    bgl.release();
}

pub fn deinit(editor: *mach.Mod(.editor)) !void {
    defer _ = gpa.deinit();

    editor.state.fragment_shader_file.close();
    allocator.free(editor.state.fragment_shader_code);

    editor.state.uniform_buffer.release();
    editor.state.bind_group.release();
}

pub fn tick(
    engine: *mach.Mod(.engine),
    editor: *mach.Mod(.editor),
) !void {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                if (ev.key == .space) return engine.send(.exit, .{});
            },
            .close => return engine.send(.exit, .{}),
            else => {},
        }
    }

    if (editor.state.fragment_shader_file.stat()) |stat| {
        if (editor.state.last_mtime < stat.mtime) {
            std.log.info("The fragment shader has been changed", .{});
            editor.state.last_mtime = stat.mtime;
            editor.state.fragment_shader_file.seekTo(0) catch unreachable;
            editor.state.fragment_shader_code = editor.state.fragment_shader_file.readToEndAllocOptions(allocator, std.math.maxInt(u32), null, 1, 0) catch |err| {
                std.log.err("Err: {}", .{err});
                return engine.send(.exit, .{});
            };
            editor.state.pipeline = recreatePipeline(editor.state.fragment_shader_code, null);
        }
    } else |err| {
        std.log.err("Something went wrong when attempting to stat file: {}\n", .{err});
    }

    const back_buffer_view = core.swap_chain.getCurrentTextureView().?;
    const color_attachment = gpu.RenderPassColorAttachment{
        .view = back_buffer_view,
        .clear_value = std.mem.zeroes(gpu.Color),
        .load_op = .clear,
        .store_op = .store,
    };

    const encoder = core.device.createCommandEncoder(null);
    const render_pass_info = gpu.RenderPassDescriptor.init(.{
        .color_attachments = &.{color_attachment},
    });

    const time = editor.state.timer.read() / @as(f32, std.time.ns_per_s);
    const ubo = UniformBufferObject{
        .resolution = .{ @as(f32, @floatFromInt(core.descriptor.width)), @as(f32, @floatFromInt(core.descriptor.height)) },
        .time = time,
    };
    encoder.writeBuffer(editor.state.uniform_buffer, 0, &[_]UniformBufferObject{ubo});

    const pass = encoder.beginRenderPass(&render_pass_info);
    pass.setPipeline(editor.state.pipeline);
    pass.setBindGroup(0, editor.state.bind_group, &.{0});
    pass.draw(3, 1, 0, 0);
    pass.end();
    pass.release();

    var command = encoder.finish(null);
    encoder.release();

    editor.state.queue.submit(&[_]*gpu.CommandBuffer{command});
    command.release();
    core.swap_chain.present();
    back_buffer_view.release();
}

fn recreatePipeline(fragment_shader_code: [:0]const u8, bgl: ?**gpu.BindGroupLayout) *gpu.RenderPipeline {
    const vs_module = core.device.createShaderModuleWGSL("vert.wgsl", @embedFile("vert.wgsl"));
    defer vs_module.release();

    // Check wether the fragment shader code compiled successfully, if not
    // print the validation layer error and show a black screen
    core.device.pushErrorScope(.validation);
    var fs_module = core.device.createShaderModuleWGSL("fragment shader", fragment_shader_code);
    var error_occurred: bool = false;
    // popErrorScope() returns always true, (unless maybe it fails to capture the error scope?)
    _ = core.device.popErrorScope(&error_occurred, struct {
        inline fn callback(ctx: *bool, typ: gpu.ErrorType, message: [*:0]const u8) void {
            if (typ != .no_error) {
                std.debug.print("🔴🔴🔴🔴:\n{s}\n", .{message});
                ctx.* = true;
            }
        }
    }.callback);
    if (error_occurred) {
        fs_module = core.device.createShaderModuleWGSL(
            "black_screen_frag.wgsl",
            @embedFile("black_screen_frag.wgsl"),
        );
    }
    defer fs_module.release();

    const blend = gpu.BlendState{};
    const color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const fragment = gpu.FragmentState.init(.{
        .module = fs_module,
        .entry_point = "main",
        .targets = &.{color_target},
    });

    const bgle = gpu.BindGroupLayout.Entry.buffer(0, .{ .fragment = true }, .uniform, true, 0);
    // bgl is needed outside, for the creation of the uniform_buffer in main
    const bgl_tmp = core.device.createBindGroupLayout(&gpu.BindGroupLayout.Descriptor.init(.{
        .entries = &.{bgle},
    }));
    defer {
        // In frame we don't need to use bgl, so we can release it inside this function, else we pass bgl
        if (bgl == null) {
            bgl_tmp.release();
        } else {
            bgl.?.* = bgl_tmp;
        }
    }

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bgl_tmp};
    const pipeline_layout = core.device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
        .bind_group_layouts = &bind_group_layouts,
    }));
    defer pipeline_layout.release();

    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState.init(.{
            .module = vs_module,
            .entry_point = "main",
        }),
    };

    // Create the render pipeline. Even if the shader compilation succeeded, this could fail if the
    // shader is missing a `main` entrypoint.
    core.device.pushErrorScope(.validation);
    const pipeline = core.device.createRenderPipeline(&pipeline_descriptor);
    // popErrorScope() returns always true, (unless maybe it fails to capture the error scope?)
    _ = core.device.popErrorScope(&error_occurred, struct {
        inline fn callback(ctx: *bool, typ: gpu.ErrorType, message: [*:0]const u8) void {
            if (typ != .no_error) {
                std.debug.print("🔴🔴🔴🔴:\n{s}\n", .{message});
                ctx.* = true;
            }
        }
    }.callback);
    if (error_occurred) {
        // Retry with black_screen_frag which we know will work.
        return recreatePipeline(@embedFile("black_screen_frag.wgsl"), bgl);
    }
    return pipeline;
}
