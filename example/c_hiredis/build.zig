const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const hiredis = b.dependency("hiredis", .{ .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "chiredis",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.addCSourceFile(.{
        .file = b.path("main.c"),
    });
    exe.linkLibrary(hiredis.artifact("hiredis"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
