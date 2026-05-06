//! Public API for the sparea library.

const builtin = @import("builtin");

const _polygon = @import("polygon.zig");
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

pub const Vec3 = _vec3.Vec3;
pub const LatLng = _latlng.LatLng;
pub const polygon_area = _polygon.polygon_area;

/// Vec3 ↔ LatLng coercion. Re-exported so callers can pre-convert
/// LatLng polygons to Vec3 once when calling `polygon_area`
/// repeatedly on the same geometry — the cross path otherwise
/// re-runs the LatLng→Vec3 trig several times per vertex per call.
pub const vertex = @import("vertex.zig");

/// Tolerance constants — every numerical-judgment choice the
/// library makes lives here. Tweaks happen in this one spot.
pub const tol = struct {
    /// Squared-magnitude threshold for the antipodal-edge check.
    /// `‖v_i + v_{i+1}‖²` must exceed this to be accepted; for
    /// unit vectors this corresponds to angular distance < π −
    /// √(2·ε) ≈ within ~0.0026° of antipodal.
    pub const ANTIPODAL: f64 = 1.0e-9;

    /// Hemisphere-containment threshold for the auto-dispatch
    /// logic. A polygon takes the high-precision centroid-fan
    /// cross-product path only if every vertex is at least this
    /// far (in dot product against the centroid direction) from
    /// the equator of the centroid hemisphere.
    pub const HEMISPHERE: f64 = 1.0e-6;
};

test {
    _ = @import("tests/all.zig");
}
