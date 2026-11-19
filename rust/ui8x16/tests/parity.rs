use ui8x16::{
    CELL_HEIGHT, CELL_WIDTH, CellRect, Color, CommandBuffer, ControlOptions, DebugBuffer,
    DebugWarning, DrawCommand, GeometryError, InteractionState, LabelPadding, MouseButton,
    MouseInput, PixelPoint, PixelRect, TextScale, Ui, UiId,
};

fn rect(col: i32, row: i32, columns: u32, rows: u32) -> CellRect {
    CellRect::new(col, row, columns, rows).unwrap()
}

fn id(value: u64) -> UiId {
    UiId::new(value).unwrap()
}

fn mouse(x: i64, y: i64, left: bool) -> MouseInput {
    MouseInput::new(PixelPoint::new(x, y), [left, false, false])
}

#[test]
fn geometry_is_absolute_non_zero_and_fixed_metric() {
    let parent = rect(10, 20, 30, 40);
    let child = CellRect::relative_to(parent, 2, 3, 4, 5).unwrap();

    assert_eq!(
        (child.col(), child.row(), child.columns(), child.rows()),
        (12, 23, 4, 5)
    );
    assert_eq!(
        child.to_pixels(),
        PixelRect {
            x: 96,
            y: 368,
            width: 4 * CELL_WIDTH,
            height: 5 * CELL_HEIGHT,
        }
    );
    assert_eq!(CellRect::new(0, 0, 0, 1), Err(GeometryError::ZeroWidth));
    assert_eq!(CellRect::new(0, 0, 1, 0), Err(GeometryError::ZeroHeight));
}

#[test]
fn hit_testing_uses_half_open_pixel_bounds() {
    let bounds = rect(1, 2, 3, 4);

    assert!(bounds.contains(PixelPoint::new(8, 32)));
    assert!(bounds.contains(PixelPoint::new(31, 95)));
    assert!(!bounds.contains(PixelPoint::new(7, 32)));
    assert!(!bounds.contains(PixelPoint::new(8, 31)));
    assert!(!bounds.contains(PixelPoint::new(32, 32)));
    assert!(!bounds.contains(PixelPoint::new(8, 96)));
}

#[test]
fn activation_requires_press_and_release_inside_the_same_control() {
    let mut state = InteractionState::default();
    let control = rect(1, 1, 2, 2);
    let control_id = id(10);

    state.begin_frame(mouse(8, 16, true));
    assert!(!state.activate(control_id, control, MouseButton::Left));
    assert!(state.hit_any());
    assert!(state.is_pressed(control_id, control, MouseButton::Left));

    state.begin_frame(mouse(9, 17, false));
    assert!(state.activate(control_id, control, MouseButton::Left));
    assert!(state.activated_any());
}

#[test]
fn activation_rejects_release_inside_a_different_control() {
    let mut state = InteractionState::default();
    let a = rect(1, 1, 2, 2);
    let b = rect(4, 1, 2, 2);

    state.begin_frame(mouse(8, 16, true));
    assert!(!state.activate(id(1), a, MouseButton::Left));
    assert!(!state.activate(id(2), b, MouseButton::Left));

    state.begin_frame(mouse(32, 16, false));
    assert!(!state.activate(id(2), b, MouseButton::Left));
    assert!(!state.activate(id(1), a, MouseButton::Left));
    assert!(!state.activated_any());
}

#[test]
fn activation_allows_leave_return_release() {
    let mut state = InteractionState::default();
    let control = rect(1, 1, 2, 2);
    let control_id = id(1);

    state.begin_frame(mouse(8, 16, true));
    assert!(!state.activate(control_id, control, MouseButton::Left));

    state.begin_frame(mouse(80, 80, true));
    assert!(!state.activate(control_id, control, MouseButton::Left));

    state.begin_frame(mouse(9, 17, false));
    assert!(state.activate(control_id, control, MouseButton::Left));

    state.begin_frame(mouse(9, 17, false));
    assert!(!state.is_pressed(control_id, control, MouseButton::Left));
}

#[test]
fn activation_identity_includes_the_rectangle() {
    let mut state = InteractionState::default();
    let original = rect(0, 0, 2, 1);
    let moved = rect(0, 0, 3, 1);
    let same_id = id(7);

    state.begin_frame(mouse(0, 0, true));
    assert!(!state.activate(same_id, original, MouseButton::Left));
    state.begin_frame(mouse(0, 0, false));
    assert!(!state.activate(same_id, moved, MouseButton::Left));
}

