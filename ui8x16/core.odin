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

// BEGIN org:block ui-style
UI_Style :: struct {
	text: Color,
	line: Color,
	panel: Color,

	button_fill:        Color,
	button_text:        Color,
	button_active_fill: Color,
	button_active_text: Color,

	bar_fill:  Color,
	bar_empty: Color,
}
// END org:block ui-style

// BEGIN org:block default-style
default_style :: proc() -> UI_Style {
	return UI_Style{
		text = Color{r = 230, g = 230, b = 230, a = 255},
		line = Color{r = 80, g = 80, b = 80, a = 255},
		panel = Color{r = 24, g = 24, b = 24, a = 255},

		button_fill = Color{r = 48, g = 48, b = 48, a = 255},
		button_text = Color{r = 235, g = 235, b = 235, a = 255},
		button_active_fill = Color{r = 220, g = 220, b = 220, a = 255},
		button_active_text = Color{r = 16, g = 16, b = 16, a = 255},

		bar_fill = Color{r = 96, g = 180, b = 120, a = 255},
		bar_empty = Color{r = 44, g = 44, b = 44, a = 255},
	}
}
// END org:block default-style

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

// BEGIN org:block draw-command-kind
Draw_Command_Kind :: enum {
	Box,
	Text,
	Bar,
}
// END org:block draw-command-kind

// BEGIN org:block draw-box-command
Draw_Box_Command :: struct {
	rect: Pixel_Rect,
	fill: Color,
	line: Color,
}
// END org:block draw-box-command

// BEGIN org:block draw-text-command
Draw_Text_Command :: struct {
	rect:  Pixel_Rect,
	text:  string,
	color: Color,
}
// END org:block draw-text-command

// BEGIN org:block draw-bar-command
Draw_Bar_Command :: struct {
	rect:  Pixel_Rect,
	fill:  Pixel_Rect,
	empty: Color,
	color: Color,
	line:  Color,
}
// END org:block draw-bar-command

// BEGIN org:block draw-command
Draw_Command :: struct {
	kind: Draw_Command_Kind,
	box:  Draw_Box_Command,
	text: Draw_Text_Command,
	bar:  Draw_Bar_Command,
}
// END org:block draw-command

// BEGIN org:block debug-warning-kind
Debug_Warning_Kind :: enum {
	Draw_Command_Overflow,
	Text_Overflow,
}
// END org:block debug-warning-kind

// BEGIN org:block debug-warning
Debug_Warning :: struct {
	kind: Debug_Warning_Kind,
	id:   UI_ID,
	rect: Cell_Rect,

	text:            string,
	measured_width:  int,
	available_width: int,
}
// END org:block debug-warning

// BEGIN org:block debug-buffer
Debug_Buffer :: struct {
	warnings: []Debug_Warning,
	count:    int,

	overflowed: bool,
}
// END org:block debug-buffer

// BEGIN org:block draw-buffer
Draw_Buffer :: struct {
	commands: []Draw_Command,
	count:    int,

	overflow_count: int,
	debug:          ^Debug_Buffer,
}
// END org:block draw-buffer

// BEGIN org:block int-clamp
int_clamp :: proc(value, low, high: int) -> int {
	if value < low {
		return low
	}
	if value > high {
		return high
	}
	return value
}
// END org:block int-clamp

// BEGIN org:block debug-push
debug_push :: proc(buffer: ^Debug_Buffer, warning: Debug_Warning) -> bool {
	if buffer == nil {
		return false
	}
	if buffer.count >= len(buffer.warnings) {
		buffer.overflowed = true
		return false
	}

	buffer.warnings[buffer.count] = warning
	buffer.count += 1
	return true
}
// END org:block debug-push

// BEGIN org:block draw-push
draw_push :: proc(buffer: ^Draw_Buffer, command: Draw_Command) -> bool {
	if buffer.count >= len(buffer.commands) {
		buffer.overflow_count += 1
		debug_push(buffer.debug, Debug_Warning{kind = .Draw_Command_Overflow})
		return false
	}

	buffer.commands[buffer.count] = command
	buffer.count += 1
	return true
}
// END org:block draw-push

// BEGIN org:block draw-box
draw_box :: proc(buffer: ^Draw_Buffer, rect: Cell_Rect, fill, line: Color) -> bool {
	return draw_push(buffer, Draw_Command{
		kind = .Box,
		box = Draw_Box_Command{rect = rect_px(rect), fill = fill, line = line},
	})
}
// END org:block draw-box

// BEGIN org:block draw-text
draw_text :: proc(buffer: ^Draw_Buffer, rect: Cell_Rect, text: string, color: Color) -> bool {
	return draw_push(buffer, Draw_Command{
		kind = .Text,
		text = Draw_Text_Command{rect = rect_px(rect), text = text, color = color},
	})
}
// END org:block draw-text

// BEGIN org:block draw-bar
draw_bar :: proc(buffer: ^Draw_Buffer, rect: Cell_Rect, fill_width_px: int, color, empty, line: Color) -> bool {
	px := rect_px(rect)
	fill_px := px
	fill_px.w = int_clamp(fill_width_px, 0, px.w)

	return draw_push(buffer, Draw_Command{
		kind = .Bar,
		bar = Draw_Bar_Command{rect = px, fill = fill_px, empty = empty, color = color, line = line},
	})
}
// END org:block draw-bar
