// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block test-package
package ui8x16
// END org:block test-package

// BEGIN org:block test-imports
import "core:testing"
// END org:block test-imports

// BEGIN org:block test-command-helpers
expect_fill_rect :: proc(t: ^testing.T, command: Draw_Command, rect: Pixel_Rect, color: Color) {
	payload, ok := command.(Fill_Rect_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.rect, rect)
		testing.expect_value(t, payload.color, color)
	}
}

expect_stroke_rect :: proc(t: ^testing.T, command: Draw_Command, rect: Pixel_Rect, color: Color) {
	payload, ok := command.(Stroke_Rect_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.rect, rect)
		testing.expect_value(t, payload.color, color)
	}
}

expect_text :: proc(t: ^testing.T, command: Draw_Command, pos: Pixel_Point, text: string, color: Color, scale: int) {
	payload, ok := command.(Text_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.pos, pos)
		testing.expect_value(t, payload.text, text)
		testing.expect_value(t, payload.color, color)
		testing.expect_value(t, payload.scale, scale)
	}
}

expect_fill_rect_kind :: proc(t: ^testing.T, command: Draw_Command) {
	_, ok := command.(Fill_Rect_Command)
	testing.expect(t, ok)
}

expect_stroke_rect_kind :: proc(t: ^testing.T, command: Draw_Command) {
	_, ok := command.(Stroke_Rect_Command)
	testing.expect(t, ok)
}

expect_text_kind :: proc(t: ^testing.T, command: Draw_Command) {
	_, ok := command.(Text_Command)
	testing.expect(t, ok)
}

expect_text_value :: proc(t: ^testing.T, command: Draw_Command, text: string) {
	payload, ok := command.(Text_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.text, text)
	}
}

expect_text_pos :: proc(t: ^testing.T, command: Draw_Command, pos: Pixel_Point) {
	payload, ok := command.(Text_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.pos, pos)
	}
}

expect_fill_rect_width :: proc(t: ^testing.T, command: Draw_Command, width: int) {
	payload, ok := command.(Fill_Rect_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.rect.w, width)
	}
}
// END org:block test-command-helpers

// BEGIN org:block test-cell-rect
@(test)
test_cell_rect_keeps_absolute_values :: proc(t: ^testing.T) {
	rect := cell_rect(2, 3, 4, 5)
	testing.expect_value(t, rect, Cell_Rect{col = 2, row = 3, w = 4, h = 5})
}
// END org:block test-cell-rect

// BEGIN org:block test-rect-rel
@(test)
test_rect_rel_returns_absolute_rect :: proc(t: ^testing.T) {
	parent := cell_rect(10, 20, 30, 40)
	child := rect_rel(parent, 2, 3, 4, 5)
	testing.expect_value(t, child, Cell_Rect{col = 12, row = 23, w = 4, h = 5})
}
// END org:block test-rect-rel

// BEGIN org:block test-rect-px
@(test)
test_rect_px_uses_fixed_cell_metrics :: proc(t: ^testing.T) {
	px := rect_px(cell_rect(2, 3, 4, 5))
	testing.expect_value(t, px, Pixel_Rect{x = 16, y = 48, w = 32, h = 80})
}
// END org:block test-rect-px

// BEGIN org:block test-contains
@(test)
test_contains_uses_half_open_pixel_bounds :: proc(t: ^testing.T) {
	rect := cell_rect(1, 2, 3, 4)

	testing.expect(t, contains(rect, 8, 32))
	testing.expect(t, contains(rect, 31, 95))
	testing.expect(t, !contains(rect, 7, 32))
	testing.expect(t, !contains(rect, 8, 31))
	testing.expect(t, !contains(rect, 32, 32))
	testing.expect(t, !contains(rect, 8, 96))
}
// END org:block test-contains

// BEGIN org:block test-invalid-width
@(test)
test_cell_rect_rejects_non_positive_width :: proc(t: ^testing.T) {
	testing.expect_assert(t, "Cell_Rect width must be positive")
	_ = cell_rect(0, 0, 0, 1)
}
// END org:block test-invalid-width

