# sparea: Spherical Polygon Area

Zig library for the area (in steradians) of a polygon on the unit
sphere. Two complementary algorithms with automatic dispatch based
on hemisphere containment.

## Installation

Requires Zig **0.15.2** or newer (CI tests both 0.15.2 and 0.16.0).

Fetch the package into your project:

```sh
zig fetch --save https://github.com/ajfriend/sparea_zig/archive/refs/tags/v0.5.0.tar.gz
```

This writes a `.sparea` entry into your `build.zig.zon` with the
content hash filled in. Then in your `build.zig`:

```zig
const sparea = b.dependency("sparea", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("sparea", sparea.module("sparea"));
```

Now `@import("sparea")` is available in your sources.

## Quick start

```zig
const std = @import("std");
const sa = @import("sparea");

const verts = [_]sa.Vec3{
    .init(1, 0, 0),
    .init(0, 1, 0),
    .init(0, 0, 1),
};
const area = try sa.polygon_area(&verts, .{}); // π/2
```

`polygon_area` takes `[]const Vec3` and an `Options` struct (defaults
to `.{}`). If your data is `LatLng`-shaped, convert at the call site:

```zig
var verts_v: [N]sa.Vec3 = undefined;
for (verts_ll, &verts_v) |ll, *v| v.* = ll.to_vec3();
const area = try sa.polygon_area(&verts_v, .{});
```

## Options

`sa.Options` carries two knobs:

- `algo: Algorithm = .auto` — kernel selection.
  - `.auto` — hemisphere-containment check picks `cross` for tight
    polygons, `angle` otherwise. The default for most callers.
  - `.cross` — force the Van Oosterom–Strackee centroid-fan
    cross-product kernel. Numerically tight; preferred for
    hemisphere-contained polygons.
  - `.angle` — force the Chamberlain–Duquette per-edge
    half-angle-latitude kernel. Naturally handles polygons spanning
    more than a hemisphere or with non-adjacent antipodal vertices.
- `signed: bool = false` — output sign convention.
  - `false` — fold the result into `[0, 4π)`. Reversing the vertex
    order yields the complementary region.
  - `true` — return the raw signed kernel value (positive for
    CCW-from-outside, negative otherwise).

The antipodal-edge and vertex-count validation runs in all modes. To
bypass validation entirely and consume the kernels directly, call
`area_cross.signed_area(verts)` or `area_angle.signed_area(verts)`.

## Conventions

- `polygon_area` returns a non-negative area in `[0, 4π)` by default
  — the area of the region the polygon's traversal encloses.
  Reversing the vertex order yields the complementary region (the
  two values sum to `4π`). Pass `signed = true` to instead get the
  raw signed value, where the sign carries orientation.
- The kernel functions `area_cross.signed_area` /
  `area_angle.signed_area` return the *signed* value directly
  (positive for CCW as viewed from outside the sphere); pass
  through `area.normalize_positive` to fold into `[0, 4π)`.
- `LatLng` stores latitude and longitude in **radians**.

## Errors

- `error.TooFewVertices` — polygon has fewer than 3 vertices.
- `error.AntipodalEdge` — two consecutive vertices are
  (near-)antipodal, making the geodesic between them ambiguous.

## Development

See [dev.md](dev.md) for build, test, and coverage instructions.

## License

MIT — see [license](license).
