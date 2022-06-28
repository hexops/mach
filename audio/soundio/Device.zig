const c = @import("c.zig");

const SoundIoDevice = @This();

handle: *c.SoundIoDevice,
