// TODO(input):

// /// Opaque cursor object.
// ///
// /// Opaque cursor object.
// ///
// /// see also: cursor_object
// ///
// ///
// /// @ingroup input
// typedef struct GLFWcursor GLFWcursor;

// /// The function pointer type for mouse button callbacks.
// ///
// /// This is the function pointer type for mouse button callback functions.
// /// A mouse button callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int button, int action, int mods)
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] button The mouse button that was pressed or
// /// released.
// /// @param[in] action One of `GLFW_PRESS` or `GLFW_RELEASE`. Future releases
// /// may add more actions.
// /// @param[in] mods Bit field describing which [modifier keys](@ref mods) were
// /// held down.
// ///
// /// see also: input_mouse_button, glfwSetMouseButtonCallback
// ///
// /// @glfw3 Added window handle and modifier mask parameters.
// ///
// /// @ingroup input
// typedef void (* GLFWmousebuttonfun)(GLFWwindow*,int,int,int);

// /// The function pointer type for cursor position callbacks.
// ///
// /// This is the function pointer type for cursor position callbacks. A cursor
// /// position callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, double xpos, double ypos);
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] xpos The new cursor x-coordinate, relative to the left edge of
// /// the content area.
// /// @param[in] ypos The new cursor y-coordinate, relative to the top edge of the
// /// content area.
// ///
// /// see also: cursor_pos, glfw.setCursorPosCallback
// /// Replaces `GLFWmouseposfun`.
// ///
// /// @ingroup input
// typedef void (* GLFWcursorposfun)(GLFWwindow*,double,double);

// /// The function pointer type for cursor enter/leave callbacks.
// ///
// /// This is the function pointer type for cursor enter/leave callbacks.
// /// A cursor enter/leave callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int entered)
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] entered `GLFW_TRUE` if the cursor entered the window's content
// /// area, or `GLFW_FALSE` if it left it.
// ///
// /// see also: cursor_enter, glfwSetCursorEnterCallback
// ///
// ///
// /// @ingroup input
// typedef void (* GLFWcursorenterfun)(GLFWwindow*,int);

// /// The function pointer type for scroll callbacks.
// ///
// /// This is the function pointer type for scroll callbacks. A scroll callback
// /// function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, double xoffset, double yoffset)
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] xoffset The scroll offset along the x-axis.
// /// @param[in] yoffset The scroll offset along the y-axis.
// ///
// /// see also: scrolling, glfwSetScrollCallback
// /// Replaces `GLFWmousewheelfun`.
// ///
// /// @ingroup input
// typedef void (* GLFWscrollfun)(GLFWwindow*,double,double);

// /// The function pointer type for keyboard key callbacks.
// ///
// /// This is the function pointer type for keyboard key callbacks. A keyboard
// /// key callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int key, int scancode, int action, int mods)
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] key The [keyboard key](@ref keys) that was pressed or released.
// /// @param[in] scancode The system-specific scancode of the key.
// /// @param[in] action `GLFW_PRESS`, `GLFW_RELEASE` or `GLFW_REPEAT`. Future
// /// releases may add more actions.
// /// @param[in] mods Bit field describing which [modifier keys](@ref mods) were
// /// held down.
// ///
// /// see also: input_key, glfwSetKeyCallback
// ///
// /// @glfw3 Added window handle, scancode and modifier mask parameters.
// ///
// /// @ingroup input
// typedef void (* GLFWkeyfun)(GLFWwindow*,int,int,int,int);

// /// The function pointer type for Unicode character callbacks.
// ///
// /// This is the function pointer type for Unicode character callbacks.
// /// A Unicode character callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, unsigned int codepoint)
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] codepoint The Unicode code point of the character.
// ///
// /// see also: input_char, glfwSetCharCallback
// ///
// /// @glfw3 Added window handle parameter.
// ///
// /// @ingroup input
// typedef void (* GLFWcharfun)(GLFWwindow*,unsigned int);

// /// The function pointer type for path drop callbacks.
// ///
// /// This is the function pointer type for path drop callbacks. A path drop
// /// callback function has the following signature:
// /// @code
// /// void function_name(GLFWwindow* window, int path_count, const char* paths[])
// /// @endcode
// ///
// /// @param[in] window The window that received the event.
// /// @param[in] path_count The number of dropped paths.
// /// @param[in] paths The UTF-8 encoded file and/or directory path names.
// ///
// /// @pointer_lifetime The path array and its strings are valid until the
// /// callback function returns.
// ///
// /// see also: path_drop, glfwSetDropCallback
// ///
// ///
// /// @ingroup input
// typedef void (* GLFWdropfun)(GLFWwindow*,int,const char*[]);

// /// The function pointer type for joystick configuration callbacks.
// ///
// /// This is the function pointer type for joystick configuration callbacks.
// /// A joystick configuration callback function has the following signature:
// /// @code
// /// void function_name(int jid, int event)
// /// @endcode
// ///
// /// @param[in] jid The joystick that was connected or disconnected.
// /// @param[in] event One of `GLFW_CONNECTED` or `GLFW_DISCONNECTED`. Future
// /// releases may add more events.
// ///
// /// see also: joystick_event, glfwSetJoystickCallback
// ///
// ///
// /// @ingroup input
// typedef void (* GLFWjoystickfun)(int,int);

