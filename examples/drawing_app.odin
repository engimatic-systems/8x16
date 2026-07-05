// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block example-drawing-app
package main

import "core:c"
import rl "vendor:raylib"
import ui "../ui8x16"
import rui "../raylib_8x16"

WINDOW_WIDTH :: 400
WINDOW_HEIGHT :: 320

FONT_PATH :: "assets/fonts/PxPlus_IBM_VGA_8x16.ttf"

CANVAS_X :: 176
CANVAS_Y :: 64
CANVAS_COLS :: 64
CANVAS_ROWS :: 64
PIXEL_SIZE :: 3

MAX_BRUSH_SIZE :: 8

ID_CLEAR :: ui.UI_ID(402)
ID_ERASE :: ui.UI_ID(403)
ID_GRID  :: ui.UI_ID(404)
ID_BRUSH_DOWN :: ui.UI_ID(407)
ID_BRUSH_UP   :: ui.UI_ID(408)

Canvas :: struct {
	cells: [CANVAS_COLS * CANVAS_ROWS]bool,
}

App_State :: struct {
	erase:      bool,
	show_grid:  bool,
	brush_size: int,
}

raylib_mouse_input :: proc() -> ui.Mouse_Input {
	return ui.Mouse_Input{
		x = int(rl.GetMouseX()),
		y = int(rl.GetMouseY()),
		down = [ui.MOUSE_BUTTON_COUNT]bool{
			rl.IsMouseButtonDown(.LEFT),
			rl.IsMouseButtonDown(.MIDDLE),
			rl.IsMouseButtonDown(.RIGHT),
		},
	}
}

canvas_index :: proc(col, row: int) -> int {
	return row * CANVAS_COLS + col
}

clear_canvas :: proc(canvas: ^Canvas) {
	for i in 0..<len(canvas.cells) {
		canvas.cells[i] = false
	}
}

paint_canvas_at_mouse :: proc(canvas: ^Canvas, erase: bool, brush_size: int) -> bool {
	if !rl.IsMouseButtonDown(.LEFT) {
		return false
	}

	mouse_x := int(rl.GetMouseX())
	mouse_y := int(rl.GetMouseY())
	if mouse_x < CANVAS_X || mouse_y < CANVAS_Y {
		return false
	}

	col := (mouse_x - CANVAS_X) / PIXEL_SIZE
	row := (mouse_y - CANVAS_Y) / PIXEL_SIZE
	if col < 0 || col >= CANVAS_COLS || row < 0 || row >= CANVAS_ROWS {
		return false
	}

	next := !erase
	changed := false
	radius := brush_size / 2
	for brush_row in 0..<brush_size {
		for brush_col in 0..<brush_size {
			paint_col := col + brush_col - radius
			paint_row := row + brush_row - radius
			if paint_col < 0 || paint_col >= CANVAS_COLS || paint_row < 0 || paint_row >= CANVAS_ROWS {
				continue
			}

			index := canvas_index(paint_col, paint_row)
			if canvas.cells[index] != next {
				changed = true
			}
			canvas.cells[index] = next
		}
	}
	return changed
}

draw_canvas :: proc(canvas: ^Canvas, show_grid: bool) {
	canvas_w := CANVAS_COLS * PIXEL_SIZE
	canvas_h := CANVAS_ROWS * PIXEL_SIZE
	rl.DrawRectangle(CANVAS_X, CANVAS_Y, c.int(canvas_w), c.int(canvas_h), rl.Color{18, 18, 20, 255})

	for row in 0..<CANVAS_ROWS {
		for col in 0..<CANVAS_COLS {
			if canvas.cells[canvas_index(col, row)] {
				rl.DrawRectangle(
					c.int(CANVAS_X + col * PIXEL_SIZE),
					c.int(CANVAS_Y + row * PIXEL_SIZE),
					c.int(PIXEL_SIZE),
					c.int(PIXEL_SIZE),
					rl.Color{232, 224, 184, 255},
				)
			}
		}
	}

	if show_grid {
		for col in 0..=CANVAS_COLS {
			x := CANVAS_X + col * PIXEL_SIZE
			rl.DrawLine(c.int(x), CANVAS_Y, c.int(x), c.int(CANVAS_Y + canvas_h), rl.Color{42, 42, 46, 255})
		}
		for row in 0..=CANVAS_ROWS {
			y := CANVAS_Y + row * PIXEL_SIZE
			rl.DrawLine(CANVAS_X, c.int(y), c.int(CANVAS_X + canvas_w), c.int(y), rl.Color{42, 42, 46, 255})
		}
	}

	rl.DrawRectangleLines(CANVAS_X, CANVAS_Y, c.int(canvas_w), c.int(canvas_h), rl.Color{118, 118, 124, 255})
}

