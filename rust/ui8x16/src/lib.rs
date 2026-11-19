//! Immediate-mode UI primitives for small tools laid out on a fixed 8x16 grid.
//!
//! Interaction and rendering are deliberately separate. Sample input into an
//! [`InteractionState`], let the application update its own state, then use
//! [`Ui`] to lower that state into an ordered sequence of primitive
//! [`DrawCommand`] values.

#![forbid(unsafe_code)]

use std::error::Error;
use std::fmt;
use std::num::{NonZeroU32, NonZeroU64};

/// Width of one layout cell in pixels.
pub const CELL_WIDTH: u64 = 8;
/// Height of one layout cell in pixels.
pub const CELL_HEIGHT: u64 = 16;
const CELL_WIDTH_I64: i64 = 8;
const CELL_HEIGHT_I64: i64 = 16;
/// Number of mouse buttons tracked by the interaction state.
pub const MOUSE_BUTTON_COUNT: usize = 3;

/// Failure to construct or compose valid cell geometry.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GeometryError {
    /// A width of zero was supplied.
    ZeroWidth,
    /// A height of zero was supplied.
    ZeroHeight,
    /// Relative coordinate composition overflowed an `i32`.
    CoordinateOverflow,
}

impl fmt::Display for GeometryError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ZeroWidth => formatter.write_str("cell rectangle width must be positive"),
            Self::ZeroHeight => formatter.write_str("cell rectangle height must be positive"),
            Self::CoordinateOverflow => formatter.write_str("cell coordinate overflow"),
        }
    }
}

impl Error for GeometryError {}

/// An absolute rectangle in integer cell space.
///
/// Its private, non-zero dimensions make an invalid rectangle impossible to
/// obtain through the safe public API.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct CellRect {
    col: i32,
    row: i32,
    columns: NonZeroU32,
    rows: NonZeroU32,
}

impl CellRect {
    /// Constructs an absolute cell rectangle.
    ///
    /// # Errors
    ///
    /// Returns [`GeometryError::ZeroWidth`] or [`GeometryError::ZeroHeight`]
    /// when a dimension is zero.
    pub const fn new(col: i32, row: i32, columns: u32, rows: u32) -> Result<Self, GeometryError> {
        let Some(columns) = NonZeroU32::new(columns) else {
            return Err(GeometryError::ZeroWidth);
        };
        let Some(rows) = NonZeroU32::new(rows) else {
            return Err(GeometryError::ZeroHeight);
        };
        Ok(Self {
            col,
            row,
            columns,
            rows,
        })
    }

    /// Composes an offset with a parent and returns another absolute rectangle.
    ///
    /// # Errors
    ///
    /// Returns a dimension error from [`CellRect::new`] or
    /// [`GeometryError::CoordinateOverflow`] when the absolute origin cannot be
    /// represented.
    pub const fn relative_to(
        parent: Self,
        col: i32,
        row: i32,
        columns: u32,
        rows: u32,
    ) -> Result<Self, GeometryError> {
        let Some(col) = parent.col.checked_add(col) else {
            return Err(GeometryError::CoordinateOverflow);
        };
        let Some(row) = parent.row.checked_add(row) else {
            return Err(GeometryError::CoordinateOverflow);
        };
        Self::new(col, row, columns, rows)
    }

    /// Left edge in cells.
    #[must_use]
    pub const fn col(self) -> i32 {
        self.col
    }

    /// Top edge in cells.
    #[must_use]
    pub const fn row(self) -> i32 {
        self.row
    }

    /// Width in cells.
    #[must_use]
    pub const fn columns(self) -> u32 {
        self.columns.get()
    }

    /// Height in cells.
    #[must_use]
    pub const fn rows(self) -> u32 {
        self.rows.get()
    }

