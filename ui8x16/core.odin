// Generated from ../8x16.org. Edit the org source.

// BEGIN org:block package
package ui8x16
// END org:block package

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
