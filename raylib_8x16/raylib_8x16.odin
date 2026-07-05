// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block raylib-package
package raylib_8x16
// END org:block raylib-package

// BEGIN org:block raylib-imports
import "core:c"
import "core:testing"
import rl "vendor:raylib"
import ui "../ui8x16"
// END org:block raylib-imports

// BEGIN org:block raylib-renderer
Renderer :: struct {
	font:       rl.Font,
	text_runes: []rune,
	spacing:    f32,
}
// END org:block raylib-renderer

// BEGIN org:block raylib-color
raylib_color :: proc(color: ui.Color) -> rl.Color {
	return rl.Color{color.r, color.g, color.b, color.a}
}
// END org:block raylib-color

// BEGIN org:block raylib-rect
raylib_rect :: proc(rect: ui.Pixel_Rect) -> rl.Rectangle {
	return rl.Rectangle{
		x = f32(rect.x),
		y = f32(rect.y),
		width = f32(rect.w),
		height = f32(rect.h),
	}
}
// END org:block raylib-rect

// BEGIN org:block raylib-point
raylib_point :: proc(point: ui.Pixel_Point) -> rl.Vector2 {
	return rl.Vector2{f32(point.x), f32(point.y)}
}
// END org:block raylib-point

// BEGIN org:block raylib-renderer-procs
load_renderer :: proc(font_path: cstring, text_runes: []rune, spacing: f32 = 0) -> Renderer {
	font := rl.LoadFont(font_path)
	rl.SetTextureFilter(font.texture, .POINT)
	return Renderer{font = font, text_runes = text_runes, spacing = spacing}
}

unload_renderer :: proc(renderer: ^Renderer) {
	rl.UnloadFont(renderer.font)
}
// END org:block raylib-renderer-procs

// BEGIN org:block raylib-text-runes
text_runes :: proc(renderer: ^Renderer, text: string) -> []rune {
	assert(len(text) <= len(renderer.text_runes), "Renderer text rune scratch too small")
	for i in 0..<len(text) {
		renderer.text_runes[i] = rune(text[i])
	}
	return renderer.text_runes[:len(text)]
}
// END org:block raylib-text-runes

// BEGIN org:block raylib-render-command
render_command :: proc(renderer: ^Renderer, command: ui.Draw_Command) {
	switch payload in command {
	case ui.Fill_Rect_Command:
		rl.DrawRectangleRec(raylib_rect(payload.rect), raylib_color(payload.color))
	case ui.Stroke_Rect_Command:
		rl.DrawRectangleLinesEx(raylib_rect(payload.rect), 1, raylib_color(payload.color))
	case ui.Text_Command:
		runes := text_runes(renderer, payload.text)
		rl.DrawTextCodepoints(
			renderer.font,
			raw_data(runes),
			c.int(len(runes)),
			raylib_point(payload.pos),
			f32(ui.CELL_HEIGHT * payload.scale),
			renderer.spacing,
			raylib_color(payload.color),
		)
	}
}
// END org:block raylib-render-command

// BEGIN org:block raylib-render-commands
render_commands :: proc(renderer: ^Renderer, commands: []ui.Draw_Command) {
	for command in commands {
		render_command(renderer, command)
	}
}
// END org:block raylib-render-commands

// BEGIN org:block raylib-smoke
smoke_commands :: proc(storage: []ui.Draw_Command) -> []ui.Draw_Command {
	buffer := ui.draw_buffer(storage)
	ui.draw_fill_rect(&buffer, ui.Pixel_Rect{x = 0, y = 0, w = 80, h = 32}, ui.Color{r = 24, g = 24, b = 24, a = 255})
	ui.draw_stroke_rect(&buffer, ui.Pixel_Rect{x = 0, y = 0, w = 80, h = 32}, ui.Color{r = 180, g = 180, b = 180, a = 255})
	ui.draw_text(&buffer, ui.Pixel_Point{x = 8, y = 8}, "8x16", ui.Color{r = 235, g = 235, b = 235, a = 255}, 1)
	return ui.ui_end(&buffer)
}

smoke_render :: proc(renderer: ^Renderer, storage: []ui.Draw_Command) {
	render_commands(renderer, smoke_commands(storage))
}
// END org:block raylib-smoke

// BEGIN org:block raylib-smoke-test
@(test)
test_smoke_commands_emit_primitives :: proc(t: ^testing.T) {
	storage: [3]ui.Draw_Command
	commands := smoke_commands(storage[:])

	testing.expect_value(t, len(commands), 3)
	_, fill_ok := commands[0].(ui.Fill_Rect_Command)
	_, stroke_ok := commands[1].(ui.Stroke_Rect_Command)
	_, text_ok := commands[2].(ui.Text_Command)
	testing.expect(t, fill_ok)
	testing.expect(t, stroke_ok)
	testing.expect(t, text_ok)
}
// END org:block raylib-smoke-test

// BEGIN org:block raylib-workbench-smoke
workbench_smoke_commands :: proc(command_storage: []ui.Draw_Command, warning_storage: []ui.Debug_Warning) -> []ui.Draw_Command {
	debug := ui.Debug_Buffer{warnings = warning_storage}
	draw := ui.draw_buffer(command_storage)
	frame := ui.ui_context(&draw, &debug)

	ui.example_dense_control_panel(&frame, true, false, 4, 8)
	return ui.ui_end(&draw)
}
// END org:block raylib-workbench-smoke

// BEGIN org:block raylib-workbench-smoke-test
@(test)
test_workbench_smoke_commands_emit_dense_panel :: proc(t: ^testing.T) {
	command_storage: [24]ui.Draw_Command
	warning_storage: [4]ui.Debug_Warning
	commands := workbench_smoke_commands(command_storage[:], warning_storage[:])

	testing.expect_value(t, len(commands), 16)
	_, fill_ok := commands[0].(ui.Fill_Rect_Command)
	_, text_ok := commands[15].(ui.Text_Command)
	testing.expect(t, fill_ok)
	testing.expect(t, text_ok)
}
// END org:block raylib-workbench-smoke-test
