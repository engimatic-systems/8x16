// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block examples-package
package ui8x16
// END org:block examples-package

// BEGIN org:block example-toolbar
example_toolbar_surface :: proc(ui: ^UI, toggle_active: bool) -> (button_activated, toggle_activated: bool) {
	ui_panel(ui, UI_ID(100), cell_rect(0, 0, 24, 3))
	ui_text(ui, UI_ID(101), cell_rect(1, 0, 8, 1), "tools", ui.style.text)
	button_activated = ui_button(ui, UI_ID(102), cell_rect(1, 1, 8, 1), "run")
	toggle_activated = ui_toggle(ui, UI_ID(103), cell_rect(10, 1, 10, 1), "snap", toggle_active)
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