// /// Gamepad input state
// ///
// /// This describes the input state of a gamepad.
// ///
// /// see also: gamepad, glfwGetGamepadState
// ///
// ///
// /// @ingroup input
// typedef struct GLFWgamepadstate
// {
//     /*! The states of each [gamepad button](@ref gamepad_buttons), `GLFW_PRESS`
//     /// or `GLFW_RELEASE`.
//         unsigned char buttons[15];
//     /*! The states of each [gamepad axis](@ref gamepad_axes), in the range -1.0
//     /// to 1.0 inclusive.
//         float axes[6];
// } GLFWgamepadstate;

// /// Returns the value of an input option for the specified window.
// ///
// /// This function returns the value of an input option for the specified window.
// /// The mode must be one of @ref GLFW_CURSOR, @ref GLFW_STICKY_KEYS,
// /// @ref GLFW_STICKY_MOUSE_BUTTONS, @ref GLFW_LOCK_KEY_MODS or
// /// @ref GLFW_RAW_MOUSE_MOTION.
// ///
// /// @param[in] window The window to query.
// /// @param[in] mode One of `GLFW_CURSOR`, `GLFW_STICKY_KEYS`,
// /// `GLFW_STICKY_MOUSE_BUTTONS`, `GLFW_LOCK_KEY_MODS` or
// /// `GLFW_RAW_MOUSE_MOTION`.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: glfw.setInputMode
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwGetInputMode(GLFWwindow* window, int mode);

// /// Sets an input option for the specified window.
// ///
// /// This function sets an input mode option for the specified window. The mode
// /// must be one of @ref GLFW_CURSOR, @ref GLFW_STICKY_KEYS,
// /// @ref GLFW_STICKY_MOUSE_BUTTONS, @ref GLFW_LOCK_KEY_MODS or
// /// @ref GLFW_RAW_MOUSE_MOTION.
// ///
// /// If the mode is `GLFW_CURSOR`, the value must be one of the following cursor
// /// modes:
// /// - `GLFW_CURSOR_NORMAL` makes the cursor visible and behaving normally.
// /// - `GLFW_CURSOR_HIDDEN` makes the cursor invisible when it is over the
// ///   content area of the window but does not restrict the cursor from leaving.
// /// - `GLFW_CURSOR_DISABLED` hides and grabs the cursor, providing virtual
// ///   and unlimited cursor movement. This is useful for implementing for
// ///   example 3D camera controls.
// ///
// /// If the mode is `GLFW_STICKY_KEYS`, the value must be either `GLFW_TRUE` to
// /// enable sticky keys, or `GLFW_FALSE` to disable it. If sticky keys are
// /// enabled, a key press will ensure that @ref glfwGetKey returns `GLFW_PRESS`
// /// the next time it is called even if the key had been released before the
// /// call. This is useful when you are only interested in whether keys have been
// /// pressed but not when or in which order.
// ///
// /// If the mode is `GLFW_STICKY_MOUSE_BUTTONS`, the value must be either
// /// `GLFW_TRUE` to enable sticky mouse buttons, or `GLFW_FALSE` to disable it.
// /// If sticky mouse buttons are enabled, a mouse button press will ensure that
// /// @ref glfwGetMouseButton returns `GLFW_PRESS` the next time it is called even
// /// if the mouse button had been released before the call. This is useful when
// /// you are only interested in whether mouse buttons have been pressed but not
// /// when or in which order.
// ///
// /// If the mode is `GLFW_LOCK_KEY_MODS`, the value must be either `GLFW_TRUE` to
// /// enable lock key modifier bits, or `GLFW_FALSE` to disable them. If enabled,
// /// callbacks that receive modifier bits will also have the @ref
// /// GLFW_MOD_CAPS_LOCK bit set when the event was generated with Caps Lock on,
// /// and the @ref GLFW_MOD_NUM_LOCK bit when Num Lock was on.
// ///
// /// If the mode is `GLFW_RAW_MOUSE_MOTION`, the value must be either `GLFW_TRUE`
// /// to enable raw (unscaled and unaccelerated) mouse motion when the cursor is
// /// disabled, or `GLFW_FALSE` to disable it. If raw motion is not supported,
// /// attempting to set this will emit glfw.Error.PlatformError. Call @ref
// /// glfwRawMouseMotionSupported to check for support.
// ///
// /// @param[in] window The window whose input mode to set.
// /// @param[in] mode One of `GLFW_CURSOR`, `GLFW_STICKY_KEYS`,
// /// `GLFW_STICKY_MOUSE_BUTTONS`, `GLFW_LOCK_KEY_MODS` or
// /// `GLFW_RAW_MOUSE_MOTION`.
// /// @param[in] value The new value of the specified input mode.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: glfw.getInputMode
// /// Replaces `glfwEnable` and `glfwDisable`.
// ///
// /// @ingroup input
// GLFWAPI void glfwSetInputMode(GLFWwindow* window, int mode, int value);

