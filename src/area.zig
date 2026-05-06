//! Polygon-area public functions: validation, dispatch, and the
//! orientation-normalization helper. The cross / angle kernels
//! this dispatches into live in `area_cross.zig` and
//! `area_angle.zig`.
//!
//! The error set itself (`SpareaError`) is declared in root.zig as
//! the documented public surface; the functions here use inferred
//! error unions (`!f64`) and `return error.X` directly — `error.X`
//! is a global name in Zig, no import needed. Inference produces a
//! set structurally equivalent to root.zig's `SpareaError`.
//!
//! Tolerance constants used here (`tol.ANTIPODAL`, `tol.HEMISPHERE`)
//! live on the `tol` namespace in `root.zig` so all numerical-
//! judgment choices the library makes are centralized in one place.

const std = @import("std");
const vec3 = @import("vec3.zig");
const area_cross = @import("area_cross.zig");
const area_angle = @import("area_angle.zig");
const tol = @import("root.zig").tol;

const Vec3 = vec3.Vec3;

// Polygon-level precondition checks shared by every public entry
// point: at least 3 vertices, and no consecutive antipodal pair.
// Antipodal validation: each edge's endpoints summed must have a
// reasonably non-zero magnitude — for unit vectors, the only way
// to get a tiny sum is if the two are nearly antipodal.
fn check_edges(verts: []const Vec3) !void {
    if (verts.len < 3) return error.TooFewVertices;
    for (0..verts.len) |i| {
        const j = (i + 1) % verts.len;
        const s = verts[i].add(verts[j]);
        if (s.dot(s) < tol.ANTIPODAL) return error.AntipodalEdge;
    }
}

// True if every vertex sits within `tol.HEMISPHERE` of the
// renormalized vertex sum (i.e., the polygon is small enough that
// the centroid-fan cross-product path is well-conditioned).
// Degenerate great-circle-ring polygons (zero vertex sum) return
// false so the dispatcher routes them to the angle formula.
fn is_hemisphere_contained(verts: []const Vec3) bool {
    const c = Vec3.centroid(verts);
    for (verts) |v| {
        if (c.dot(v) < tol.HEMISPHERE) return false;
    }
    return true;
}

/// Normalize a signed area into [0, 4π) — adds 4π if the input is
/// negative. The public `polygon_area` already applies this; reach
/// for it directly when consuming the signed kernel functions
/// (`area_cross.signed_area` / `area_angle.signed_area`).
pub fn normalize_positive(area: f64) f64 {
    if (area < 0) {
        return area + 4.0 * std.math.pi;
    } else {
        return area;
    }
}

/// Area in steradians of a spherical polygon, in `[0, 4π)`.
///
/// Auto-dispatches between algorithms: hemisphere-contained
/// polygons take the cross-product centroid-fan path; polygons
/// that span more of the sphere fall back to the per-edge angle
/// formula. The raw kernel result (signed, depending on
/// orientation) is folded into the positive range before return —
/// callers get the area of the region the polygon's traversal
/// encloses, not a negative value. To recover the signed value,
/// call `area_cross.signed_area` or `area_angle.signed_area`
/// directly.
///
/// Returns `error.TooFewVertices` if the polygon has fewer than 3
/// vertices, or `error.AntipodalEdge` if any consecutive vertex pair
/// is (near-)antipodal.
pub fn polygon_area(verts: []const Vec3) !f64 {
    try check_edges(verts);

    var signed: f64 = undefined;
    if (is_hemisphere_contained(verts)) {
        signed = area_cross.signed_area(verts);
    } else {
        signed = area_angle.signed_area(verts);
    }

    return normalize_positive(signed);
}
