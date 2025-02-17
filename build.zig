const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const use_ssl = b.option(bool, "use-ssl", "Enable SSL support") orelse false;
    const enable_examples = b.option(bool, "enable-examples", "Build examples") orelse false;
    const enable_tests = b.option(bool, "enable-tests", "Build test suite") orelse false;
    const enable_async_tests = b.option(bool, "enable-async-tests", "Enable asynchronous tests") orelse false;

    const hiredis_dep = b.dependency("hiredis", .{});
    const hiredis_path = hiredis_dep.path(".");

    const hiredis_sources = &[_][]const u8{
        "alloc.c",
        "async.c",
        "hiredis.c",
        "net.c",
        "read.c",
        "sds.c",
        "sockcompat.c",
    };

    const lib = b.addStaticLibrary(.{
        .name = "hiredis",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    for (hiredis_sources) |source| {
        lib.addCSourceFile(.{
            .file = hiredis_dep.path(source),
            .flags = &[_][]const u8{ "-std=c99", "-Wall", "-Wextra", "-Werror" },
        });
    }

    const platform_libs = switch (target.result.os.tag) {
        .windows => &[_][]const u8{ "ws2_32", "crypt32" },
        .freebsd => &[_][]const u8{"m"},
        .solaris => &[_][]const u8{"socket"},
        else => &[_][]const u8{},
    };
    for (platform_libs) |libname| {
        lib.linkSystemLibrary(libname);
    }

    lib.installHeadersDirectory(hiredis_path, "", .{
        .include_extensions = &.{
            "alloc.h",
            "async.h",
            "hiredis.h",
            "net.h",
            "read.h",
            "sds.h",
            "sockcompat.h",
        },
    });
    lib.addIncludePath(hiredis_path);
    b.installArtifact(lib);

    const hiredis_zig = b.addTranslateC(.{
        .root_source_file = hiredis_dep.path("hiredis.h"),
        .target = target,
        .optimize = optimize,
    });
    //hiredis_zig.addIncludePath(hiredis_path);

    const hiredis_mod = hiredis_zig.addModule("hiredis");
    hiredis_mod.linkLibrary(lib);

    const ssl_lib = b.addStaticLibrary(.{
        .name = "hiredis_ssl",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    if (use_ssl) {
        lib.linkSystemLibrary("ssl");
        lib.linkSystemLibrary("crypto");

        ssl_lib.addCSourceFile(.{
            .file = hiredis_dep.path("ssl.c"),
            .flags = &[_][]const u8{ "-std=c99", "-Wall", "-Wextra", "-Werror" },
        });
        ssl_lib.linkLibrary(lib);
        ssl_lib.linkSystemLibrary("ssl");
        ssl_lib.linkSystemLibrary("crypto");

        ssl_lib.installHeadersDirectory(hiredis_path, "", .{ .include_extensions = &.{"hiredis_ssl.h"} });
        b.installArtifact(ssl_lib);

        const hiredis_ssl_zig = b.addTranslateC(.{
            .root_source_file = hiredis_dep.path("hiredis_ssl.h"),
            .target = target,
            .optimize = optimize,
        });
        //hiredis_ssl_zig.addIncludePath(hiredis_path);

        const hiredis_ssl_mod = hiredis_ssl_zig.addModule("hiredis-ssl");
        hiredis_ssl_mod.linkLibrary(ssl_lib);
    }

    if (enable_examples) {
        const example = try getHiredisExecutable(b, target, optimize, hiredis_path, "examples/example.c", "hiredis-example");
        example.linkLibrary(lib);

        b.installArtifact(example);

        if (use_ssl) {
            const example_ssl = try getHiredisExecutable(b, target, optimize, hiredis_path, "examples/example-ssl.c", "hiredis-example-ssl");
            example_ssl.linkLibrary(lib);
            example_ssl.linkLibrary(ssl_lib);

            b.installArtifact(example_ssl);
        }
    }

    if (enable_tests) {
        const test_suite = try getHiredisExecutable(b, target, optimize, hiredis_path, "test.c", "hiredis-test");
        
        if (use_ssl) {
            test_suite.linkLibrary(ssl_lib);
            test_suite.defineCMacro("HIREDIS_TEST_SSL", "1");
        }

        if (enable_async_tests) {
            test_suite.linkSystemLibrary("event");
            test_suite.defineCMacro("HIREDIS_TEST_ASYNC", "1");
        }

        test_suite.linkLibrary(lib);

        b.installArtifact(test_suite);
    }
}

fn getHiredisExecutable(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, hiredis_path: std.Build.LazyPath, sub_path: []const u8, name: []const u8) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.addCSourceFile(.{
        .file = b.path(sub_path),
    });
    exe.addIncludePath(hiredis_path);

    return exe;
}