handle_controls :: proc(interaction: ^ui.UI_State, app: ^App_State, canvas: ^Canvas) {
	if ui.ui_activate(interaction, ID_CLEAR, ui.example_drawing_clear_rect()) {
		clear_canvas(canvas)
	}
	if ui.ui_activate(interaction, ID_ERASE, ui.example_drawing_erase_rect()) {
		app.erase = !app.erase
	}
	if ui.ui_activate(interaction, ID_GRID, ui.example_drawing_grid_rect()) {
		app.show_grid = !app.show_grid
	}
	if ui.ui_activate(interaction, ID_BRUSH_DOWN, ui.example_drawing_brush_down_rect()) {
		app.brush_size = ui.int_clamp(app.brush_size - 1, 1, MAX_BRUSH_SIZE)
	}
	if ui.ui_activate(interaction, ID_BRUSH_UP, ui.example_drawing_brush_up_rect()) {
		app.brush_size = ui.int_clamp(app.brush_size + 1, 1, MAX_BRUSH_SIZE)
	}
}

build_ui_commands :: proc(interaction: ^ui.UI_State, app: ^App_State, canvas: ^Canvas, command_storage: []ui.Draw_Command, warning_storage: []ui.Debug_Warning) -> []ui.Draw_Command {
	debug := ui.Debug_Buffer{warnings = warning_storage}
	draw := ui.draw_buffer(command_storage)
	frame := ui.ui_context(&draw, &debug)

	ui.example_drawing_controls_surface(
		&frame,
		app.erase,
		app.show_grid,
		app.brush_size,
		MAX_BRUSH_SIZE,
		clear_pressed = ui.ui_pressed(interaction, ID_CLEAR),
		erase_pressed = ui.ui_pressed(interaction, ID_ERASE),
		grid_pressed = ui.ui_pressed(interaction, ID_GRID),
		brush_down_pressed = ui.ui_pressed(interaction, ID_BRUSH_DOWN),
		brush_up_pressed = ui.ui_pressed(interaction, ID_BRUSH_UP),
	)

	return ui.ui_end(&draw)
}

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "8x16 drawing example")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	text_runes: [1024]rune
	renderer := rui.load_renderer(FONT_PATH, text_runes[:])
	defer rui.unload_renderer(&renderer)

	interaction: ui.UI_State
	app := App_State{show_grid = true, brush_size = 2}
	canvas: Canvas
	command_storage: [64]ui.Draw_Command
	warning_storage: [16]ui.Debug_Warning

	for !rl.WindowShouldClose() {
		ui.ui_begin_frame(&interaction, raylib_mouse_input())
		handle_controls(&interaction, &app, &canvas)
		if !interaction.hit_any {
			paint_canvas_at_mouse(&canvas, app.erase, app.brush_size)
		}

		commands := build_ui_commands(&interaction, &app, &canvas, command_storage[:], warning_storage[:])

		rl.BeginDrawing()
		rl.ClearBackground(rl.Color{12, 12, 14, 255})
		draw_canvas(&canvas, app.show_grid)
		rui.render_commands(&renderer, commands)
		rl.EndDrawing()
	}
}
// END org:block example-drawing-app
