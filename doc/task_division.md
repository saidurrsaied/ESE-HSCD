# Task division (3 people)

The design is split so each person owns a set of modules with clean,
already-defined interfaces (see the entity ports). You can work in parallel
because the ports + the shared `command_pkg.vhd` are fixed.

> If you really need to change an interface (a port or a constant), tell the
> group first and update `command_pkg.vhd` / the top level together.

## Person A — Input & Timing
Files: `synchronizer.vhd`, `debouncer.vhd`, `edge_detector.vhd`, `tick_generator.vhd`
- Make the asynchronous buttons / DIP switches safe for clocked logic.
- Produce a clean one-clock "press" pulse for the FSM.
- Produce the selectable repeat-rate `TICK` (clock enable).
- Deliver: these 4 modules + help wire the clock constraints.

## Person B — Core Logic (the heart)
Files: `command_decoder.vhd`, `command_register.vhd`, `data_register.vhd`, `execution_fsm.vhd`
- Decode DIP switches into a command + payload + freq select.
- Store the command in the command register on `cmd_load_en`.
- Implement the 8 operations + the DIP data-load path in the data register.
- Implement the **four-phase FSM** (enter-data → enter-cmd → ready → run,
  repeat on tick, stop on press in RUN; publish STATE_CODE).
- Deliver: these 4 modules + `execution_fsm_tb.vhd` + `data_register_tb.vhd`.

## Person C — Output & Integration
Files: `display_driver.vhd`, `pmod_out.vhd`, `command_interpreter_top.vhd`,
`constraints/command_interpreter.lpf`, `command_interpreter_top_tb.vhd`
- Finish the 7-seg encoder table (`command_pkg.seg7_encode`) + the driver.
- Route the oscilloscope signals to the PMOD.
- Keep the top-level wiring and the LPF correct; run the full build in Diamond.
- Deliver: display + PMOD modules, working top + LPF, board-mimic testbench,
  and confirm the tentative items (polarities, PMOD pins) on hardware.

## Shared (everyone)
- `command_pkg.vhd` is shared — coordinate before editing.
- Written report, test plan, presentation slides (see `doc/`).

## Suggested order of work
1. A finishes synchronizer + edge detector early (B and C need clean inputs).
2. B implements data_register first (easy to unit-test), then the FSM.
3. C finishes seg7 table + display so something shows on the board ASAP.
4. Integrate, simulate `command_interpreter_top_tb`, then test on hardware.
