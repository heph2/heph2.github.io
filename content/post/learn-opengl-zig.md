+++
author = "Marco Bauce"
title = "Learn OpenGL with Zig"
date = "2024-12-01"
description = "OpenGL Journey with Zig!"
tags = [
    "zig",
	"opengl",
	"macos",
	"nix",	
]
+++

This will be a series of articles about my journey on learning a bit
of OpenGL using zig, instead of C/C++.
A bit of context.

While i was searching the best online resources for learning opengl, i
found https://learnopengl.com/, which seems to be the most complete
and definetely the best for beginners.

Meanwhile, a friend of mine point me out about a online workshop by
[Loris Cro](https://kristoff.it) on [Zig](https://ziglang.com).

So i thought, why shouldn't i combine those two and try to learn opengl using zig.
In this article i'll show you how to setup the dev environment specifically for zig.

## Premises
This series of articles doesn't have the presumption to teach you
something. I'm myself learning both zig and OpenGL. However i may take
something for granted.

## Requirements
- Zig (0.13)
- GLFW
- OpenGL binding generator (es. Glad)

Basically for working with OpenGL, you need something that handles the
context, windows and user inputs.
From https://learnopengl.com/Getting-started/Creating-a-window

>GLFW is a library, written in C, specifically targeted at
>OpenGL. GLFW gives us the bare necessities required for rendering
>goodies to the screen. It allows us to create an OpenGL context,
>define window parameters, and handle user input, which is plenty
>enough for our purposes.

Here we have two path that we can follow.
The first one is using the native zig bindings from [Mach](https://machengine.org/)
https://github.com/slimsag/mach-glfw

This is the path that i didn't follow because i want to experiment
myself one of the most acclaimed features of Zig, the C/C++ interoperability.

The second one, which i follow, is using
https://github.com/slimsag/glfw This basically is a porting of the C
library using zig as build system (instead of cmake or whatever).

### GLFW

First thing first we need to fetch the dependency, which is as easy as
```bash
zig fetch --save git+https://github.com/slimsag/glfw
```

This will generate a `build.zig.zon` which list the dependencies fetched.
```zig
.dependencies = .{
    .glfw = .{
        .url = "git+https://github.com/slimsag/glfw.git#e6f377baed70a7bef9fa08d808f40b64c5136bf6",
        .hash = "1220c15e66c13f9633fcfd50b5ed265f74f2950c98b1f1defd66298fa027765e0190",
    },
},
```

From there we can leverage the `build.zig` written by `slimsag` and
link `GLFW` within our zig program.

```zig
const glfw = b.dependency("glfw", .{ .target = target, .optimize = optimize });
exe.linkLibrary(glfw.artifact("glfw"));
```

(don't worry, i'll link the entire repo at the end of the article.)

Finally this allow us to import in our `src/main.zig` `GLFW`
```zig
const glfw = @import("glfw");
```

### OpenGL bindings
Before starting my journey with OpenGL i thought that opengl was a
simple library, but it's not!  OpenGL's API defines signatures and
name of functions, but they need to be find at runtime, and this is
totally OS/GPU dependant.


{{< css.inline >}}
<style>
.canon { background: white; width: 100%; height: auto; }
</style>
{{< /css.inline >}}
