# 8x16 UI V0 Spec

## Purpose

Small immediate-mode UI package for Odin workbenches.

Primary job: make 8x16 cell geometry, hitboxes, button activation, and text overflow legible and hard to accidentally desync.

## Core Invariant

```text
1 UI cell = 8 px wide x 16 px tall
layout geometry = integer cell-space
rects are values, not nodes
```

API should avoid `VGA` language. Documentation may mention IBM VGA-style fonts as aesthetic context.

## Package Scope

Use a separate Odin package directory. Do not depend on raylib directly.

The package may expose plain structs that are easy for a raylib caller to translate:

```odin
Color :: struct { r, g, b, a: u8 }
Pixel_Rect :: struct { x, y, w, h: int }
```

## Geometry

```odin
Cell_Rect :: struct {
    col, row: int,
    w, h:    int,
}
```

Rules:

- `Cell_Rect` is always absolute after construction.
- `w` and `h` must be positive.
- Hit testing is half-open: `x >= left && x < right`.
- No retained parent/child tree.
- Nesting is coordinate composition.

Minimal API:

```odin
cell_rect :: proc(col, row, w, h: int) -> Cell_Rect
rect_rel  :: proc(parent: Cell_Rect, col, row, w, h: int) -> Cell_Rect
rect_px   :: proc(rect: Cell_Rect) -> Pixel_Rect
contains  :: proc(rect: Cell_Rect, x, y: int) -> bool
```

No split/stack helpers in v0.

## Input

UI owns mouse sampling/state, not keyboard routing. Keyboard shortcuts remain app-level commands.

Button activation:

```text
press began inside same control
release ended inside same control
=> activated
```

Click A, release B: no activation.

Click A, leave, return, release A: activate A.

Likely state shape:

```odin
Mouse_Button :: enum { Left, Middle, Right }

UI_State :: struct {
    pressed_id:   [3]UI_ID,
    pressed_rect: [3]Cell_Rect,
}
```

Caller owns and initializes `UI_State`.

## Identity

Controls should accept caller-provided IDs or labels.

Rect equality can serve as fallback identity, but ID plus rect is safer. Duplicate rects are caller error; v0 may process overlapping controls rather than resolving z-order.

## Routing Metadata

No global pointer claim/consume in v0.

UI may expose advisory fields:

```odin
hit_any:       bool
activated_any: bool
```

Rules:

- Labels count as `hit_any`.
- Disabled controls count as `hit_any`.
- Panels/background boxes count as `hit_any`.
- Canvas/world surface is not a `Cell_Rect`; model it separately.

## Controls

Controls return activation events, not state.

```odin
ui_button :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, label: string) -> bool
ui_toggle :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, label: string, active: bool) -> bool
```

Caller mutates app state:

```odin
if ui_toggle(&ui, id, rect, "material", paint_mode == .Material) {
    paint_mode = .Material
}
```

## Styling

Domain colors are caller-owned.

Toolkit may own minimal chrome styling, decoupled from logic:

```odin
UI_Style :: struct {
    button_fill:        Color,
    button_text:        Color,
    button_active_fill: Color,
    button_active_text: Color,
    line:               Color,
    panel:              Color,
}
```

Caller can configure once. Material colors, automata colors, heat colors, and other domain colors stay outside.

## Text

Text takes a rect.

```odin
ui_text :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, text: string, color: Color)
```

V0:

- ASCII-ish only.
- No UTF-8 semantics.
- Draw and trust caller.
- No clipping.
- Warn on overflow in debug.
- Measurement uses configured 8x16 metrics, not raylib.

## Padding

No general padding system.

`ui_button` may use exactly `2px` internal left padding. Footprint unchanged. No top/bottom padding.

## Debug

Compile-time gated.

Debug may emit to stderr or to caller-owned debug buffer.

Text overflow warning should include:

```text
id
rect
text
measured width
available width
```

Warnings should dedupe by ID.

## Non-Goals

- No retained widget tree.
- No heap allocation requirement.
- No proportional font support.
- No dynamic font metrics.
- No hidden layout engine.
- No UTF-8 text editing.
- No z-order system.
- No global event capture.
- No canvas abstraction inside UI package.

## Work Sequence

1. Build separate `8x16` package/API.
2. Make example UIs against it.
3. Review package surface.
4. In a later PR, migrate `auto` panel code to it.