    /// Translates this cell-space rectangle to backend-facing pixels.
    #[must_use]
    pub const fn to_pixels(self) -> PixelRect {
        PixelRect {
            x: self.col as i64 * CELL_WIDTH_I64,
            y: self.row as i64 * CELL_HEIGHT_I64,
            width: self.columns.get() as u64 * CELL_WIDTH,
            height: self.rows.get() as u64 * CELL_HEIGHT,
        }
    }

    /// Tests a pixel point against half-open bounds.
    #[must_use]
    pub fn contains(self, point: PixelPoint) -> bool {
        self.to_pixels().contains(point)
    }
}

/// A backend-facing point in pixels.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub struct PixelPoint {
    /// Horizontal coordinate.
    pub x: i64,
    /// Vertical coordinate.
    pub y: i64,
}

impl PixelPoint {
    /// Constructs a pixel point.
    #[must_use]
    pub const fn new(x: i64, y: i64) -> Self {
        Self { x, y }
    }
}

/// A backend-facing rectangle in pixels.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub struct PixelRect {
    /// Left edge.
    pub x: i64,
    /// Top edge.
    pub y: i64,
    /// Width.
    pub width: u64,
    /// Height.
    pub height: u64,
}

impl PixelRect {
    /// Tests a point using half-open bounds without overflowing integer edges.
    #[must_use]
    pub fn contains(self, point: PixelPoint) -> bool {
        let x = i128::from(point.x);
        let y = i128::from(point.y);
        let left = i128::from(self.x);
        let top = i128::from(self.y);
        x >= left
            && y >= top
            && x < left + i128::from(self.width)
            && y < top + i128::from(self.height)
    }
}

/// A non-zero, caller-owned stable identity for a semantic UI element.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct UiId(NonZeroU64);

impl UiId {
    /// Constructs an ID, returning `None` for the reserved zero value.
    #[must_use]
    pub const fn new(value: u64) -> Option<Self> {
        match NonZeroU64::new(value) {
            Some(value) => Some(Self(value)),
            None => None,
        }
    }

    /// Returns the numeric ID.
    #[must_use]
    pub const fn get(self) -> u64 {
        self.0.get()
    }
}

/// Mouse buttons independently tracked for press/release activation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[repr(usize)]
pub enum MouseButton {
    /// Primary mouse button.
    Left = 0,
    /// Middle mouse button.
    Middle = 1,
    /// Secondary mouse button.
    Right = 2,
}

/// Mouse position and sampled down state for one frame.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct MouseInput {
    /// Mouse position in backend pixels.
    pub position: PixelPoint,
    /// Down state ordered as left, middle, right.
    pub down: [bool; MOUSE_BUTTON_COUNT],
}

impl MouseInput {
    /// Constructs sampled input.
    #[must_use]
    pub const fn new(position: PixelPoint, down: [bool; MOUSE_BUTTON_COUNT]) -> Self {
        Self { position, down }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct PressOrigin {
    id: UiId,
    rect: CellRect,
}

/// Caller-owned interaction state sampled once per frame.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct InteractionState {
    mouse: MouseInput,
    previous_down: [bool; MOUSE_BUTTON_COUNT],
    pressed: [Option<PressOrigin>; MOUSE_BUTTON_COUNT],
    hit_any: bool,
    activated_any: bool,
}

impl InteractionState {
    /// Begins a frame with newly sampled platform input.
    pub fn begin_frame(&mut self, input: MouseInput) {
        for index in 0..MOUSE_BUTTON_COUNT {
            // Keep the press origin through the release frame so queries can
            // observe it; clear it on the following frame.
            if self.previous_down[index] && !self.mouse.down[index] {
                self.pressed[index] = None;
            }
            self.previous_down[index] = self.mouse.down[index];
        }

        self.mouse = input;
        self.hit_any = false;
        self.activated_any = false;
    }

    /// Tests a rectangle and updates advisory pointer-routing metadata.
    pub fn hit(&mut self, rect: CellRect) -> bool {
        let hit = rect.contains(self.mouse.position);
        self.hit_any |= hit;
        hit
    }

