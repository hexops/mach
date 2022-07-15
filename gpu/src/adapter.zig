const testing = @import("std").testing;
const ChainedStructOut = @import("types.zig").ChainedStructOut;

pub const Adapter = enum(usize) {
    _,

    pub const none: Adapter = @intToEnum(Adapter, 0);

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
        next_in_chain: *ChainedStructOut,
        vendor_id: u32,
        vendor_name: [*:0]const u8,
        architecture: [*:0]const u8,
        device_id: u32,
        name: [*:0]const u8,
        driver_description: [*:0]const u8,
        adapter_type: Type,
        backend_type: Type,
    };
};

test "Adapter.Type name" {
    try testing.expectEqualStrings("Discrete GPU", Adapter.Type.discrete_gpu.name());
}
