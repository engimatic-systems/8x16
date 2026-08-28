use ui8x16::{CellRect, CommandBuffer, ControlOptions, DebugBuffer, TextScale, Ui, UiId};

fn rect(col: i32, row: i32, columns: u32, rows: u32) -> CellRect {
    CellRect::new(col, row, columns, rows).expect("example geometry is valid")
}

fn id(value: u64) -> UiId {
    UiId::new(value).expect("example IDs are non-zero")
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut commands = CommandBuffer::new(16);
    let mut diagnostics = DebugBuffer::new(4);

    {
        let mut ui = Ui::new(&mut commands, Some(&mut diagnostics));
        let style = ui.style();
        ui.panel(rect(0, 0, 24, 4))?;
        ui.text(
            id(101),
            rect(1, 0, 8, 1),
            "tools",
            style.text,
            TextScale::One,
        )?;
        ui.button(
            id(102),
            rect(1, 1, 8, 1),
            "run",
            ControlOptions::default(),
            false,
        )?;
        ui.toggle(
            id(103),
            rect(10, 1, 10, 1),
            "snap",
            true,
            ControlOptions::default(),
            false,
        )?;
    }

    println!(
        "lowered {} primitive commands with {} diagnostics",
        commands.as_slice().len(),
        diagnostics.as_slice().len()
    );
    Ok(())
}