    /// Returns an activation only when press and release use the same ID and rect.
    pub fn activate(&mut self, id: UiId, rect: CellRect, button: MouseButton) -> bool {
        let index = button as usize;
        let hit = self.hit(rect);
        let pressed = !self.previous_down[index] && self.mouse.down[index];
        let released = self.previous_down[index] && !self.mouse.down[index];
        let origin = PressOrigin { id, rect };

        if pressed && hit {
            self.pressed[index] = Some(origin);
        }

        let activated = released && hit && self.pressed[index] == Some(origin);
        self.activated_any |= activated;
        activated
    }

    /// Reports whether a control owns a currently held press.
    #[must_use]
    pub fn is_pressed(&self, id: UiId, rect: CellRect, button: MouseButton) -> bool {
        let index = button as usize;
        self.mouse.down[index] && self.pressed[index] == Some(PressOrigin { id, rect })
    }

    /// Whether any queried region was hit during this frame.
    #[must_use]
    pub const fn hit_any(&self) -> bool {
        self.hit_any
    }

    /// Whether any queried control activated during this frame.
    #[must_use]
    pub const fn activated_any(&self) -> bool {
        self.activated_any
    }
}

/// A plain backend-facing RGBA color.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub struct Color {
    /// Red channel.
    pub r: u8,
    /// Green channel.
    pub g: u8,
    /// Blue channel.
    pub b: u8,
    /// Alpha channel.
    pub a: u8,
}

impl Color {
    /// Constructs an RGBA color.
    #[must_use]
    pub const fn rgba(r: u8, g: u8, b: u8, a: u8) -> Self {
        Self { r, g, b, a }
    }
}

/// The only supported integer text scales.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
#[repr(u8)]
pub enum TextScale {
    /// 8x16 pixels per byte.
    #[default]
    One = 1,
    /// 16x32 pixels per byte.
    Two = 2,
    /// 24x48 pixels per byte.
    Three = 3,
    /// 32x64 pixels per byte.
    Four = 4,
}

impl TextScale {
    /// Returns the integer scale factor.
    #[must_use]
    pub const fn factor(self) -> u64 {
        self as u64
    }
}

/// Failure to convert an integer to [`TextScale`].
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct InvalidTextScale(pub u8);

impl fmt::Display for InvalidTextScale {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "text scale must be 1..=4, got {}", self.0)
    }
}

impl Error for InvalidTextScale {}

impl TryFrom<u8> for TextScale {
    type Error = InvalidTextScale;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value {
            1 => Ok(Self::One),
            2 => Ok(Self::Two),
            3 => Ok(Self::Three),
            4 => Ok(Self::Four),
            other => Err(InvalidTextScale(other)),
        }
    }
}

/// A primitive, backend-ready draw command.
///
/// Commands are rendered in slice order. There is no z coordinate, sorting,
/// clipping, or semantic `Button`/`Bar` variant.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DrawCommand<'text> {
    /// Fill a pixel rectangle.
    FillRect { rect: PixelRect, color: Color },
    /// Stroke a pixel rectangle with backend-defined one-pixel lines.
    StrokeRect { rect: PixelRect, color: Color },
    /// Draw borrowed text at a pixel origin.
    Text {
        pos: PixelPoint,
        text: &'text str,
        color: Color,
        scale: TextScale,
    },
}

/// A loud command-capacity failure; the command is not appended.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CommandOverflow {
    /// Configured maximum number of commands.
    pub capacity: usize,
}

impl fmt::Display for CommandOverflow {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            formatter,
            "draw command buffer capacity {} exceeded",
            self.capacity
        )
    }
}

impl Error for CommandOverflow {}

/// An append-only, explicitly capacity-bounded primitive command buffer.
#[derive(Clone, Debug)]
pub struct CommandBuffer<'text> {
    commands: Vec<DrawCommand<'text>>,
    capacity: usize,
}

