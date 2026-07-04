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

// BEGIN org:block pixel-point
Pixel_Point :: struct {
	x, y: int,
}
// END org:block pixel-point

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

	pressed_id: [MOUSE_BUTTON_COUNT]UI_ID,

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
	}

	activated := released &&
	             hit &&
	             state.pressed_id[index] == id
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

// BEGIN org:block draw-command-kind
Draw_Command_Kind :: enum {
	Fill_Rect,
	Stroke_Rect,
	Text,
}
// END org:block draw-command-kind

// BEGIN org:block draw-rect-command
Draw_Rect_Command :: struct {
	rect:  Pixel_Rect,
	color: Color,
}
// END org:block draw-rect-command

// BEGIN org:block draw-text-command
Draw_Text_Command :: struct {
	pos:   Pixel_Point,
	text:  string,
	color: Color,
	scale: int,
}
// END org:block draw-text-command

// BEGIN org:block draw-command
Draw_Command :: struct {
	kind:        Draw_Command_Kind,
	fill_rect:   Draw_Rect_Command,
	stroke_rect: Draw_Rect_Command,
	text:        Draw_Text_Command,
}
// END org:block draw-command

// BEGIN org:block draw-buffer
Draw_Buffer :: struct {
	commands: []Draw_Command,
	count:    int,
}
// END org:block draw-buffer

// BEGIN org:block draw-buffer-proc
draw_buffer :: proc(storage: []Draw_Command) -> Draw_Buffer {
	return Draw_Buffer{commands = storage}
}
// END org:block draw-buffer-proc

// BEGIN org:block text-scale-valid
text_scale_valid :: proc(scale: int) -> bool {
	return scale >= 1 && scale <= 4
}
// END org:block text-scale-valid

// BEGIN org:block draw-push
draw_push :: proc(buffer: ^Draw_Buffer, command: Draw_Command) {
	assert(buffer.count < len(buffer.commands), "Draw_Buffer overflow")
	buffer.commands[buffer.count] = command
	buffer.count += 1
}
// END org:block draw-push

// BEGIN org:block draw-fill-rect
draw_fill_rect :: proc(buffer: ^Draw_Buffer, rect: Pixel_Rect, color: Color) {
	draw_push(buffer, Draw_Command{
		kind = .Fill_Rect,
		fill_rect = Draw_Rect_Command{rect = rect, color = color},
	})
}
// END org:block draw-fill-rect

// BEGIN org:block draw-stroke-rect
draw_stroke_rect :: proc(buffer: ^Draw_Buffer, rect: Pixel_Rect, color: Color) {
	draw_push(buffer, Draw_Command{
		kind = .Stroke_Rect,
		stroke_rect = Draw_Rect_Command{rect = rect, color = color},
	})
}
// END org:block draw-stroke-rect

// BEGIN org:block draw-text
draw_text :: proc(buffer: ^Draw_Buffer, pos: Pixel_Point, text: string, color: Color, scale: int) {
	assert(text_scale_valid(scale), "Text scale must be 1..4")
	draw_push(buffer, Draw_Command{
		kind = .Text,
		text = Draw_Text_Command{pos = pos, text = text, color = color, scale = scale},
	})
}
// END org:block draw-text

// BEGIN org:block ui-end
ui_end :: proc(buffer: ^Draw_Buffer) -> []Draw_Command {
	return buffer.commands[:buffer.count]
}
// END org:block ui-end
