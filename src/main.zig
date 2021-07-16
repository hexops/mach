const std = @import("std");
const testing = std.testing;

const glfw = @import("glfw");

test "glfw_basic" {
    glfw.basicTest() catch unreachable;
}
