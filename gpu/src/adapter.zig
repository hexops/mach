const testing = @import("std").testing;
const ChainedStructOut = @import("types.zig").ChainedStructOut;
const Device = @import("device.zig").Device;
const DeviceDescriptor = @import("device.zig").DeviceDescriptor;
const FeatureName = @import("types.zig").FeatureName;
const SupportedLimits = @import("types.zig").SupportedLimits;
const RequestDeviceStatus = @import("types.zig").RequestDeviceStatus;
const impl = @import("interface.zig").impl;

pub const Adapter = *opaque {
    pub inline fn createDevice(adapter: Adapter, descriptor: ?*const DeviceDescriptor) ?Device {
        return impl.createDevice(adapter, descriptor);
    }

    /// Call once with null to determine the array length, and again to fetch the feature list.
    pub inline fn enumerateFeatures(adapter: Adapter, features: ?[*]FeatureName) usize {
        return impl.adapterEnumerateFeatures(adapter, features);
    }

    pub inline fn getLimits(adapter: Adapter, limits: *SupportedLimits) bool {
        return impl.adapterGetLimits(adapter, limits);
    }

    pub inline fn getProperties(adapter: Adapter, properties: *AdapterProperties) void {
        impl.adapterGetProperties(adapter, properties);
    }

    pub inline fn hasFeature(adapter: Adapter, feature: FeatureName) bool {
        return impl.adapterHasFeature(adapter, feature);
    }

    pub inline fn requestDevice(adapter: Adapter, descriptor: ?*const DeviceDescriptor, callback: RequestDeviceCallback, userdata: *anyopaque) void {
        impl.adapterRequestDevice(adapter, descriptor, callback, userdata);
    }

    pub inline fn reference(adapter: Adapter) void {
        impl.adapterReference(adapter);
    }

    pub inline fn release(adapter: Adapter) void {
        impl.adapterRelease(adapter);
    }
};

pub const RequestDeviceCallback = fn (
    status: RequestDeviceStatus,
    device: Device,
    message: [*:0]const u8,
    userdata: *anyopaque,
) callconv(.C) void;

pub const AdapterType = enum(u32) {
    discrete_gpu,
    integrated_gpu,
    cpu,
    unknown,

    pub fn name(t: AdapterType) []const u8 {
        return switch (t) {
            .discrete_gpu => "Discrete GPU",
            .integrated_gpu => "Integrated GPU",
            .cpu => "CPU",
            .unknown => "Unknown",
        };
    }
};

pub const AdapterProperties = extern struct {
    next_in_chain: *ChainedStructOut,
    vendor_id: u32,
    vendor_name: [*:0]const u8,
    architecture: [*:0]const u8,
    device_id: u32,
    name: [*:0]const u8,
    driver_description: [*:0]const u8,
    adapter_type: AdapterType,
    backend_type: AdapterType,
};

test "AdapterType name" {
    try testing.expectEqualStrings("Discrete GPU", AdapterType.discrete_gpu.name());
}
