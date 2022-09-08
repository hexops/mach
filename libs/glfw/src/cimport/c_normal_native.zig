pub fn import(comptime options: anytype) type {
    return @cImport({
        @cDefine("GLFW_INCLUDE_VULKAN", "1");
        @cInclude("GLFW/glfw3.h");
        if (options.win32) @cDefine("GLFW_EXPOSE_NATIVE_WIN32", "1");
        if (options.wgl) @cDefine("GLFW_EXPOSE_NATIVE_WGL", "1");
        if (options.cocoa) @cDefine("GLFW_EXPOSE_NATIVE_COCOA", "1");
        if (options.nsgl) @cDefine("GLFW_EXPOSE_NATIVE_NGSL", "1");
        if (options.x11) @cDefine("GLFW_EXPOSE_NATIVE_X11", "1");
        if (options.glx) @cDefine("GLFW_EXPOSE_NATIVE_GLX", "1");
        if (options.wayland) @cDefine("GLFW_EXPOSE_NATIVE_WAYLAND", "1");
        if (options.egl) @cDefine("GLFW_EXPOSE_NATIVE_EGL", "1");
        if (options.osmesa) @cDefine("GLFW_EXPOSE_NATIVE_OSMESA", "1");
        @cInclude("GLFW/glfw3native.h");
    });
}
