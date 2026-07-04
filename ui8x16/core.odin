// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block package
package ui8x16
// END org:block package

// BEGIN org:block cell-metrics
CELL_WIDTH  :: 8
CELL_HEIGHT :: 16
// END org:block cell-metrics

// BEGIN org:block cell-rect
Cell_Rect :: struct {
	col, row: int,
	w, h:    int,
}
// END org:block cell-rect

// BEGIN org:block pixel-rect
Pixel_Rect :: struct {
	x, y: int,
	w, h: int,
}
// END org:block pixel-rect

// BEGIN org:block color
Color :: struct {
	r, g, b, a: u8,
}
// END org:block color

// BEGIN org:block ui-id
UI_ID :: distinct u64
// END org:block ui-id

// BEGIN org:block ui-id-none
UI_ID_NONE :: UI_ID(0)
// END org:block ui-id-none

// BEGIN org:block mouse-button
Mouse_Button :: enum {
	Left,
	Middle,
	Right,
}
// END org:block mouse-button

// BEGIN org:block mouse-button-count
MOUSE_BUTTON_COUNT :: 3
// END org:block mouse-button-count

// BEGIN org:block mouse-input
Mouse_Input :: struct {
	x, y: int,
	down: [MOUSE_BUTTON_COUNT]bool,
}
// END org:block mouse-input

// BEGIN org:block ui-state
UI_State :: struct {
	mouse:         Mouse_Input,
	previous_down: [MOUSE_BUTTON_COUNT]bool,

	pressed_id:   [MOUSE_BUTTON_COUNT]UI_ID,
	pressed_rect: [MOUSE_BUTTON_COUNT]Cell_Rect,

	hit_any:       bool,
	activated_any: bool,
}
// END org:block ui-state

// BEGIN org:block mouse-button-index
mouse_button_index :: proc(button: Mouse_Button) -> int {
	return int(button)
}
// END org:block mouse-button-index

// BEGIN org:block ui-begin-frame
ui_begin_frame :: proc(state: ^UI_State, input: Mouse_Input) {
	for i in 0..<MOUSE_BUTTON_COUNT {
		if state.previous_down[i] && !state.mouse.down[i] {
			state.pressed_id[i] = UI_ID_NONE
			state.pressed_rect[i] = Cell_Rect{}
		}

		state.previous_down[i] = state.mouse.down[i]
	}

	state.mouse = input
	state.hit_any = false
	state.activated_any = false
}
// END org:block ui-begin-frame

// BEGIN org:block ui-hit
ui_hit :: proc(state: ^UI_State, rect: Cell_Rect) -> bool {
	hit := contains(rect, state.mouse.x, state.mouse.y)
	if hit {
		state.hit_any = true
	}
	return hit
}
// END org:block ui-hit

// BEGIN org:block ui-activate
ui_activate :: proc(state: ^UI_State, id: UI_ID, rect: Cell_Rect, button: Mouse_Button = .Left) -> bool {
	index := mouse_button_index(button)
	hit := ui_hit(state, rect)
	pressed := !state.previous_down[index] && state.mouse.down[index]
	released := state.previous_down[index] && !state.mouse.down[index]

	if pressed && hit {
		state.pressed_id[index] = id
		state.pressed_rect[index] = rect
	}

	activated := released &&
	             hit &&
	             state.pressed_id[index] == id &&
	             state.pressed_rect[index] == rect
	if activated {
		state.activated_any = true
	}
	return activated
}
// END org:block ui-activate

// BEGIN org:block cell-rect-proc
cell_rect :: proc(col, row, w, h: int) -> Cell_Rect {
	assert(w > 0, "Cell_Rect width must be positive")
	assert(h > 0, "Cell_Rect height must be positive")
	return Cell_Rect{col = col, row = row, w = w, h = h}
}
// END org:block cell-rect-proc

// BEGIN org:block rect-rel
rect_rel :: proc(parent: Cell_Rect, col, row, w, h: int) -> Cell_Rect {
	return cell_rect(parent.col + col, parent.row + row, w, h)
}
// END org:block rect-rel

// BEGIN org:block rect-px
rect_px :: proc(rect: Cell_Rect) -> Pixel_Rect {
	return Pixel_Rect{
		x = rect.col * CELL_WIDTH,
		y = rect.row * CELL_HEIGHT,
		w = rect.w * CELL_WIDTH,
		h = rect.h * CELL_HEIGHT,
	}
}
// END org:block rect-px

// BEGIN org:block contains
contains :: proc(rect: Cell_Rect, x, y: int) -> bool {
	px := rect_px(rect)
	return x >= px.x &&
	       y >= px.y &&
	       x < px.x + px.w &&
	       y < px.y + px.h
}
// END org:block contains
