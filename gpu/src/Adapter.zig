//! A GPUAdapter which identifies an implementation of WebGPU on the system.
//!
//! An adapter is both an instance of compute/rendering functionality on the platform, and an
//! instance of the WebGPU implementation on top of that functionality.
//!
//! Adapters do not uniquely represent underlying implementations: calling `requestAdapter()`
//! multiple times returns a different adapter object each time.
//!
//! An adapter object may become invalid at any time. This happens inside "lose the device" and
//! "mark adapters stale". An invalid adapter is unable to vend new devices.
//!
//! Note: This mechanism ensures that various adapter-creation scenarios look similar to
//! applications, so they can easily be robust to more scenarios with less testing: first
//! initialization, reinitialization due to an unplugged adapter, reinitialization due to a test
//! GPUDevice.destroy() call, etc. It also ensures applications use the latest system state to make
//! decisions about which adapter to use.
//!
//! https://gpuweb.github.io/gpuweb/#adapters
//! https://gpuweb.github.io/gpuweb/#gpuadapter
const std = @import("std");

const Feature = @import("enums.zig").Feature;
const Limits = @import("data.zig").Limits;
const Device = @import("Device.zig");

const Adapter = @This();

/// The features which can be used to create devices on this adapter.
features: []Feature,
_features: [std.enums.values(Feature).len]Feature = undefined,

/// The best limits which can be used to create devices on this adapter.
///
/// Each adapter limit will be the same or better than its default value in supported limits.
limits: Limits,

/// If set to true indicates that the adapter is a fallback adapter.
///
/// An adapter may be considered a fallback adapter if it has significant performance caveats in
/// exchange for some combination of wider compatibility, more predictable behavior, or improved
/// privacy. It is not guaranteed that a fallback adapter is available on every system.
///
/// Always false on native implementations of WebGPU (TODO: why is this not queryable in Dawn?)
fallback: bool,

properties: Properties,

/// The type erased pointer to the Adapter implementation
/// Equal to c.WGPUAdapter for NativeInstance.
ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    reference: fn (ptr: *anyopaque) void,
    release: fn (ptr: *anyopaque) void,
    requestDevice: fn requestDevice(
        ptr: *anyopaque,
        descriptor: *const Device.Descriptor,
        callback: *RequestDeviceCallback,
    ) void,
};

pub inline fn reference(adapter: Adapter) void {
    adapter.vtable.reference(adapter.ptr);
}

pub inline fn release(adapter: Adapter) void {
    adapter.vtable.release(adapter.ptr);
}

/// Tests of the given feature can be used to create devices on this adapter.
pub fn hasFeature(adapter: Adapter, feature: Feature) bool {
    for (adapter.features) |f| {
        if (f == feature) return true;
    }
    return false;
}

pub const Properties = struct {
    vendor_id: u32,
    device_id: u32,
    name: []const u8,
    driver_description: []const u8,
    adapter_type: Type,
    backend_type: BackendType,
};

pub const Type = enum(u32) {
    discrete_gpu,
    integrated_gpu,
    cpu,
    unknown,
};

pub fn typeName(t: Type) []const u8 {
    return switch (t) {
        .discrete_gpu => "Discrete GPU",
        .integrated_gpu => "Integrated GPU",
        .cpu => "CPU",
        .unknown => "Unknown",
    };
}

pub const BackendType = enum(u32) {
    nul,
    webgpu,
    d3d11,
    d3d12,
    metal,
    vulkan,
    opengl,
    opengles,
};

pub fn backendTypeName(t: BackendType) []const u8 {
    return switch (t) {
        .nul => "Null",
        .webgpu => "WebGPU",
        .d3d11 => "D3D11",
        .d3d12 => "D3D12",
        .metal => "Metal",
        .vulkan => "Vulkan",
        .opengl => "OpenGL",
        .opengles => "OpenGLES",
    };
}

pub const RequestDeviceErrorCode = error{
    Error,
    Unknown,
};

pub const RequestDeviceError = struct {
    message: []const u8,
    code: RequestDeviceErrorCode,
};

pub const RequestDeviceResponseTag = enum {
    device,
    err,
};

pub const RequestDeviceResponse = union(RequestDeviceResponseTag) {
    device: Device,
    err: RequestDeviceError,
};

pub fn requestDevice(
    adapter: Adapter,
    descriptor: *const Device.Descriptor,
    callback: *RequestDeviceCallback,
) void {
    adapter.vtable.requestDevice(adapter.ptr, descriptor, callback);
}

pub const RequestDeviceCallback = struct {
    type_erased_ctx: *anyopaque,
    type_erased_callback: fn (ctx: *anyopaque, response: RequestDeviceResponse) callconv(.Inline) void,

    pub fn init(
        comptime Context: type,
        ctx: Context,
        comptime callback: fn (ctx: Context, response: RequestDeviceResponse) void,
    ) RequestDeviceCallback {
        const erased = (struct {
            pub inline fn erased(type_erased_ctx: *anyopaque, response: RequestDeviceResponse) void {
                callback(if (Context == void) {} else @ptrCast(Context, @alignCast(std.meta.alignment(Context), type_erased_ctx)), response);
            }
        }).erased;

        return .{
            .type_erased_ctx = if (Context == void) undefined else ctx,
            .type_erased_callback = erased,
        };
    }
};

/// A helper which invokes requestDevice and blocks until the device is recieved.
pub fn waitForDevice(adapter: Adapter, descriptor: *const Device.Descriptor) RequestDeviceResponse {
    var response: RequestDeviceResponse = undefined;
    var callback = RequestDeviceCallback.init(*RequestDeviceResponse, &response, (struct {
        pub fn callback(ctx: *RequestDeviceResponse, callback_response: RequestDeviceResponse) void {
            ctx.* = callback_response;
        }
    }).callback);

    adapter.requestDevice(descriptor, &callback);

    // TODO: FUTURE: Once crbug.com/dawn/1122 is fixed, we should process events here otherwise our
    // callback would not be invoked:
    //c.wgpuInstanceProcessEvents(adapter.instance)

    return response;
}

test {
    _ = VTable;
    _ = hasFeature;
    _ = Properties;
    _ = Type;
    _ = BackendType;
    _ = RequestDeviceErrorCode;
    _ = RequestDeviceError;
    _ = RequestDeviceResponse;
    _ = RequestDeviceCallback;
    _ = requestDevice;
    _ = waitForDevice;
}
