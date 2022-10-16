// fetch.zig - a dependency management solution for zig projects!
// see the repo at https://github.com/bootradev/zig-fetch for more info

const std = @import("std");

// adds a step that will be passed through to the build file
pub fn addStep(
    builder: *std.build.Builder,
    name: []const u8,
    description: []const u8,
) void {
    builder.step(name, description).dependOn(builder.getInstallStep());
}

// adds an option that will be passed through to the build file
pub fn addOption(
    builder: *std.build.Builder,
    comptime T: type,
    name: []const u8,
    description: []const u8,
) void {
    _ = builder.option(T, name, description);
}

pub const GitDependency = struct {
    url: []const u8,
    commit: []const u8,
    recursive: bool = false,
    shallow_branch: ?[]const u8 = null,
};

pub const Dependency = struct {
    name: []const u8,
    vcs: union(enum) {
        git: GitDependency,
    },
};

pub fn fetchAndBuild(
    builder: *std.build.Builder,
    deps_dir: []const u8,
    deps: []const Dependency,
    build_file: []const u8,
) !void {
    // no-op standard options to pass through to build file
    _ = builder.standardTargetOptions(.{});
    _ = builder.standardReleaseOptions();

    const fetch_and_build = try FetchAndBuild.init(builder, deps_dir, deps, build_file);
    builder.getInstallStep().dependOn(&fetch_and_build.step);
}

const FetchAndBuild = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    deps: []const Dependency,
    build_file: []const u8,
    write_fetch_cache: bool,
    run_zig_build: bool,

    fn init(
        builder: *std.build.Builder,
        deps_dir: []const u8,
        deps: []const Dependency,
        build_file: []const u8,
    ) !*FetchAndBuild {
        const fetch_skip = builder.option(
            bool,
            "fetch-skip",
            "Skip fetch dependencies",
        ) orelse false;

        const fetch_only = builder.option(
            bool,
            "fetch-only",
            "Only fetch dependencies",
        ) orelse false;

        const fetch_force = builder.option(
            bool,
            "fetch-force",
            "Force fetch dependencies",
        ) orelse false;

        if (fetch_skip and fetch_only) {
            std.log.err("fetch-skip and fetch-only are mutually exclusive!", .{});
            return error.InvalidOptions;
        }

        var fetch_and_build = try builder.allocator.create(FetchAndBuild);
        fetch_and_build.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "fetch and build", builder.allocator, make),
            .deps = try builder.allocator.dupe(Dependency, deps),
            .build_file = builder.dupe(build_file),
            .write_fetch_cache = false,
            .run_zig_build = !fetch_only,
        };

        const git_available = checkGitAvailable(builder);

        if (!fetch_skip) {
            const fetch_cache = try readFetchCache(builder);

            for (deps) |dep| {
                if (!fetch_force) {
                    if (fetch_cache) |cache| {
                        var dep_in_cache = false;
                        for (cache) |cache_dep| {
                            if (dependencyEql(dep, cache_dep)) {
                                dep_in_cache = true;
                                break;
                            }
                        }
                        if (dep_in_cache) {
                            continue;
                        }
                    }
                }

                const fetch_dir = builder.pathJoin(&.{ builder.build_root, deps_dir, dep.name });
                const recursive_fetch = try RecursiveFetch.init(builder, fetch_dir, fetch_force);
                fetch_and_build.step.dependOn(&recursive_fetch.step);

                switch (dep.vcs) {
                    .git => |git_dep| {
                        if (!git_available) {
                            return error.GitNotAvailable;
                        }
                        const git_fetch = try GitFetch.init(builder, fetch_dir, git_dep);
                        recursive_fetch.step.dependOn(&git_fetch.step);
                    },
                }

                fetch_and_build.write_fetch_cache = true;
            }
        }

        return fetch_and_build;
    }

    fn make(step: *std.build.Step) !void {
        const fetch_and_build = @fieldParentPtr(FetchAndBuild, "step", step);
        const builder = fetch_and_build.builder;

        if (fetch_and_build.write_fetch_cache) {
            try writeFetchCache(builder, fetch_and_build.deps);
        }

        if (fetch_and_build.run_zig_build) {
            const args = try std.process.argsAlloc(builder.allocator);
            defer std.process.argsFree(builder.allocator, args);

            // TODO: this might be platform specific.
            // on windows, 5 args are prepended before the user defined args
            const args_offset = 5;

            var build_args_list = std.ArrayList([]const u8).init(builder.allocator);
            defer build_args_list.deinit();

            try build_args_list.appendSlice(
                &.{ "zig", "build", "--build-file", fetch_and_build.build_file },
            );
            for (args[args_offset..]) |arg| {
                if (std.mem.startsWith(u8, arg, "-Dfetch-skip=") or
                    std.mem.startsWith(u8, arg, "-Dfetch-only=") or
                    std.mem.startsWith(u8, arg, "-Dfetch-force="))
                {
                    continue;
                }
                try build_args_list.append(arg);
            }

            if (fetch_and_build.write_fetch_cache or builder.verbose) {
                std.log.info("building with build file {s}...", .{fetch_and_build.build_file});
            }

            const build_args = build_args_list.items;
            runChildProcess(builder, builder.build_root, build_args, true) catch return;
        }
    }
};

