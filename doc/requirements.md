# Requirements document (template)

Project: Command Interpreter for DIP-Switch Commands
Board: Lattice XP2-17 — Toolchain: Lattice Diamond

> This is a deliverable. Fill the TODOs, then keep it in sync with the code
> (especially the DIP-switch mapping and the repeat-rate table).

## 1. Functional requirements

Realised as a **four-phase "program, then run"** sequence driven by S1
(ENTER_DATA → ENTER_CMD → READY → RUN); S4 = reset.

| # | Requirement | Source |
|---|-------------|--------|
| R1 | The DIP switches encode a command; the design decodes it. | topic |
| R2 | In ENTER_DATA, the DIP switches set an 8-bit value; a press stores it in the data register. | topic/design |
| R3 | In ENTER_CMD, the DIP switches select a command + speed; a press stores it in the command register. | topic |
| R4 | In READY, a press starts execution; the command repeats at the selected frequency in RUN. | topic |
| R5 | A press in RUN stops the repetition (returns to ENTER_DATA). | topic |
| R6 | Command set: load, clear, count up, count down, shift left, rotate left, invert, hold. | topic |
| R7 | The data register is 8 bits wide. | topic |
| R8 | The 7-segment display shows the phase: `d` / `C` / command+speed (right dp = running). | topic |
| R9 | The LED row shows the data register value (live DIP preview in ENTER_DATA). | topic |
| R10 | PMOD outputs (OPTIONAL — omitted in the reference): command valid, execute active, operation done, status, data content. | topic |
| R11 | At least one clocked process / FSM (no purely combinational design). | rules |

## 2. DIP-switch mapping (FINAL — matches the reference)

In **ENTER_DATA** all 8 switches are the data value (dip(7:0), sw1=LSB).
In **ENTER_CMD** the switches mean:

| Bits | Meaning |
|------|---------|
| `dip(7:5)` | command select (000=LOAD … 111=HOLD) |
| `dip(4:3)` | FREQ_SEL (repeat rate) |
| `dip(7:0)` | whole word → PAYLOAD (used by CMD_LOAD) |

Command codes: see `src/command_pkg.vhd` (CMD_* constants).

**Polarity (VERIFIED):** DIP switches are **active-low** (`DIP_ON='0'`); the top level
inverts the synchronized word, so logically *switch up = '1'*. See `doc/lessons_learned.md`.

## 3. Repeat-rate table (FINAL)

| FREQ_SEL | Repeat rate |
|----------|-------------|
| 00 | 1 Hz |
| 01 | 2 Hz |
| 10 | 4 Hz |
| 11 | 8 Hz |

## 4. Clock

- `clk_in` = 24 MHz on-board oscillator (site 53). Single clock domain.
- Async inputs (buttons, DIP) are synchronized before use.

## 5. PMOD signal assignment (OPTIONAL — reference design omits the PMOD)

| Pin | Signal | Direction |
|-----|--------|-----------|
| pmod[0] | command_valid | FPGA → scope |
| pmod[1] | execute_active | FPGA → scope |
| pmod[2] | operation_done | FPGA → scope |
| pmod[3] | status (tick) | FPGA → scope |
| pmod[7:4] | data_value[3:0] | FPGA → scope |

(Pin sites are tentative — see LPF. Add only if the assignment needs scope signals.)

## 6. Non-functional / constraints

- All I/O 3.3 V LVCMOS33.
- Verified hardware polarities: buttons / DIP / LEDs **active-low**, 7-seg **active-high**
  (constants in `command_pkg.vhd`).
- PMOD is output-only, never driven externally, common ground when probing.
