const std = @import("std");
const testing = std.testing;
const dawn = @import("dawn.zig");
const Bool32 = @import("main.zig").Bool32;
const ChainedStructOut = @import("main.zig").ChainedStructOut;
const Device = @import("device.zig").Device;
const Instance = @import("instance.zig").Instance;
const FeatureName = @import("main.zig").FeatureName;
const SupportedLimits = @import("main.zig").SupportedLimits;
const RequestDeviceStatus = @import("main.zig").RequestDeviceStatus;
const BackendType = @import("main.zig").BackendType;
const RequestDeviceCallback = @import("main.zig").RequestDeviceCallback;
const Impl = @import("interface.zig").Impl;

pub const Adapter = opaque {
    pub const Type = enum(u32) {
        discrete_gpu,
        integrated_gpu,
        cpu,
        unknown,

        pub fn name(t: Type) []const u8 {
            return switch (t) {
                .discrete_gpu => "Discrete GPU",
                .integrated_gpu => "Integrated GPU",
                .cpu => "CPU",
                .unknown => "Unknown",
            };
        }
    };

    pub const Properties = extern struct {
        pub const NextInChain = extern union {
            generic: ?*const ChainedStructOut,
            dawn_adapter_properties_power_preference: *const dawn.AdapterPropertiesPowerPreference,
        };

        next_in_chain: NextInChain = .{ .generic = null },
        vendor_id: u32,
        vendor_name: [*:0]const u8,
        architecture: [*:0]const u8,
        device_id: u32,
        name: [*:0]const u8,
        driver_description: [*:0]const u8,
        adapter_type: Type,
        backend_type: BackendType,
        compatibility_mode: Bool32 = .false,
    };

    pub inline fn createDevice(adapter: *Adapter, descriptor: ?*const Device.Descriptor) ?*Device {
        return Impl.adapterCreateDevice(adapter, descriptor);
    }

    /// Call once with null to determine the array length, and again to fetch the feature list.
    ///
    /// Consider using the enumerateFeaturesOwned helper.
    pub inline fn enumerateFeatures(adapter: *Adapter, features: ?[*]FeatureName) usize {
        return Impl.adapterEnumerateFeatures(adapter, features);
    }

    /// Enumerates the adapter features, storing the result in an allocated slice which is owned by
    /// the caller.
    pub inline fn enumerateFeaturesOwned(adapter: *Adapter, allocator: std.mem.Allocator) ![]FeatureName {
        const count = adapter.enumerateFeatures(null);
        const data = try allocator.alloc(FeatureName, count);
        _ = adapter.enumerateFeatures(data.ptr);
        return data;
    }

    pub inline fn getInstance(adapter: *Adapter) *Instance {
        return Impl.adapterGetInstance(adapter);
    }

    pub inline fn getLimits(adapter: *Adapter, limits: *SupportedLimits) bool {
        return Impl.adapterGetLimits(adapter, limits);
    }

    pub inline fn getProperties(adapter: *Adapter, properties: *Adapter.Properties) void {
        Impl.adapterGetProperties(adapter, properties);
    }

    pub inline fn hasFeature(adapter: *Adapter, feature: FeatureName) bool {
        return Impl.adapterHasFeature(adapter, feature);
    }

    pub inline fn requestDevice(
        adapter: *Adapter,
        descriptor: ?*const Device.Descriptor,
        context: anytype,
        comptime callback: fn (
            ctx: @TypeOf(context),
            status: RequestDeviceStatus,
            device: *Device,
            message: ?[*:0]const u8,
        ) callconv(.Inline) void,
    ) void {
        const Context = @TypeOf(context);
        const Helper = struct {
            pub fn cCallback(status: RequestDeviceStatus, device: *Device, message: ?[*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
                callback(
                    if (Context == void) {} else @as(Context, @ptrCast(@alignCast(userdata))),
                    status,
                    device,
                    message,
                );
            }
        };
        Impl.adapterRequestDevice(adapter, descriptor, Helper.cCallback, if (Context == void) null else context);
    }

    pub inline fn reference(adapter: *Adapter) void {
        Impl.adapterReference(adapter);
    }

    pub inline fn release(adapter: *Adapter) void {
        Impl.adapterRelease(adapter);
    }
};

test "Adapter.Type name" {
    try testing.expectEqualStrings("Discrete GPU", Adapter.Type.discrete_gpu.name());
}