fn getFetchCachePath(builder: *std.build.Builder) []const u8 {
    return builder.pathJoin(&.{ builder.build_root, builder.cache_root, "fetch_cache" });
}

fn readFetchCache(builder: *std.build.Builder) !?[]const Dependency {
    const cache_path = getFetchCachePath(builder);
    const cache_file = std.fs.cwd().openFile(cache_path, .{}) catch return null;
    defer cache_file.close();
    const reader = cache_file.reader();

    var dependencies = std.ArrayList(Dependency).init(builder.allocator);
    var read_buf: [256]u8 = undefined;
    while (true) {
        const name = builder.dupe(reader.readUntilDelimiter(&read_buf, '\n') catch |e| {
            if (e == error.EndOfStream) {
                break;
            } else {
                return e;
            }
        });

        var dependency: Dependency = undefined;
        dependency.name = name;

        const vcs_type = try reader.readUntilDelimiter(&read_buf, '\n');
        if (std.mem.eql(u8, vcs_type, "git")) {
            const url = builder.dupe(try reader.readUntilDelimiter(&read_buf, '\n'));
            const commit = builder.dupe(try reader.readUntilDelimiter(&read_buf, '\n'));
            const recursive = try parseBool(try reader.readUntilDelimiter(&read_buf, '\n'));
            dependency.vcs = .{
                .git = .{
                    .url = url,
                    .commit = commit,
                    .recursive = recursive,
                },
            };
        } else {
            return error.InvalidVcsType;
        }

        try dependencies.append(dependency);
    }

    return dependencies.toOwnedSlice();
}

fn writeFetchCache(builder: *std.build.Builder, deps: []const Dependency) !void {
    const cache_path = getFetchCachePath(builder);
    try std.fs.cwd().makePath(std.fs.path.dirname(cache_path) orelse unreachable);

    const cache_file = try std.fs.cwd().createFile(cache_path, .{});
    const writer = cache_file.writer();

    for (deps) |dep| {
        try writer.print("{s}\n", .{dep.name});
        switch (dep.vcs) {
            .git => |git_dep| {
                try writer.print("git\n", .{});
                try writer.print("{s}\n", .{git_dep.url});
                try writer.print("{s}\n", .{git_dep.commit});
                try writer.print("{}\n", .{git_dep.recursive});
            },
        }
    }
}

const RecursiveFetch = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    dir: []const u8,
    fetch_force: bool,

    pub fn init(
        builder: *std.build.Builder,
        dir: []const u8,
        fetch_force: bool,
    ) !*RecursiveFetch {
        var recursive_fetch = try builder.allocator.create(RecursiveFetch);
        recursive_fetch.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "recursive fetch", builder.allocator, make),
            .dir = dir,
            .fetch_force = fetch_force,
        };
        return recursive_fetch;
    }

    pub fn make(step: *std.build.Step) !void {
        const recursive_fetch = @fieldParentPtr(RecursiveFetch, "step", step);
        const builder = recursive_fetch.builder;

        var dir = try std.fs.openDirAbsolute(recursive_fetch.dir, .{});
        defer dir.close();
        if (dir.openFile("build.zig", .{})) |file| {
            file.close();

            std.log.info("recursively fetching within {s}...", .{recursive_fetch.dir});

            var build_args_list = std.ArrayList([]const u8).init(builder.allocator);
            defer build_args_list.deinit();
            try build_args_list.appendSlice(&.{ "zig", "build", "-Dfetch-only=true" });
            if (builder.verbose) {
                try build_args_list.append("--verbose");
            }
            if (recursive_fetch.fetch_force) {
                try build_args_list.append("-Dfetch-force=true");
            }

            const build_args = build_args_list.items;
            const result = try runChildProcessExec(builder, recursive_fetch.dir, build_args);
            defer builder.allocator.free(result.stdout);
            defer builder.allocator.free(result.stderr);

            try logChildProcessOutput(result.stdout);
            // only log error if it's not related to missing zig-fetch functionality
            if (!std.mem.startsWith(u8, result.stderr, "error: Invalid option: -Dfetch-only")) {
                try logChildProcessOutput(result.stderr);
            }
        } else |_| {}
    }
};

