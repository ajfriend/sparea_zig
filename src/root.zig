//! Public API for the sparea library.

const builtin = @import("builtin");

const _area = @import("area.zig");
const _vec3 = @import("vec3.zig");
const _latlng = @import("latlng.zig");

// On windows-msvc, LLVM fuses adjacent `@sin`/`@cos` on the same
// value into a `sincos` call, but MSVC's libm doesn't ship that
// symbol. Pull in a shim that exports `sincos` so `libsparea.lib`
// links cleanly. The `_ = @import(...)` triggers the shim's
// top-level comptime `@export`. Other targets never see the file.
comptime {
    if (builtin.target.os.tag == .windows and builtin.target.abi == .msvc) {
        _ = @import("windows_sincos.zig");
    }
}

/// Errors raised by the sparea library.
pub const SpareaError = error{
    /// A consecutive pair of vertices is antipodal or near-antipodal,
    /// so the geodesic between them is ambiguous and the polygon is
    /// geometrically ill-defined. Insert an intermediate vertex on
    /// the great-circle arc to fix.
    AntipodalEdge,

    /// The polygon has fewer than 3 vertices. A spherical polygon
    /// needs at least 3 vertices to bound a region.
    TooFewVertices,
};

/// Tolerance constants — every numerical-judgment choice the
/// library makes lives here. Tweaks happen in this one spot.
pub const tol = struct {
    /// Squared-magnitude threshold for the antipodal-edge check.
    /// `‖v_i + v_{i+1}‖²` must exceed this to be accepted; for unit
    /// vectors the corresponding angular rejection radius is
    /// √ANTIPODAL ≈ 0.0316 rad (~1.81°) of antipodal.
    pub const ANTIPODAL: f64 = 1.0e-3;

    /// Hemisphere-containment threshold for the auto-dispatch
    /// logic. A polygon takes the centroid-fan cross-product path
    /// only if every vertex's dot product against the centroid is
    /// at least this large — i.e., the vertex sits at least
    /// arcsin(HEMISPHERE) ≈ 1e-3 rad (~0.057°) inside the centroid
    /// hemisphere. Vertices closer to the boundary route to the
    /// angle formula.
    pub const HEMISPHERE: f64 = 1.0e-3;
};


pub const Vec3 = _vec3.Vec3;
pub const LatLng = _latlng.LatLng;
pub const polygon_area = _area.polygon_area;


test {
    _ = @import("tests/all.zig");
}
