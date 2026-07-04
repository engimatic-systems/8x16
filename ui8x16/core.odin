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

// BEGIN org:block color
Color :: struct {
	r, g, b, a: u8,
}
// END org:block color

// BEGIN org:block ui-id
UI_ID :: distinct u64
// END org:block ui-id

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