impl<'text> CommandBuffer<'text> {
    /// Allocates storage for exactly `capacity` commands.
    #[must_use]
    pub fn new(capacity: usize) -> Self {
        Self {
            commands: Vec::with_capacity(capacity),
            capacity,
        }
    }

    /// Appends a primitive command or returns a loud overflow error.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when the configured capacity is full.
    pub fn push(&mut self, command: DrawCommand<'text>) -> Result<(), CommandOverflow> {
        if self.commands.len() == self.capacity {
            return Err(CommandOverflow {
                capacity: self.capacity,
            });
        }
        self.commands.push(command);
        Ok(())
    }

    /// Returns the ordered backend handoff slice.
    #[must_use]
    pub fn as_slice(&self) -> &[DrawCommand<'text>] {
        &self.commands
    }

    /// Clears commands while retaining allocated storage.
    pub fn clear(&mut self) {
        self.commands.clear();
    }
}

/// The kind of a compiler diagnostic.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum DebugWarningKind {
    /// Text exceeds its semantic rectangle.
    TextOverflow,
    /// One-cell/half-cell padding was used with a control that is too short.
    ControlLabelPaddingTooShort,
}

/// A semantic compiler diagnostic emitted before primitive drawing.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DebugWarning<'text> {
    /// Fixed-metric text is wider than its remaining bounds.
    TextOverflow {
        id: UiId,
        rect: CellRect,
        text: &'text str,
        measured_width: u64,
        available_width: u64,
    },
    /// Padded control text lacks the required two scaled rows of height.
    ControlLabelPaddingTooShort { id: UiId, rect: CellRect },
}

impl DebugWarning<'_> {
    /// Returns this warning's stable semantic identity.
    #[must_use]
    pub const fn id(&self) -> UiId {
        match *self {
            Self::TextOverflow { id, .. } | Self::ControlLabelPaddingTooShort { id, .. } => id,
        }
    }

    /// Returns this warning's category.
    #[must_use]
    pub const fn kind(&self) -> DebugWarningKind {
        match self {
            Self::TextOverflow { .. } => DebugWarningKind::TextOverflow,
            Self::ControlLabelPaddingTooShort { .. } => {
                DebugWarningKind::ControlLabelPaddingTooShort
            }
        }
    }
}

/// Optional, bounded compiler diagnostics with per-kind, per-ID deduplication.
#[derive(Clone, Debug)]
pub struct DebugBuffer<'text> {
    warnings: Vec<DebugWarning<'text>>,
    capacity: usize,
    overflowed: bool,
}

impl<'text> DebugBuffer<'text> {
    /// Allocates storage for up to `capacity` warnings.
    #[must_use]
    pub fn new(capacity: usize) -> Self {
        Self {
            warnings: Vec::with_capacity(capacity),
            capacity,
            overflowed: false,
        }
    }

    fn record(&mut self, warning: DebugWarning<'text>) -> bool {
        if self
            .warnings
            .iter()
            .any(|existing| existing.kind() == warning.kind() && existing.id() == warning.id())
        {
            return false;
        }
        if self.warnings.len() == self.capacity {
            self.overflowed = true;
            return false;
        }
        self.warnings.push(warning);
        true
    }

    /// Returns emitted warnings in discovery order.
    #[must_use]
    pub fn as_slice(&self) -> &[DebugWarning<'text>] {
        &self.warnings
    }

    /// Whether warning capacity was exceeded.
    #[must_use]
    pub const fn overflowed(&self) -> bool {
        self.overflowed
    }

    /// Clears diagnostics while retaining allocated storage.
    pub fn clear(&mut self) {
        self.warnings.clear();
        self.overflowed = false;
    }
}

/// Minimal semantic chrome resolved before commands reach a backend.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Style {
    pub text: Color,
    pub line: Color,
    pub panel: Color,
    pub button_fill: Color,
    pub button_text: Color,
    pub button_active_fill: Color,
    pub button_active_text: Color,
    pub bar_fill: Color,
    pub bar_empty: Color,
}

