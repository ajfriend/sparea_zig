# sparea: Spherical Polygon Area

Zig library for the area (in steradians) of a polygon on the unit
sphere. Two complementary algorithms with automatic dispatch based
on hemisphere containment.

## Installation

Requires Zig **0.15.2** or newer (CI tests both 0.15.2 and 0.16.0).

Fetch the package into your project:

```sh
zig fetch --save https://github.com/ajfriend/sparea_zig/archive/refs/tags/v0.4.0.tar.gz
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
const area = try sa.polygon_area(&verts); // π/2
```

`polygon_area` takes `[]const Vec3`. If your data is
`LatLng`-shaped, convert at the call site:

```zig
var verts_v: [N]sa.Vec3 = undefined;
for (verts_ll, &verts_v) |ll, *v| v.* = ll.to_vec3();
const area = try sa.polygon_area(&verts_v);
```

## Algorithms

- **cross** — Van Oosterom–Strackee triangle formula, fan-triangulated
  around the spherical centroid. Numerically tight; the preferred
  path for hemisphere-contained polygons.
- **angle** — Chamberlain–Duquette per-edge half-angle-latitude
  formula. Naturally handles polygons spanning more than a
  hemisphere or having non-adjacent antipodal vertices.

`polygon_area` auto-dispatches between the two based on a
hemisphere-containment check. To force one path explicitly, call
`area_cross.signed_area(verts)` or `area_angle.signed_area(verts)`
directly — they skip the antipodal-edge / vertex-count validation
that `polygon_area` performs.

## Conventions

- `polygon_area` returns a non-negative area in `[0, 4π)` — the
  area of the region the polygon's traversal encloses. Reversing
  the vertex order yields the complementary region (the two
  values sum to `4π`).
- The kernel functions `area_cross.signed_area` /
  `area_angle.signed_area` return the *signed* value (positive for
  CCW as viewed from outside the sphere); pass through
  `area.normalize_positive` to fold into `[0, 4π)`.
- `LatLng` stores latitude and longitude in **radians**.

## Errors

- `error.TooFewVertices` — polygon has fewer than 3 vertices.
- `error.AntipodalEdge` — two consecutive vertices are
  (near-)antipodal, making the geodesic between them ambiguous.

## Development

See [dev.md](dev.md) for build, test, and coverage instructions.

## License

MIT — see [license](license).
