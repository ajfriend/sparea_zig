//! Per-edge spherical-polygon area via the Chamberlain–Duquette
//! (JPL, 2007) angle formula — sometimes labeled "Cagnoli" in
//! D3-geo and elsewhere; that attribution is historically wrong.
//! No fan triangulation — each edge contributes a signed term that
//! sums to the polygon's signed area. Naturally handles polygons
//! that span more than a hemisphere or have antipodal vertices
//! that aren't adjacent. Returns the raw signed sum; caller
//! normalizes if desired.
//!
//! The half-angle latitude trick (`φ' = φ/2 + π/4`) makes the
//! formula numerically well-behaved at the poles (where longitude
//! is undefined): one of `sin(φ')` / `cos(φ')` is 1 and the other
//! is 0, collapsing the atan2 cleanly.
//!
//! Sign convention: the raw per-edge sum lives in roughly
//! `(-4π, 4π)`, whereas the centroid-fan formula in `area_cross.zig`
//! returns values in `(-2π, 2π]`. The two paths differ by a
//! multiple of `4π` (typically `0` or `±4π`) on any polygon both
//! can compute, and agree after `normalize_positive`.
//!
//! The `±4π` jumps happen even on small hemispheric polygons
//! whenever an edge crosses the antimeridian — the longitude
//! difference `d` flips through `±π`, where `atan2(0, −x) = π`
//! contributes a full `2π` to a single edge term that "should"
//! have been near zero. Example: an octant `[NP, (0,1,0),
//! (-1,0,0)]` traversed CCW from outside has true area `+π/2`,
//! but the angle formula returns `-7π/2` because edge 3 crosses
//! the antimeridian. `normalize_positive(-7π/2) = π/2`.
//!
//! We deliberately do *not* fold the angle-formula result here —
//! callers that need a single canonical magnitude should pass
//! the result through `polygon.normalize_positive` to get a
//! value in `[0, 4π)`.

const std = @import("std");
const vec3 = @import("vec3.zig");
const latlng = @import("latlng.zig");
const adder = @import("adder.zig");

const Vec3 = vec3.Vec3;
const LatLng = latlng.LatLng;
const Adder = adder.Adder;

/// Single-edge contribution to the angle-formula polygon area.
pub fn edge_area(a: LatLng, b: LatLng) f64 {
    const lat_a = a.lat / 2.0 + std.math.pi / 4.0;
    const lat_b = b.lat / 2.0 + std.math.pi / 4.0;
    const sa = @sin(lat_a) * @sin(lat_b);
    const ca = @cos(lat_a) * @cos(lat_b);

    const d = b.lng - a.lng;
    const sd = @sin(d);
    const cd = @cos(d);

    return -2.0*std.math.atan2(sa*sd, sa*cd + ca);
}

/// Per-edge sum over a polygon's vertices. Returns the raw signed
/// value (reversing the polygon's orientation negates the result).
/// No antipodal-edge validation; caller is responsible. Always
/// succeeds for valid input — the angle formula has no failure
/// modes.
pub fn signed_area(verts: []const Vec3) f64 {
    var sum = Adder.init();
    var prev = verts[verts.len - 1].to_lat_lng();
    for (verts) |v| {
        const cur = v.to_lat_lng();
        sum.add(edge_area(prev, cur));
        prev = cur;
    }
    return sum.value();
}
