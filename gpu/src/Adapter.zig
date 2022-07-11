const testing = @import("std").testing;

ptr: *anyopaque,

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

test "Adapter.Type name" {
    try testing.expectEqualStrings("Discrete GPU", Type.discrete_gpu.name());
}
