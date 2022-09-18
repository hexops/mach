//! Note: All the above requests can be blocking - dbus requests can and will block while the daemon
//! handles the request. It is not recommended to make these calls in performance critical code
const builtin = @import("builtin");
pub const c = @cImport(@cInclude("gamemode_client.h"));

pub const GamemodeError = error{
    RequestFailed,
    RequestRejected,
    QueryFailed,
};

pub const GamemodeStatus = enum(c_int) {
    Inactive = 0,
    Active = 1,
    /// Gamemode is active and the client is registered
    ActiveAndRegistered = 2,
};

/// Request gamemode starts
pub fn requestStart() GamemodeError!void {
    if (c.gamemode_request_start() == -1)
        return GamemodeError.RequestFailed;
}

/// Request gamemode ends
pub fn requestEnd() GamemodeError!void {
    if (c.gamemode_request_end() == -1)
        return GamemodeError.RequestFailed;
}

/// Query the current status of gamemode
pub fn queryStatus() GamemodeError!GamemodeStatus {
    const status = c.gamemode_query_status();
    if (status == -1)
        return GamemodeError.QueryFailed;

    return @intToEnum(GamemodeStatus, status);
}

/// Request gamemode starts for another process
pub fn requestStartFor(pid: c.pid_t) GamemodeError!void {
    const res = c.gamemode_request_start_for(pid);
    if (res == 0) {
        return;
    } else if (res == -1) {
        return GamemodeError.RequestFailed;
    } else if (res == -2) {
        return GamemodeError.RequestRejected;
    }
}

/// Request gamemode ends for another process
pub fn requestEndFor(pid: c.pid_t) GamemodeError!void {
    const res = c.gamemode_request_end_for(pid);
    if (res == 0) {
        return;
    } else if (res == -1) {
        return GamemodeError.RequestFailed;
    } else if (res == -2) {
        return GamemodeError.RequestRejected;
    }
}

/// Query the current status of gamemode for another process
pub fn queryStatusFor(pid: c.pid_t) GamemodeError!GamemodeStatus {
    const status = c.gamemode_query_status_for(pid);
    if (status == -1)
        return GamemodeError.QueryFailed;

    return @intToEnum(GamemodeStatus, status);
}

/// Get an error string
pub fn errorString() []const u8 {
    return @import("std").mem.sliceTo(c.gamemode_error_string(), 0);
}
