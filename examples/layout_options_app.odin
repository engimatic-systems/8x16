// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block example-layout-options-app
package main

import rl "vendor:raylib"
import surf "./surfaces"
import ui "../ui8x16"
import rui "../raylib_8x16"

WINDOW_WIDTH :: 224
WINDOW_HEIGHT :: 112

FONT_PATH :: "assets/fonts/PxPlus_IBM_VGA_8x16.ttf"

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "8x16 layout options")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	text_runes: [1024]rune
	renderer := rui.load_renderer(FONT_PATH, text_runes[:])
	defer rui.unload_renderer(&renderer)

	command_storage: [32]ui.Draw_Command
	warning_storage: [8]ui.Debug_Warning

	for !rl.WindowShouldClose() {
		debug := ui.Debug_Buffer{warnings = warning_storage[:]}
		draw := ui.draw_buffer(command_storage[:])
		frame := ui.ui_context(&draw, &debug)
		surf.example_layout_options_surface(&frame)
		commands := ui.ui_end(&draw)

		rl.BeginDrawing()
		rl.ClearBackground(rl.Color{12, 12, 14, 255})
		rui.render_commands(&renderer, commands)
		rl.EndDrawing()
	}
}
// END org:block example-layout-options-app