// /// Returns whether raw mouse motion is supported.
// ///
// /// This function returns whether raw mouse motion is supported on the current
// /// system. This status does not change after GLFW has been initialized so you
// /// only need to check this once. If you attempt to enable raw motion on
// /// a system that does not support it, glfw.Error.PlatformError will be emitted.
// ///
// /// Raw mouse motion is closer to the actual motion of the mouse across
// /// a surface. It is not affected by the scaling and acceleration applied to
// /// the motion of the desktop cursor. That processing is suitable for a cursor
// /// while raw motion is better for controlling for example a 3D camera. Because
// /// of this, raw mouse motion is only provided when the cursor is disabled.
// ///
// /// @return `GLFW_TRUE` if raw mouse motion is supported on the current machine,
// /// or `GLFW_FALSE` otherwise.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: raw_mouse_motion, glfw.setInputMode
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwRawMouseMotionSupported(void);

// /// Returns the layout-specific name of the specified printable key.
// ///
// /// This function returns the name of the specified printable key, encoded as
// /// UTF-8. This is typically the character that key would produce without any
// /// modifier keys, intended for displaying key bindings to the user. For dead
// /// keys, it is typically the diacritic it would add to a character.
// ///
// /// __Do not use this function__ for [text input](@ref input_char). You will
// /// break text input for many languages even if it happens to work for yours.
// ///
// /// If the key is `GLFW_KEY_UNKNOWN`, the scancode is used to identify the key,
// /// otherwise the scancode is ignored. If you specify a non-printable key, or
// /// `GLFW_KEY_UNKNOWN` and a scancode that maps to a non-printable key, this
// /// function returns null but does not emit an error.
// ///
// /// This behavior allows you to always pass in the arguments in the
// /// [key callback](@ref input_key) without modification.
// ///
// /// The printable keys are:
// /// - `GLFW_KEY_APOSTROPHE`
// /// - `GLFW_KEY_COMMA`
// /// - `GLFW_KEY_MINUS`
// /// - `GLFW_KEY_PERIOD`
// /// - `GLFW_KEY_SLASH`
// /// - `GLFW_KEY_SEMICOLON`
// /// - `GLFW_KEY_EQUAL`
// /// - `GLFW_KEY_LEFT_BRACKET`
// /// - `GLFW_KEY_RIGHT_BRACKET`
// /// - `GLFW_KEY_BACKSLASH`
// /// - `GLFW_KEY_WORLD_1`
// /// - `GLFW_KEY_WORLD_2`
// /// - `GLFW_KEY_0` to `GLFW_KEY_9`
// /// - `GLFW_KEY_A` to `GLFW_KEY_Z`
// /// - `GLFW_KEY_KP_0` to `GLFW_KEY_KP_9`
// /// - `GLFW_KEY_KP_DECIMAL`
// /// - `GLFW_KEY_KP_DIVIDE`
// /// - `GLFW_KEY_KP_MULTIPLY`
// /// - `GLFW_KEY_KP_SUBTRACT`
// /// - `GLFW_KEY_KP_ADD`
// /// - `GLFW_KEY_KP_EQUAL`
// ///
// /// Names for printable keys depend on keyboard layout, while names for
// /// non-printable keys are the same across layouts but depend on the application
// /// language and should be localized along with other user interface text.
// ///
// /// @param[in] key The key to query, or `GLFW_KEY_UNKNOWN`.
// /// @param[in] scancode The scancode of the key to query.
// /// @return The UTF-8 encoded, layout-specific name of the key, or null.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// The contents of the returned string may change when a keyboard
// /// layout change event is received.
// ///
// /// @pointer_lifetime The returned string is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_key_name
// ///
// ///
// /// @ingroup input
// GLFWAPI const char* glfwGetKeyName(int key, int scancode);

// /// Returns the platform-specific scancode of the specified key.
// ///
// /// This function returns the platform-specific scancode of the specified key.
// ///
// /// If the key is `GLFW_KEY_UNKNOWN` or does not exist on the keyboard this
// /// method will return `-1`.
// ///
// /// @param[in] key Any [named key](@ref keys).
// /// @return The platform-specific scancode for the key, or `-1` if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function may be called from any thread.
// ///
// /// see also: input_key
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwGetKeyScancode(int key);

// /// Returns the last reported state of a keyboard key for the specified
// /// window.
// ///
// /// This function returns the last state reported for the specified key to the
// /// specified window. The returned state is one of `GLFW_PRESS` or
// /// `GLFW_RELEASE`. The higher-level action `GLFW_REPEAT` is only reported to
// /// the key callback.
// ///
// /// If the @ref GLFW_STICKY_KEYS input mode is enabled, this function returns
// /// `GLFW_PRESS` the first time you call it for a key that was pressed, even if
// /// that key has already been released.
// ///
// /// The key functions deal with physical keys, with [key tokens](@ref keys)
// /// named after their use on the standard US keyboard layout. If you want to
// /// input text, use the Unicode character callback instead.
// ///
// /// The [modifier key bit masks](@ref mods) are not key tokens and cannot be
// /// used with this function.
// ///
// /// __Do not use this function__ to implement [text input](@ref input_char).
// ///
// /// @param[in] window The desired window.
// /// @param[in] key The desired [keyboard key](@ref keys). `GLFW_KEY_UNKNOWN` is
// /// not a valid key for this function.
// /// @return One of `GLFW_PRESS` or `GLFW_RELEASE`.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_key
// ///
// /// @glfw3 Added window handle parameter.
// ///
// /// @ingroup input
// GLFWAPI int glfwGetKey(GLFWwindow* window, int key);

