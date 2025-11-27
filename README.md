# VectorEngine - A physics engine built in Zig and Raylib

This is a physics engine build in [Zig](https://ziglang.org) and [Raylib-Zig](https://github.com/raylib-zig/raylib-zig). The key choice for this is because the *explicit allocator model* in Zig makes it easy to design memory systems that works well while developing physics workloads. You can also build for multiple platforms from a single maschine. Raylib was part of this project because it is easy and simple to use.


## Download
Download this project from the releases tab.

### Compilation
To compile project you need to have *zig-0.16.0-dev-1484* installed. 

First clone this project and enter it:
```bash
git clone https://github.com/PrathamGhaywat/vector-engine.git


cd vector-engine
```

Then proceed to build this project:
```bash
zig build -Doptimize=ReleaseFast
```
after that you will see a zig-out/bin folder. inside bin there will be a Project.exe. Run that to start the application


## License
This is licensed under Apache License 2.0


