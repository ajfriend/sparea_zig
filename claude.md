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
  - Stable-norm scaffolding on `Vec3T.norm` (every Vec3 here is a
    unit vector or small sum thereof; scaled-by-max wasn't earning
    its 12 lines).
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
- `Vec3T(T)` is generic over precision; `Vec3 = Vec3T(f64)` is
  the only convenience alias. Other instantiations (e.g.
  `Vec3T(f128)` for the high-precision reference path) are
  produced on demand by `area_cross.signed_area(f128, …)` or
  `triangle_area(f128, …)` — no top-level `Vec3F128` const.
  Same shape for `AdderT(T)` / `Adder` (compensated summation,
  Kahan-Babuška-Neumaier).
- Local accumulator variables stay named `sum` even though the
  type is `Adder` — name describes what's being computed, not
  what's being held.

## Architecture

- All numerical-judgment thresholds live on the `tol` namespace
  in `src/root.zig` (a struct-as-namespace with `pub const`s).
  Reach for them via `tol.X`; don't introduce local `const`
  tolerances.
- Errors are declared once in `src/root.zig` as `SpareaError`.
  Functions in `polygon.zig` use inferred error unions (`!f64`)
  and `return error.X` directly — `error.X` is a global name in
  Zig, no import needed.
- Vec3 ↔ LatLng conversions live in `vertex.zig` behind a single
  `vertex.as(comptime To, v) To` — caller writes the target type
  and the function picks the right path at compile time. Kept
  out of `vec3.zig` and `latlng.zig` so neither type module
  depends on the other. `inline fn` + comptime branches → zero
  runtime cost; lowered code at each call site is exactly the
  bare conversion.
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
