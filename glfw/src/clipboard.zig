// TODO(clipboard):
// /// Sets the clipboard to the specified string.
// ///
// /// This function sets the system clipboard to the specified, UTF-8 encoded
// /// string.
// ///
// /// @param[in] window Deprecated. Any valid window or null.
// /// @param[in] string A UTF-8 encoded string.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The specified string is copied before this function
// /// returns.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: clipboard, glfwGetClipboardString
// ///
// ///
// /// @ingroup input
// GLFWAPI void glfwSetClipboardString(GLFWwindow* window, const char* string);

// /// Returns the contents of the clipboard as a string.
// ///
// /// This function returns the contents of the system clipboard, if it contains
// /// or is convertible to a UTF-8 encoded string. If the clipboard is empty or
// /// if its contents cannot be converted, null is returned and a glfw.Error.FormatUnavailable error is generated.
// ///
// /// @param[in] window Deprecated. Any valid window or null.
// /// @return The contents of the clipboard as a UTF-8 encoded string, or null
// /// if an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned string is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the next call to @ref
// /// glfwGetClipboardString or @ref glfwSetClipboardString, or until the library
// /// is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: clipboard, glfwSetClipboardString
// ///
// ///
// /// @ingroup input
// GLFWAPI const char* glfwGetClipboardString(GLFWwindow* window);
