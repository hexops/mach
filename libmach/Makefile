build/libmach.dylib: ../build.zig ../src/*.zig ../src/**/*.zig
	cd ..; zig build

test: test.c build/libmach.dylib
	clang -L./build -lmach -o test test.c

test_c: test
	# my best attempt at cross-platform dynamic linking (for now)
	DYLD_LIBRARY_PATH=./build LD_LIBRARY_OATH=./build ./test

test_lisp: build/libmach.dylib
	sbcl --load test.lisp
