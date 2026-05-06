//! On windows-msvc, MSVC's libm has no `sincos` symbol, but the LLVM
//! optimizer fuses adjacent `@sin(x)` / `@cos(x)` on the same value
//! into a `sincos(x)` call. We provide the symbol here so
//! `libsparea.lib` links cleanly under MSVC.
//!
//! `noinline` on the helpers prevents the optimizer from inlining
//! them back into the shim and re-fusing into a recursive `sincos`
//! call.
//!
//! Only imported on `*-windows-msvc`; see the comptime guard in
//! `root.zig`.

noinline fn sin_opaque(x: f64) f64 {
    return @sin(x);
}

noinline fn cos_opaque(x: f64) f64 {
    return @cos(x);
}

fn sincos_impl(x: f64, s: *f64, c: *f64) callconv(.c) void {
    s.* = sin_opaque(x);
    c.* = cos_opaque(x);
}

comptime {
    @export(&sincos_impl, .{ .name = "sincos", .linkage = .strong });
}