// BEGIN org:block test-invalid-height
@(test)
test_cell_rect_rejects_non_positive_height :: proc(t: ^testing.T) {
	testing.expect_assert(t, "Cell_Rect height must be positive")
	_ = cell_rect(0, 0, 1, 0)
}
// END org:block test-invalid-height

// BEGIN org:block test-mouse-input-helper
test_mouse_input :: proc(x, y: int, left := false, middle := false, right := false) -> Mouse_Input {
	return Mouse_Input{x = x, y = y, down = [MOUSE_BUTTON_COUNT]bool{left, middle, right}}
}
// END org:block test-mouse-input-helper

// BEGIN org:block test-ui-hit
@(test)
test_ui_hit_sets_hit_any :: proc(t: ^testing.T) {
	state: UI_State
	rect := cell_rect(1, 1, 2, 2)

	ui_begin_frame(&state, test_mouse_input(8, 16))
	testing.expect(t, ui_hit(&state, rect))
	testing.expect(t, state.hit_any)
	testing.expect(t, !state.activated_any)
}
// END org:block test-ui-hit

// BEGIN org:block test-activation-release-inside
@(test)
test_ui_activate_requires_press_and_release_inside_same_control :: proc(t: ^testing.T) {
	state: UI_State
	rect := cell_rect(1, 1, 2, 2)
	id := UI_ID(10)

	ui_begin_frame(&state, test_mouse_input(8, 16, left = true))
	testing.expect(t, !ui_activate(&state, id, rect))
	testing.expect(t, state.hit_any)

	ui_begin_frame(&state, test_mouse_input(9, 17, left = false))
	testing.expect(t, ui_activate(&state, id, rect))
	testing.expect(t, state.activated_any)
}
// END org:block test-activation-release-inside

// BEGIN org:block test-activation-release-other
@(test)
test_ui_activate_rejects_release_inside_different_control :: proc(t: ^testing.T) {
	state: UI_State
	a := cell_rect(1, 1, 2, 2)
	b := cell_rect(4, 1, 2, 2)

	ui_begin_frame(&state, test_mouse_input(8, 16, left = true))
	testing.expect(t, !ui_activate(&state, UI_ID(1), a))
	testing.expect(t, !ui_activate(&state, UI_ID(2), b))

	ui_begin_frame(&state, test_mouse_input(32, 16, left = false))
	testing.expect(t, !ui_activate(&state, UI_ID(2), b))
	testing.expect(t, !ui_activate(&state, UI_ID(1), a))
	testing.expect(t, !state.activated_any)
}
// END org:block test-activation-release-other

// BEGIN org:block test-activation-return
@(test)
test_ui_activate_allows_leave_return_release :: proc(t: ^testing.T) {
	state: UI_State
	rect := cell_rect(1, 1, 2, 2)
	id := UI_ID(20)

	ui_begin_frame(&state, test_mouse_input(8, 16, left = true))
	testing.expect(t, !ui_activate(&state, id, rect))

	ui_begin_frame(&state, test_mouse_input(80, 80, left = true))
	testing.expect(t, !ui_activate(&state, id, rect))

	ui_begin_frame(&state, test_mouse_input(9, 17, left = false))
	testing.expect(t, ui_activate(&state, id, rect))
}
// END org:block test-activation-return

// BEGIN org:block test-activation-clear-next-frame
@(test)
test_ui_begin_frame_clears_press_origin_after_release_frame :: proc(t: ^testing.T) {
	state: UI_State
	rect := cell_rect(1, 1, 2, 2)
	id := UI_ID(30)

	ui_begin_frame(&state, test_mouse_input(8, 16, left = true))
	testing.expect(t, !ui_activate(&state, id, rect))

	ui_begin_frame(&state, test_mouse_input(9, 17, left = false))
	testing.expect(t, ui_activate(&state, id, rect))

	ui_begin_frame(&state, test_mouse_input(9, 17, left = false))
	testing.expect_value(t, state.pressed_id[mouse_button_index(.Left)], UI_ID_NONE)
}
// END org:block test-activation-clear-next-frame

