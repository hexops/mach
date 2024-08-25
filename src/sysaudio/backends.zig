const builtin = @import("builtin");
const std = @import("std");

pub const Backend = std.meta.Tag(Context);

pub const Context = switch (builtin.os.tag) {
    .linux => union(enum) {
        pulseaudio: *@import("pulseaudio.zig").Context,
        pipewire: *@import("pipewire.zig").Context,
        jack: *@import("jack.zig").Context,
        alsa: *@import("alsa.zig").Context,
        dummy: *@import("dummy.zig").Context,
    },
    .freebsd, .netbsd, .openbsd, .solaris => union(enum) {
        pipewire: *@import("pipewire.zig").Context,
        pulseaudio: *@import("pulseaudio.zig").Context,
        jack: *@import("jack.zig").Context,
        dummy: *@import("dummy.zig").Context,
    },
    .macos, .ios, .watchos, .tvos => union(enum) {
        coreaudio: *@import("coreaudio.zig").Context,
        dummy: *@import("dummy.zig").Context,
    },
    .windows => union(enum) {
        wasapi: *@import("wasapi.zig").Context,
        dummy: *@import("dummy.zig").Context,
    },
    .freestanding => switch (builtin.cpu.arch) {
        else => union(enum) {
            dummy: *@import("dummy.zig").Context,
        },
    },
    else => union(enum) { dummy: *@import("dummy.zig").Context },
};

pub const Player = switch (builtin.os.tag) {
    .linux => union(enum) {
        pulseaudio: *@import("pulseaudio.zig").Player,
        pipewire: *@import("pipewire.zig").Player,
        jack: *@import("jack.zig").Player,
        alsa: *@import("alsa.zig").Player,
        dummy: *@import("dummy.zig").Player,
    },
    .freebsd, .netbsd, .openbsd, .solaris => union(enum) {
        pipewire: *@import("pipewire.zig").Player,
        pulseaudio: *@import("pulseaudio.zig").Player,
        jack: *@import("jack.zig").Player,
        dummy: *@import("dummy.zig").Player,
    },
    .macos, .ios, .watchos, .tvos => union(enum) {
        coreaudio: *@import("coreaudio.zig").Player,
        dummy: *@import("dummy.zig").Player,
    },
    .windows => union(enum) {
        wasapi: *@import("wasapi.zig").Player,
        dummy: *@import("dummy.zig").Player,
    },
    .freestanding => switch (builtin.cpu.arch) {
        else => union(enum) {
            dummy: *@import("dummy.zig").Player,
        },
    },
    else => union(enum) { dummy: *@import("dummy.zig").Player },
};

pub const Recorder = switch (builtin.os.tag) {
    .linux => union(enum) {
        pulseaudio: *@import("pulseaudio.zig").Recorder,
        pipewire: *@import("pipewire.zig").Recorder,
        jack: *@import("jack.zig").Recorder,
        alsa: *@import("alsa.zig").Recorder,
        dummy: *@import("dummy.zig").Recorder,
    },
    .freebsd, .netbsd, .openbsd, .solaris => union(enum) {
        pipewire: *@import("pipewire.zig").Recorder,
        pulseaudio: *@import("pulseaudio.zig").Recorder,
        jack: *@import("jack.zig").Recorder,
        dummy: *@import("dummy.zig").Recorder,
    },
    .macos, .ios, .watchos, .tvos => union(enum) {
        coreaudio: *@import("coreaudio.zig").Recorder,
        dummy: *@import("dummy.zig").Recorder,
    },
    .windows => union(enum) {
        wasapi: *@import("wasapi.zig").Recorder,
        dummy: *@import("dummy.zig").Recorder,
    },
    .freestanding => switch (builtin.cpu.arch) {
        else => union(enum) {
            dummy: *@import("dummy.zig").Recorder,
        },
    },
    else => union(enum) { dummy: *@import("dummy.zig").Recorder },
};