// /// Returns the last reported state of a mouse button for the specified
// /// window.
// ///
// /// This function returns the last state reported for the specified mouse button
// /// to the specified window. The returned state is one of `GLFW_PRESS` or
// /// `GLFW_RELEASE`.
// ///
// /// If the @ref GLFW_STICKY_MOUSE_BUTTONS input mode is enabled, this function
// /// returns `GLFW_PRESS` the first time you call it for a mouse button that was
// /// pressed, even if that mouse button has already been released.
// ///
// /// @param[in] window The desired window.
// /// @param[in] button The desired mouse button.
// /// @return One of `GLFW_PRESS` or `GLFW_RELEASE`.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_mouse_button
// ///
// /// @glfw3 Added window handle parameter.
// ///
// /// @ingroup input
// GLFWAPI int glfwGetMouseButton(GLFWwindow* window, int button);

// /// Retrieves the position of the cursor relative to the content area of
// /// the window.
// ///
// /// This function returns the position of the cursor, in screen coordinates,
// /// relative to the upper-left corner of the content area of the specified
// /// window.
// ///
// /// If the cursor is disabled (with `GLFW_CURSOR_DISABLED`) then the cursor
// /// position is unbounded and limited only by the minimum and maximum values of
// /// a `double`.
// ///
// /// The coordinate can be converted to their integer equivalents with the
// /// `floor` function. Casting directly to an integer type works for positive
// /// coordinates, but fails for negative ones.
// ///
// /// Any or all of the position arguments may be null. If an error occurs, all
// /// non-null position arguments will be set to zero.
// ///
// /// @param[in] window The desired window.
// /// @param[out] xpos Where to store the cursor x-coordinate, relative to the
// /// left edge of the content area, or null.
// /// @param[out] ypos Where to store the cursor y-coordinate, relative to the to
// /// top edge of the content area, or null.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_pos, glfw.setCursorPos
// /// Replaces `glfwGetMousePos`.
// ///
// /// @ingroup input
// GLFWAPI void glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);

// /// Sets the position of the cursor, relative to the content area of the
// /// window.
// ///
// /// This function sets the position, in screen coordinates, of the cursor
// /// relative to the upper-left corner of the content area of the specified
// /// window. The window must have input focus. If the window does not have
// /// input focus when this function is called, it fails silently.
// ///
// /// __Do not use this function__ to implement things like camera controls. GLFW
// /// already provides the `GLFW_CURSOR_DISABLED` cursor mode that hides the
// /// cursor, transparently re-centers it and provides unconstrained cursor
// /// motion. See @ref glfwSetInputMode for more information.
// ///
// /// If the cursor mode is `GLFW_CURSOR_DISABLED` then the cursor position is
// /// unconstrained and limited only by the minimum and maximum values of
// /// a `double`.
// ///
// /// @param[in] window The desired window.
// /// @param[in] xpos The desired x-coordinate, relative to the left edge of the
// /// content area.
// /// @param[in] ypos The desired y-coordinate, relative to the top edge of the
// /// content area.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// wayland: This function will only work when the cursor mode is
// /// `GLFW_CURSOR_DISABLED`, otherwise it will do nothing.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_pos, glfw.getCursorPos
// /// Replaces `glfwSetMousePos`.
// ///
// /// @ingroup input
// GLFWAPI void glfwSetCursorPos(GLFWwindow* window, double xpos, double ypos);

// /// Creates a custom cursor.
// ///
// /// Creates a new custom cursor image that can be set for a window with @ref
// /// glfwSetCursor. The cursor can be destroyed with @ref glfwDestroyCursor.
// /// Any remaining cursors are destroyed by @ref glfwTerminate.
// ///
// /// The pixels are 32-bit, little-endian, non-premultiplied RGBA, i.e. eight
// /// bits per channel with the red channel first. They are arranged canonically
// /// as packed sequential rows, starting from the top-left corner.
// ///
// /// The cursor hotspot is specified in pixels, relative to the upper-left corner
// /// of the cursor image. Like all other coordinate systems in GLFW, the X-axis
// /// points to the right and the Y-axis points down.
// ///
// /// @param[in] image The desired cursor image.
// /// @param[in] xhot The desired x-coordinate, in pixels, of the cursor hotspot.
// /// @param[in] yhot The desired y-coordinate, in pixels, of the cursor hotspot.
// /// @return The handle of the created cursor, or null if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The specified image data is copied before this function
// /// returns.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_object, glfwDestroyCursor, glfwCreateStandardCursor
// ///
// ///
// /// @ingroup input
// GLFWAPI GLFWcursor* glfwCreateCursor(const GLFWimage* image, int xhot, int yhot);

