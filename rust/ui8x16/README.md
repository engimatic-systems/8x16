# Rust `ui8x16`

This crate is a dependency-free Rust-native vertical slice of the repository's
Odin `ui8x16` package. It does not replace or generate the Odin implementation.
Its canonical literate source is [`ui8x16.org`](ui8x16.org); edit that file and
tangle it to regenerate the Rust crate files.

The architecture preserves the same frame split:

1. sample `MouseInput` into caller-owned `InteractionState`;
2. query hits/activation and update application state;
3. lower current state through `Ui` into ordered primitive `DrawCommand`s;
4. let a backend translate those plain commands to concrete draw calls.

## Rust-specific design choices

- `CellRect` has private `NonZeroU32` dimensions, so constructed rectangles are
  always valid. Relative coordinate overflow is reported as `GeometryError`.
- `UiId` is non-zero and press state uses `Option`, removing the Odin sentinel.
- `TextScale` is an enum over exactly `1..=4`.
- `DrawCommand` is an enum with only backend primitives. Text borrows its source
  `str`, making command/text lifetime coupling explicit and allocation-free.
- command buffers have an explicit capacity and return `CommandOverflow` rather
  than silently dropping output. They use a reusable `Vec` internally for an
  idiomatic safe first slice.
- activation records both ID and rectangle. This tightens the documented
  "same control" rule when a caller accidentally reuses an ID with moved bounds.

## Parity status

Implemented and tested: fixed 8x16 geometry, absolute/relative cell layout,
pixel conversion, half-open hit testing, left/middle/right press-release state,
leave-and-return activation, advisory hit/activation metadata, ordered primitive
commands, styles, panels, boxes, buttons, toggles, bars, per-call text scale,
compact and one-cell/half-cell label padding, byte-based text measurement,
overflow diagnostics, diagnostic deduplication, and loud capacity handling.

Open gaps are deliberately outside this milestone: there is no Rust raylib
backend or windowed example; text remains byte-measured and unclipped; buffers
use preallocated `Vec`s rather than caller-provided slices; and diagnostics are
opt-in at runtime rather than compile-time gated. Keyboard routing, a retained
tree, layout engines, canvas ownership, and semantic backend commands remain
non-goals.

Run the verified slice from the repository root:

```sh
cargo test --manifest-path rust/ui8x16/Cargo.toml --all-targets
cargo run --manifest-path rust/ui8x16/Cargo.toml --example surface
```

Regenerate the crate from its Org source with standard Org Babel:

```sh
emacs --batch rust/ui8x16/ui8x16.org \
  --eval '(org-babel-tangle)'
```
