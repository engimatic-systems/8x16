// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block test-package
package ui8x16
// END org:block test-package

// BEGIN org:block test-imports
import "core:testing"
// END org:block test-imports

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

// BEGIN org:block test-draw-box
@(test)
test_draw_box_pushes_pixel_command :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := Draw_Buffer{commands = storage[:]}
	fill := Color{r = 1, g = 2, b = 3, a = 4}
	line := Color{r = 5, g = 6, b = 7, a = 8}

	testing.expect(t, draw_box(&buffer, cell_rect(1, 2, 3, 4), fill, line))
	testing.expect_value(t, buffer.count, 1)
	testing.expect_value(t, buffer.commands[0].kind, Draw_Command_Kind.Box)
	testing.expect_value(t, buffer.commands[0].box.rect, Pixel_Rect{x = 8, y = 32, w = 24, h = 64})
	testing.expect_value(t, buffer.commands[0].box.fill, fill)
	testing.expect_value(t, buffer.commands[0].box.line, line)
}
// END org:block test-draw-box

// BEGIN org:block test-draw-text
@(test)
test_draw_text_pushes_text_command :: proc(t: ^testing.T) {
	storage: [1]Draw_Command
	buffer := Draw_Buffer{commands = storage[:]}
	color := Color{r = 10, g = 11, b = 12, a = 13}

	testing.expect(t, draw_text(&buffer, cell_rect(0, 1, 4, 1), "ok", color))
	testing.expect_value(t, buffer.commands[0].kind, Draw_Command_Kind.Text)
	testing.expect_value(t, buffer.commands[0].text.rect, Pixel_Rect{x = 0, y = 16, w = 32, h = 16})
	testing.expect_value(t, buffer.commands[0].text.text, "ok")
	testing.expect_value(t, buffer.commands[0].text.color, color)
}
// END org:block test-draw-text

// BEGIN org:block test-draw-bar
@(test)
test_draw_bar_clamps_fill_width :: proc(t: ^testing.T) {
	storage: [2]Draw_Command
	buffer := Draw_Buffer{commands = storage[:]}
	color := Color{r = 1, g = 1, b = 1, a = 255}

	testing.expect(t, draw_bar(&buffer, cell_rect(0, 0, 2, 1), 99, color, color, color))
	testing.expect_value(t, buffer.commands[0].bar.fill, Pixel_Rect{x = 0, y = 0, w = 16, h = 16})

	testing.expect(t, draw_bar(&buffer, cell_rect(0, 0, 2, 1), -1, color, color, color))
	testing.expect_value(t, buffer.commands[1].bar.fill, Pixel_Rect{x = 0, y = 0, w = 0, h = 16})
}
// END org:block test-draw-bar

// BEGIN org:block test-draw-overflow
@(test)
test_draw_buffer_overflow_records_debug_warning :: proc(t: ^testing.T) {
	command_storage: [1]Draw_Command
	warning_storage: [1]Debug_Warning
	debug := Debug_Buffer{warnings = warning_storage[:]}
	buffer := Draw_Buffer{commands = command_storage[:], debug = &debug}
	color := Color{a = 255}

	testing.expect(t, draw_box(&buffer, cell_rect(0, 0, 1, 1), color, color))
	testing.expect(t, !draw_box(&buffer, cell_rect(1, 0, 1, 1), color, color))
	testing.expect_value(t, buffer.count, 1)
	testing.expect_value(t, buffer.overflow_count, 1)
	testing.expect_value(t, debug.count, 1)
	testing.expect_value(t, debug.warnings[0].kind, Debug_Warning_Kind.Draw_Command_Overflow)
}
// END org:block test-draw-overflow

// BEGIN org:block test-ui-helper
test_ui_init :: proc(ui: ^UI, state: ^UI_State, draw: ^Draw_Buffer, debug: ^Debug_Buffer, command_storage: []Draw_Command, warning_storage: []Debug_Warning) {
	debug^ = Debug_Buffer{warnings = warning_storage}
	draw^ = Draw_Buffer{commands = command_storage, debug = debug}
	ui^ = ui_context(state, draw)
}
// END org:block test-ui-helper

// BEGIN org:block test-ui-text
@(test)
test_ui_text_emits_command_and_dedupes_overflow_warning :: proc(t: ^testing.T) {
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
	testing.expect_value(t, debug.count, 1)
	testing.expect_value(t, debug.warnings[0].kind, Debug_Warning_Kind.Text_Overflow)
	testing.expect_value(t, debug.warnings[0].measured_width, 24)
	testing.expect_value(t, debug.warnings[0].available_width, 8)
}
// END org:block test-ui-text

// BEGIN org:block test-ui-button
@(test)
test_ui_button_returns_release_inside_activation :: proc(t: ^testing.T) {
	command_storage: [8]Draw_Command
	warning_storage: [2]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])
	rect := cell_rect(0, 0, 4, 1)

	ui_begin_frame(&state, test_mouse_input(0, 0, left = true))
	testing.expect(t, !ui_button(&ui, UI_ID(2), rect, "go"))

	ui_begin_frame(&state, test_mouse_input(1, 1, left = false))
	testing.expect(t, ui_button(&ui, UI_ID(2), rect, "go"))
	testing.expect(t, state.activated_any)
	testing.expect(t, draw.count >= 4)
}
// END org:block test-ui-button

// BEGIN org:block test-ui-toggle
@(test)
test_ui_toggle_uses_active_style_and_returns_event :: proc(t: ^testing.T) {
	command_storage: [4]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])

	ui_begin_frame(&state, test_mouse_input(0, 0, left = true))
	testing.expect(t, !ui_toggle(&ui, UI_ID(3), cell_rect(0, 0, 6, 1), "snap", true))
	testing.expect_value(t, draw.commands[0].box.fill, ui.style.button_active_fill)
}
// END org:block test-ui-toggle

// BEGIN org:block test-ui-bar
@(test)
test_ui_bar_emits_proportional_fill :: proc(t: ^testing.T) {
	command_storage: [1]Draw_Command
	warning_storage: [1]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])
	ui_begin_frame(&state, test_mouse_input(0, 0))

	ui_bar(&ui, UI_ID(4), cell_rect(0, 0, 10, 1), 3, 10, ui.style.bar_fill)
	testing.expect_value(t, draw.commands[0].bar.fill.w, 24)
}
// END org:block test-ui-bar

// BEGIN org:block test-examples
@(test)
test_example_surfaces_emit_commands :: proc(t: ^testing.T) {
	command_storage: [16]Draw_Command
	warning_storage: [4]Debug_Warning
	ui: UI
	state: UI_State
	draw: Draw_Buffer
	debug: Debug_Buffer
	test_ui_init(&ui, &state, &draw, &debug, command_storage[:], warning_storage[:])
	ui_begin_frame(&state, test_mouse_input(0, 0))

	button, toggle := example_toolbar_surface(&ui, false)
	example_status_surface(&ui, 5, 10)

	testing.expect(t, !button)
	testing.expect(t, !toggle)
	testing.expect(t, draw.count > 0)
}
// END org:block test-examples
