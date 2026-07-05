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

// BEGIN org:block ui-pressed
ui_pressed :: proc(state: ^UI_State, id: UI_ID, button: Mouse_Button = .Left) -> bool {
	index := mouse_button_index(button)
	return state.mouse.down[index] && state.pressed_id[index] == id
}
// END org:block ui-pressed

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

// BEGIN org:block fill-rect-command
Fill_Rect_Command :: struct {
	rect:  Pixel_Rect,
	color: Color,
}
// END org:block fill-rect-command

// BEGIN org:block stroke-rect-command
Stroke_Rect_Command :: struct {
	rect:  Pixel_Rect,
	color: Color,
}
// END org:block stroke-rect-command

// BEGIN org:block text-command
Text_Command :: struct {
	pos:   Pixel_Point,
	text:  string,
	color: Color,
	scale: int,
}
// END org:block text-command

// BEGIN org:block draw-command
Draw_Command :: union {
	Fill_Rect_Command,
	Stroke_Rect_Command,
	Text_Command,
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
	draw_push(buffer, Draw_Command(Fill_Rect_Command{rect = rect, color = color}))
}
// END org:block draw-fill-rect

// BEGIN org:block draw-stroke-rect
draw_stroke_rect :: proc(buffer: ^Draw_Buffer, rect: Pixel_Rect, color: Color) {
	draw_push(buffer, Draw_Command(Stroke_Rect_Command{rect = rect, color = color}))
}
// END org:block draw-stroke-rect

// BEGIN org:block draw-text
draw_text :: proc(buffer: ^Draw_Buffer, pos: Pixel_Point, text: string, color: Color, scale: int) {
	assert(text_scale_valid(scale), "Text scale must be 1..4")
	draw_push(buffer, Draw_Command(Text_Command{pos = pos, text = text, color = color, scale = scale}))
}
// END org:block draw-text

// BEGIN org:block ui-end
ui_end :: proc(buffer: ^Draw_Buffer) -> []Draw_Command {
	return buffer.commands[:buffer.count]
}
// END org:block ui-end

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

// BEGIN org:block debug-warning-kind
Debug_Warning_Kind :: enum {
	Text_Overflow,
	Control_Label_Padding_Too_Short,
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

// BEGIN org:block debug-text-overflow
debug_text_overflow :: proc(buffer: ^Debug_Buffer, id: UI_ID, rect: Cell_Rect, text: string, measured_width, available_width: int) -> bool {
	if buffer == nil {
		return false
	}

	for i in 0..<buffer.count {
		warning := buffer.warnings[i]
		if warning.kind == .Text_Overflow && warning.id == id {
			return false
		}
	}

	return debug_push(buffer, Debug_Warning{
		kind = .Text_Overflow,
		id = id,
		rect = rect,
		text = text,
		measured_width = measured_width,
		available_width = available_width,
	})
}
// END org:block debug-text-overflow

// BEGIN org:block debug-control-label-padding-too-short
debug_control_label_padding_too_short :: proc(buffer: ^Debug_Buffer, id: UI_ID, rect: Cell_Rect) -> bool {
	if buffer == nil {
		return false
	}

	for i in 0..<buffer.count {
		warning := buffer.warnings[i]
		if warning.kind == .Control_Label_Padding_Too_Short && warning.id == id {
			return false
		}
	}

	return debug_push(buffer, Debug_Warning{
		kind = .Control_Label_Padding_Too_Short,
		id = id,
		rect = rect,
	})
}
// END org:block debug-control-label-padding-too-short

// BEGIN org:block ui-context
UI :: struct {
	draw:  ^Draw_Buffer,
	debug: ^Debug_Buffer,
	style: UI_Style,
}
// END org:block ui-context

// BEGIN org:block control-options
Control_Label_Padding :: enum {
	None,
	One_Half,
}

Control_Options :: struct {
	scale:         int,
	label_padding: Control_Label_Padding,
}

DEFAULT_CONTROL_OPTIONS :: Control_Options{
	scale = 1,
	label_padding = .None,
}
// END org:block control-options

// BEGIN org:block control-options-scale
control_options_scale :: proc(options: Control_Options) -> int {
	if options.scale == 0 {
		return DEFAULT_CONTROL_OPTIONS.scale
	}
	return options.scale
}
// END org:block control-options-scale

// BEGIN org:block ui-context-proc
ui_context :: proc {
	ui_context_default,
	ui_context_with_style,
}

ui_context_default :: proc(draw: ^Draw_Buffer, debug: ^Debug_Buffer) -> UI {
	return ui_context_with_style(draw, debug, default_style())
}

ui_context_with_style :: proc(draw: ^Draw_Buffer, debug: ^Debug_Buffer, style: UI_Style) -> UI {
	return UI{draw = draw, debug = debug, style = style}
}
// END org:block ui-context-proc

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

// BEGIN org:block text-width-px
text_width_px :: proc(text: string, scale: int) -> int {
	assert(text_scale_valid(scale), "Text scale must be 1..4")
	return len(text) * CELL_WIDTH * scale
}
// END org:block text-width-px

// BEGIN org:block pixel-origin
pixel_origin :: proc(rect: Cell_Rect) -> Pixel_Point {
	px := rect_px(rect)
	return Pixel_Point{x = px.x, y = px.y}
}
// END org:block pixel-origin

// BEGIN org:block compile-text
compile_text :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, pos: Pixel_Point, text: string, color: Color, scale: int) {
	measured_width := text_width_px(text, scale)
	bounds := rect_px(rect)
	available_width := bounds.x + bounds.w - pos.x
	if available_width < 0 {
		available_width = 0
	}
	if measured_width > available_width {
		debug_text_overflow(ui.debug, id, rect, text, measured_width, available_width)
	}

	draw_text(ui.draw, pos, text, color, scale)
}
// END org:block compile-text

