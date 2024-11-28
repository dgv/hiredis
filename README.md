# `build.zig` for hiredis

Provides a package to be used by the zig package manager for C programs

# Status

| Refname   | Hiredis version | Zig `0.12.x` | Zig `0.13.x` | Zig `0.14.0-dev` |
|:----------|:---------------|:------------:|:------------:|:----------------:|
| `1.2.0` | `v1.2.0`       | ✅           | ✅           | ✅               |

# Usage

Add the dependency in your `build.zig.zon` by running the following command:

```
zig fetch --save=hiredis git+https://github.com/afirium/hiredis
```

Then, choose one:

## Option 1: Statically linking hiredis

build.zig:

```
const hiredis = b.dependency("hiredis", .{ .target = target, .optimize = optimize });
exe.linkLibrary(hiredis.artifact("hiredis"));
```

c:

```
#include <hiredis.h>
```

## Option 2: Using from zig with automatic translate-c bindings

build.zig:

```
const hiredis = b.dependency("hiredis", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("hiredis", hiredis.module("hiredis"));
```

zig:

```
const hiredis = @import("hiredis");
```
