const std = @import("std");
const c = @import("c.zig");

pub const Error = error{
    OutOfMemory,
    /// The backend does not appear to be active or running.
    InitAudioBackend,
    /// A system resource other than memory was not available.
    SystemResources,
    /// Attempted to open a device and failed.
    OpeningDevice,
    NoSuchDevice,
    /// The programmer did not comply with the API.
    Invalid,
    /// libsoundio was compiled without support for that backend.
    BackendUnavailable,
    /// An open stream had an error that can only be recovered from by
    /// destroying the stream and creating it again.
    Streaming,
    /// Attempted to use a device with parameters it cannot support.
    IncompatibleDevice,
    /// When JACK returns `JackNoSuchClient`
    NoSuchClient,
    /// Attempted to use parameters that the backend cannot support.
    IncompatibleBackend,
    /// Backend server shutdown or became inactive.
    BackendDisconnected,
    Interrupted,
    /// Buffer underrun occurred.
    Underflow,
    /// Unable to convert to or from UTF-8 to the native string format.
    EncodingString,
};

pub fn intToError(err: c_int) Error!void {
    return switch (err) {
        c.SoundIoErrorNone => {},
        c.SoundIoErrorNoMem => Error.OutOfMemory,
        c.SoundIoErrorInitAudioBackend => Error.InitAudioBackend,
        c.SoundIoErrorSystemResources => Error.SystemResources,
        c.SoundIoErrorOpeningDevice => Error.OpeningDevice,
        c.SoundIoErrorNoSuchDevice => Error.NoSuchDevice,
        c.SoundIoErrorInvalid => Error.Invalid,
        c.SoundIoErrorBackendUnavailable => Error.BackendUnavailable,
        c.SoundIoErrorStreaming => Error.Streaming,
        c.SoundIoErrorIncompatibleDevice => Error.IncompatibleDevice,
        c.SoundIoErrorNoSuchClient => Error.NoSuchClient,
        c.SoundIoErrorIncompatibleBackend => Error.IncompatibleBackend,
        c.SoundIoErrorBackendDisconnected => Error.BackendDisconnected,
        c.SoundIoErrorInterrupted => Error.Interrupted,
        c.SoundIoErrorUnderflow => Error.Underflow,
        c.SoundIoErrorEncodingString => Error.EncodingString,
        else => unreachable,
    };
}

test "error convertion" {
    const expectError = @import("std").testing.expectError;

    try intToError(c.SoundIoErrorNone);
    try expectError(Error.OutOfMemory, intToError(c.SoundIoErrorNoMem));
}