// /// Creates a cursor with a standard shape.
// ///
// /// Returns a cursor with a [standard shape](@ref shapes), that can be set for
// /// a window with @ref glfwSetCursor.
// ///
// /// @param[in] shape One of the [standard shapes](@ref shapes).
// /// @return A new cursor ready to use or null if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_object, glfwCreateCursor
// ///
// ///
// /// @ingroup input
// GLFWAPI GLFWcursor* glfwCreateStandardCursor(int shape);

// /// Destroys a cursor.
// ///
// /// This function destroys a cursor previously created with @ref
// /// glfwCreateCursor. Any remaining cursors will be destroyed by @ref
// /// glfwTerminate.
// ///
// /// If the specified cursor is current for any window, that window will be
// /// reverted to the default cursor. This does not affect the cursor mode.
// ///
// /// @param[in] cursor The cursor object to destroy.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @reentrancy This function must not be called from a callback.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_object, glfwCreateCursor
// ///
// ///
// /// @ingroup input
// GLFWAPI void glfwDestroyCursor(GLFWcursor* cursor);

// /// Sets the cursor for the window.
// ///
// /// This function sets the cursor image to be used when the cursor is over the
// /// content area of the specified window. The set cursor will only be visible
// /// when the [cursor mode](@ref cursor_mode) of the window is
// /// `GLFW_CURSOR_NORMAL`.
// ///
// /// On some platforms, the set cursor may not be visible unless the window also
// /// has input focus.
// ///
// /// @param[in] window The window to set the cursor for.
// /// @param[in] cursor The cursor to set, or null to switch back to the default
// /// arrow cursor.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_object
// ///
// ///
// /// @ingroup input
// GLFWAPI void glfwSetCursor(GLFWwindow* window, GLFWcursor* cursor);

// /// Sets the key callback.
// ///
// /// This function sets the key callback of the specified window, which is called
// /// when a key is pressed, repeated or released.
// ///
// /// The key functions deal with physical keys, with layout independent
// /// [key tokens](@ref keys) named after their values in the standard US keyboard
// /// layout. If you want to input text, use the
// /// [character callback](@ref glfwSetCharCallback) instead.
// ///
// /// When a window loses input focus, it will generate synthetic key release
// /// events for all pressed keys. You can tell these events from user-generated
// /// events by the fact that the synthetic ones are generated after the focus
// /// loss event has been processed, i.e. after the
// /// [window focus callback](@ref glfwSetWindowFocusCallback) has been called.
// ///
// /// The scancode of a key is specific to that platform or sometimes even to that
// /// machine. Scancodes are intended to allow users to bind keys that don't have
// /// a GLFW key token. Such keys have `key` set to `GLFW_KEY_UNKNOWN`, their
// /// state is not saved and so it cannot be queried with @ref glfwGetKey.
// ///
// /// Sometimes GLFW needs to generate synthetic key events, in which case the
// /// scancode may be zero.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new key callback, or null to remove the currently
// /// set callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int key, int scancode, int action, int mods)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWkeyfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_key
// ///
// /// @glfw3 Added window handle parameter and return value.
// ///
// /// @ingroup input
// GLFWAPI GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun callback);

// /// Sets the Unicode character callback.
// ///
// /// This function sets the character callback of the specified window, which is
// /// called when a Unicode character is input.
// ///
// /// The character callback is intended for Unicode text input. As it deals with
// /// characters, it is keyboard layout dependent, whereas the
// /// [key callback](@ref glfwSetKeyCallback) is not. Characters do not map 1:1
// /// to physical keys, as a key may produce zero, one or more characters. If you
// /// want to know whether a specific physical key was pressed or released, see
// /// the key callback instead.
// ///
// /// The character callback behaves as system text input normally does and will
// /// not be called if modifier keys are held down that would prevent normal text
// /// input on that platform, for example a Super (Command) key on macOS or Alt key
// /// on Windows.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, unsigned int codepoint)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWcharfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_char
// ///
// /// @glfw3 Added window handle parameter and return value.
// ///
// /// @ingroup input
// GLFWAPI GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun callback);

// /// Sets the mouse button callback.
// ///
// /// This function sets the mouse button callback of the specified window, which
// /// is called when a mouse button is pressed or released.
// ///
// /// When a window loses input focus, it will generate synthetic mouse button
// /// release events for all pressed mouse buttons. You can tell these events
// /// from user-generated events by the fact that the synthetic ones are generated
// /// after the focus loss event has been processed, i.e. after the
// /// [window focus callback](@ref glfwSetWindowFocusCallback) has been called.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int button, int action, int mods)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWmousebuttonfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: input_mouse_button
// ///
// /// @glfw3 Added window handle parameter and return value.
// ///
// /// @ingroup input
// GLFWAPI GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun callback);

