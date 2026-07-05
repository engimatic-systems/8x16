// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block example-test-package
package surfaces
// END org:block example-test-package

// BEGIN org:block example-test-imports
import "core:testing"
import ui "../../ui8x16"
// END org:block example-test-imports

// BEGIN org:block example-test-helpers
expect_fill_rect_kind :: proc(t: ^testing.T, command: ui.Draw_Command) {
	_, ok := command.(ui.Fill_Rect_Command)
	testing.expect(t, ok)
}

expect_stroke_rect_kind :: proc(t: ^testing.T, command: ui.Draw_Command) {
	_, ok := command.(ui.Stroke_Rect_Command)
	testing.expect(t, ok)
}

expect_text_kind :: proc(t: ^testing.T, command: ui.Draw_Command) {
	_, ok := command.(ui.Text_Command)
	testing.expect(t, ok)
}

expect_text_value :: proc(t: ^testing.T, command: ui.Draw_Command, text: string) {
	payload, ok := command.(ui.Text_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.text, text)
	}
}

expect_text_pos :: proc(t: ^testing.T, command: ui.Draw_Command, pos: ui.Pixel_Point) {
	payload, ok := command.(ui.Text_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.pos, pos)
	}
}

expect_fill_rect_width :: proc(t: ^testing.T, command: ui.Draw_Command, width: int) {
	payload, ok := command.(ui.Fill_Rect_Command)
	testing.expect(t, ok)
	if ok {
		testing.expect_value(t, payload.rect.w, width)
	}
}

example_test_ui :: proc(frame: ^ui.UI, draw: ^ui.Draw_Buffer, debug: ^ui.Debug_Buffer, command_storage: []ui.Draw_Command, warning_storage: []ui.Debug_Warning) {
	draw^ = ui.draw_buffer(command_storage)
	debug^ = ui.Debug_Buffer{warnings = warning_storage}
	frame^ = ui.ui_context(draw, debug)
}
// END org:block example-test-helpers

// BEGIN org:block test-example-toolbar
@(test)
test_example_toolbar_surface_command_snapshot :: proc(t: ^testing.T) {
	command_storage: [16]ui.Draw_Command
	warning_storage: [4]ui.Debug_Warning
	frame: ui.UI
	draw: ui.Draw_Buffer
	debug: ui.Debug_Buffer
	example_test_ui(&frame, &draw, &debug, command_storage[:], warning_storage[:])

	example_toolbar_surface(&frame, true)
	commands := ui.ui_end(&draw)

	testing.expect_value(t, len(commands), 9)
	expect_fill_rect_kind(t, commands[0])
	expect_stroke_rect_kind(t, commands[1])
	expect_text_kind(t, commands[2])
	expect_text_value(t, commands[5], "run")
	expect_text_value(t, commands[8], "snap")
}
// END org:block test-example-toolbar

// BEGIN org:block test-example-status
@(test)
test_example_status_surface_command_snapshot :: proc(t: ^testing.T) {
	command_storage: [8]ui.Draw_Command
	warning_storage: [2]ui.Debug_Warning
	frame: ui.UI
	draw: ui.Draw_Buffer
	debug: ui.Debug_Buffer
	example_test_ui(&frame, &draw, &debug, command_storage[:], warning_storage[:])

	example_status_surface(&frame, 5, 10)
	commands := ui.ui_end(&draw)

	testing.expect_value(t, len(commands), 6)
	expect_fill_rect_kind(t, commands[0])
	expect_text_value(t, commands[2], "status")
	expect_fill_rect_width(t, commands[4], 120)
}
// END org:block test-example-status

// BEGIN org:block test-example-layout-options
@(test)
test_example_layout_options_surface_command_snapshot :: proc(t: ^testing.T) {
	command_storage: [16]ui.Draw_Command
	warning_storage: [4]ui.Debug_Warning
	frame: ui.UI
	draw: ui.Draw_Buffer
	debug: ui.Debug_Buffer
	example_test_ui(&frame, &draw, &debug, command_storage[:], warning_storage[:])

	example_layout_options_surface(&frame)
	commands := ui.ui_end(&draw)

	testing.expect_value(t, len(commands), 12)
	expect_text_value(t, commands[2], "layout options")
	expect_text_value(t, commands[5], "default")
	expect_text_pos(t, commands[5], ui.Pixel_Point{x = 10, y = 32})
	expect_text_value(t, commands[8], "one/half")
	expect_text_pos(t, commands[8], ui.Pixel_Point{x = 16, y = 72})
	expect_text_value(t, commands[11], "padded")
	expect_text_pos(t, commands[11], ui.Pixel_Point{x = 104, y = 72})
	testing.expect_value(t, debug.count, 0)
}
// END org:block test-example-layout-options

// BEGIN org:block test-example-dense-panel
@(test)
test_example_dense_control_panel_command_snapshot :: proc(t: ^testing.T) {
	command_storage: [24]ui.Draw_Command
	warning_storage: [4]ui.Debug_Warning
	frame: ui.UI
	draw: ui.Draw_Buffer
	debug: ui.Debug_Buffer
	example_test_ui(&frame, &draw, &debug, command_storage[:], warning_storage[:])

	example_dense_control_panel(&frame, true, false, 3, 6)
	commands := ui.ui_end(&draw)

	testing.expect_value(t, len(commands), 16)
	expect_text_value(t, commands[2], "control panel")
	expect_text_value(t, commands[5], "run")
	expect_text_value(t, commands[8], "material")
	expect_text_value(t, commands[11], "heat")
	expect_fill_rect_width(t, commands[13], 120)
	expect_text_value(t, commands[15], "cells use 8x16 grid")
}
// END org:block test-example-dense-panel

// BEGIN org:block test-example-drawing-controls
@(test)
test_example_drawing_controls_command_snapshot :: proc(t: ^testing.T) {
	command_storage: [24]ui.Draw_Command
	warning_storage: [4]ui.Debug_Warning
	frame: ui.UI
	draw: ui.Draw_Buffer
	debug: ui.Debug_Buffer
	example_test_ui(&frame, &draw, &debug, command_storage[:], warning_storage[:])

	example_drawing_controls_surface(&frame, true, false, 3, 8)
	commands := ui.ui_end(&draw)

	testing.expect_value(t, len(commands), 22)
	expect_text_value(t, commands[2], "draw lab")
	expect_text_value(t, commands[5], "clear")
	expect_text_value(t, commands[8], "erase")
	expect_text_value(t, commands[11], "grid")
	expect_text_value(t, commands[14], "-")
	expect_text_value(t, commands[17], "+")
	expect_text_value(t, commands[18], "brush size")
	expect_fill_rect_width(t, commands[20], 48)
}
// END org:block test-example-drawing-controls