pub const GitFetch = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    dep: GitDependency,
    dir: []const u8,

    pub fn init(
        builder: *std.build.Builder,
        dir: []const u8,
        dep: GitDependency,
    ) !*GitFetch {
        var git_fetch = try builder.allocator.create(GitFetch);
        git_fetch.* = .{
            .builder = builder,
            .step = std.build.Step.init(.custom, "git fetch", builder.allocator, make),
            .dep = dep,
            .dir = dir,
        };
        return git_fetch;
    }

    pub fn make(step: *std.build.Step) !void {
        const git_fetch = @fieldParentPtr(GitFetch, "step", step);
        const builder = git_fetch.builder;

        // TODO: the logging behavior here suppresses important Git progress reports, like:
        //
        // remote: Enumerating objects: 34369, done.
        // remote: Counting objects: 100% (34369/34369), done.
        // remote: Compressing objects: 100% (14619/14619), done.
        // remote: Total 34369 (delta 20763), reused 30144 (delta 19405), pack-reused 0
        // Receiving objects: 100% (34369/34369), 56.13 MiB | 21.65 MiB/s, done.
        // Resolving deltas: 100% (20763/20763), done.
        //
        std.log.info("fetching from git into {s}...", .{git_fetch.dir});

        std.fs.accessAbsolute(git_fetch.dir, .{}) catch {
            const clone_args: []const []const u8 = if (git_fetch.dep.shallow_branch) |branch|
                &.{ "git", "clone", "--depth", "1", "-b", branch, git_fetch.dep.url, git_fetch.dir }
            else
                &.{ "git", "clone", git_fetch.dep.url, git_fetch.dir };

            try runChildProcess(builder, builder.build_root, clone_args, builder.verbose);
        };

        if (git_fetch.dep.recursive) {
            const submodule_args = &.{ "git", "submodule", "update", "--init", "--recursive" };
            try runChildProcess(builder, git_fetch.dir, submodule_args, builder.verbose);
        }

        // TODO: zig-fetch does not currently correctly handle updating the git repo if it already
        // exists and the revision has changed. It should run something akin to `git fetch` (adding
        // `--depth 1` if a shallow clone) followed by `git checkout`. This is a network access,
        // though, so should be ran rarely.
        const checkout_args = &.{ "git", "checkout", git_fetch.dep.commit };
        try runChildProcess(builder, git_fetch.dir, checkout_args, builder.verbose);
    }
};

fn checkGitAvailable(builder: *std.build.Builder) bool {
    const args = &.{ "git", "--version" };
    runChildProcess(builder, builder.build_root, args, builder.verbose) catch return false;
    return true;
}

fn runChildProcess(
    builder: *std.build.Builder,
    cwd: []const u8,
    args: []const []const u8,
    log_output: bool,
) !void {
    try logCommand(builder, args);

    var child_process = std.ChildProcess.init(args, builder.allocator);
    child_process.cwd = cwd;
    child_process.env_map = builder.env_map;
    child_process.stdin_behavior = .Ignore;
    if (!log_output) {
        child_process.stdout_behavior = .Ignore;
        child_process.stderr_behavior = .Ignore;
    }

    switch (try child_process.spawnAndWait()) {
        .Exited => |code| if (code != 0) {
            return error.RunChildProcessFailed;
        },
        else => {
            return error.RunChildProcessFailed;
        },
    }
}

fn runChildProcessExec(
    builder: *std.build.Builder,
    cwd: []const u8,
    args: []const []const u8,
) !std.ChildProcess.ExecResult {
    try logCommand(builder, args);

    return try std.ChildProcess.exec(.{
        .allocator = builder.allocator,
        .argv = args,
        .cwd = cwd,
        .env_map = builder.env_map,
    });
}

fn logCommand(builder: *std.build.Builder, args: []const []const u8) !void {
    if (builder.verbose) {
        var command = std.ArrayList(u8).init(builder.allocator);
        defer command.deinit();

        try command.appendSlice("RUNNING COMMAND:");
        for (args) |arg| {
            try command.append(' ');
            try command.appendSlice(arg);
        }

        std.log.info("{s}", .{command.items});
    }
}

fn logChildProcessOutput(output: []const u8) !void {
    try std.io.getStdOut().writer().writeAll(output);
}

pub fn dependencyEql(a: Dependency, b: Dependency) bool {
    return std.mem.eql(u8, a.name, b.name) and
        std.meta.activeTag(a.vcs) == std.meta.activeTag(b.vcs) and
        switch (a.vcs) {
        .git => std.mem.eql(u8, a.vcs.git.url, b.vcs.git.url) and
            std.mem.eql(u8, a.vcs.git.commit, b.vcs.git.commit) and
            a.vcs.git.recursive == b.vcs.git.recursive,
    };
}

fn parseBool(str: []const u8) !bool {
    if (std.mem.eql(u8, str, "true")) {
        return true;
    } else if (std.mem.eql(u8, str, "false")) {
        return false;
    } else {
        return error.ParseBoolFailed;
    }
}
