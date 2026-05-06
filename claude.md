# claude.md

Notes for future Claude sessions working on this codebase. Things
that keep mattering and aren't obvious from the source.

## Sister repos

- `~/work/sparea_py` — Python bindings via ctypes. The C ABI
  (`c_api.zig`) lives there, not here. When the Zig public API
  changes, the c_api in that repo will need updating too.
- `~/work/sparea-docs` — Quarto documentation.

## Working with this user

- Terse. Don't summarize what the diff already shows.
- Push back on over-engineering. Things this user has explicitly
  rejected during the project's history:
  - Stable-norm scaffolding on `Vec3.norm` (every Vec3 here is a
    unit vector or small sum thereof; scaled-by-max wasn't earning
    its 12 lines).
  - Genericity over float precision (`Vec3T(T)`, `AdderT(T)`,
    `comptime T` threading down to an f128 reference path).
    Removed in favor of plain f64; the compensated-summation
    pipeline (`Adder`, `diff_of_products`) carries the precision
    the f128 reference used to verify, and the f128 cross-checks
    weren't earning their surface area.
  - SoA / XYZ parallel entry points (deleted — not currently
    motivated, and they doubled the surface of every check /
    analyze helper).
  - "Cagnoli" as the name for the per-edge formula (it's a misnomer
    inherited from D3-geo; the formula is Chamberlain–Duquette
    2007).
- Filenames are lowercase: `readme.md`, `dev.md`, `claude.md`.
- Sentence-case markdown headers, matching `dev.md` and `readme.md`.
- The 100% line-coverage gate (`just test`) is real and enforced.
  Adding code without an exercising test breaks the build.

## Naming

- The two area algorithms are `cross` (Van Oosterom–Strackee
  triangle; polygon via centroid-fan) and `angle` (Chamberlain–
  Duquette per-edge half-angle-latitude formula). Don't reintroduce
  "VOS" or "Cagnoli" outside of attribution comments.
- `Vec3` and `Adder` (compensated summation, Kahan-Babuška-
  Neumaier) are plain f64 structs. See the rejected-genericity
  bullet above — don't reintroduce a `Vec3T(T)` / `AdderT(T)` shape.
- Local accumulator variables stay named `sum` even though the
  type is `Adder` — name describes what's being computed, not
  what's being held.

## Architecture

- All numerical-judgment thresholds live on the `tol` namespace
  in `src/root.zig` (a struct-as-namespace with `pub const`s).
  Reach for them via `tol.X`; don't introduce local `const`
  tolerances.
- Errors are declared once in `src/root.zig` as `SpareaError`.
  Functions in `area.zig` use inferred error unions (`!f64`)
  and `return error.X` directly — `error.X` is a global name in
  Zig, no import needed.
- The library is monolingual on `Vec3` — every entry point takes
  `[]const Vec3` (no `verts: anytype`). Callers with `LatLng`-shaped
  data convert once at the call site via `ll.to_vec3()`. The
  `verts: anytype` shape used to be there but was removed: it
  doubled the surface of every entry point and caused the
  `LatLng → Vec3` trig conversion to repeat ~7× per vertex per
  `polygon_area` call.
- Vec3 ↔ LatLng conversions, plus the spherical centroid, are
  methods on the structs themselves: `Vec3.to_lat_lng`,
  `Vec3.centroid([]const Vec3)`, and `LatLng.to_vec3`. There used
  to be a `vertex.zig` module holding free functions — it was
  removed once everything fit naturally on one struct or the other.
  The mutual imports between `vec3.zig` and `latlng.zig` are fine:
  Zig handles cyclic imports as long as struct definitions
  themselves aren't cyclic.
- `LatLng` stores radians, not degrees. A literal `-10.0` in `.lat`
  is -10 radians (out of range); convert from degrees when working
  with human-friendly numbers.

## Why centroid-fan and not v0-fan

The v0-fan triangulation silently returns 0 for polygons with a
non-adjacent antipodal vertex pair: every fan triangle from
`v0 = a` to `ā` has both endpoints antipodal, so the cross-product
formula evaluates `2·atan2(0, 0) = 0`. Pinned down with concrete
polygons in `src/tests/math_fail_examples.zig`. Don't replace
centroid-fan with v0-fan as a "simplification" — it isn't.

## Tests

- Per-module test files under `src/tests/<module>_test.zig`,
  aggregated in `src/tests/all.zig`. New test files must be added
  to `all.zig` or they won't run.
- `helpers.zig` exports `random_unit_vec3`, `vertex_fan_area`.
  There's no `helpers.normalize` — use `Vec3.normalized()` directly.
- For ad-hoc test debugging: `std.debug.print("...", .{...});`
  writes to stderr. `zig build test` shows the output cleanly;
  `just test` goes through kcov which buffers.

## See also

- [readme.md](readme.md) — public-facing description.
- [dev.md](dev.md) — build, test, coverage instructions.
