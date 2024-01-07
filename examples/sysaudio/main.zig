const mach = @import("mach");

const Piano = @import("Piano.zig");

// The list of modules to be used in our application.
// Our Piano itself is implemented in our own module called Piano.
pub const modules = .{
    mach.Engine,
    mach.Audio,
    Piano,
};

pub const App = mach.App;