#[test]
fn primitive_commands_are_ordered_and_overflow_is_loud() {
    let color = Color::rgba(1, 2, 3, 4);
    let pixel_rect = PixelRect {
        x: 0,
        y: 0,
        width: 8,
        height: 16,
    };
    let mut commands = CommandBuffer::new(3);
    commands
        .push(DrawCommand::FillRect {
            rect: pixel_rect,
            color,
        })
        .unwrap();
    commands
        .push(DrawCommand::StrokeRect {
            rect: pixel_rect,
            color,
        })
        .unwrap();
    commands
        .push(DrawCommand::Text {
            pos: PixelPoint::new(2, 3),
            text: "x",
            color,
            scale: TextScale::One,
        })
        .unwrap();

    assert!(matches!(
        commands.as_slice()[0],
        DrawCommand::FillRect { .. }
    ));
    assert!(matches!(
        commands.as_slice()[1],
        DrawCommand::StrokeRect { .. }
    ));
    assert!(matches!(commands.as_slice()[2], DrawCommand::Text { .. }));
    assert_eq!(
        commands
            .push(DrawCommand::FillRect {
                rect: pixel_rect,
                color
            })
            .unwrap_err()
            .capacity,
        3
    );
    assert!(TextScale::try_from(0).is_err());
    assert!(TextScale::try_from(5).is_err());
}

#[test]
fn text_overflow_is_measured_in_bytes_and_deduped_by_id() {
    let mut commands = CommandBuffer::new(2);
    let mut debug = DebugBuffer::new(2);
    let style;
    {
        let mut ui = Ui::new(&mut commands, Some(&mut debug));
        style = ui.style();
        ui.text(id(1), rect(0, 0, 1, 1), "abc", style.text, TextScale::One)
            .unwrap();
        ui.text(id(1), rect(0, 0, 1, 1), "abc", style.text, TextScale::One)
            .unwrap();
    }

    assert_eq!(commands.as_slice().len(), 2);
    assert_eq!(debug.as_slice().len(), 1);
    assert_eq!(
        debug.as_slice()[0],
        DebugWarning::TextOverflow {
            id: id(1),
            rect: rect(0, 0, 1, 1),
            text: "abc",
            measured_width: 24,
            available_width: 8,
        }
    );
}

#[test]
fn controls_lower_to_primitive_commands_and_resolve_state() {
    let mut commands = CommandBuffer::new(8);
    let mut debug = DebugBuffer::new(2);
    let style;
    {
        let mut ui = Ui::new(&mut commands, Some(&mut debug));
        style = ui.style();
        ui.button(
            id(4),
            rect(0, 0, 5, 1),
            "run",
            ControlOptions::default(),
            true,
        )
        .unwrap();
        ui.bar(rect(0, 1, 10, 1), 3, 10, style.bar_fill).unwrap();
    }

    assert_eq!(commands.as_slice().len(), 6);
    assert_eq!(
        commands.as_slice()[0],
        DrawCommand::FillRect {
            rect: PixelRect {
                x: 0,
                y: 0,
                width: 40,
                height: 16,
            },
            color: style.button_active_fill,
        }
    );
    assert_eq!(
        commands.as_slice()[2],
        DrawCommand::Text {
            pos: PixelPoint::new(2, 0),
            text: "run",
            color: style.button_active_text,
            scale: TextScale::One,
        }
    );
    assert_eq!(
        commands.as_slice()[4],
        DrawCommand::FillRect {
            rect: PixelRect {
                x: 0,
                y: 16,
                width: 24,
                height: 16,
            },
            color: style.bar_fill,
        }
    );
}

#[test]
fn one_cell_half_vertical_padding_matches_cell_metrics_and_warns_when_short() {
    let options = ControlOptions {
        scale: TextScale::One,
        label_padding: LabelPadding::OneCellHalfVertical,
    };
    let mut commands = CommandBuffer::new(6);
    let mut debug = DebugBuffer::new(2);
    {
        let mut ui = Ui::new(&mut commands, Some(&mut debug));
        ui.button(id(40), rect(0, 0, 8, 2), "run", options, false)
            .unwrap();
        ui.button(id(41), rect(0, 2, 8, 1), "run", options, false)
            .unwrap();
    }

    assert!(matches!(
        commands.as_slice()[2],
        DrawCommand::Text {
            pos: PixelPoint { x: 8, y: 8 },
            ..
        }
    ));
    assert!(matches!(
        commands.as_slice()[5],
        DrawCommand::Text {
            pos: PixelPoint { x: 8, y: 32 },
            ..
        }
    ));
    assert_eq!(
        debug.as_slice(),
        &[DebugWarning::ControlLabelPaddingTooShort {
            id: id(41),
            rect: rect(0, 2, 8, 1),
        }]
    );
}
