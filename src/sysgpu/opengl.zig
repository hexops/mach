const std = @import("std");
const builtin = @import("builtin");
const sysgpu = @import("sysgpu/main.zig");
const limits = @import("limits.zig");
const utils = @import("utils.zig");
const shader = @import("shader.zig");
const c = @import("opengl/c.zig");
const conv = @import("opengl/conv.zig");
const proc = @import("opengl/proc.zig");

const log = std.log.scoped(.opengl);

const instance_class_name = "sysgpu-hwnd";
const upload_page_size = 64 * 1024 * 1024; // TODO - split writes and/or support large uploads
const gl_major_version = 4;
const gl_minor_version = 6; // TODO - lower this after initial implementation is complete
const use_buffer_storage = true;
const max_back_buffer_count = 3;

var allocator: std.mem.Allocator = undefined;
var debug_enabled: bool = undefined;

pub const InitOptions = struct {
    debug_enabled: bool = builtin.mode == .Debug,
};

pub fn init(alloc: std.mem.Allocator, options: InitOptions) !void {
    allocator = alloc;
    debug_enabled = options.debug_enabled;
}

const BindingPoint = shader.CodeGen.BindingPoint;
const BindingTable = shader.CodeGen.BindingTable;

const MapCallback = struct {
    buffer: *Buffer,
    callback: sysgpu.Buffer.MapCallback,
    userdata: ?*anyopaque,
};

const ActiveContext = struct {
    old_hdc: c.HDC,
    old_hglrc: c.HGLRC,

    pub fn init(hdc: c.HDC, hglrc: c.HGLRC) ActiveContext {
        const old_hdc = c.wglGetCurrentDC();
        const old_hglrc = c.wglGetCurrentContext();

        if (c.wglMakeCurrent(hdc, hglrc) == c.FALSE)
            @panic("ActiveContext failed");
        return .{ .old_hdc = old_hdc, .old_hglrc = old_hglrc };
    }

    pub fn deinit(ctx: *ActiveContext) void {
        _ = c.wglMakeCurrent(ctx.old_hdc, ctx.old_hglrc);
    }
};

fn createDummyWindow() c.HWND {
    const hinstance = c.GetModuleHandleA(null);
    const dwExStyle = c.WS_EX_OVERLAPPEDWINDOW;
    const dwStyle = c.WS_CLIPSIBLINGS | c.WS_CLIPCHILDREN;

    return c.CreateWindowExA(
        dwExStyle,
        instance_class_name,
        instance_class_name,
        dwStyle,
        0,
        0,
        1,
        1,
        null,
        null,
        hinstance,
        null,
    );
}

fn setPixelFormat(wgl: *proc.InstanceWGL, hwnd: c.HWND) !c_int {
    const hdc = c.GetDC(hwnd);

    const format_attribs = [_]c_int{
        c.WGL_DRAW_TO_WINDOW_ARB, c.GL_TRUE,
        c.WGL_SUPPORT_OPENGL_ARB, c.GL_TRUE,
        c.WGL_DOUBLE_BUFFER_ARB,  c.GL_TRUE,
        c.WGL_PIXEL_TYPE_ARB,     c.WGL_TYPE_RGBA_ARB,
        c.WGL_COLOR_BITS_ARB,     32,
        0,
    };

    var num_formats: c_uint = undefined;
    var pixel_format: c_int = undefined;
    if (wgl.choosePixelFormatARB(hdc, &format_attribs, null, 1, &pixel_format, &num_formats) == c.FALSE)
        return error.ChoosePixelFormatARBFailed;
    if (num_formats == 0)
        return error.NoFormatsAvailable;

    var pfd: c.PIXELFORMATDESCRIPTOR = undefined;
    if (c.DescribePixelFormat(hdc, pixel_format, @sizeOf(@TypeOf(pfd)), &pfd) == c.FALSE)
        return error.DescribePixelFormatFailed;

    if (c.SetPixelFormat(hdc, pixel_format, &pfd) == c.FALSE)
        return error.SetPixelFormatFailed;

    return pixel_format;
}

fn messageCallback(
    source: c.GLenum,
    message_type: c.GLenum,
    id: c.GLuint,
    severity: c.GLenum,
    length: c.GLsizei,
    message: [*c]const c.GLchar,
    user_data: ?*const anyopaque,
) callconv(.C) void {
    _ = source;
    _ = length;
    _ = user_data;
    switch (id) {
        0x20071 => return, // Buffer detailed info
        else => {},
    }

    std.debug.print("GL CALLBACK: {s} type = 0x{x}, id = 0x{x}, severity = 0x{x}, message = {s}\n", .{
        if (message_type == c.GL_DEBUG_TYPE_ERROR) "** GL ERROR **" else "",
        message_type,
        id,
        severity,
        message,
    });
}

fn checkError(gl: *proc.DeviceGL) void {
    const err = gl.getError();
    if (err != c.GL_NO_ERROR) {
        std.debug.print("glGetError {x}\n", .{err});
    }
}

pub const Instance = struct {
    manager: utils.Manager(Instance) = .{},
    wgl: proc.InstanceWGL,

    pub fn init(desc: *const sysgpu.Instance.Descriptor) !*Instance {
        // TODO
        _ = desc;

        // WNDCLASS
        const hinstance = c.GetModuleHandleA(null);
        const wc: c.WNDCLASSA = .{
            .lpfnWndProc = c.DefWindowProcA,
            .hInstance = hinstance,
            .lpszClassName = instance_class_name,
            .style = c.CS_OWNDC,
        };
        if (c.RegisterClassA(&wc) == 0)
            return error.RegisterClassFailed;

        // Dummy context
        const hwnd = createDummyWindow();
        const hdc = c.GetDC(hwnd);

        const pfd = c.PIXELFORMATDESCRIPTOR{
            .nSize = @sizeOf(c.PIXELFORMATDESCRIPTOR),
            .nVersion = 1,
            .dwFlags = c.PFD_DRAW_TO_WINDOW | c.PFD_SUPPORT_OPENGL | c.PFD_DOUBLEBUFFER,
            .iPixelType = c.PFD_TYPE_RGBA,
            .cColorBits = 32,
            .iLayerType = c.PFD_MAIN_PLANE,
        };
        const pixel_format = c.ChoosePixelFormat(hdc, &pfd);
        if (c.SetPixelFormat(hdc, pixel_format, &pfd) == c.FALSE)
            return error.SetPixelFormatFailed;

        const hglrc = c.WGLCreateContext(hdc);
        if (hglrc == null)
            return error.WGLCreateContextFailed;
        defer _ = c.WGLDeleteContext(hglrc);

        // Extension procs
        try proc.init();

        var ctx = ActiveContext.init(hdc, hglrc);
        defer ctx.deinit();

        var wgl: proc.InstanceWGL = undefined;
        wgl.load();

        // Result
        const instance = try allocator.create(Instance);
        instance.* = .{
            .wgl = wgl,
        };
        return instance;
    }

    pub fn deinit(instance: *Instance) void {
        const hinstance = c.GetModuleHandleA(null);

        proc.deinit();
        _ = c.UnregisterClassA(instance_class_name, hinstance);

        allocator.destroy(instance);
    }

    pub fn createSurface(instance: *Instance, desc: *const sysgpu.Surface.Descriptor) !*Surface {
        return Surface.init(instance, desc);
    }
};

pub const Adapter = struct {
    manager: utils.Manager(Adapter) = .{},
    hwnd: ?c.HWND,
    hdc: c.HDC,
    hglrc: c.HGLRC,
    pixel_format: c_int,
    vendor: [*c]const c.GLubyte,
    renderer: [*c]const c.GLubyte,
    version: [*c]const c.GLubyte,

    pub fn init(instance: *Instance, options: *const sysgpu.RequestAdapterOptions) !*Adapter {
        const wgl = &instance.wgl;

        // Use hwnd from surface is provided
        var hwnd: c.HWND = undefined;
        var pixel_format: c_int = undefined;
        if (options.compatible_surface) |surface_raw| {
            const surface: *Surface = @ptrCast(@alignCast(surface_raw));

            hwnd = surface.hwnd;
            pixel_format = surface.pixel_format;
        } else {
            hwnd = createDummyWindow();
            pixel_format = try setPixelFormat(wgl, hwnd);
        }

        // GL context
        const hdc = c.GetDC(hwnd);
        if (hdc == null)
            return error.GetDCFailed;

        const context_attribs = [_]c_int{
            c.WGL_CONTEXT_MAJOR_VERSION_ARB, gl_major_version,
            c.WGL_CONTEXT_MINOR_VERSION_ARB, gl_minor_version,
            c.WGL_CONTEXT_FLAGS_ARB,         c.WGL_CONTEXT_DEBUG_BIT_ARB,
            c.WGL_CONTEXT_PROFILE_MASK_ARB,  c.WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0,
        };

        const hglrc = wgl.createContextAttribsARB(hdc, null, &context_attribs);
        if (hglrc == null)
            return error.WGLCreateContextFailed;

        var ctx = ActiveContext.init(hdc, hglrc);
        defer ctx.deinit();

        var gl: proc.AdapterGL = undefined;
        gl.load();

        const vendor = gl.getString(c.GL_VENDOR);
        const renderer = gl.getString(c.GL_RENDERER);
        const version = gl.getString(c.GL_VERSION);

        // Result
        const adapter = try allocator.create(Adapter);
        adapter.* = .{
            .hwnd = if (options.compatible_surface == null) hwnd else null,
            .hdc = hdc,
            .pixel_format = pixel_format,
            .hglrc = hglrc,
            .vendor = vendor,
            .renderer = renderer,
            .version = version,
        };
        return adapter;
    }

    pub fn deinit(adapter: *Adapter) void {
        _ = c.wglDeleteContext(adapter.hglrc);
        if (adapter.hwnd) |hwnd| _ = c.DestroyWindow(hwnd);
        allocator.destroy(adapter);
    }

    pub fn createDevice(adapter: *Adapter, desc: ?*const sysgpu.Device.Descriptor) !*Device {
        return Device.init(adapter, desc);
    }

    pub fn getProperties(adapter: *Adapter) sysgpu.Adapter.Properties {
        return .{
            .vendor_id = 0, // TODO
            .vendor_name = adapter.vendor,
            .architecture = adapter.renderer,
            .device_id = 0, // TODO
            .name = adapter.vendor, // TODO
            .driver_description = adapter.version,
            .adapter_type = .unknown,
            .backend_type = .opengl,
            .compatibility_mode = .false,
        };
    }
};

pub const Surface = struct {
    manager: utils.Manager(Surface) = .{},
    hwnd: c.HWND,
    pixel_format: c_int,

    pub fn init(instance: *Instance, desc: *const sysgpu.Surface.Descriptor) !*Surface {
        const wgl = &instance.wgl;

        if (utils.findChained(sysgpu.Surface.DescriptorFromWindowsHWND, desc.next_in_chain.generic)) |win_desc| {
            // workaround issues with @alignCast panicking as HWND is not a real pointer
            var hwnd: c.HWND = undefined;
            @memcpy(std.mem.asBytes(&hwnd), std.mem.asBytes(&win_desc.hwnd));

            const pixel_format = try setPixelFormat(wgl, hwnd);

            const surface = try allocator.create(Surface);
            surface.* = .{
                .hwnd = hwnd,
                .pixel_format = pixel_format,
            };
            return surface;
        } else {
            return error.InvalidDescriptor;
        }
    }

    pub fn deinit(surface: *Surface) void {
        allocator.destroy(surface);
    }
};

