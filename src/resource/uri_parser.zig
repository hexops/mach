const std = @import("std");
const mem = std.mem;

pub const Uri = struct {
    scheme: []const u8,
    path: []const u8,
};

pub const Error = error{InvalidUri};

pub fn parseUri(uri: []const u8) Error!Uri {
    const scheme_end = mem.indexOfScalar(u8, uri, ':');
    if (scheme_end == null)
        return error.InvalidUri;

    const scheme = uri[0..scheme_end.?];

    if (scheme_end.? + 3 >= uri.len)
        return error.InvalidUri;

    if (uri[scheme_end.? + 1] != '/' or uri[scheme_end.? + 2] != '/')
        return error.InvalidUri;

    const path = uri[scheme_end.? + 3 ..];

    return Uri{
        .scheme = scheme,
        .path = path,
    };
}

const testing = std.testing;
const expectError = testing.expectError;
const expectEqualStrings = testing.expectEqualStrings;

test "invalid" {
    try expectError(error.InvalidUri, parseUri("xyz"));
    try expectError(error.InvalidUri, parseUri("xyz:"));
    try expectError(error.InvalidUri, parseUri("xyz:/"));
    try expectError(error.InvalidUri, parseUri("xyz://"));
}

test "path" {
    try expectEqualStrings("xyz", (try parseUri("xyz://abc")).scheme);
    try expectEqualStrings("abc", (try parseUri("xyz://abc")).path);
}