// /// Sets the cursor position callback.
// ///
// /// This function sets the cursor position callback of the specified window,
// /// which is called when the cursor is moved. The callback is provided with the
// /// position, in screen coordinates, relative to the upper-left corner of the
// /// content area of the window.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, double xpos, double ypos);
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWcursorposfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_pos
// /// Replaces `glfwSetMousePosCallback`.
// ///
// /// @ingroup input
// GLFWAPI GLFWcursorposfun glfwSetCursorPosCallback(GLFWwindow* window, GLFWcursorposfun callback);

// /// Sets the cursor enter/leave callback.
// ///
// /// This function sets the cursor boundary crossing callback of the specified
// /// window, which is called when the cursor enters or leaves the content area of
// /// the window.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int entered)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWcursorenterfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: cursor_enter
// ///
// ///
// /// @ingroup input
// GLFWAPI GLFWcursorenterfun glfwSetCursorEnterCallback(GLFWwindow* window, GLFWcursorenterfun callback);

// /// Sets the scroll callback.
// ///
// /// This function sets the scroll callback of the specified window, which is
// /// called when a scrolling device is used, such as a mouse wheel or scrolling
// /// area of a touchpad.
// ///
// /// The scroll callback receives all scrolling input, like that from a mouse
// /// wheel or a touchpad scrolling area.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new scroll callback, or null to remove the
// /// currently set callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, double xoffset, double yoffset)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWscrollfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: scrolling
// /// Replaces `glfwSetMouseWheelCallback`.
// ///
// /// @ingroup input
// GLFWAPI GLFWscrollfun glfwSetScrollCallback(GLFWwindow* window, GLFWscrollfun callback);

// /// Sets the path drop callback.
// ///
// /// This function sets the path drop callback of the specified window, which is
// /// called when one or more dragged paths are dropped on the window.
// ///
// /// Because the path array and its strings may have been generated specifically
// /// for that event, they are not guaranteed to be valid after the callback has
// /// returned. If you wish to use them after the callback returns, you need to
// /// make a deep copy.
// ///
// /// @param[in] window The window whose callback to set.
// /// @param[in] callback The new file drop callback, or null to remove the
// /// currently set callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(GLFWwindow* window, int path_count, const char* paths[])
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWdropfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// wayland: File drop is currently unimplemented.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: path_drop
// ///
// ///
// /// @ingroup input
// GLFWAPI GLFWdropfun glfwSetDropCallback(GLFWwindow* window, GLFWdropfun callback);

// /// Returns whether the specified joystick is present.
// ///
// /// This function returns whether the specified joystick is present.
// ///
// /// There is no need to call this function before other functions that accept
// /// a joystick ID, as they all check for presence before performing any other
// /// work.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @return `GLFW_TRUE` if the joystick is present, or `GLFW_FALSE` otherwise.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick
// /// Replaces `glfwGetJoystickParam`.
// ///
// /// @ingroup input
// GLFWAPI int glfwJoystickPresent(int jid);

// /// Returns the values of all axes of the specified joystick.
// ///
// /// This function returns the values of all axes of the specified joystick.
// /// Each element in the array is a value between -1.0 and 1.0.
// ///
// /// If the specified joystick is not present this function will return null
// /// but will not generate an error. This can be used instead of first calling
// /// @ref glfwJoystickPresent.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @param[out] count Where to store the number of axis values in the returned
// /// array. This is set to zero if the joystick is not present or an error
// /// occurred.
// /// @return An array of axis values, or null if the joystick is not present or
// /// an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned array is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected or the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick_axis
// /// Replaces `glfwGetJoystickPos`.
// ///
// /// @ingroup input
// GLFWAPI const float* glfwGetJoystickAxes(int jid, int* count);

// /// Returns the state of all buttons of the specified joystick.
// ///
// /// This function returns the state of all buttons of the specified joystick.
// /// Each element in the array is either `GLFW_PRESS` or `GLFW_RELEASE`.
// ///
// /// For backward compatibility with earlier versions that did not have @ref
// /// glfwGetJoystickHats, the button array also includes all hats, each
// /// represented as four buttons. The hats are in the same order as returned by
// /// __glfwGetJoystickHats__ and are in the order _up_, _right_, _down_ and
// /// _left_. To disable these extra buttons, set the @ref
// /// GLFW_JOYSTICK_HAT_BUTTONS init hint before initialization.
// ///
// /// If the specified joystick is not present this function will return null
// /// but will not generate an error. This can be used instead of first calling
// /// @ref glfwJoystickPresent.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @param[out] count Where to store the number of button states in the returned
// /// array. This is set to zero if the joystick is not present or an error
// /// occurred.
// /// @return An array of button states, or null if the joystick is not present
// /// or an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned array is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected or the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick_button
// ///
// /// @glfw3 Changed to return a dynamic array.
// ///
// /// @ingroup input
// GLFWAPI const unsigned char* glfwGetJoystickButtons(int jid, int* count);

