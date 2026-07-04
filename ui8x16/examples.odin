// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block examples-package
package ui8x16
// END org:block examples-package

// BEGIN org:block example-toolbar
example_toolbar_surface :: proc(ui: ^UI, snap_active: bool) -> (run_activated, snap_activated: bool) {
	ui_panel(ui, UI_ID(100), cell_rect(0, 0, 24, 3))
	ui_text(ui, UI_ID(101), cell_rect(1, 0, 8, 1), "tools", ui.style.text)
	run_activated = ui_button(ui, UI_ID(102), cell_rect(1, 1, 8, 1), "run")
	snap_activated = ui_toggle(ui, UI_ID(103), cell_rect(10, 1, 10, 1), "snap", snap_active)
	return
}
// END org:block example-toolbar

// BEGIN org:block example-status
example_status_surface :: proc(ui: ^UI, progress, max_progress: int) {
	ui_panel(ui, UI_ID(200), cell_rect(0, 0, 32, 4))
	ui_text(ui, UI_ID(201), cell_rect(1, 0, 12, 1), "status", ui.style.text)
	ui_bar(ui, UI_ID(202), cell_rect(1, 2, 30, 1), progress, max_progress, ui.style.bar_fill)
}
// END org:block example-status

// BEGIN org:block example-dense-result
Dense_Control_Result :: struct {
	run:      bool,
	material: bool,
	heat:     bool,
}
// END org:block example-dense-result

// BEGIN org:block example-dense-panel
example_dense_control_panel :: proc(ui: ^UI, material_active, heat_active: bool, progress, max_progress: int) -> Dense_Control_Result {
	result: Dense_Control_Result

	ui_panel(ui, UI_ID(300), cell_rect(0, 0, 32, 8))
	ui_text(ui, UI_ID(301), cell_rect(1, 0, 18, 1), "control panel", ui.style.text)
	result.run = ui_button(ui, UI_ID(302), cell_rect(1, 2, 8, 1), "run")
	result.material = ui_toggle(ui, UI_ID(303), cell_rect(10, 2, 10, 1), "material", material_active)
	result.heat = ui_toggle(ui, UI_ID(304), cell_rect(21, 2, 8, 1), "heat", heat_active)
	ui_bar(ui, UI_ID(305), cell_rect(1, 4, 30, 1), progress, max_progress, ui.style.bar_fill)
	ui_text(ui, UI_ID(306), cell_rect(1, 6, 22, 1), "cells use 8x16 grid", ui.style.text)

	return result
}
// END org:block example-dense-panel
