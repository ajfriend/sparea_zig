# Development notes

## Dependencies

- **[zig](https://ziglang.org/)** 0.15.2+ — the language. `brew install zig`
  on macOS; see ziglang.org for other platforms.
- **[just](https://github.com/casey/just)** — task runner. `brew install just`.
- **[kcov](https://github.com/SimonKagstrom/kcov)** — line-coverage tool
  used by `just test`. `brew install kcov` on macOS,
  `apt-get install kcov` on Debian/Ubuntu.
- **[jq](https://stedolan.github.io/jq/)** — used by `just test` to check
  the coverage threshold. `brew install jq` / `apt-get install jq`.

## Common commands

| Command | What it does |
| --- | --- |
| `just test` | Build the test binary, run tests under `kcov`, print line coverage, fail if not exactly 100%. This is the inner-loop iteration command. |
| `just build` | Build the library (no tests). |
| `just coverage` | Same as `just test`, then prints the path to the HTML report. |
| `just clean` | Remove `zig-out/`, `.zig-cache/`, `coverage/`. |

CI runs `just test` — same invocation locally and in CI.

## Coverage

`kcov` runs the test binary as a black box: it instruments the binary
with traps at each source line and records which lines execute. Output
is per-file/per-line HTML at `coverage/sparea-test/index.html`, plus a
`coverage.json` summary.

The CI gate enforces **100% line coverage** across both production
files (`src/*.zig`) and test files (`src/tests/*.zig`). Test code isn't
exempt — dead test helpers are dead code too.

What "100% line coverage" buys you:

- Every line in every shipped function is reached by some test.
- `comptime` branches that aren't realized at runtime don't appear in
  the binary, so they don't show as uncovered — Zig's comptime is
  naturally well-suited to line coverage.

What 100% line coverage **doesn't** buy you:

- **Branch coverage.** A one-line `if (a) x() else y()` counts as one
  line. Both sides being executed isn't measured. Discipline + code
  review fill the gap; explicit tests for both branches are the norm.

### Why kcov and not LLVM source-based coverage?

Zig 0.15.x / 0.16.x doesn't expose the LLVM coverage flags
(`-fprofile-instr-generate`, `-fcoverage-mapping`) that would feed
`llvm-cov` and unlock branch coverage. The CLI only has `-ffuzz` for
instrumentation. Track [ziglang/zig#352](https://github.com/ziglang/zig/issues/352)
— when LLVM-style coverage lands upstream, swap the kcov pipeline in
`justfile` for an `llvm-profdata merge` + `llvm-cov show` flow and
pick up branch coverage automatically.

## Test layout

- **`src/tests/<module>_test.zig`** — per-module unit tests, importing
  source files via `@import("../<module>.zig")`.
- **`src/tests/integration_test.zig`** — dispatch / validation /
  fuzz tests against the public API.
- **`src/tests/helpers.zig`** — shared test helpers
  (`random_unit_vec3`, `vertex_fan_area`).
- **`src/tests/all.zig`** — aggregator: `comptime { _ = @import(...); }`
  for each test file. Pulled in by `root.zig`'s `test {}` block so
  `zig build test` (and therefore `kcov`) sees them all.

To add tests for a new source module `foo.zig`, create
`src/tests/foo_test.zig`, then add `_ = @import("foo_test.zig");` to
`src/tests/all.zig`.

## Adding new errors

The error set is declared in `src/root.zig` as the public API:

```zig
pub const SpareaError = error{
    AntipodalEdge,
    TooFewVertices,
};
```

To add a new variant:

1. Add it (with a doc-comment) to `SpareaError` in `root.zig`.
2. `return error.NewVariant` from wherever in `polygon.zig` it applies.
3. Add a test that exercises the new error path (otherwise the
   coverage gate fails).
4. If the C ABI exposes it, add an error code to
   `sparea_py/src/c_api.zig` and a Python exception class to
   `sparea_py/sparea/__init__.py`.

Functions in `polygon.zig` use *inferred* error unions (`!f64`,
`!void`) and `return error.X` directly — `error.X` is a global name,
no import needed. Inferred unions are structurally equivalent to
`SpareaError`, so callers can still spell the named type if they want.

## Tolerances

All numerical-judgment thresholds live on the `tol` namespace in
`src/root.zig` (a struct-as-namespace with `pub const`s) so
they're greppable from one place:

```zig
pub const tol = struct {
    pub const ANTIPODAL: f64 = 1.0e-9;     // ‖v_i + v_{i+1}‖² rejection threshold
    pub const HEMISPHERE: f64 = 1.0e-6;    // centroid·v dispatch threshold
};
```

When you add a tolerance, add it here, not as a local `const` next to
its use site.

## Publishing a release

1. Bump `.version` in `build.zig.zon`, commit (`Bump to vX.Y.Z`),
   push to `main`. Wait for CI green.
2. GitHub UI → **Releases → Draft a new release**. Tag `vX.Y.Z`
   (create on publish), target `main`, title `vX.Y.Z`, prose notes
   matching prior releases. Publish.

GitHub auto-generates the tarball at
`https://github.com/ajfriend/sparea_zig/archive/refs/tags/vX.Y.Z.tar.gz`.

Downstream consumers (e.g. `sparea_py`) bump with:

```
zig fetch --save https://github.com/ajfriend/sparea_zig/archive/refs/tags/vX.Y.Z.tar.gz
```

Treat tags as append-only — repointing a published tag changes the
tarball hash and breaks every consumer pinned to it. Fix-forward
with `vX.Y.(Z+1)` instead.
