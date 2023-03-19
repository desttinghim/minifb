const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const minifb = b.addStaticLibrary(.{
        .name = "minifb",
        .target = target,
        .optimize = optimize,
    });
    minifb.install();
    minifb.linkLibC();
    minifb.linkLibCpp();
    minifb.addIncludePath("src");
    minifb.addIncludePath("include");
    minifb.addCSourceFiles(&.{
        "src/MiniFB_common.c",
        "src/MiniFB_cpp.cpp",
        "src/MiniFB_internal.c",
        "src/MiniFB_timer.c",
    }, &.{});

    minifb.installHeader("include/MiniFB.h", "MiniFB.h");
    minifb.installHeader("include/MiniFB_enums.h", "MiniFB_enums.h");

    const use_gl = b.option(bool, "USE_OPENGL_API", "Use OpenGL for minifb") orelse false;

    if (use_gl) {
        minifb.addCSourceFiles(&.{
            "src/gl/MiniFB_GL.c",
        }, &.{});
    }

    switch (target.getOsTag()) {
        .windows => {
            minifb.addCSourceFiles(&.{
                "src/windows/WinMiniFB.c",
            }, &.{});
        },
        .macos => {
            const use_metal_api = b.option(bool, "USE_METAL_API", "Use metal api for macOS") orelse false;
            const use_inverted_coordinate_system = b.option(bool, "USE_INVERTED_Y_ON_MACOS", "Use inverted y on macOS") orelse false;
            minifb.defineCMacro("USE_METAL_API", if (use_metal_api) "" else null);
            minifb.defineCMacro("USE_INVERTED_Y_ON_MACOS", if (use_inverted_coordinate_system) "" else null);
            minifb.addCSourceFiles(&.{
                "src/macosx/MacMiniFB.m",
                "src/macosx/OSXWindow.m",
                "src/macosx/OSXView.m",
                "src/macosx/OSXViewDelegate.m",
            }, &.{});
        },
        .ios => {
            minifb.addCSourceFiles(&.{
                "src/ios/iOSMiniFB.m",
                "src/ios/iOSView.m",
                "src/ios/iOSViewController.m",
                "src/ios/iOSViewDelegate.m",
            }, &.{});
        },
        .linux => {
            const use_wayland = b.option(bool, "USE_WAYLAND_API", "Use wayland for minifb") orelse true;
            const use_x11 = b.option(bool, "USE_X11_API", "Use X11 for minifb") orelse true;
            if (use_wayland) {
                minifb.linkSystemLibrary("wayland-client");
                minifb.linkSystemLibrary("wayland-cursor");

                minifb.addCSourceFiles(&.{
                    "src/wayland/WaylandMiniFB.c",
                    "src/MiniFB_linux.c",
                }, &.{});
            }

            // Use X11 by default
            if (use_x11) {
                minifb.linkSystemLibrary("X11");
                minifb.addCSourceFiles(&.{
                    "src/x11/X11MiniFB.c",
                    "src/MiniFB_linux.c",
                }, &.{});
            }
        },
        else => |t| {
            std.log.err("Unsupported target {}", .{t});
        },
    }
}
