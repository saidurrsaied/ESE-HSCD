# ESE-HSCD — Command Interpreter for DIP-Switch Commands

Group project for *Microelectronics & HW/SW Co-Design (ESE)*.
Target board: **Lattice XP2-17** (`LFXP2-17E-5QN208C`, TQFP-208), toolchain: **Lattice Diamond**, language: **VHDL**.

## Task Description

> The FPGA interprets the DIP-switch setting as a **command**. A push button **loads and executes** the selected command. The command **repeats with a selectable frequency** until the push button is pressed again.

## Operating model — "program, then run" (four phases)

We realise the topic as a small sequence driven by **one button (S1)**. Each press
advances one phase; **S4** is reset:

1. **ENTER_DATA** — left 7-seg shows `d`. Dial an 8-bit value on the DIP switches
   (the LEDs preview it live). Press S1 → the value is stored in the data register.
2. **ENTER_CMD** — left 7-seg shows `C`. Dial the command (DIP 8·7·6) and speed
   (DIP 5·4). Press S1 → the command is stored in the command register.
3. **READY** — 7-seg shows command code + speed. Press S1 → start.
4. **RUN** — the command **repeats at the selected rate** (right decimal point lit).
   Press S1 → stop, back to ENTER_DATA.

Required pieces (all present as skeleton modules): a **command decoder**, an
**execution FSM**, a **command register**, and an 8-bit **data register**.

### Command set (DIP 8·7·6, 3-bit) and speed (DIP 5·4)

| code | command | LED effect | | sel | rate |
|------|---------|-----------|---|-----|------|
| 000 | LOAD | reloads command-phase word (0x00–0x1F) | | 00 | 1 Hz |
| 001 | CLEAR | all LEDs off | | 01 | 2 Hz |
| 010 | COUNT_UP | binary count up | | 10 | 4 Hz |
| 011 | COUNT_DOWN | binary count down | | 11 | 8 Hz |
| 100 | SHIFT_LEFT | shift left, 0 in | | | |
| 101 | ROTATE_LEFT | one lit LED walks left & wraps | | | |
| 110 | INVERT | all bits toggle (blink) | | | |
| 111 | HOLD | value frozen (shows the entered data) | | | |

## How it fits together

```
 DIP(8) ─► synchronizer ─► dip_logic ─┬─► command_decoder ─► command_register ─┐
        (active-low, inverted in top)  │                                       │
                                       └─► data_register.DATA_IN (ENTER_DATA)  │
 S1 ─► sync ─► debouncer ─► edge_detector ─► PRESS ─► execution_fsm ◄─ tick_gen┘
                                                          │ data_load_en/op_en/op_code
                                                          ▼
                                                      data_register ─► LED(8)
                                                          │   (LED_ON polarity)
                          state_code + cmd/freq ─► display_driver (7-seg)  &  pmod_out
```

## Repository layout

```
src/          VHDL source (synthesised onto the board)
  command_pkg.vhd              shared constants, op-codes, polarity, seg7 helper
  synchronizer.vhd            2-FF synchronizer for async inputs        [A]
  debouncer.vhd               push-button debounce                       [A]
  edge_detector.vhd           level -> one-clock pulse                   [A]
  tick_generator.vhd          selectable repeat-rate (clock enable)      [A]
  command_decoder.vhd         DIP -> command + payload + speed           [B]
  command_register.vhd        stores the selected command                [B]
  data_register.vhd           8-bit datapath + DIP data-load             [B]
  execution_fsm.vhd           4-phase FSM: enter-data/cmd/ready/run      [B]
  display_driver.vhd          drives both 7-seg digits directly          [C]
  pmod_out.vhd                routes signals to the PMOD connector        [C]
  command_interpreter_top.vhd top level + wiring + polarity              [C]
tb/           Testbenches (VHDL-93 safe: no std.env, end via sim_done)
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
  lessons_learned.md          hardware + tooling gotchas (from the reference)
```

`[A] [B] [C]` = owner, see `doc/task_division.md`.

## Build flow in Lattice Diamond (quick steps)

1. **New Project** → device `LFXP2-17E`, package `TQFP208`, speed `-5`, part `LFXP2-17E-5QN208C`.
2. **Add Source** → add all files in `src/` (add `command_pkg.vhd` first, it is used by the rest).
   *Note:* Diamond **copies** sources into `impl1/source/` on import and compiles those copies — edit the copies once the project exists, not a stray `src/`.
3. Set `command_interpreter_top` as the **top-level unit**.
4. **Add** `constraints/command_interpreter.lpf` as the LPF constraint file.
5. Run **Synthesize → Map → Place & Route → Export Files → JEDEC File** (the XP2 is
   flash-based, so the bitstream is a `.jed`).
6. Program with **Tools → Programmer**, operation *FLASH Erase, Program, Verify*.
   On Linux this needs `libusb-0.1-4`, the right cable type, and a udev rule —
   see `doc/lessons_learned.md`.
7. Simulation: add the `tb/` files to a simulation set and run with the bundled
   QuestaSim. Simulate `execution_fsm_tb` first, then `command_interpreter_top_tb`.
   (Run vsim with `-voptargs=+acc` so the 7-seg outputs stay visible.)

## Status

All modules are **skeletons**: entities, ports, component wiring, the package and the
testbench frames are done. The internal logic is marked `TODO` with an *IMPLEMENTATION
GUIDE* in each file. Split per `doc/task_division.md` and fill them in.

A **complete, working reference** of this exact design (four-phase flow, verified on the
board) lives in the separate `command_interpreter_ref/` project — compare against it, but
write your own RTL.

## Hardware polarities — VERIFIED on the board (in `command_pkg.vhd`)

These were confirmed on the real XP2-17 (see `doc/lessons_learned.md` for how):

- **Buttons active-low** — `BTN_PRESSED = '0'`.
- **DIP switches active-low** — `DIP_ON = '0'`; the top level inverts the synchronized
  word so the rest of the design sees active-high (*switch up = 1*).
- **LED row active-low** — `LED_ON = '0'`.
- **7-seg active-high** — `SEG_ON = '1'` / `SEG_OFF = '0'`.
- **PMOD pin numbers** in the LPF are still **tentative** — confirm with the lab assistant.
