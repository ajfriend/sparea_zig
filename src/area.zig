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
const root = @import("root.zig");
const tol = root.tol;

const Vec3 = vec3.Vec3;
const Options = root.Options;

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

/// Area in steradians of a spherical polygon.
///
/// `opts.algo` selects the kernel:
///   - `.auto` (default) — hemisphere-contained polygons take the
///     cross-product centroid-fan path; polygons that span more of
///     the sphere fall back to the per-edge angle formula.
///   - `.cross` — force the centroid-fan cross-product kernel.
///   - `.angle` — force the per-edge angle-formula kernel.
///
/// `opts.signed` controls the output sign convention:
///   - `false` (default) — fold the result into `[0, 4π)`. Reversing
///     the vertex order yields the complementary region.
///   - `true` — return the raw signed kernel output (positive for
///     CCW-from-outside, negative otherwise).
///
/// Returns `error.TooFewVertices` if the polygon has fewer than 3
/// vertices, or `error.AntipodalEdge` if any consecutive vertex pair
/// is (near-)antipodal.
pub fn polygon_area(verts: []const Vec3, opts: Options) !f64 {
    try check_edges(verts);

    const signed = switch (opts.algo) {
        .auto => if (is_hemisphere_contained(verts))
            area_cross.signed_area(verts)
        else
            area_angle.signed_area(verts),
        .cross => area_cross.signed_area(verts),
        .angle => area_angle.signed_area(verts),
    };

    return if (opts.signed) signed else normalize_positive(signed);
}