// /// Returns the state of all hats of the specified joystick.
// ///
// /// This function returns the state of all hats of the specified joystick.
// /// Each element in the array is one of the following values:
// ///
// /// Name                  | Value
// /// ----                  | -----
// /// `GLFW_HAT_CENTERED`   | 0
// /// `GLFW_HAT_UP`         | 1
// /// `GLFW_HAT_RIGHT`      | 2
// /// `GLFW_HAT_DOWN`       | 4
// /// `GLFW_HAT_LEFT`       | 8
// /// `GLFW_HAT_RIGHT_UP`   | `GLFW_HAT_RIGHT` \| `GLFW_HAT_UP`
// /// `GLFW_HAT_RIGHT_DOWN` | `GLFW_HAT_RIGHT` \| `GLFW_HAT_DOWN`
// /// `GLFW_HAT_LEFT_UP`    | `GLFW_HAT_LEFT` \| `GLFW_HAT_UP`
// /// `GLFW_HAT_LEFT_DOWN`  | `GLFW_HAT_LEFT` \| `GLFW_HAT_DOWN`
// ///
// /// The diagonal directions are bitwise combinations of the primary (up, right,
// /// down and left) directions and you can test for these individually by ANDing
// /// it with the corresponding direction.
// ///
// /// @code
// /// if (hats[2] & GLFW_HAT_RIGHT)
// /// {
// ///     // State of hat 2 could be right-up, right or right-down
// /// }
// /// @endcode
// ///
// /// If the specified joystick is not present this function will return null
// /// but will not generate an error. This can be used instead of first calling
// /// @ref glfwJoystickPresent.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @param[out] count Where to store the number of hat states in the returned
// /// array. This is set to zero if the joystick is not present or an error
// /// occurred.
// /// @return An array of hat states, or null if the joystick is not present
// /// or an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned array is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected, this function is called again for that joystick or the library
// /// is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick_hat
// ///
// ///
// /// @ingroup input
// GLFWAPI const unsigned char* glfwGetJoystickHats(int jid, int* count);

// /// Returns the name of the specified joystick.
// ///
// /// This function returns the name, encoded as UTF-8, of the specified joystick.
// /// The returned string is allocated and freed by GLFW. You should not free it
// /// yourself.
// ///
// /// If the specified joystick is not present this function will return null
// /// but will not generate an error. This can be used instead of first calling
// /// @ref glfwJoystickPresent.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @return The UTF-8 encoded name of the joystick, or null if the joystick
// /// is not present or an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned string is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected or the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick_name
// ///
// ///
// /// @ingroup input
// GLFWAPI const char* glfwGetJoystickName(int jid);

// /// Returns the SDL compatible GUID of the specified joystick.
// ///
// /// This function returns the SDL compatible GUID, as a UTF-8 encoded
// /// hexadecimal string, of the specified joystick. The returned string is
// /// allocated and freed by GLFW. You should not free it yourself.
// ///
// /// The GUID is what connects a joystick to a gamepad mapping. A connected
// /// joystick will always have a GUID even if there is no gamepad mapping
// /// assigned to it.
// ///
// /// If the specified joystick is not present this function will return null
// /// but will not generate an error. This can be used instead of first calling
// /// @ref glfwJoystickPresent.
// ///
// /// The GUID uses the format introduced in SDL 2.0.5. This GUID tries to
// /// uniquely identify the make and model of a joystick but does not identify
// /// a specific unit, e.g. all wired Xbox 360 controllers will have the same
// /// GUID on that platform. The GUID for a unit may vary between platforms
// /// depending on what hardware information the platform specific APIs provide.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @return The UTF-8 encoded GUID of the joystick, or null if the joystick
// /// is not present or an error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized, glfw.Error.InvalidEnum and glfw.Error.PlatformError.
// ///
// /// @pointer_lifetime The returned string is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected or the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: gamepad
// ///
// ///
// /// @ingroup input
// GLFWAPI const char* glfwGetJoystickGUID(int jid);

// /// Sets the user pointer of the specified joystick.
// ///
// /// This function sets the user-defined pointer of the specified joystick. The
// /// current value is retained until the joystick is disconnected. The initial
// /// value is null.
// ///
// /// This function may be called from the joystick callback, even for a joystick
// /// that is being disconnected.
// ///
// /// @param[in] jid The joystick whose pointer to set.
// /// @param[in] pointer The new value.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread. Access is not
// /// synchronized.
// ///
// /// see also: joystick_userptr, glfwGetJoystickUserPointer
// ///
// ///
// /// @ingroup input
// GLFWAPI void glfwSetJoystickUserPointer(int jid, void* pointer);

// /// Returns the user pointer of the specified joystick.
// ///
// /// This function returns the current value of the user-defined pointer of the
// /// specified joystick. The initial value is null.
// ///
// /// This function may be called from the joystick callback, even for a joystick
// /// that is being disconnected.
// ///
// /// @param[in] jid The joystick whose pointer to return.
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function may be called from any thread. Access is not
// /// synchronized.
// ///
// /// see also: joystick_userptr, glfwSetJoystickUserPointer
// ///
// ///
// /// @ingroup input
// GLFWAPI void* glfwGetJoystickUserPointer(int jid);

