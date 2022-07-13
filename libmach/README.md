# libmach

Build the `libmach` dynamic library by running `make` (or running `zig build` in the parent directory).
The resulting binary should be located in `libmach/build/`.

Test the functionality of `libmach` using `make test_c` and `make test_lisp`.
These commands use C and Lisp to call into `libmach`, and both should show a blank window for exactly 1 second.

Note: `make test_lisp` requires a relatively recent version of Steel Bank Common Lisp (`sbcl`) to be installed.

You can find the Zig source code for `libmach` in `src/bindings.zig`.