impl Default for Style {
    fn default() -> Self {
        Self {
            text: Color::rgba(230, 230, 230, 255),
            line: Color::rgba(80, 80, 80, 255),
            panel: Color::rgba(24, 24, 24, 255),
            button_fill: Color::rgba(48, 48, 48, 255),
            button_text: Color::rgba(235, 235, 235, 255),
            button_active_fill: Color::rgba(220, 220, 220, 255),
            button_active_text: Color::rgba(16, 16, 16, 255),
            bar_fill: Color::rgba(96, 180, 120, 255),
            bar_empty: Color::rgba(44, 44, 44, 255),
        }
    }
}

/// Layout policy for button-like control labels.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum LabelPadding {
    /// Compact two-pixel horizontal inset and no vertical inset.
    #[default]
    Compact,
    /// One scaled cell horizontally and half a scaled cell vertically.
    OneCellHalfVertical,
}

/// Stable display options for button-like controls.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct ControlOptions {
    /// Label scale.
    pub scale: TextScale,
    /// Label inset policy.
    pub label_padding: LabelPadding,
}

/// Per-frame semantic-to-primitive command compiler.
pub struct Ui<'output, 'text> {
    commands: &'output mut CommandBuffer<'text>,
    debug: Option<&'output mut DebugBuffer<'text>>,
    style: Style,
}

impl<'output, 'text> Ui<'output, 'text> {
    /// Creates a compiler using the default style and optional diagnostics.
    pub fn new(
        commands: &'output mut CommandBuffer<'text>,
        debug: Option<&'output mut DebugBuffer<'text>>,
    ) -> Self {
        Self::with_style(commands, debug, Style::default())
    }

    /// Creates a compiler with caller-provided chrome styling.
    pub fn with_style(
        commands: &'output mut CommandBuffer<'text>,
        debug: Option<&'output mut DebugBuffer<'text>>,
        style: Style,
    ) -> Self {
        Self {
            commands,
            debug,
            style,
        }
    }

    /// Returns the resolved chrome style.
    #[must_use]
    pub const fn style(&self) -> Style {
        self.style
    }

    /// Lowers fixed-metric text at the rectangle origin.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when its primitive cannot be appended.
    pub fn text(
        &mut self,
        id: UiId,
        rect: CellRect,
        text: &'text str,
        color: Color,
        scale: TextScale,
    ) -> Result<(), CommandOverflow> {
        let px = rect.to_pixels();
        self.compile_text(id, rect, PixelPoint::new(px.x, px.y), text, color, scale)
    }

    /// Lowers a filled and stroked rectangle.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when either primitive cannot be appended.
    pub fn box_(
        &mut self,
        rect: CellRect,
        fill: Color,
        line: Color,
    ) -> Result<(), CommandOverflow> {
        let rect = rect.to_pixels();
        self.commands
            .push(DrawCommand::FillRect { rect, color: fill })?;
        self.commands
            .push(DrawCommand::StrokeRect { rect, color: line })
    }

    /// Lowers a panel using the current style.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when either primitive cannot be appended.
    pub fn panel(&mut self, rect: CellRect) -> Result<(), CommandOverflow> {
        self.box_(rect, self.style.panel, self.style.line)
    }

    /// Lowers a clamped scalar bar to empty fill, value fill, and outline.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when any primitive cannot be appended.
    pub fn bar(
        &mut self,
        rect: CellRect,
        value: i64,
        max_value: i64,
        fill: Color,
    ) -> Result<(), CommandOverflow> {
        let bounds = rect.to_pixels();
        let filled_width = if max_value > 0 {
            let clamped = value.clamp(0, max_value).cast_unsigned();
            let maximum = max_value.cast_unsigned();
            u64::try_from((u128::from(bounds.width) * u128::from(clamped)) / u128::from(maximum))
                .unwrap_or(bounds.width)
        } else {
            0
        };
        let filled = PixelRect {
            width: filled_width,
            ..bounds
        };

        self.commands.push(DrawCommand::FillRect {
            rect: bounds,
            color: self.style.bar_empty,
        })?;
        self.commands.push(DrawCommand::FillRect {
            rect: filled,
            color: fill,
        })?;
        self.commands.push(DrawCommand::StrokeRect {
            rect: bounds,
            color: self.style.line,
        })
    }