// BEGIN org:block test-draw-fill-rect
@(test)
test_draw_fill_rect_appends_primitive_command :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := draw_buffer(storage[:])
	color := Color{r = 1, g = 2, b = 3, a = 4}
	rect := Pixel_Rect{x = 8, y = 16, w = 24, h = 32}

	draw_fill_rect(&buffer, rect, color)

	testing.expect_value(t, buffer.count, 1)
	expect_fill_rect(t, buffer.commands[0], rect, color)
}
// END org:block test-draw-fill-rect

// BEGIN org:block test-draw-stroke-rect
@(test)
test_draw_stroke_rect_appends_primitive_command :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := draw_buffer(storage[:])
	color := Color{r = 5, g = 6, b = 7, a = 8}
	rect := Pixel_Rect{x = 1, y = 2, w = 3, h = 4}

	draw_stroke_rect(&buffer, rect, color)

	testing.expect_value(t, buffer.count, 1)
	expect_stroke_rect(t, buffer.commands[0], rect, color)
}
// END org:block test-draw-stroke-rect

// BEGIN org:block test-draw-text
@(test)
test_draw_text_uses_pixel_origin_and_scale :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := draw_buffer(storage[:])
	color := Color{r = 9, g = 10, b = 11, a = 12}
	pos := Pixel_Point{x = 16, y = 32}

	draw_text(&buffer, pos, "ok", color, 2)

	testing.expect_value(t, buffer.count, 1)
	expect_text(t, buffer.commands[0], pos, "ok", color, 2)
}
// END org:block test-draw-text

// BEGIN org:block test-draw-order
@(test)
test_draw_commands_keep_append_order :: proc(t: ^testing.T) {
	storage: [3]Draw_Command
	buffer := draw_buffer(storage[:])
	color := Color{a = 255}

	draw_fill_rect(&buffer, Pixel_Rect{x = 0, y = 0, w = 8, h = 16}, color)
	draw_stroke_rect(&buffer, Pixel_Rect{x = 1, y = 1, w = 6, h = 14}, color)
	draw_text(&buffer, Pixel_Point{x = 2, y = 3}, "x", color, 1)

	commands := ui_end(&buffer)
	testing.expect_value(t, len(commands), 3)
	expect_fill_rect_kind(t, commands[0])
	expect_stroke_rect_kind(t, commands[1])
	expect_text_kind(t, commands[2])
}
// END org:block test-draw-order

// BEGIN org:block test-draw-overflow
@(test)
test_draw_buffer_overflow_fails_loudly :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := draw_buffer(storage[:])
	color := Color{a = 255}

	draw_fill_rect(&buffer, Pixel_Rect{x = 0, y = 0, w = 1, h = 1}, color)
	testing.expect_assert(t, "Draw_Buffer overflow")
	draw_fill_rect(&buffer, Pixel_Rect{x = 1, y = 0, w = 1, h = 1}, color)
}
// END org:block test-draw-overflow

// BEGIN org:block test-text-scale
@(test)
test_draw_text_rejects_invalid_scale :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := draw_buffer(storage[:])

	testing.expect_assert(t, "Text scale must be 1..4")
	draw_text(&buffer, Pixel_Point{}, "x", Color{a = 255}, 0)
}
// END org:block test-text-scale

// BEGIN org:block test-ui-helper
test_ui_init :: proc(ui: ^UI, state: ^UI_State, draw: ^Draw_Buffer, debug: ^Debug_Buffer, command_storage: []Draw_Command, warning_storage: []Debug_Warning) {
	debug^ = Debug_Buffer{warnings = warning_storage}
	draw^ = draw_buffer(command_storage)
	ui^ = ui_context(state, draw, debug)
}
// END org:block test-ui-helper

