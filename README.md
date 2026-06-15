# ESE-HSCD — Command Interpreter for DIP-Switch Commands

Group project for *Microelectronics & HW/SW Co-Design (ESE)*.
Target board: **Lattice XP2-17** (`LFXP2-17E-5QN208C`, TQFP-208), toolchain: **Lattice Diamond**, language: **VHDL**.

## The task (topic, homework page 10)

> The FPGA interprets the DIP-switch setting as a **command**. A push button **loads and executes** the selected command. The command **repeats with a selectable frequency** until the push button is pressed again.

Required pieces (all present as skeleton modules):
- a **command decoder**, an **execution FSM**, and at least one **data register / counter** (8-bit data register)
- command set: `load, clear, count up, count down, shift, rotate, hold, reset`
- the selected command is stored in a **command register** before execution
- **7-segment display** shows the current command / status, the **LED row** shows the data register value
- **PMOD** outputs (oscilloscope): command valid, execute active, operation done, a status signal, data register content

## How it fits together

```
 DIP(8) ─► synchronizer ─► command_decoder ─► command_register ─┐
                                                                ├─► execution_fsm
 S1 ─► sync ─► debouncer ─► edge_detector ─► start/stop pulse ──┘     │ op_en / op_code
                                                                      ▼
                                       tick_generator ─► data_register ─► LED(8)
                                                                      │
                          status signals ─► display_driver (7-seg)  &  pmod_out (scope)
```

## Repository layout

```
src/          VHDL source (synthesised onto the board)
  command_pkg.vhd              shared constants + command op-codes + seg7 helper
  synchronizer.vhd            2-FF synchronizer for async inputs        [A]
  debouncer.vhd               push-button debounce                       [A]
  edge_detector.vhd           level -> one-clock pulse                   [A]
  tick_generator.vhd          selectable repeat-rate (clock enable)      [A]
  command_decoder.vhd         DIP switches -> command + payload          [B]
  command_register.vhd        stores the selected command                [B]
  data_register.vhd           8-bit datapath (the commands act on it)    [B]
  execution_fsm.vhd           main FSM: load / run / stop, repeat        [B]
  display_driver.vhd          drives both 7-seg digits directly          [C]
  pmod_out.vhd                routes signals to the PMOD connector       [C]
  command_interpreter_top.vhd top level + wiring                         [C]
tb/           Testbenches
  execution_fsm_tb.vhd        central-part test (most important)         [B]
  data_register_tb.vhd        datapath unit test                         [B]
  command_interpreter_top_tb.vhd  board-mimicking full-system test       [C]
constraints/
  command_interpreter.lpf     pin assignment (all sites from board doc)
doc/
  requirements.md             requirements document (deliverable)
  test_plan.md                test plan (deliverable)
  task_division.md            who does what
  clock_jumper_config.md      clock-section jumper notes (deliverable)
```

`[A] [B] [C]` = owner, see `doc/task_division.md`.

## Build flow in Lattice Diamond (quick steps)

1. **New Project** → device `LFXP2-17E`, package `TQFP208`, speed `-5`, part `LFXP2-17E-5QN208C`.
2. **Add Source** → add all files in `src/` (add `command_pkg.vhd` first, it is used by the rest).
3. Set `command_interpreter_top` as the **top-level unit**.
4. **Add** `constraints/command_interpreter.lpf` as the LPF constraint file.
5. Run **Synthesize → Map → Place & Route → Export (Generate) Bitstream**.
6. Program the board with **Programmer** over USB.
7. Simulation: add the `tb/` files to a simulation set and run with the bundled simulator (Active-HDL / ModelSim). Simulate `execution_fsm_tb` first, then `command_interpreter_top_tb`.

## Status

All modules are **skeletons**: entities, ports, component wiring, the package and the testbench frames are done. The internal logic is marked with `TODO` and an *IMPLEMENTATION GUIDE* comment block in each file. Split per `doc/task_division.md` and fill them in.

## Things to verify on real hardware (don't trust the defaults)

- **Segment polarity** (`SEG_ON`/`SEG_OFF` in `command_pkg.vhd`) — board doc says verify.
- **LED polarity** (active high vs low).
- **Button polarity** (pressed = '0' or '1') for the NO contacts.
- **DIP logical interpretation** (lower = '0', upper = '1' per doc, but confirm).
- **PMOD pin numbers** in the LPF are **tentative** — the real mapping is "provided separately"; confirm with the lab assistant.