    /// Lowers a button visual; interaction remains caller-owned.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when any primitive cannot be appended.
    pub fn button(
        &mut self,
        id: UiId,
        rect: CellRect,
        label: &'text str,
        options: ControlOptions,
        pressed: bool,
    ) -> Result<(), CommandOverflow> {
        self.button_like(id, rect, label, options, pressed)
    }

    /// Lowers a toggle visual without mutating caller-owned active state.
    ///
    /// # Errors
    ///
    /// Returns [`CommandOverflow`] when any primitive cannot be appended.
    pub fn toggle(
        &mut self,
        id: UiId,
        rect: CellRect,
        label: &'text str,
        active: bool,
        options: ControlOptions,
        pressed: bool,
    ) -> Result<(), CommandOverflow> {
        self.button_like(id, rect, label, options, active || pressed)
    }

    fn button_like(
        &mut self,
        id: UiId,
        rect: CellRect,
        label: &'text str,
        options: ControlOptions,
        highlighted: bool,
    ) -> Result<(), CommandOverflow> {
        let (fill, text_color) = if highlighted {
            (self.style.button_active_fill, self.style.button_active_text)
        } else {
            (self.style.button_fill, self.style.button_text)
        };
        self.box_(rect, fill, self.style.line)?;
        let pos = self.control_label_origin(id, rect, options);
        self.compile_text(id, rect, pos, label, text_color, options.scale)
    }

    fn control_label_origin(
        &mut self,
        id: UiId,
        rect: CellRect,
        options: ControlOptions,
    ) -> PixelPoint {
        let px = rect.to_pixels();
        match options.label_padding {
            LabelPadding::Compact => PixelPoint::new(px.x + 2, px.y),
            LabelPadding::OneCellHalfVertical => {
                let scale = options.scale.factor();
                let horizontal_inset =
                    i64::try_from(CELL_WIDTH * scale).expect("supported text scale inset fits i64");
                let x = px.x + horizontal_inset;
                let required_height = CELL_HEIGHT * scale * 2;
                if px.height < required_height {
                    self.record_warning(DebugWarning::ControlLabelPaddingTooShort { id, rect });
                    PixelPoint::new(x, px.y)
                } else {
                    let vertical_inset = i64::try_from(CELL_HEIGHT * scale / 2)
                        .expect("supported text scale inset fits i64");
                    PixelPoint::new(x, px.y + vertical_inset)
                }
            }
        }
    }

    fn compile_text(
        &mut self,
        id: UiId,
        rect: CellRect,
        pos: PixelPoint,
        text: &'text str,
        color: Color,
        scale: TextScale,
    ) -> Result<(), CommandOverflow> {
        let byte_count = u64::try_from(text.len()).expect("text byte length does not fit u64");
        let measured_width = byte_count
            .checked_mul(CELL_WIDTH * scale.factor())
            .expect("text measurement overflow");
        let bounds = rect.to_pixels();
        let available = i128::from(bounds.x) + i128::from(bounds.width) - i128::from(pos.x);
        let available_width = u64::try_from(available.max(0)).unwrap_or(u64::MAX);

        if measured_width > available_width {
            self.record_warning(DebugWarning::TextOverflow {
                id,
                rect,
                text,
                measured_width,
                available_width,
            });
        }

        self.commands.push(DrawCommand::Text {
            pos,
            text,
            color,
            scale,
        })
    }

    fn record_warning(&mut self, warning: DebugWarning<'text>) {
        if let Some(debug) = self.debug.as_deref_mut() {
            debug.record(warning);
        }
    }
}
