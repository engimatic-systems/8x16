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