pub const Device = struct {
    manager: utils.Manager(Device) = .{},
    queue: *Queue,
    hdc: c.HDC,
    hglrc: c.HGLRC,
    pixel_format: c_int,
    gl: proc.DeviceGL,
    streaming_manager: StreamingManager = undefined,
    reference_trackers: std.ArrayListUnmanaged(*ReferenceTracker) = .{},
    map_callbacks: std.ArrayListUnmanaged(MapCallback) = .{},

    lost_cb: ?sysgpu.Device.LostCallback = null,
    lost_cb_userdata: ?*anyopaque = null,
    log_cb: ?sysgpu.LoggingCallback = null,
    log_cb_userdata: ?*anyopaque = null,
    err_cb: ?sysgpu.ErrorCallback = null,
    err_cb_userdata: ?*anyopaque = null,

    pub fn init(adapter: *Adapter, desc: ?*const sysgpu.Device.Descriptor) !*Device {
        // TODO
        _ = desc;

        var ctx = ActiveContext.init(adapter.hdc, adapter.hglrc);
        defer ctx.deinit();

        var gl: proc.DeviceGL = undefined;
        gl.loadVersion(gl_major_version, gl_minor_version);

        // Default state
        gl.enable(c.GL_SCISSOR_TEST);
        gl.enable(c.GL_PRIMITIVE_RESTART_FIXED_INDEX);
        gl.enable(c.GL_FRAMEBUFFER_SRGB);

        if (debug_enabled) {
            gl.enable(c.GL_DEBUG_OUTPUT);
            gl.enable(c.GL_DEBUG_OUTPUT_SYNCHRONOUS);
            gl.debugMessageCallback(messageCallback, null);
        }

        // Queue
        const queue = try allocator.create(Queue);
        errdefer allocator.destroy(queue);

        // Object
        var device = try allocator.create(Device);
        device.* = .{
            .queue = queue,
            .hdc = adapter.hdc,
            .hglrc = adapter.hglrc,
            .pixel_format = adapter.pixel_format,
            .gl = gl,
        };

        // Initialize
        device.queue.* = try Queue.init(device);
        errdefer queue.deinit();

        device.streaming_manager = try StreamingManager.init(device);
        errdefer device.streaming_manager.deinit();

        return device;
    }

    pub fn deinit(device: *Device) void {
        if (device.lost_cb) |lost_cb| {
            lost_cb(.destroyed, "Device was destroyed.", device.lost_cb_userdata);
        }

        device.waitAll() catch {};
        device.processQueuedOperations();

        device.map_callbacks.deinit(allocator);
        device.reference_trackers.deinit(allocator);
        device.streaming_manager.deinit();
        device.queue.manager.release();
        allocator.destroy(device.queue);
        allocator.destroy(device);
    }

    pub fn createBindGroup(device: *Device, desc: *const sysgpu.BindGroup.Descriptor) !*BindGroup {
        return BindGroup.init(device, desc);
    }

    pub fn createBindGroupLayout(device: *Device, desc: *const sysgpu.BindGroupLayout.Descriptor) !*BindGroupLayout {
        return BindGroupLayout.init(device, desc);
    }

    pub fn createBuffer(device: *Device, desc: *const sysgpu.Buffer.Descriptor) !*Buffer {
        return Buffer.init(device, desc);
    }

    pub fn createCommandEncoder(device: *Device, desc: *const sysgpu.CommandEncoder.Descriptor) !*CommandEncoder {
        return CommandEncoder.init(device, desc);
    }

    pub fn createComputePipeline(device: *Device, desc: *const sysgpu.ComputePipeline.Descriptor) !*ComputePipeline {
        return ComputePipeline.init(device, desc);
    }

    pub fn createPipelineLayout(device: *Device, desc: *const sysgpu.PipelineLayout.Descriptor) !*PipelineLayout {
        return PipelineLayout.init(device, desc);
    }

    pub fn createRenderPipeline(device: *Device, desc: *const sysgpu.RenderPipeline.Descriptor) !*RenderPipeline {
        return RenderPipeline.init(device, desc);
    }

    pub fn createSampler(device: *Device, desc: *const sysgpu.Sampler.Descriptor) !*Sampler {
        return Sampler.init(device, desc);
    }

    pub fn createShaderModuleAir(device: *Device, air: *shader.Air, label: [*:0]const u8) !*ShaderModule {
        _ = label;
        return ShaderModule.initAir(device, air);
    }

    pub fn createShaderModuleSpirv(device: *Device, code: []const u8) !*ShaderModule {
        _ = code;
        _ = device;
        return error.Unsupported;
    }

    pub fn createSwapChain(device: *Device, surface: *Surface, desc: *const sysgpu.SwapChain.Descriptor) !*SwapChain {
        return SwapChain.init(device, surface, desc);
    }

    pub fn createTexture(device: *Device, desc: *const sysgpu.Texture.Descriptor) !*Texture {
        return Texture.init(device, desc);
    }

    pub fn getQueue(device: *Device) !*Queue {
        return device.queue;
    }

    pub fn tick(device: *Device) !void {
        device.processQueuedOperations();
    }

    // Internal
    pub fn processQueuedOperations(device: *Device) void {
        // Reference trackers
        if (device.reference_trackers.items.len > 0) {
            const gl = &device.gl;
            var ctx = ActiveContext.init(device.hdc, device.hglrc);
            defer ctx.deinit();

            var i: usize = 0;
            while (i < device.reference_trackers.items.len) {
                const reference_tracker = device.reference_trackers.items[i];

                var status: c.GLenum = undefined;
                gl.getSynciv(reference_tracker.sync, c.GL_SYNC_STATUS, @sizeOf(c.GLenum), null, @ptrCast(&status));

                if (status == c.GL_SIGNALED) {
                    reference_tracker.deinit();
                    _ = device.reference_trackers.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }

        // MapAsync
        {
            var i: usize = 0;
            while (i < device.map_callbacks.items.len) {
                const map_callback = device.map_callbacks.items[i];

                if (map_callback.buffer.gpu_count == 0) {
                    map_callback.buffer.executeMapAsync(map_callback);

                    _ = device.map_callbacks.swapRemove(i);
                } else {
                    i += 1;
                }
            }
        }
    }

    fn waitAll(device: *Device) !void {
        if (device.reference_trackers.items.len > 0) {
            const gl = &device.gl;
            var ctx = ActiveContext.init(device.hdc, device.hglrc);
            defer ctx.deinit();

            for (device.reference_trackers.items) |reference_tracker| {
                _ = gl.clientWaitSync(reference_tracker.sync, c.GL_SYNC_FLUSH_COMMANDS_BIT, std.math.maxInt(u64));
            }
        }
    }
};

pub const StreamingManager = struct {
    device: *Device,
    free_buffers: std.ArrayListUnmanaged(*Buffer) = .{},

    pub fn init(device: *Device) !StreamingManager {
        return .{
            .device = device,
        };
    }

    pub fn deinit(manager: *StreamingManager) void {
        for (manager.free_buffers.items) |buffer| buffer.manager.release();
        manager.free_buffers.deinit(allocator);
    }

    pub fn acquire(manager: *StreamingManager) !*Buffer {
        const device = manager.device;

        // Recycle finished buffers
        if (manager.free_buffers.items.len == 0) {
            device.processQueuedOperations();
        }

        // Create new buffer
        if (manager.free_buffers.items.len == 0) {
            const buffer = try Buffer.init(device, &.{
                .label = "upload",
                .usage = .{
                    .copy_src = true,
                    .map_write = true,
                },
                .size = upload_page_size,
                .mapped_at_creation = .true,
            });
            errdefer _ = buffer.manager.release();

            try manager.free_buffers.append(allocator, buffer);
        }

        // Result
        return manager.free_buffers.pop();
    }

    pub fn release(manager: *StreamingManager, buffer: *Buffer) void {
        manager.free_buffers.append(allocator, buffer) catch {
            std.debug.panic("OutOfMemory", .{});
        };
    }
};

pub const SwapChain = struct {
    manager: utils.Manager(SwapChain) = .{},
    device: *Device,
    hdc: c.HDC,
    pixel_format: c_int,
    back_buffer_count: u32,
    textures: [max_back_buffer_count]*Texture,
    views: [max_back_buffer_count]*TextureView,

    pub fn init(device: *Device, surface: *Surface, desc: *const sysgpu.SwapChain.Descriptor) !*SwapChain {
        const swapchain = try allocator.create(SwapChain);

        const back_buffer_count: u32 = if (desc.present_mode == .mailbox) 3 else 2;

        var textures = std.BoundedArray(*Texture, max_back_buffer_count){};
        var views = std.BoundedArray(*TextureView, max_back_buffer_count){};
        errdefer {
            for (views.slice()) |view| view.manager.release();
            for (textures.slice()) |texture| texture.manager.release();
        }

        for (0..back_buffer_count) |_| {
            const texture = try Texture.initForSwapChain(device, desc, swapchain);
            const view = try texture.createView(&sysgpu.TextureView.Descriptor{});

            textures.appendAssumeCapacity(texture);
            views.appendAssumeCapacity(view);
        }

        swapchain.* = .{
            .device = device,
            .hdc = c.GetDC(surface.hwnd),
            .pixel_format = surface.pixel_format,
            .back_buffer_count = back_buffer_count,
            .textures = textures.buffer,
            .views = views.buffer,
        };
        return swapchain;
    }

    pub fn deinit(swapchain: *SwapChain) void {
        for (swapchain.views[0..swapchain.back_buffer_count]) |view| view.manager.release();
        for (swapchain.textures[0..swapchain.back_buffer_count]) |texture| texture.manager.release();
        allocator.destroy(swapchain);
    }

    pub fn getCurrentTextureView(swapchain: *SwapChain) !*TextureView {
        const index = 0;
        // TEMP - resolve reference tracking in main.zig
        swapchain.views[index].manager.reference();
        return swapchain.views[index];
    }

    pub fn present(swapchain: *SwapChain) !void {
        const device = swapchain.device;
        var ctx = ActiveContext.init(swapchain.hdc, device.hglrc);
        defer ctx.deinit();

        if (c.SwapBuffers(swapchain.hdc) == c.FALSE)
            return error.SwapBuffersFailed;
    }
};

pub const Buffer = struct {
    manager: utils.Manager(Buffer) = .{},
    device: *Device,
    target: c.GLenum,
    handle: c.GLuint,
    gpu_count: u32 = 0,
    map: ?[*]u8,
    mapped_at_creation: bool,
    // TODO - packed buffer descriptor struct
    size: u64,
    usage: sysgpu.Buffer.UsageFlags,

    pub fn init(device: *Device, desc: *const sysgpu.Buffer.Descriptor) !*Buffer {
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        const target = conv.glTargetForBuffer(desc.usage);

        var handle: c.GLuint = undefined;
        gl.genBuffers(1, &handle);
        gl.bindBuffer(target, handle);

        if (use_buffer_storage) {
            const flags = conv.glBufferStorageFlags(desc.usage, desc.mapped_at_creation);
            gl.bufferStorage(target, @intCast(desc.size), null, flags);
        } else {
            const usage = conv.glBufferDataUsage(desc.usage, desc.mapped_at_creation);
            gl.bufferData(target, desc.size, null, usage);
        }

        // TODO - create an upload buffer instead of using persistent mapping when map_read/write are both false
        var map: ?*anyopaque = null;
        const access = conv.glMapAccess(desc.usage, desc.mapped_at_creation);
        if (access != 0) {
            map = gl.mapBufferRange(target, 0, @intCast(desc.size), access);
        }

        const buffer = try allocator.create(Buffer);
        buffer.* = .{
            .device = device,
            .target = target,
            .handle = handle,
            .size = desc.size,
            .usage = desc.usage,
            .map = @ptrCast(map),
            .mapped_at_creation = desc.mapped_at_creation == .true,
        };
        return buffer;
    }

    pub fn deinit(buffer: *Buffer) void {
        const device = buffer.device;
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        gl.deleteBuffers(1, &buffer.handle);

        allocator.destroy(buffer);
    }

    pub fn getMappedRange(buffer: *Buffer, offset: usize, size: usize) !?*anyopaque {
        return @ptrCast(buffer.map.?[offset .. offset + size]);
    }

    pub fn getSize(buffer: *Buffer) u64 {
        return buffer.size;
    }

    pub fn getUsage(buffer: *Buffer) sysgpu.Buffer.UsageFlags {
        return buffer.usage;
    }

    pub fn mapAsync(
        buffer: *Buffer,
        mode: sysgpu.MapModeFlags,
        offset: usize,
        size: usize,
        callback: sysgpu.Buffer.MapCallback,
        userdata: ?*anyopaque,
    ) !void {
        _ = mode;
        _ = size;
        _ = offset;

        const map_callback = MapCallback{ .buffer = buffer, .callback = callback, .userdata = userdata };
        if (buffer.gpu_count == 0) {
            buffer.executeMapAsync(map_callback);
        } else {
            try buffer.device.map_callbacks.append(allocator, map_callback);
        }
    }

    pub fn setLabel(buffer: *Buffer, label: [*:0]const u8) void {
        _ = label;
        _ = buffer;
    }

    pub fn unmap(buffer: *Buffer) !void {
        if (buffer.mapped_at_creation) {
            const device = buffer.device;
            const gl = &device.gl;
            var ctx = ActiveContext.init(device.hdc, device.hglrc);
            defer ctx.deinit();

            gl.bindBuffer(buffer.target, buffer.handle);
            _ = gl.unmapBuffer(buffer.target); // TODO - handle error?
            buffer.mapped_at_creation = false;
        }
    }

    // Internal
    pub fn executeMapAsync(buffer: *Buffer, map_callback: MapCallback) void {
        _ = buffer;

        map_callback.callback(.success, map_callback.userdata);
    }
};

pub const Texture = struct {
    manager: utils.Manager(Texture) = .{},
    handle: c.GLuint,
    swapchain: ?*SwapChain = null,
    // TODO - packed texture descriptor struct
    usage: sysgpu.Texture.UsageFlags,
    dimension: sysgpu.Texture.Dimension,
    size: sysgpu.Extent3D,
    format: sysgpu.Texture.Format,
    mip_level_count: u32,
    sample_count: u32,

    pub fn init(device: *Device, desc: *const sysgpu.Texture.Descriptor) !*Texture {
        _ = device;

        const texture = try allocator.create(Texture);
        texture.* = .{
            .handle = 0,
            .swapchain = null,
            .usage = desc.usage,
            .dimension = desc.dimension,
            .size = desc.size,
            .format = desc.format,
            .mip_level_count = desc.mip_level_count,
            .sample_count = desc.sample_count,
        };
        return texture;
    }

    pub fn initForSwapChain(device: *Device, desc: *const sysgpu.SwapChain.Descriptor, swapchain: *SwapChain) !*Texture {
        _ = device;

        const texture = try allocator.create(Texture);
        texture.* = .{
            .handle = 0,
            .swapchain = swapchain,
            .usage = desc.usage,
            .dimension = .dimension_2d,
            .size = .{ .width = desc.width, .height = desc.height, .depth_or_array_layers = 1 },
            .format = desc.format,
            .mip_level_count = 1,
            .sample_count = 1,
        };
        return texture;
    }

    pub fn deinit(texture: *Texture) void {
        allocator.destroy(texture);
    }

    pub fn createView(texture: *Texture, desc: *const sysgpu.TextureView.Descriptor) !*TextureView {
        return TextureView.init(texture, desc);
    }
};

pub const TextureView = struct {
    manager: utils.Manager(TextureView) = .{},
    texture: *Texture,
    format: sysgpu.Texture.Format,
    dimension: sysgpu.TextureView.Dimension,
    base_mip_level: u32,
    mip_level_count: u32,
    base_array_layer: u32,
    array_layer_count: u32,
    aspect: sysgpu.Texture.Aspect,

    pub fn init(texture: *Texture, desc: *const sysgpu.TextureView.Descriptor) !*TextureView {
        texture.manager.reference();

        const texture_dimension: sysgpu.TextureView.Dimension = switch (texture.dimension) {
            .dimension_1d => .dimension_1d,
            .dimension_2d => .dimension_2d,
            .dimension_3d => .dimension_3d,
        };

        const view = try allocator.create(TextureView);
        view.* = .{
            .texture = texture,
            .format = if (desc.format != .undefined) desc.format else texture.format,
            .dimension = if (desc.dimension != .dimension_undefined) desc.dimension else texture_dimension,
            .base_mip_level = desc.base_mip_level,
            .mip_level_count = desc.mip_level_count,
            .base_array_layer = desc.base_array_layer,
            .array_layer_count = desc.array_layer_count,
            .aspect = desc.aspect,
        };
        return view;
    }

    pub fn deinit(view: *TextureView) void {
        view.texture.manager.release();
        allocator.destroy(view);
    }

    // Internal
    pub fn width(view: *TextureView) u32 {
        return @max(1, view.texture.size.width >> @intCast(view.base_mip_level));
    }

    pub fn height(view: *TextureView) u32 {
        return @max(1, view.texture.size.height >> @intCast(view.base_mip_level));
    }
};

pub const Sampler = struct {
    manager: utils.Manager(TextureView) = .{},

    pub fn init(device: *Device, desc: *const sysgpu.Sampler.Descriptor) !*Sampler {
        _ = desc;
        _ = device;

        const sampler = try allocator.create(Sampler);
        sampler.* = .{};
        return sampler;
    }

    pub fn deinit(sampler: *Sampler) void {
        allocator.destroy(sampler);
    }
};

pub const BindGroupLayout = struct {
    manager: utils.Manager(BindGroupLayout) = .{},
    entries: []const sysgpu.BindGroupLayout.Entry,

    pub fn init(device: *Device, desc: *const sysgpu.BindGroupLayout.Descriptor) !*BindGroupLayout {
        _ = device;

        var entries: []const sysgpu.BindGroupLayout.Entry = undefined;
        if (desc.entry_count > 0) {
            entries = try allocator.dupe(sysgpu.BindGroupLayout.Entry, desc.entries.?[0..desc.entry_count]);
        } else {
            entries = &[_]sysgpu.BindGroupLayout.Entry{};
        }

        const layout = try allocator.create(BindGroupLayout);
        layout.* = .{
            .entries = entries,
        };
        return layout;
    }

    pub fn deinit(layout: *BindGroupLayout) void {
        if (layout.entries.len > 0)
            allocator.free(layout.entries);
        allocator.destroy(layout);
    }

    // Internal
    pub fn getEntry(layout: *BindGroupLayout, binding: u32) ?*const sysgpu.BindGroupLayout.Entry {
        for (layout.entries) |*entry| {
            if (entry.binding == binding)
                return entry;
        }

        return null;
    }

    pub fn getDynamicIndex(layout: *BindGroupLayout, binding: u32) ?u32 {
        var index: u32 = 0;
        for (layout.entries) |entry| {
            if (entry.buffer.has_dynamic_offset == .false)
                continue;

            if (entry.binding == binding)
                return index;
            index += 1;
        }

        return null;
    }
};

pub const BindGroup = struct {
    const Kind = enum {
        buffer,
        sampler,
        texture,
    };

    const Entry = struct {
        kind: Kind = undefined,
        binding: u32,
        dynamic_index: ?u32,
        target: c.GLenum = 0,
        buffer: ?*Buffer = null,
        offset: u32 = 0,
        size: u32 = 0,
    };

    manager: utils.Manager(BindGroup) = .{},
    entries: []const Entry,

    pub fn init(device: *Device, desc: *const sysgpu.BindGroup.Descriptor) !*BindGroup {
        _ = device;

        const layout: *BindGroupLayout = @ptrCast(@alignCast(desc.layout));

        var entries = try allocator.alloc(Entry, desc.entry_count);
        errdefer allocator.free(entries);

        for (desc.entries.?[0..desc.entry_count], 0..) |entry, i| {
            var gl_entry = &entries[i];

            const bind_group_entry = layout.getEntry(entry.binding) orelse return error.UnknownBinding;

            gl_entry.* = .{
                .binding = entry.binding,
                .dynamic_index = layout.getDynamicIndex(entry.binding),
            };
            if (entry.buffer) |buffer_raw| {
                const buffer: *Buffer = @ptrCast(@alignCast(buffer_raw));
                buffer.manager.reference();
                gl_entry.kind = .buffer;
                gl_entry.target = conv.glTargetForBufferBinding(bind_group_entry.buffer.type);
                gl_entry.buffer = buffer;
                gl_entry.offset = @intCast(entry.offset);
                gl_entry.size = @intCast(entry.size);
            }
        }

        const group = try allocator.create(BindGroup);
        group.* = .{
            .entries = entries,
        };
        return group;
    }

    pub fn deinit(group: *BindGroup) void {
        for (group.entries) |entry| {
            if (entry.buffer) |buffer| buffer.manager.release();
        }
        allocator.free(group.entries);
        allocator.destroy(group);
    }
};

pub const PipelineLayout = struct {
    manager: utils.Manager(PipelineLayout) = .{},
    group_layouts: []*BindGroupLayout,
    bindings: BindingTable,

    pub fn init(device: *Device, desc: *const sysgpu.PipelineLayout.Descriptor) !*PipelineLayout {
        _ = device;

        var group_layouts = try allocator.alloc(*BindGroupLayout, desc.bind_group_layout_count);
        errdefer allocator.free(group_layouts);

        for (0..desc.bind_group_layout_count) |i| {
            const layout: *BindGroupLayout = @ptrCast(@alignCast(desc.bind_group_layouts.?[i]));
            layout.manager.reference();
            group_layouts[i] = layout;
        }

        var bindings: BindingTable = .{};
        errdefer bindings.deinit(allocator);

        var buffer_index: u32 = 0;
        var texture_index: u32 = 0;
        var sampler_index: u32 = 0;

        for (group_layouts, 0..) |group_layout, group| {
            for (group_layout.entries) |entry| {
                const key = BindingPoint{ .group = @intCast(group), .binding = entry.binding };

                if (entry.buffer.type != .undefined) {
                    try bindings.put(allocator, key, buffer_index);
                    buffer_index += 1;
                } else if (entry.sampler.type != .undefined) {
                    try bindings.put(allocator, key, sampler_index);
                    sampler_index += 1;
                } else if (entry.texture.sample_type != .undefined or entry.storage_texture.format != .undefined) {
                    try bindings.put(allocator, key, texture_index);
                    texture_index += 1;
                }
            }
        }

        const layout = try allocator.create(PipelineLayout);
        layout.* = .{
            .group_layouts = group_layouts,
            .bindings = bindings,
        };
        return layout;
    }

    pub fn initDefault(device: *Device, default_pipeline_layout: utils.DefaultPipelineLayoutDescriptor) !*PipelineLayout {
        const groups = default_pipeline_layout.groups;
        var bind_group_layouts = std.BoundedArray(*sysgpu.BindGroupLayout, limits.max_bind_groups){};
        defer {
            for (bind_group_layouts.slice()) |bind_group_layout_raw| {
                const bind_group_layout: *BindGroupLayout = @ptrCast(@alignCast(bind_group_layout_raw));
                bind_group_layout.manager.release();
            }
        }

        for (groups.slice()) |entries| {
            const bind_group_layout = try device.createBindGroupLayout(
                &sysgpu.BindGroupLayout.Descriptor.init(.{ .entries = entries.items }),
            );
            bind_group_layouts.appendAssumeCapacity(@ptrCast(bind_group_layout));
        }

        return device.createPipelineLayout(
            &sysgpu.PipelineLayout.Descriptor.init(.{ .bind_group_layouts = bind_group_layouts.slice() }),
        );
    }

    pub fn deinit(layout: *PipelineLayout) void {
        for (layout.group_layouts) |group_layout| group_layout.manager.release();
        layout.bindings.deinit(allocator);

        allocator.free(layout.group_layouts);
        allocator.destroy(layout);
    }
};

pub const ShaderModule = struct {
    manager: utils.Manager(ShaderModule) = .{},
    device: *Device,
    air: *shader.Air,

    pub fn initAir(device: *Device, air: *shader.Air) !*ShaderModule {
        const module = try allocator.create(ShaderModule);
        module.* = .{
            .device = device,
            .air = air,
        };
        return module;
    }

    pub fn deinit(shader_module: *ShaderModule) void {
        shader_module.air.deinit(allocator);
        allocator.destroy(shader_module.air);
        allocator.destroy(shader_module);
    }

    pub fn compile(
        module: *ShaderModule,
        entrypoint: [*:0]const u8,
        shader_type: c.GLenum,
        bindings: *const BindingTable,
    ) !c.GLuint {
        const gl = &module.device.gl;

        const stage = switch (shader_type) {
            c.GL_VERTEX_SHADER => shader.CodeGen.Stage.vertex,
            c.GL_FRAGMENT_SHADER => shader.CodeGen.Stage.fragment,
            c.GL_COMPUTE_SHADER => shader.CodeGen.Stage.compute,
            else => unreachable,
        };

        const code = try shader.CodeGen.generate(
            allocator,
            module.air,
            .glsl,
            true,
            .{ .emit_source_file = "" },
            .{ .name = entrypoint, .stage = stage },
            bindings,
            null,
        );
        defer allocator.free(code);
        const code_z = try allocator.dupeZ(u8, code);
        defer allocator.free(code_z);

        std.debug.print("{s}\n", .{code});

        const gl_shader = gl.createShader(shader_type);
        if (gl_shader == 0)
            return error.CreateShaderFailed;

        gl.shaderSource(gl_shader, 1, @ptrCast(&code_z), null);
        gl.compileShader(gl_shader);

        var success: c.GLint = undefined;
        gl.getShaderiv(gl_shader, c.GL_COMPILE_STATUS, &success);
        if (success == c.GL_FALSE) {
            var info_log: [512]c.GLchar = undefined;
            gl.getShaderInfoLog(gl_shader, @sizeOf(@TypeOf(info_log)), null, &info_log);
            std.debug.print("Compilation Failed {s}\n", .{@as([*:0]u8, @ptrCast(&info_log))});
            return error.CompilationFailed;
        }

        return gl_shader;
    }
};

pub const ComputePipeline = struct {
    manager: utils.Manager(ComputePipeline) = .{},
    device: *Device,
    layout: *PipelineLayout,
    program: c.GLuint,

    pub fn init(device: *Device, desc: *const sysgpu.ComputePipeline.Descriptor) !*ComputePipeline {
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        const compute_module: *ShaderModule = @ptrCast(@alignCast(desc.compute.module));

        // Pipeline Layout
        var layout: *PipelineLayout = undefined;
        if (desc.layout) |layout_raw| {
            layout = @ptrCast(@alignCast(layout_raw));
            layout.manager.reference();
        } else {
            var layout_desc = utils.DefaultPipelineLayoutDescriptor.init(allocator);
            defer layout_desc.deinit();

            try layout_desc.addFunction(compute_module.air, .{ .compute = true }, desc.compute.entry_point);
            layout = try PipelineLayout.initDefault(device, layout_desc);
        }
        errdefer layout.manager.release();

        // Shaders
        const compute_shader = try compute_module.compile(desc.compute.entry_point, c.GL_COMPUTE_SHADER, &layout.bindings);
        defer gl.deleteShader(compute_shader);

        // Program
        const program = gl.createProgram();
        errdefer gl.deleteProgram(program);

        gl.attachShader(program, compute_shader);
        gl.linkProgram(program);

        var success: c.GLint = undefined;
        gl.getProgramiv(program, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            var info_log: [512]c.GLchar = undefined;
            gl.getProgramInfoLog(program, @sizeOf(@TypeOf(info_log)), null, &info_log);
            std.debug.print("Link Failed {s}\n", .{@as([*:0]u8, @ptrCast(&info_log))});
            return error.LinkFailed;
        }

        // Result
        const pipeline = try allocator.create(ComputePipeline);
        pipeline.* = .{
            .device = device,
            .layout = layout,
            .program = program,
        };
        return pipeline;
    }

    pub fn deinit(pipeline: *ComputePipeline) void {
        const device = pipeline.device;
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        gl.deleteProgram(pipeline.program);

        pipeline.layout.manager.release();
        allocator.destroy(pipeline);
    }

    pub fn getBindGroupLayout(pipeline: *ComputePipeline, group_index: u32) *BindGroupLayout {
        return @ptrCast(pipeline.layout.group_layouts[group_index]);
    }
};

pub const RenderPipeline = struct {
    const Attribute = struct {
        is_int: bool,
        index: c.GLuint,
        count: c.GLint,
        vertex_type: c.GLenum,
        normalized: c.GLboolean,
        stride: c.GLsizei,
        offset: c.GLuint,
    };
    const ColorTarget = struct {
        blend_enabled: bool,
        color_op: c.GLenum,
        alpha_op: c.GLenum,
        src_color_blend: c.GLenum,
        dst_color_blend: c.GLenum,
        src_alpha_blend: c.GLenum,
        dst_alpha_blend: c.GLenum,
        write_red: c.GLboolean,
        write_green: c.GLboolean,
        write_blue: c.GLboolean,
        write_alpha: c.GLboolean,
    };

    manager: utils.Manager(RenderPipeline) = .{},
    device: *Device,
    layout: *PipelineLayout,
    program: c.GLuint,
    vao: c.GLuint,
    attributes: []Attribute,
    buffer_attributes: [][]Attribute,
    mode: c.GLenum,
    front_face: c.GLenum,
    cull_enabled: bool,
    cull_face: c.GLenum,
    depth_test_enabled: bool,
    depth_mask: c.GLboolean,
    depth_func: c.GLenum,
    stencil_test_enabled: bool,
    stencil_read_mask: c.GLuint,
    stencil_write_mask: c.GLuint,
    stencil_back_compare_func: c.GLenum,
    stencil_back_fail_op: c.GLenum,
    stencil_back_depth_fail_op: c.GLenum,
    stencil_back_pass_op: c.GLenum,
    stencil_front_compare_func: c.GLenum,
    stencil_front_fail_op: c.GLenum,
    stencil_front_depth_fail_op: c.GLenum,
    stencil_front_pass_op: c.GLenum,
    polygon_offset_enabled: bool,
    depth_bias: f32,
    depth_bias_slope_scale: f32,
    depth_bias_clamp: f32,
    multisample_enabled: bool,
    sample_mask_enabled: bool,
    sample_mask_value: c.GLuint,
    alpha_to_coverage_enabled: bool,
    color_targets: []ColorTarget,

    pub fn init(device: *Device, desc: *const sysgpu.RenderPipeline.Descriptor) !*RenderPipeline {
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        const vertex_module: *ShaderModule = @ptrCast(@alignCast(desc.vertex.module));

        // Pipeline Layout
        var layout: *PipelineLayout = undefined;
        if (desc.layout) |layout_raw| {
            layout = @ptrCast(@alignCast(layout_raw));
            layout.manager.reference();
        } else {
            var layout_desc = utils.DefaultPipelineLayoutDescriptor.init(allocator);
            defer layout_desc.deinit();

            try layout_desc.addFunction(vertex_module.air, .{ .vertex = true }, desc.vertex.entry_point);
            if (desc.fragment) |frag| {
                const frag_module: *ShaderModule = @ptrCast(@alignCast(frag.module));
                try layout_desc.addFunction(frag_module.air, .{ .fragment = true }, frag.entry_point);
            }
            layout = try PipelineLayout.initDefault(device, layout_desc);
        }
        errdefer layout.manager.release();

        // Shaders
        const vertex_shader = try vertex_module.compile(desc.vertex.entry_point, c.GL_VERTEX_SHADER, &layout.bindings);
        defer gl.deleteShader(vertex_shader);

        var opt_fragment_shader: ?c.GLuint = null;
        if (desc.fragment) |frag| {
            const frag_module: *ShaderModule = @ptrCast(@alignCast(frag.module));
            opt_fragment_shader = try frag_module.compile(frag.entry_point, c.GL_FRAGMENT_SHADER, &layout.bindings);
        }
        defer if (opt_fragment_shader) |fragment_shader| gl.deleteShader(fragment_shader);

        // Vertex State
        var vao: c.GLuint = undefined;
        gl.genVertexArrays(1, &vao);
        gl.bindVertexArray(vao);

        var attribute_count: usize = 0;
        for (0..desc.vertex.buffer_count) |i| {
            const buffer = desc.vertex.buffers.?[i];
            attribute_count += buffer.attribute_count;
        }

        var attributes = try allocator.alloc(Attribute, attribute_count);
        errdefer allocator.free(attributes);

        var buffer_attributes = try allocator.alloc([]Attribute, desc.vertex.buffer_count);
        errdefer allocator.free(buffer_attributes);

        attribute_count = 0;
        for (0..desc.vertex.buffer_count) |i| {
            const buffer = desc.vertex.buffers.?[i];

            const attributes_begin = attribute_count;
            for (0..buffer.attribute_count) |j| {
                const attr = buffer.attributes.?[j];

                const format_type = utils.vertexFormatType(attr.format);
                attributes[attribute_count] = .{
                    .is_int = conv.glAttributeIsInt(format_type),
                    .index = attr.shader_location,
                    .count = conv.glAttributeCount(attr.format),
                    .vertex_type = conv.glAttributeType(attr.format),
                    .normalized = conv.glAttributeIsNormalized(format_type),
                    .stride = @intCast(buffer.array_stride),
                    .offset = @intCast(attr.offset),
                };

                gl.enableVertexAttribArray(attr.shader_location);
                if (buffer.step_mode == .instance)
                    gl.vertexAttribDivisor(attr.shader_location, 1);

                attribute_count += 1;
            }

            buffer_attributes[i] = attributes[attributes_begin..attribute_count];
        }

        // Primitive State
        const mode = conv.glPrimitiveMode(desc.primitive.topology);
        const front_face = conv.glFrontFace(desc.primitive.front_face);
        const cull_enabled = conv.glCullEnabled(desc.primitive.cull_mode);
        const cull_face = conv.glCullFace(desc.primitive.cull_mode);

        // Depth Stencil State
        var depth_test_enabled = false;
        var depth_mask: c.GLboolean = c.GL_FALSE;
        var depth_func: c.GLenum = c.GL_LESS;
        var stencil_test_enabled = false;
        var stencil_read_mask: c.GLuint = 0xff;
        var stencil_write_mask: c.GLuint = 0xff;
        var stencil_back_compare_func: c.GLenum = c.GL_ALWAYS;
        var stencil_back_fail_op: c.GLenum = c.GL_KEEP;
        var stencil_back_depth_fail_op: c.GLenum = c.GL_KEEP;
        var stencil_back_pass_op: c.GLenum = c.GL_KEEP;
        var stencil_front_compare_func: c.GLenum = c.GL_ALWAYS;
        var stencil_front_fail_op: c.GLenum = c.GL_KEEP;
        var stencil_front_depth_fail_op: c.GLenum = c.GL_KEEP;
        var stencil_front_pass_op: c.GLenum = c.GL_KEEP;
        var polygon_offset_enabled = false;
        var depth_bias: f32 = 0.0;
        var depth_bias_slope_scale: f32 = 0.0;
        var depth_bias_clamp: f32 = 0.0;
        if (desc.depth_stencil) |ds| {
            depth_test_enabled = conv.glDepthTestEnabled(ds);
            depth_mask = conv.glDepthMask(ds);
            depth_func = conv.glCompareFunc(ds.depth_compare);
            stencil_test_enabled = conv.glStencilTestEnabled(ds);
            stencil_read_mask = @intCast(ds.stencil_read_mask & 0xff);
            stencil_write_mask = @intCast(ds.stencil_write_mask & 0xff);
            stencil_back_compare_func = conv.glCompareFunc(ds.stencil_back.compare);
            stencil_back_fail_op = conv.glStencilOp(ds.stencil_back.fail_op);
            stencil_back_depth_fail_op = conv.glStencilOp(ds.stencil_back.depth_fail_op);
            stencil_back_pass_op = conv.glStencilOp(ds.stencil_back.pass_op);
            stencil_front_compare_func = conv.glCompareFunc(ds.stencil_front.compare);
            stencil_front_fail_op = conv.glStencilOp(ds.stencil_front.fail_op);
            stencil_front_depth_fail_op = conv.glStencilOp(ds.stencil_front.depth_fail_op);
            stencil_front_pass_op = conv.glStencilOp(ds.stencil_front.pass_op);
            polygon_offset_enabled = ds.depth_bias != 0;
            depth_bias = @floatFromInt(ds.depth_bias);
            depth_bias_slope_scale = ds.depth_bias_slope_scale;
            depth_bias_clamp = ds.depth_bias_clamp;
        }

        // Multisample
        const multisample_enabled = desc.multisample.count != 1;
        const sample_mask_enabled = desc.multisample.mask != 0xFFFFFFFF;
        const sample_mask_value = desc.multisample.mask;
        const alpha_to_coverage_enabled = desc.multisample.alpha_to_coverage_enabled == .true;

        // Fragment
        const target_count = if (desc.fragment) |fragment| fragment.target_count else 0;
        var color_targets = try allocator.alloc(ColorTarget, target_count);
        errdefer allocator.free(color_targets);

        if (desc.fragment) |fragment| {
            for (0..fragment.target_count) |i| {
                const target = fragment.targets.?[i];

                var blend_enabled = false;
                var color_op: c.GLenum = c.GL_FUNC_ADD;
                var alpha_op: c.GLenum = c.GL_FUNC_ADD;
                var src_color_blend: c.GLenum = c.GL_ONE;
                var dst_color_blend: c.GLenum = c.GL_ZERO;
                var src_alpha_blend: c.GLenum = c.GL_ONE;
                var dst_alpha_blend: c.GLenum = c.GL_ZERO;
                const write_red: c.GLboolean = if (target.write_mask.red) c.GL_TRUE else c.GL_FALSE;
                const write_green: c.GLboolean = if (target.write_mask.green) c.GL_TRUE else c.GL_FALSE;
                const write_blue: c.GLboolean = if (target.write_mask.blue) c.GL_TRUE else c.GL_FALSE;
                const write_alpha: c.GLboolean = if (target.write_mask.alpha) c.GL_TRUE else c.GL_FALSE;
                if (target.blend) |blend| {
                    blend_enabled = true;
                    color_op = conv.glBlendOp(blend.color.operation);
                    alpha_op = conv.glBlendOp(blend.alpha.operation);
                    src_color_blend = conv.glBlendFactor(blend.color.src_factor, true);
                    dst_color_blend = conv.glBlendFactor(blend.color.dst_factor, true);
                    src_alpha_blend = conv.glBlendFactor(blend.alpha.src_factor, false);
                    dst_alpha_blend = conv.glBlendFactor(blend.alpha.dst_factor, false);
                }

                color_targets[i] = .{
                    .blend_enabled = blend_enabled,
                    .color_op = color_op,
                    .alpha_op = alpha_op,
                    .src_color_blend = src_color_blend,
                    .dst_color_blend = dst_color_blend,
                    .src_alpha_blend = src_alpha_blend,
                    .dst_alpha_blend = dst_alpha_blend,
                    .write_red = write_red,
                    .write_green = write_green,
                    .write_blue = write_blue,
                    .write_alpha = write_alpha,
                };
            }
        }

        // Object
        var pipeline = try allocator.create(RenderPipeline);
        pipeline.* = .{
            .device = device,
            .layout = layout,
            .program = 0,
            .vao = vao,
            .attributes = attributes,
            .buffer_attributes = buffer_attributes,
            .mode = mode,
            .front_face = front_face,
            .cull_enabled = cull_enabled,
            .cull_face = cull_face,
            .depth_test_enabled = depth_test_enabled,
            .depth_mask = depth_mask,
            .depth_func = depth_func,
            .stencil_test_enabled = stencil_test_enabled,
            .stencil_read_mask = stencil_read_mask,
            .stencil_write_mask = stencil_write_mask,
            .stencil_back_compare_func = stencil_back_compare_func,
            .stencil_back_fail_op = stencil_back_fail_op,
            .stencil_back_depth_fail_op = stencil_back_depth_fail_op,
            .stencil_back_pass_op = stencil_back_pass_op,
            .stencil_front_compare_func = stencil_front_compare_func,
            .stencil_front_fail_op = stencil_front_fail_op,
            .stencil_front_depth_fail_op = stencil_front_depth_fail_op,
            .stencil_front_pass_op = stencil_front_pass_op,
            .polygon_offset_enabled = polygon_offset_enabled,
            .depth_bias = depth_bias,
            .depth_bias_slope_scale = depth_bias_slope_scale,
            .depth_bias_clamp = depth_bias_clamp,
            .multisample_enabled = multisample_enabled,
            .sample_mask_enabled = sample_mask_enabled,
            .sample_mask_value = sample_mask_value,
            .alpha_to_coverage_enabled = alpha_to_coverage_enabled,
            .color_targets = color_targets,
        };

        // Apply state to avoid program recompilation
        pipeline.applyState(0);

        // Program
        const program = gl.createProgram();
        errdefer gl.deleteProgram(program);

        gl.attachShader(program, vertex_shader);
        if (opt_fragment_shader) |fragment_shader|
            gl.attachShader(program, fragment_shader);
        gl.linkProgram(program);

        var success: c.GLint = undefined;
        gl.getProgramiv(program, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) {
            var info_log: [512]c.GLchar = undefined;
            gl.getProgramInfoLog(program, @sizeOf(@TypeOf(info_log)), null, &info_log);
            std.debug.print("Link Failed {s}\n", .{@as([*:0]u8, @ptrCast(&info_log))});
            return error.LinkFailed;
        }

        pipeline.program = program;

        return pipeline;
    }

    pub fn deinit(pipeline: *RenderPipeline) void {
        const device = pipeline.device;
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        gl.deleteVertexArrays(1, &pipeline.vao);
        gl.deleteProgram(pipeline.program);

        pipeline.layout.manager.release();
        allocator.free(pipeline.color_targets);
        allocator.free(pipeline.attributes);
        allocator.free(pipeline.buffer_attributes);
        allocator.destroy(pipeline);
    }

    // Internal
    pub fn getBindGroupLayout(pipeline: *RenderPipeline, group_index: u32) *BindGroupLayout {
        return @ptrCast(pipeline.layout.group_layouts[group_index]);
    }

    pub fn applyState(pipeline: *RenderPipeline, stencil_ref: c.GLint) void {
        const device = pipeline.device;
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        gl.bindVertexArray(pipeline.vao);
        gl.frontFace(pipeline.front_face);
        if (pipeline.cull_enabled) {
            gl.enable(c.GL_CULL_FACE);
            gl.cullFace(pipeline.cull_face);
        } else {
            gl.disable(c.GL_CULL_FACE);
        }
        if (pipeline.depth_test_enabled) {
            gl.enable(c.GL_DEPTH_TEST);
            gl.depthMask(pipeline.depth_mask);
            gl.depthFunc(pipeline.depth_func);
        } else {
            gl.disable(c.GL_DEPTH_TEST);
        }
        if (pipeline.stencil_test_enabled) {
            gl.enable(c.GL_STENCIL_TEST);
            gl.stencilFuncSeparate(
                c.GL_BACK,
                pipeline.stencil_back_compare_func,
                stencil_ref,
                pipeline.stencil_read_mask,
            );
            gl.stencilFuncSeparate(
                c.GL_FRONT,
                pipeline.stencil_front_compare_func,
                stencil_ref,
                pipeline.stencil_read_mask,
            );
            gl.stencilOpSeparate(
                c.GL_BACK,
                pipeline.stencil_back_fail_op,
                pipeline.stencil_back_depth_fail_op,
                pipeline.stencil_back_pass_op,
            );
            gl.stencilOpSeparate(
                c.GL_FRONT,
                pipeline.stencil_front_fail_op,
                pipeline.stencil_front_depth_fail_op,
                pipeline.stencil_front_pass_op,
            );
            gl.stencilMask(pipeline.stencil_write_mask);
        } else {
            gl.disable(c.GL_STENCIL_TEST);
        }
        if (pipeline.polygon_offset_enabled) {
            gl.enable(c.GL_POLYGON_OFFSET_FILL);
            gl.polygonOffsetClamp(
                pipeline.depth_bias_slope_scale,
                pipeline.depth_bias,
                pipeline.depth_bias_clamp,
            );
        } else {
            gl.disable(c.GL_POLYGON_OFFSET_FILL);
        }
        if (pipeline.multisample_enabled) {
            gl.enable(c.GL_MULTISAMPLE);
            if (pipeline.sample_mask_enabled) {
                gl.enable(c.GL_SAMPLE_MASK);
                gl.sampleMaski(0, pipeline.sample_mask_value);
            } else {
                gl.disable(c.GL_SAMPLE_MASK);
            }
            if (pipeline.alpha_to_coverage_enabled) {
                gl.enable(c.GL_SAMPLE_ALPHA_TO_COVERAGE);
            } else {
                gl.disable(c.GL_SAMPLE_ALPHA_TO_COVERAGE);
            }
        } else {
            gl.disable(c.GL_MULTISAMPLE);
        }
        for (pipeline.color_targets, 0..) |target, i| {
            const buf: c.GLuint = @intCast(i);
            if (target.blend_enabled) {
                gl.enablei(c.GL_BLEND, buf);
                gl.blendEquationSeparatei(buf, target.color_op, target.alpha_op);
                gl.blendFuncSeparatei(
                    buf,
                    target.src_color_blend,
                    target.dst_color_blend,
                    target.src_alpha_blend,
                    target.dst_alpha_blend,
                );
            } else {
                gl.disablei(c.GL_BLEND, buf);
            }
            gl.colorMaski(buf, target.write_red, target.write_green, target.write_blue, target.write_alpha);
        }
    }
};

const Command = union(enum) {
    begin_render_pass: struct {
        color_attachments: std.BoundedArray(sysgpu.RenderPassColorAttachment, limits.max_color_attachments),
        depth_stencil_attachment: ?sysgpu.RenderPassDepthStencilAttachment,
    },
    end_render_pass,
    copy_buffer_to_buffer: struct {
        source: *Buffer,
        source_offset: u64,
        destination: *Buffer,
        destination_offset: u64,
        size: u64,
    },
    dispatch_workgroups: struct {
        workgroup_count_x: u32,
        workgroup_count_y: u32,
        workgroup_count_z: u32,
    },
    draw: struct {
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    },
    draw_indexed: struct {
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    },
    set_compute_bind_group: struct {
        group_index: u32,
        group: *BindGroup,
        dynamic_offsets: std.BoundedArray(u32, limits.max_bind_groups),
    },
    set_compute_pipeline: struct {
        pipeline: *ComputePipeline,
    },
    set_render_bind_group: struct {
        group_index: u32,
        group: *BindGroup,
        dynamic_offsets: std.BoundedArray(u32, limits.max_bind_groups),
    },
    set_index_buffer: struct {
        buffer: *Buffer,
        format: sysgpu.IndexFormat,
        offset: u64,
    },
    set_render_pipeline: struct {
        pipeline: *RenderPipeline,
    },
    set_scissor_rect: struct {
        x: c.GLint,
        y: c.GLint,
        width: c.GLsizei,
        height: c.GLsizei,
    },
    set_vertex_buffer: struct {
        slot: u32,
        buffer: *Buffer,
        offset: u64,
    },
    set_viewport: struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        min_depth: f32,
        max_depth: f32,
    },
};

pub const CommandBuffer = struct {
    const VertexBuffersState = struct {
        apply_count: u32 = 0,
        buffers: [limits.max_vertex_buffers]?*Buffer = std.mem.zeroes([limits.max_vertex_buffers]?*Buffer),
        buffer_offsets: [limits.max_vertex_buffers]u64 = std.mem.zeroes([limits.max_vertex_buffers]u64),
    };

    manager: utils.Manager(CommandBuffer) = .{},
    device: *Device,
    commands: std.ArrayListUnmanaged(Command) = .{},
    reference_tracker: *ReferenceTracker,

    pub fn init(device: *Device) !*CommandBuffer {
        const reference_tracker = try ReferenceTracker.init(device);
        errdefer reference_tracker.deinit();

        const command_buffer = try allocator.create(CommandBuffer);
        command_buffer.* = .{
            .device = device,
            .reference_tracker = reference_tracker,
        };
        return command_buffer;
    }

    pub fn deinit(command_buffer: *CommandBuffer) void {
        // reference_tracker lifetime is managed externally
        command_buffer.commands.deinit(allocator);
        allocator.destroy(command_buffer);
    }

    // Internal
    pub fn execute(command_buffer: *CommandBuffer) !void {
        const device = command_buffer.device;
        const gl = &device.gl;
        var ctx = ActiveContext.init(device.hdc, device.hglrc);
        defer ctx.deinit();

        var compute_pipeline: ?*ComputePipeline = null;
        var render_pass_fbo: ?c.GLuint = null;
        var render_pipeline: ?*RenderPipeline = null;
        const stencil_ref: c.GLint = 0;
        var index_type: c.GLenum = undefined;
        var index_element_size: usize = undefined;
        var index_buffer: ?*Buffer = null;
        var index_buffer_offset: usize = undefined;
        var vertex_state: VertexBuffersState = .{};

        try command_buffer.reference_tracker.submit();
        try device.reference_trackers.append(allocator, command_buffer.reference_tracker);

        for (command_buffer.commands.items) |command| {
            switch (command) {
                .begin_render_pass => |cmd| {
                    // Test if rendering to default framebuffer
                    var default_framebuffer = false;
                    if (cmd.color_attachments.len == 1) {
                        const attach = cmd.color_attachments.buffer[0];
                        if (attach.view) |view_raw| {
                            const view: *TextureView = @ptrCast(@alignCast(view_raw));
                            if (view.texture.swapchain) |swapchain| {
                                default_framebuffer = true;
                                if (swapchain.hdc != device.hdc) {
                                    if (c.wglMakeCurrent(swapchain.hdc, device.hglrc) == c.FALSE)
                                        return error.WGLMakeCurrentFailed;
                                }
                            }
                        }
                    }

                    // Framebuffer
                    var width: u32 = 0;
                    var height: u32 = 0;
                    if (!default_framebuffer) {
                        var fbo: c.GLuint = undefined;
                        gl.genFramebuffers(1, &fbo);
                        render_pass_fbo = fbo;

                        gl.bindFramebuffer(c.GL_DRAW_FRAMEBUFFER, fbo);

                        var draw_buffers: std.BoundedArray(c.GLenum, limits.max_color_attachments) = .{};

                        for (cmd.color_attachments.buffer, 0..) |attach, i| {
                            if (attach.view) |view_raw| {
                                const view: *TextureView = @ptrCast(@alignCast(view_raw));
                                width = view.width();
                                height = view.height();

                                draw_buffers.appendAssumeCapacity(@intCast(c.GL_COLOR_ATTACHMENT0 + i));
                                gl.framebufferTexture2D(
                                    c.GL_FRAMEBUFFER,
                                    c.GL_COLOR_ATTACHMENT0,
                                    c.GL_TEXTURE_2D,
                                    view.texture.handle,
                                    0,
                                );
                            } else {
                                draw_buffers.appendAssumeCapacity(c.GL_NONE);
                            }
                        }
                        if (cmd.depth_stencil_attachment) |attach| {
                            const view: *TextureView = @ptrCast(@alignCast(attach.view));
                            width = view.width();
                            height = view.height();

                            const attachment: c.GLuint = switch (utils.textureFormatType(view.texture.format)) {
                                .depth => c.GL_DEPTH_ATTACHMENT,
                                .stencil => c.GL_STENCIL_ATTACHMENT,
                                .depth_stencil => c.GL_DEPTH_STENCIL_ATTACHMENT,
                                else => unreachable,
                            };

                            gl.framebufferTexture2D(
                                c.GL_FRAMEBUFFER,
                                attachment,
                                c.GL_TEXTURE_2D,
                                view.texture.handle,
                                0,
                            );
                        }

                        gl.drawBuffers(draw_buffers.len, &draw_buffers.buffer);
                        if (gl.checkFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE)
                            return error.CheckFramebufferStatusFailed;
                    } else {
                        // TODO - always render to framebuffer?
                        gl.bindFramebuffer(c.GL_DRAW_FRAMEBUFFER, 0);
                        const view: *TextureView = @ptrCast(@alignCast(cmd.color_attachments.buffer[0].view.?));

                        width = view.width();
                        height = view.height();
                    }

                    // Default State
                    gl.viewport(0, 0, @intCast(width), @intCast(height));
                    gl.depthRangef(0.0, 1.0);
                    gl.scissor(0, 0, @intCast(width), @intCast(height));
                    gl.blendColor(0, 0, 0, 0);
                    gl.colorMask(c.GL_TRUE, c.GL_TRUE, c.GL_TRUE, c.GL_TRUE);
                    gl.depthMask(c.GL_TRUE);
                    gl.stencilMask(0xff);

                    // Clear color targets
                    for (cmd.color_attachments.buffer, 0..) |attach, i| {
                        if (attach.view) |view_raw| {
                            const view: *TextureView = @ptrCast(@alignCast(view_raw));

                            if (attach.load_op == .clear) {
                                switch (utils.textureFormatType(view.texture.format)) {
                                    .float,
                                    .unorm,
                                    .unorm_srgb,
                                    .snorm,
                                    => {
                                        const data = [4]f32{
                                            @floatCast(attach.clear_value.r),
                                            @floatCast(attach.clear_value.g),
                                            @floatCast(attach.clear_value.b),
                                            @floatCast(attach.clear_value.a),
                                        };
                                        gl.clearBufferfv(c.GL_COLOR, @intCast(i), &data);
                                    },
                                    .uint => {
                                        const data = [4]u32{
                                            @intFromFloat(attach.clear_value.r),
                                            @intFromFloat(attach.clear_value.g),
                                            @intFromFloat(attach.clear_value.b),
                                            @intFromFloat(attach.clear_value.a),
                                        };
                                        gl.clearBufferuiv(c.GL_COLOR, @intCast(i), &data);
                                    },
                                    .sint => {
                                        const data = [4]i32{
                                            @intFromFloat(attach.clear_value.r),
                                            @intFromFloat(attach.clear_value.g),
                                            @intFromFloat(attach.clear_value.b),
                                            @intFromFloat(attach.clear_value.a),
                                        };
                                        gl.clearBufferiv(c.GL_COLOR, @intCast(i), &data);
                                    },
                                    else => unreachable,
                                }
                            }
                        }
                    }

                    // Clear depth target
                    if (cmd.depth_stencil_attachment) |attach| {
                        const view: *TextureView = @ptrCast(@alignCast(attach.view));
                        const format_type = utils.textureFormatType(view.texture.format);
                        const depth_clear =
                            attach.depth_load_op == .clear and
                            (format_type == .depth or format_type == .depth_stencil);
                        const stencil_clear =
                            attach.stencil_load_op == .clear and
                            (format_type == .stencil or format_type == .depth_stencil);

                        if (depth_clear and stencil_clear) {
                            gl.clearBufferfi(
                                c.GL_DEPTH_STENCIL,
                                0,
                                attach.depth_clear_value,
                                @intCast(attach.stencil_clear_value),
                            );
                        } else if (depth_clear) {
                            gl.clearBufferfv(c.GL_DEPTH, 0, &attach.depth_clear_value);
                        } else if (stencil_clear) {
                            gl.clearBufferiv(c.GL_STENCIL, 0, attach.stencil_clear_value);
                        }
                    }

                    // Release references
                    for (cmd.color_attachments.buffer) |attach| {
                        if (attach.view) |view_raw| {
                            const view: *TextureView = @ptrCast(@alignCast(view_raw));
                            view.manager.release();
                        }
                    }
                    if (cmd.depth_stencil_attachment) |attach| {
                        const view: *TextureView = @ptrCast(@alignCast(attach.view));
                        view.manager.release();
                    }
                },
                .end_render_pass => {
                    // TODO - invalidate on discard
                    if (render_pass_fbo) |fbo| gl.deleteFramebuffers(1, &fbo);
                    render_pass_fbo = null;
                },
                .copy_buffer_to_buffer => |cmd| {
                    gl.bindBuffer(c.GL_COPY_READ_BUFFER, cmd.source.handle);
                    gl.bindBuffer(c.GL_COPY_WRITE_BUFFER, cmd.destination.handle);

                    gl.copyBufferSubData(
                        c.GL_COPY_READ_BUFFER,
                        c.GL_COPY_WRITE_BUFFER,
                        @intCast(cmd.source_offset),
                        @intCast(cmd.destination_offset),
                        @intCast(cmd.size),
                    );
                },
                .dispatch_workgroups => |cmd| {
                    gl.dispatchCompute(cmd.workgroup_count_x, cmd.workgroup_count_y, cmd.workgroup_count_z);
                },
                .draw => |cmd| {
                    if (vertex_state.apply_count > 0)
                        applyVertexBuffers(gl, &vertex_state, render_pipeline.?);

                    gl.drawArraysInstancedBaseInstance(
                        render_pipeline.?.mode,
                        @intCast(cmd.first_vertex),
                        @intCast(cmd.vertex_count),
                        @intCast(cmd.instance_count),
                        cmd.first_instance,
                    );
                },
                .draw_indexed => |cmd| {
                    if (vertex_state.apply_count > 0)
                        applyVertexBuffers(gl, &vertex_state, render_pipeline.?);

                    gl.drawElementsInstancedBaseVertexBaseInstance(
                        render_pipeline.?.mode,
                        @intCast(cmd.index_count),
                        index_type,
                        @ptrFromInt(index_buffer_offset + cmd.first_index * index_element_size),
                        @intCast(cmd.instance_count),
                        cmd.base_vertex,
                        cmd.first_instance,
                    );
                },
                .set_index_buffer => |cmd| {
                    const buffer = cmd.buffer;
                    gl.bindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, buffer.handle);
                    index_type = conv.glIndexType(cmd.format);
                    index_element_size = conv.glIndexElementSize(cmd.format);
                    index_buffer_offset = cmd.offset;

                    if (index_buffer) |old_index_buffer| old_index_buffer.manager.release();
                    index_buffer = buffer;
                },
                .set_compute_pipeline => |cmd| {
                    const pipeline = cmd.pipeline;
                    gl.useProgram(pipeline.program);

                    if (compute_pipeline) |old_pipeline| old_pipeline.manager.release();
                    compute_pipeline = pipeline;
                },
                .set_compute_bind_group => |cmd| {
                    // NOTE - this does not work yet for applications that expect bind groups to stay valid after
                    // pipeline changes.  For that we will need to defer GLSL compilation until layout is known.
                    const group = cmd.group;

                    for (group.entries) |entry| {
                        const key = BindingPoint{ .group = cmd.group_index, .binding = entry.binding };

                        if (compute_pipeline.?.layout.bindings.get(key)) |slot| {
                            switch (entry.kind) {
                                .buffer => {
                                    var offset = entry.offset;
                                    if (entry.dynamic_index) |i|
                                        offset += cmd.dynamic_offsets.buffer[i];
                                    gl.bindBufferRange(entry.target, slot, entry.buffer.?.handle, offset, entry.size);
                                },
                                else => @panic("unimplemented"),
                            }
                        }
                    }

                    group.manager.release();
                },
                .set_render_bind_group => |cmd| {
                    // NOTE - this does not work yet for applications that expect bind groups to stay valid after
                    // pipeline changes.  For that we will need to defer GLSL compilation until layout is known.
                    const group = cmd.group;

                    for (group.entries) |entry| {
                        const key = BindingPoint{ .group = cmd.group_index, .binding = entry.binding };

                        if (render_pipeline.?.layout.bindings.get(key)) |slot| {
                            switch (entry.kind) {
                                .buffer => {
                                    var offset = entry.offset;
                                    if (entry.dynamic_index) |i|
                                        offset += cmd.dynamic_offsets.buffer[i];
                                    gl.bindBufferRange(entry.target, slot, entry.buffer.?.handle, offset, entry.size);
                                },
                                else => @panic("unimplemented"),
                            }
                        }
                    }
                    group.manager.release();
                },
                .set_render_pipeline => |cmd| {
                    var pipeline = cmd.pipeline;

                    pipeline.applyState(stencil_ref);
                    gl.useProgram(pipeline.program);

                    if (render_pipeline) |old_pipeline| old_pipeline.manager.release();
                    render_pipeline = pipeline;
                },
                .set_scissor_rect => |cmd| {
                    gl.scissor(cmd.x, cmd.y, cmd.width, cmd.height);
                },
                .set_vertex_buffer => |cmd| {
                    const buffer = cmd.buffer;
                    vertex_state.buffers[cmd.slot] = buffer;
                    vertex_state.buffer_offsets[cmd.slot] = cmd.offset;
                    vertex_state.apply_count = @max(vertex_state.apply_count, cmd.slot + 1);
                },
                .set_viewport => |cmd| {
                    gl.viewportIndexedf(0, cmd.x, cmd.y, cmd.width, cmd.height);
                    gl.depthRangef(cmd.min_depth, cmd.max_depth);
                },
            }
        }

        command_buffer.reference_tracker.sync = gl.fenceSync(c.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

        std.debug.assert(render_pass_fbo == null);
        if (compute_pipeline) |pipeline| pipeline.manager.release();
        if (render_pipeline) |pipeline| pipeline.manager.release();
        if (index_buffer) |buffer| buffer.manager.release();
        checkError(gl);
    }

    fn applyVertexBuffers(gl: *proc.DeviceGL, vertex_state: *VertexBuffersState, render_pipeline: *RenderPipeline) void {
        for (0..vertex_state.apply_count) |buffer_index| {
            if (vertex_state.buffers[buffer_index]) |buffer| {
                gl.bindBuffer(c.GL_ARRAY_BUFFER, buffer.handle);

                const offset = vertex_state.buffer_offsets[buffer_index];
                for (render_pipeline.buffer_attributes[buffer_index]) |attribute| {
                    if (attribute.is_int) {
                        gl.vertexAttribIPointer(
                            attribute.index,
                            attribute.count,
                            attribute.vertex_type,
                            attribute.stride,
                            @ptrFromInt(attribute.offset + offset),
                        );
                    } else {
                        gl.vertexAttribPointer(
                            attribute.index,
                            attribute.count,
                            attribute.vertex_type,
                            attribute.normalized,
                            attribute.stride,
                            @ptrFromInt(attribute.offset + offset),
                        );
                    }
                }
                buffer.manager.release();
                vertex_state.buffers[buffer_index] = null;
            }
        }

        vertex_state.apply_count = 0;
    }
};

pub const ReferenceTracker = struct {
    device: *Device,
    sync: c.GLsync = undefined,
    buffers: std.ArrayListUnmanaged(*Buffer) = .{},
    bind_groups: std.ArrayListUnmanaged(*BindGroup) = .{},
    upload_pages: std.ArrayListUnmanaged(*Buffer) = .{},

    pub fn init(device: *Device) !*ReferenceTracker {
        const tracker = try allocator.create(ReferenceTracker);
        tracker.* = .{
            .device = device,
        };
        return tracker;
    }

    pub fn deinit(tracker: *ReferenceTracker) void {
        const device = tracker.device;

        for (tracker.buffers.items) |buffer| {
            buffer.gpu_count -= 1;
            buffer.manager.release();
        }

        for (tracker.bind_groups.items) |group| {
            for (group.entries) |entry| {
                switch (entry.kind) {
                    .buffer => entry.buffer.?.gpu_count -= 1,
                    else => {},
                }
            }
            group.manager.release();
        }

        for (tracker.upload_pages.items) |buffer| {
            device.streaming_manager.release(buffer);
        }

        tracker.buffers.deinit(allocator);
        tracker.bind_groups.deinit(allocator);
        tracker.upload_pages.deinit(allocator);
        allocator.destroy(tracker);
    }

    pub fn referenceBuffer(tracker: *ReferenceTracker, buffer: *Buffer) !void {
        buffer.manager.reference();
        try tracker.buffers.append(allocator, buffer);
    }

    pub fn referenceBindGroup(tracker: *ReferenceTracker, group: *BindGroup) !void {
        group.manager.reference();
        try tracker.bind_groups.append(allocator, group);
    }

    pub fn referenceUploadPage(tracker: *ReferenceTracker, upload_page: *Buffer) !void {
        try tracker.upload_pages.append(allocator, upload_page);
    }

    pub fn submit(tracker: *ReferenceTracker) !void {
        for (tracker.buffers.items) |buffer| {
            buffer.gpu_count += 1;
        }

        for (tracker.bind_groups.items) |group| {
            for (group.entries) |entry| {
                switch (entry.kind) {
                    .buffer => entry.buffer.?.gpu_count += 1,
                    else => {},
                }
            }
        }
    }
};

pub const CommandEncoder = struct {
    pub const StreamingResult = struct {
        buffer: *Buffer,
        map: [*]u8,
        offset: u32,
    };

    manager: utils.Manager(CommandEncoder) = .{},
    device: *Device,
    command_buffer: *CommandBuffer,
    commands: *std.ArrayListUnmanaged(Command),
    reference_tracker: *ReferenceTracker,
    upload_buffer: ?*Buffer = null,
    upload_map: ?[*]u8 = null,
    upload_next_offset: u32 = upload_page_size,

    pub fn init(device: *Device, desc: ?*const sysgpu.CommandEncoder.Descriptor) !*CommandEncoder {
        _ = desc;

        const command_buffer = try CommandBuffer.init(device);

        const encoder = try allocator.create(CommandEncoder);
        encoder.* = .{
            .device = device,
            .command_buffer = command_buffer,
            .commands = &command_buffer.commands,
            .reference_tracker = command_buffer.reference_tracker,
        };
        return encoder;
    }

    pub fn deinit(encoder: *CommandEncoder) void {
        encoder.command_buffer.manager.release();
        allocator.destroy(encoder);
    }

    pub fn beginComputePass(encoder: *CommandEncoder, desc: *const sysgpu.ComputePassDescriptor) !*ComputePassEncoder {
        return ComputePassEncoder.init(encoder, desc);
    }

    pub fn beginRenderPass(encoder: *CommandEncoder, desc: *const sysgpu.RenderPassDescriptor) !*RenderPassEncoder {
        return RenderPassEncoder.init(encoder, desc);
    }

    pub fn copyBufferToBuffer(
        encoder: *CommandEncoder,
        source: *Buffer,
        source_offset: u64,
        destination: *Buffer,
        destination_offset: u64,
        size: u64,
    ) !void {
        try encoder.reference_tracker.referenceBuffer(source);
        try encoder.reference_tracker.referenceBuffer(destination);

        try encoder.commands.append(allocator, .{ .copy_buffer_to_buffer = .{
            .source = source,
            .source_offset = source_offset,
            .destination = destination,
            .destination_offset = destination_offset,
            .size = size,
        } });
    }

    pub fn copyBufferToTexture(
        encoder: *CommandEncoder,
        source: *const sysgpu.ImageCopyBuffer,
        destination: *const sysgpu.ImageCopyTexture,
        copy_size: *const sysgpu.Extent3D,
    ) !void {
        _ = copy_size;
        _ = destination;
        const source_buffer: *Buffer = @ptrCast(@alignCast(source.buffer));

        try encoder.reference_tracker.referenceBuffer(source_buffer);
    }

    pub fn copyTextureToTexture(
        encoder: *CommandEncoder,
        source: *const sysgpu.ImageCopyTexture,
        destination: *const sysgpu.ImageCopyTexture,
        copy_size: *const sysgpu.Extent3D,
    ) !void {
        _ = copy_size;
        _ = destination;
        _ = source;
        _ = encoder;
    }

    pub fn finish(encoder: *CommandEncoder, desc: *const sysgpu.CommandBuffer.Descriptor) !*CommandBuffer {
        _ = desc;
        const command_buffer = encoder.command_buffer;

        return command_buffer;
    }

    pub fn writeBuffer(encoder: *CommandEncoder, buffer: *Buffer, offset: u64, data: [*]const u8, size: u64) !void {
        const stream = try encoder.upload(size);
        @memcpy(stream.map[0..size], data[0..size]);

        try encoder.copyBufferToBuffer(stream.buffer, stream.offset, buffer, offset, size);
    }

    pub fn writeTexture(
        encoder: *CommandEncoder,
        destination: *const sysgpu.ImageCopyTexture,
        data: [*]const u8,
        data_size: usize,
        data_layout: *const sysgpu.Texture.DataLayout,
        write_size: *const sysgpu.Extent3D,
    ) !void {
        const stream = try encoder.upload(data_size);
        @memcpy(stream.map[0..data_size], data[0..data_size]);

        try encoder.copyBufferToTexture(
            &.{
                .layout = .{
                    .offset = stream.offset,
                    .bytes_per_row = data_layout.bytes_per_row,
                    .rows_per_image = data_layout.rows_per_image,
                },
                .buffer = @ptrCast(stream.buffer),
            },
            destination,
            write_size,
        );
    }

    pub fn upload(encoder: *CommandEncoder, size: u64) !StreamingResult {
        if (encoder.upload_next_offset + size > upload_page_size) {
            const streaming_manager = &encoder.device.streaming_manager;

            std.debug.assert(size <= upload_page_size); // TODO - support large uploads
            const buffer = try streaming_manager.acquire();

            try encoder.reference_tracker.referenceUploadPage(buffer);
            encoder.upload_buffer = buffer;
            encoder.upload_map = buffer.map;
            encoder.upload_next_offset = 0;
        }

        const offset = encoder.upload_next_offset;
        encoder.upload_next_offset = @intCast(utils.alignUp(offset + size, limits.min_uniform_buffer_offset_alignment));
        return StreamingResult{
            .buffer = encoder.upload_buffer.?,
            .map = encoder.upload_map.? + offset,
            .offset = offset,
        };
    }
};

pub const ComputePassEncoder = struct {
    manager: utils.Manager(ComputePassEncoder) = .{},
    commands: *std.ArrayListUnmanaged(Command),
    reference_tracker: *ReferenceTracker,

    pub fn init(cmd_encoder: *CommandEncoder, desc: *const sysgpu.ComputePassDescriptor) !*ComputePassEncoder {
        _ = desc;

        const encoder = try allocator.create(ComputePassEncoder);
        encoder.* = .{
            .commands = &cmd_encoder.command_buffer.commands,
            .reference_tracker = cmd_encoder.reference_tracker,
        };
        return encoder;
    }

    pub fn deinit(encoder: *ComputePassEncoder) void {
        allocator.destroy(encoder);
    }

    pub fn dispatchWorkgroups(
        encoder: *ComputePassEncoder,
        workgroup_count_x: u32,
        workgroup_count_y: u32,
        workgroup_count_z: u32,
    ) !void {
        try encoder.commands.append(allocator, .{ .dispatch_workgroups = .{
            .workgroup_count_x = workgroup_count_x,
            .workgroup_count_y = workgroup_count_y,
            .workgroup_count_z = workgroup_count_z,
        } });
    }

    pub fn end(encoder: *ComputePassEncoder) void {
        _ = encoder;
    }

    pub fn setBindGroup(
        encoder: *ComputePassEncoder,
        group_index: u32,
        group: *BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) !void {
        group.manager.reference();
        var dynamic_offsets_array: std.BoundedArray(u32, limits.max_bind_groups) = .{};
        if (dynamic_offset_count > 0)
            dynamic_offsets_array.appendSliceAssumeCapacity(dynamic_offsets.?[0..dynamic_offset_count]);

        try encoder.commands.append(allocator, .{ .set_compute_bind_group = .{
            .group_index = group_index,
            .group = group,
            .dynamic_offsets = dynamic_offsets_array,
        } });
    }

    pub fn setPipeline(encoder: *ComputePassEncoder, pipeline: *ComputePipeline) !void {
        pipeline.manager.reference();
        try encoder.commands.append(allocator, .{ .set_compute_pipeline = .{
            .pipeline = pipeline,
        } });
    }
};

pub const RenderPassEncoder = struct {
    manager: utils.Manager(RenderPassEncoder) = .{},
    commands: *std.ArrayListUnmanaged(Command),
    reference_tracker: *ReferenceTracker,

    pub fn init(cmd_encoder: *CommandEncoder, desc: *const sysgpu.RenderPassDescriptor) !*RenderPassEncoder {
        var encoder = try allocator.create(RenderPassEncoder);
        encoder.* = .{
            .commands = &cmd_encoder.command_buffer.commands,
            .reference_tracker = cmd_encoder.reference_tracker,
        };

        var color_attachments: std.BoundedArray(sysgpu.RenderPassColorAttachment, limits.max_color_attachments) = .{};
        for (0..desc.color_attachment_count) |i| {
            const attach = &desc.color_attachments.?[i];
            if (attach.view) |view_raw| {
                const view: *TextureView = @ptrCast(@alignCast(view_raw));
                view.manager.reference();
            }
            color_attachments.appendAssumeCapacity(attach.*);
        }

        if (desc.depth_stencil_attachment) |attach| {
            const view: *TextureView = @ptrCast(@alignCast(attach.view));
            view.manager.reference();
        }

        try encoder.commands.append(allocator, .{ .begin_render_pass = .{
            .color_attachments = color_attachments,
            .depth_stencil_attachment = if (desc.depth_stencil_attachment) |ds| ds.* else null,
        } });

        return encoder;
    }

    pub fn deinit(encoder: *RenderPassEncoder) void {
        allocator.destroy(encoder);
    }

    pub fn draw(
        encoder: *RenderPassEncoder,
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    ) !void {
        try encoder.commands.append(allocator, .{ .draw = .{
            .vertex_count = vertex_count,
            .instance_count = instance_count,
            .first_vertex = first_vertex,
            .first_instance = first_instance,
        } });
    }

    pub fn drawIndexed(
        encoder: *RenderPassEncoder,
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    ) !void {
        try encoder.commands.append(allocator, .{ .draw_indexed = .{
            .index_count = index_count,
            .instance_count = instance_count,
            .first_index = first_index,
            .base_vertex = base_vertex,
            .first_instance = first_instance,
        } });
    }

    pub fn end(encoder: *RenderPassEncoder) !void {
        try encoder.commands.append(allocator, .end_render_pass);
    }

    pub fn setBindGroup(
        encoder: *RenderPassEncoder,
        group_index: u32,
        group: *BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) !void {
        group.manager.reference();
        var dynamic_offsets_array: std.BoundedArray(u32, limits.max_bind_groups) = .{};
        if (dynamic_offset_count > 0)
            dynamic_offsets_array.appendSliceAssumeCapacity(dynamic_offsets.?[0..dynamic_offset_count]);

        try encoder.commands.append(allocator, .{ .set_render_bind_group = .{
            .group_index = group_index,
            .group = group,
            .dynamic_offsets = dynamic_offsets_array,
        } });
    }

    pub fn setIndexBuffer(
        encoder: *RenderPassEncoder,
        buffer: *Buffer,
        format: sysgpu.IndexFormat,
        offset: u64,
        size: u64,
    ) !void {
        _ = size;

        try encoder.reference_tracker.referenceBuffer(buffer);

        buffer.manager.reference();
        try encoder.commands.append(allocator, .{ .set_index_buffer = .{
            .buffer = buffer,
            .format = format,
            .offset = offset,
        } });
    }

    pub fn setPipeline(encoder: *RenderPassEncoder, pipeline: *RenderPipeline) !void {
        pipeline.manager.reference();
        try encoder.commands.append(allocator, .{ .set_render_pipeline = .{
            .pipeline = pipeline,
        } });
    }

    pub fn setScissorRect(encoder: *RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) !void {
        try encoder.commands.append(allocator, .{ .set_scissor_rect = .{
            .x = @intCast(x),
            .y = @intCast(y),
            .width = @intCast(width),
            .height = @intCast(height),
        } });
    }

    pub fn setVertexBuffer(encoder: *RenderPassEncoder, slot: u32, buffer: *Buffer, offset: u64, size: u64) !void {
        _ = size;

        try encoder.reference_tracker.referenceBuffer(buffer);

        buffer.manager.reference();
        try encoder.commands.append(allocator, .{ .set_vertex_buffer = .{
            .slot = slot,
            .buffer = buffer,
            .offset = offset,
        } });
    }

    pub fn setViewport(
        encoder: *RenderPassEncoder,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        min_depth: f32,
        max_depth: f32,
    ) !void {
        try encoder.commands.append(allocator, .{ .set_viewport = .{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .min_depth = min_depth,
            .max_depth = max_depth,
        } });
    }
};

pub const Queue = struct {
    manager: utils.Manager(Queue) = .{},
    device: *Device,
    command_encoder: ?*CommandEncoder = null,

    pub fn init(device: *Device) !Queue {
        return .{
            .device = device,
        };
    }

    pub fn deinit(queue: *Queue) void {
        if (queue.command_encoder) |command_encoder| command_encoder.manager.release();
    }

    pub fn submit(queue: *Queue, commands: []const *CommandBuffer) !void {
        if (queue.command_encoder) |command_encoder| {
            const command_buffer = try command_encoder.finish(&.{});
            command_buffer.manager.reference(); // handled in main.zig
            defer command_buffer.manager.release();

            try command_buffer.execute();

            command_encoder.manager.release();
            queue.command_encoder = null;
        }
        for (commands) |command_buffer| {
            try command_buffer.execute();
        }
    }

    pub fn writeBuffer(queue: *Queue, buffer: *Buffer, offset: u64, data: [*]const u8, size: u64) !void {
        const encoder = try queue.getCommandEncoder();
        try encoder.writeBuffer(buffer, offset, data, size);
    }

    pub fn writeTexture(
        queue: *Queue,
        destination: *const sysgpu.ImageCopyTexture,
        data: [*]const u8,
        data_size: usize,
        data_layout: *const sysgpu.Texture.DataLayout,
        write_size: *const sysgpu.Extent3D,
    ) !void {
        const encoder = try queue.getCommandEncoder();
        try encoder.writeTexture(destination, data, data_size, data_layout, write_size);
    }

    // Private
    fn getCommandEncoder(queue: *Queue) !*CommandEncoder {
        if (queue.command_encoder) |command_encoder| return command_encoder;

        const command_encoder = try CommandEncoder.init(queue.device, &.{});
        queue.command_encoder = command_encoder;
        return command_encoder;
    }
};

test "reference declarations" {
    std.testing.refAllDeclsRecursive(@This());
}
