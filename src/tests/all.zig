//! Aggregator: pulls every test file in this directory into a single
//! compilation unit. Imported by `root.zig`'s `test {}` block so
//! `zig build test` picks them all up.

comptime {
    _ = @import("vec3_test.zig");
    _ = @import("latlng_test.zig");
    _ = @import("adder_test.zig");
    _ = @import("area_cross_test.zig");
    _ = @import("area_angle_test.zig");
    _ = @import("integration_test.zig");
    _ = @import("math_fail_examples.zig");
    _ = @import("equator_ring_test.zig");
}
