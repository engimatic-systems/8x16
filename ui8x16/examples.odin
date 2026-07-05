// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block examples-package
package ui8x16
// END org:block examples-package

// BEGIN org:block example-toolbar
example_toolbar_surface :: proc(ui: ^UI, snap_active: bool, run_pressed: bool = false, snap_pressed: bool = false) {
	ui_panel(ui, UI_ID(100), cell_rect(0, 0, 24, 3))
	ui_text(ui, UI_ID(101), cell_rect(1, 0, 8, 1), "tools", ui.style.text)
	ui_button(ui, UI_ID(102), cell_rect(1, 1, 8, 1), "run", pressed = run_pressed)
	ui_toggle(ui, UI_ID(103), cell_rect(10, 1, 10, 1), "snap", snap_active, pressed = snap_pressed)
}
// END org:block example-toolbar

// BEGIN org:block example-status
example_status_surface :: proc(ui: ^UI, progress, max_progress: int) {
	ui_panel(ui, UI_ID(200), cell_rect(0, 0, 32, 4))
	ui_text(ui, UI_ID(201), cell_rect(1, 0, 12, 1), "status", ui.style.text)
	ui_bar(ui, UI_ID(202), cell_rect(1, 2, 30, 1), progress, max_progress, ui.style.bar_fill)
}
// END org:block example-status

// BEGIN org:block example-dense-panel
example_dense_control_panel :: proc(ui: ^UI, material_active, heat_active: bool, progress, max_progress: int, run_pressed: bool = false, material_pressed: bool = false, heat_pressed: bool = false) {
	ui_panel(ui, UI_ID(300), cell_rect(0, 0, 32, 8))
	ui_text(ui, UI_ID(301), cell_rect(1, 0, 18, 1), "control panel", ui.style.text)
	ui_button(ui, UI_ID(302), cell_rect(1, 2, 8, 1), "run", pressed = run_pressed)
	ui_toggle(ui, UI_ID(303), cell_rect(10, 2, 10, 1), "material", material_active, pressed = material_pressed)
	ui_toggle(ui, UI_ID(304), cell_rect(21, 2, 8, 1), "heat", heat_active, pressed = heat_pressed)
	ui_bar(ui, UI_ID(305), cell_rect(1, 4, 30, 1), progress, max_progress, ui.style.bar_fill)
	ui_text(ui, UI_ID(306), cell_rect(1, 6, 22, 1), "cells use 8x16 grid", ui.style.text)
}
// END org:block example-dense-panel

// BEGIN org:block example-drawing-control-rects
example_drawing_clear_rect :: proc() -> Cell_Rect {
	return cell_rect(1, 4, 7, 1)
}

example_drawing_erase_rect :: proc() -> Cell_Rect {
	return cell_rect(9, 4, 8, 1)
}

example_drawing_grid_rect :: proc() -> Cell_Rect {
	return cell_rect(1, 6, 7, 1)
}

example_drawing_brush_down_rect :: proc() -> Cell_Rect {
	return cell_rect(9, 6, 3, 1)
}

example_drawing_brush_up_rect :: proc() -> Cell_Rect {
	return cell_rect(13, 6, 3, 1)
}
// END org:block example-drawing-control-rects

// BEGIN org:block example-drawing-controls
example_drawing_controls_surface :: proc(ui: ^UI, erase_active, grid_active: bool, brush_size, max_brush_size: int, clear_pressed: bool = false, erase_pressed: bool = false, grid_pressed: bool = false, brush_down_pressed: bool = false, brush_up_pressed: bool = false) {
	ui_panel(ui, UI_ID(400), cell_rect(0, 0, 18, 16))
	ui_text(ui, UI_ID(401), cell_rect(1, 0, 16, 2), "draw lab", ui.style.text, scale = 2)
	ui_button(ui, UI_ID(402), example_drawing_clear_rect(), "clear", pressed = clear_pressed)
	ui_toggle(ui, UI_ID(403), example_drawing_erase_rect(), "erase", erase_active, pressed = erase_pressed)
	ui_toggle(ui, UI_ID(404), example_drawing_grid_rect(), "grid", grid_active, pressed = grid_pressed)
	ui_button(ui, UI_ID(407), example_drawing_brush_down_rect(), "-", pressed = brush_down_pressed)
	ui_button(ui, UI_ID(408), example_drawing_brush_up_rect(), "+", pressed = brush_up_pressed)
	ui_text(ui, UI_ID(406), cell_rect(1, 11, 10, 1), "brush size", ui.style.text)
	ui_bar(ui, UI_ID(405), cell_rect(1, 13, 16, 1), brush_size, max_brush_size, ui.style.bar_fill)
}
// END org:block example-drawing-controls
