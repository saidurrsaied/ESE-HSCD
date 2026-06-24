# Test plan (template)

> Deliverable. The simulation testbenches must perform this plan.

## A. Simulation tests

### A1. Data register unit test (`data_register_tb`)
| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset | DATA_OUT = 0x01 (SEED) |
| 2 | DATA_IN=0x55, LOAD_EN pulse | DATA_OUT = 0x55 |
| 3 | CMD_COUNT_UP × 3 | 0x56, 0x57, 0x58 |
| 4 | CMD_COUNT_DOWN × 1 | 0x57 |
| 5 | CMD_SHIFT_LEFT | left shift, 0 in |
| 6 | CMD_ROTATE_LEFT | left rotate, MSB → LSB |
| 7 | CMD_CLEAR | 0x00 |
| 8 | CMD_INVERT | all bits toggle |
| 9 | CMD_HOLD | unchanged |

### A2. FSM test (`execution_fsm_tb`) — central part
| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset | STATE_CODE = ST_ENTER_DATA, EXEC_ACTIVE=0 |
| 2 | PRESS | DATA_LOAD_EN pulses, → ST_ENTER_CMD |
| 3 | PRESS (CMD_VALID=1) | CMD_LOAD_EN pulses, → ST_READY |
| 4 | PRESS | → ST_RUN, EXEC_ACTIVE=1 |
| 5 | TICK pulses | one OP_EN + OP_DONE per tick |
| 6 | PRESS | → ST_ENTER_DATA, EXEC_ACTIVE=0 |

### A3. Full system (`command_interpreter_top_tb`) — board mimic
Drive PHYSICAL pin levels (active-low) via the `dip_phys` / `BTN_PRESSED` helpers;
read LEDs back through `led_logic`. Exercise **all eight commands** with `run_command`.

| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset (S4) | FSM in ENTER_DATA, 7-seg left = 'd' |
| 2 | ENTER_DATA: dip=value, press S1 | value saved; 7-seg → 'C' |
| 3 | ENTER_CMD: dip=cmd+freq, press S1 | 7-seg → command code + speed |
| 4 | READY: press S1 | RUN; right dp lit; LEDs animate per command |
| 5 | per command | LOAD/CLEAR/HOLD self-check via `led_logic(led_tb)`; others visual |
| 6 | press S1 in RUN | stops, back to ENTER_DATA |

## B. Hardware tests (lab)

| # | Check |
|---|-------|
| H1 | The four phases walk correctly: 7-seg `d` → `C` → cmd+speed, dp lit in RUN. |
| H2 | Each command visibly works on the LEDs. |
| H3 | Data entry: switch up lights the matching LED (sw1 ↔ LED site 93). |
| H4 | Repeat rate changes with FREQ_SEL (1/2/4/8 Hz). |
| H5 | Reset (S4) returns to ENTER_DATA. |

## C. Things to confirm before/while testing
- Hardware polarities are VERIFIED (buttons/DIP/LED active-low, 7-seg active-high) —
  see `doc/lessons_learned.md`. Only re-check if the board revision changes.
- Real PMOD pin numbers (only if you add the optional PMOD).
- Clock-section jumper setting (see clock_jumper_config.md).
