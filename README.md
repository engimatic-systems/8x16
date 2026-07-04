# 8x16

Small immediate-mode UI package for Odin workbenches.

The design kernel is fixed 8x16 cell geometry: layout is expressed in integer cells, while drawing backends translate those cells to pixels. The initial target is boring, predictable UI for small tools: boxes, labels, buttons, toggles, bars, hitboxes, and debug warnings for text overflow.

See [SPEC.md](SPEC.md) for the current v0 contract and [PLAN.md](PLAN.md) for staged work.
