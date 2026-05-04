# sparea

Zig library for the area (in steradians) of a polygon on the unit
sphere. Two complementary algorithms with automatic dispatch based
on hemisphere containment.

## Installation

Requires Zig **0.15.2** or newer (CI tests both 0.15.2 and 0.16.0).

Fetch the package into your project:

```sh
zig fetch --save https://github.com/<your-handle>/sphere_area/archive/refs/tags/v0.1.0.tar.gz
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

const verts = [_]sa.LatLng{
    .init(0.0, 0.0),
    .init(0.0, std.math.pi / 2.0),
    .init(std.math.pi / 2.0, 0.0),
};
const area = try sa.polygon_area(f64, &verts); // π/2
```

`polygon_area` accepts a slice of `Vec3` *or* `LatLng` —
comptime-dispatched on the element type, no runtime branch.

## Algorithms

- **cross** — Van Oosterom–Strackee triangle formula, fan-triangulated
  around the spherical centroid. Numerically tight; the preferred
  path for hemisphere-contained polygons.
- **angle** — Chamberlain–Duquette per-edge half-angle-latitude
  formula. Naturally handles polygons spanning more than a
  hemisphere or having non-adjacent antipodal vertices.

`polygon_area` auto-dispatches between the two based on a
hemisphere-containment check. To force one path explicitly, call
`area_cross.signed_area(comptime T, verts)` or
`area_angle.signed_area(verts)` directly — they skip the
antipodal-edge / vertex-count validation that `polygon_area`
performs.

## Conventions

- `polygon_area` returns a non-negative area in `[0, 4π)` — the
  area of the region the polygon's traversal encloses. Reversing
  the vertex order yields the complementary region (the two
  values sum to `4π`).
- The kernel functions `area_cross.signed_area` /
  `area_angle.signed_area` return the *signed* value (positive for
  CCW as viewed from outside the sphere); pass through
  `polygon.normalize_positive` to fold into `[0, 4π)`.
- `LatLng` stores latitude and longitude in **radians**.

## Performance note for LatLng input

The library forbids allocations, so it can't cache the
`LatLng → Vec3` conversion. On the cross-product path each input
vertex gets converted ~7× per `polygon_area` call (validation,
hemisphere check, centroid pass, per-edge triangle math) — about
~28 trig ops per vertex vs the theoretical minimum of ~4. Vec3
input has no such overhead (the conversion is identity).

If you call `polygon_area` repeatedly on the same LatLng polygon,
convert it to `Vec3` once at your call site:

```zig
var verts_v: [N]sa.Vec3 = undefined;
for (verts_ll, &verts_v) |ll, *v| v.* = sa.vertex.as(sa.Vec3, ll);
const area = try sa.polygon_area(f64, &verts_v);
```

For one-shot LatLng calls the overhead doesn't matter.

## Errors

- `error.TooFewVertices` — polygon has fewer than 3 vertices.
- `error.AntipodalEdge` — two consecutive vertices are
  (near-)antipodal, making the geodesic between them ambiguous.

## Development

See [dev.md](dev.md) for build, test, and coverage instructions.

## License

MIT — see [license](license).