// /// Returns whether the specified joystick has a gamepad mapping.
// ///
// /// This function returns whether the specified joystick is both present and has
// /// a gamepad mapping.
// ///
// /// If the specified joystick is present but does not have a gamepad mapping
// /// this function will return `GLFW_FALSE` but will not generate an error. Call
// /// @ref glfwJoystickPresent to check if a joystick is present regardless of
// /// whether it has a mapping.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @return `GLFW_TRUE` if a joystick is both present and has a gamepad mapping,
// /// or `GLFW_FALSE` otherwise.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: gamepad, glfwGetGamepadState
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwJoystickIsGamepad(int jid);

// /// Sets the joystick configuration callback.
// ///
// /// This function sets the joystick configuration callback, or removes the
// /// currently set callback. This is called when a joystick is connected to or
// /// disconnected from the system.
// ///
// /// For joystick connection and disconnection events to be delivered on all
// /// platforms, you need to call one of the [event processing](@ref events)
// /// functions. Joystick disconnection may also be detected and the callback
// /// called by joystick functions. The function will then return whatever it
// /// returns if the joystick is not present.
// ///
// /// @param[in] callback The new callback, or null to remove the currently set
// /// callback.
// /// @return The previously set callback, or null if no callback was set or the
// /// library had not been [initialized](@ref intro_init).
// ///
// /// @callback_signature
// /// @code
// /// void function_name(int jid, int event)
// /// @endcode
// /// For more information about the callback parameters, see the
// /// [function pointer type](@ref GLFWjoystickfun).
// ///
// /// Possible errors include glfw.Error.NotInitialized.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: joystick_event
// ///
// ///
// /// @ingroup input
// GLFWAPI GLFWjoystickfun glfwSetJoystickCallback(GLFWjoystickfun callback);

// /// Adds the specified SDL_GameControllerDB gamepad mappings.
// ///
// /// This function parses the specified ASCII encoded string and updates the
// /// internal list with any gamepad mappings it finds. This string may
// /// contain either a single gamepad mapping or many mappings separated by
// /// newlines. The parser supports the full format of the `gamecontrollerdb.txt`
// /// source file including empty lines and comments.
// ///
// /// See @ref gamepad_mapping for a description of the format.
// ///
// /// If there is already a gamepad mapping for a given GUID in the internal list,
// /// it will be replaced by the one passed to this function. If the library is
// /// terminated and re-initialized the internal list will revert to the built-in
// /// default.
// ///
// /// @param[in] string The string containing the gamepad mappings.
// /// @return `GLFW_TRUE` if successful, or `GLFW_FALSE` if an
// /// error occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidValue.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: gamepad, glfwJoystickIsGamepad, glfwGetGamepadName
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwUpdateGamepadMappings(const char* string);

// /// Returns the human-readable gamepad name for the specified joystick.
// ///
// /// This function returns the human-readable name of the gamepad from the
// /// gamepad mapping assigned to the specified joystick.
// ///
// /// If the specified joystick is not present or does not have a gamepad mapping
// /// this function will return null but will not generate an error. Call
// /// @ref glfwJoystickPresent to check whether it is present regardless of
// /// whether it has a mapping.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @return The UTF-8 encoded name of the gamepad, or null if the
// /// joystick is not present, does not have a mapping or an
// /// error occurred.
// ///
// /// @pointer_lifetime The returned string is allocated and freed by GLFW. You
// /// should not free it yourself. It is valid until the specified joystick is
// /// disconnected, the gamepad mappings are updated or the library is terminated.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: gamepad, glfwJoystickIsGamepad
// ///
// ///
// /// @ingroup input
// GLFWAPI const char* glfwGetGamepadName(int jid);

// /// Retrieves the state of the specified joystick remapped as a gamepad.
// ///
// /// This function retrieves the state of the specified joystick remapped to
// /// an Xbox-like gamepad.
// ///
// /// If the specified joystick is not present or does not have a gamepad mapping
// /// this function will return `GLFW_FALSE` but will not generate an error. Call
// /// @ref glfwJoystickPresent to check whether it is present regardless of
// /// whether it has a mapping.
// ///
// /// The Guide button may not be available for input as it is often hooked by the
// /// system or the Steam client.
// ///
// /// Not all devices have all the buttons or axes provided by @ref
// /// GLFWgamepadstate. Unavailable buttons and axes will always report
// /// `GLFW_RELEASE` and 0.0 respectively.
// ///
// /// @param[in] jid The [joystick](@ref joysticks) to query.
// /// @param[out] state The gamepad input state of the joystick.
// /// @return `GLFW_TRUE` if successful, or `GLFW_FALSE` if no joystick is
// /// connected, it has no gamepad mapping or an error
// /// occurred.
// ///
// /// Possible errors include glfw.Error.NotInitialized and glfw.Error.InvalidEnum.
// ///
// /// @thread_safety This function must only be called from the main thread.
// ///
// /// see also: gamepad, glfwUpdateGamepadMappings, glfwJoystickIsGamepad
// ///
// ///
// /// @ingroup input
// GLFWAPI int glfwGetGamepadState(int jid, GLFWgamepadstate* state);