// BEGIN org:block ui-text
ui_text :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, text: string, color: Color, scale: int = 1) {
	compile_text(ui, id, rect, pixel_origin(rect), text, color, scale)
}
// END org:block ui-text

// BEGIN org:block ui-box
ui_box :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, fill, line: Color) {
	_ = id
	px := rect_px(rect)
	draw_fill_rect(ui.draw, px, fill)
	draw_stroke_rect(ui.draw, px, line)
}
// END org:block ui-box

// BEGIN org:block ui-panel
ui_panel :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect) {
	ui_box(ui, id, rect, ui.style.panel, ui.style.line)
}
// END org:block ui-panel

// BEGIN org:block ui-bar
ui_bar :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, value, max_value: int, fill: Color) {
	_ = id
	px := rect_px(rect)
	fill_px := px
	fill_px.w = 0
	if max_value > 0 {
		fill_px.w = px.w * int_clamp(value, 0, max_value) / max_value
	}

	draw_fill_rect(ui.draw, px, ui.style.bar_empty)
	draw_fill_rect(ui.draw, fill_px, fill)
	draw_stroke_rect(ui.draw, px, ui.style.line)
}
// END org:block ui-bar

// BEGIN org:block control-label-origin
control_label_origin :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, options: Control_Options) -> Pixel_Point {
	px := rect_px(rect)
	scale := control_options_scale(options)

	switch options.label_padding {
	case .One_Half:
		px.x += CELL_WIDTH * scale
		required_height := CELL_HEIGHT * scale * 2
		if px.h < required_height {
			debug_control_label_padding_too_short(ui.debug, id, rect)
			return Pixel_Point{x = px.x, y = px.y}
		}
		return Pixel_Point{x = px.x, y = px.y + CELL_HEIGHT * scale / 2}
	case .None:
		return Pixel_Point{x = px.x + 2, y = px.y}
	}
	return Pixel_Point{x = px.x + 2, y = px.y}
}
// END org:block control-label-origin

// BEGIN org:block ui-button
ui_button :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, label: string, options: Control_Options = DEFAULT_CONTROL_OPTIONS, pressed: bool = false) {
	fill := ui.style.button_fill
	text_color := ui.style.button_text
	if pressed {
		fill = ui.style.button_active_fill
		text_color = ui.style.button_active_text
	}

	ui_box(ui, id, rect, fill, ui.style.line)
	compile_text(ui, id, rect, control_label_origin(ui, id, rect, options), label, text_color, control_options_scale(options))
}
// END org:block ui-button

// BEGIN org:block ui-toggle
ui_toggle :: proc(ui: ^UI, id: UI_ID, rect: Cell_Rect, label: string, active: bool, options: Control_Options = DEFAULT_CONTROL_OPTIONS, pressed: bool = false) {
	fill := ui.style.button_fill
	text_color := ui.style.button_text
	if active || pressed {
		fill = ui.style.button_active_fill
		text_color = ui.style.button_active_text
	}

	ui_box(ui, id, rect, fill, ui.style.line)
	compile_text(ui, id, rect, control_label_origin(ui, id, rect, options), label, text_color, control_options_scale(options))
}
// END org:block ui-toggle