// BEGIN org:block test-ui-text
@(test)
test_ui_text_emits_primitive_text_and_overflow_warning :: proc(t: ^testing.T) {
	command_storage: [2]Draw_Command
	warning_storage: [2]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])
	ui_begin_frame(&state, test_mouse_input(0, 0))

	ui_text(&ui, UI_ID(1), cell_rect(0, 0, 1, 1), "abc", ui.style.text)
	ui_text(&ui, UI_ID(1), cell_rect(0, 0, 1, 1), "abc", ui.style.text)

	testing.expect_value(t, draw.count, 2)
	expect_text_pos(t, draw.commands[0], Pixel_Point{x = 0, y = 0})
	expect_text_value(t, draw.commands[0], "abc")
	testing.expect_value(t, debug.count, 1)
	testing.expect_value(t, debug.warnings[0].kind, Debug_Warning_Kind.Text_Overflow)
	testing.expect_value(t, debug.warnings[0].measured_width, 24)
	testing.expect_value(t, debug.warnings[0].available_width, 8)
}
// END org:block test-ui-text

// BEGIN org:block test-ui-box
@(test)
test_ui_box_compiles_to_fill_then_stroke :: proc(t: ^testing.T) {
	command_storage: [2]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])

	fill := Color{r = 1, a = 255}
	line := Color{r = 2, a = 255}
	ui_box(&ui, UI_ID(2), cell_rect(1, 1, 2, 1), fill, line)

	testing.expect_value(t, draw.count, 2)
	expect_fill_rect(t, draw.commands[0], Pixel_Rect{x = 8, y = 16, w = 16, h = 16}, fill)
	expect_stroke_rect(t, draw.commands[1], Pixel_Rect{x = 8, y = 16, w = 16, h = 16}, line)
}
// END org:block test-ui-box

// BEGIN org:block test-ui-bar
@(test)
test_ui_bar_compiles_to_empty_fill_value_fill_and_stroke :: proc(t: ^testing.T) {
	command_storage: [3]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])

	ui_bar(&ui, UI_ID(3), cell_rect(0, 0, 10, 1), 3, 10, ui.style.bar_fill)

	testing.expect_value(t, draw.count, 3)
	expect_fill_rect_kind(t, draw.commands[0])
	expect_fill_rect(t, draw.commands[1], Pixel_Rect{x = 0, y = 0, w = 24, h = 16}, ui.style.bar_fill)
	expect_stroke_rect_kind(t, draw.commands[2])
}
// END org:block test-ui-bar

// BEGIN org:block test-ui-button
@(test)
test_ui_button_returns_activation_and_compiles_primitives :: proc(t: ^testing.T) {
	command_storage: [8]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])
	rect := cell_rect(0, 0, 5, 1)

	ui_begin_frame(&state, test_mouse_input(0, 0, left = true))
	testing.expect(t, !ui_button(&ui, UI_ID(4), rect, "run"))

	ui_begin_frame(&state, test_mouse_input(1, 1, left = false))
	testing.expect(t, ui_button(&ui, UI_ID(4), rect, "run"))

	commands := ui_end(&draw)
	testing.expect_value(t, len(commands), 6)
	expect_fill_rect_kind(t, commands[0])
	expect_stroke_rect_kind(t, commands[1])
	expect_text_kind(t, commands[2])
	expect_text_pos(t, commands[5], Pixel_Point{x = 2, y = 0})
}
// END org:block test-ui-button

// BEGIN org:block test-ui-toggle
@(test)
test_ui_toggle_active_state_resolves_style_to_primitive_fill :: proc(t: ^testing.T) {
	command_storage: [3]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])

	ui_toggle(&ui, UI_ID(5), cell_rect(0, 0, 6, 1), "snap", true)

	testing.expect_value(t, draw.count, 3)
	expect_fill_rect(t, draw.commands[0], Pixel_Rect{x = 0, y = 0, w = 48, h = 16}, ui.style.button_active_fill)
	expect_text_kind(t, draw.commands[2])
}
// END org:block test-ui-toggle
