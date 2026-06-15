# Requirements document (template)

Project: Command Interpreter for DIP-Switch Commands
Board: Lattice XP2-17 — Toolchain: Lattice Diamond

> This is a deliverable. Fill the TODOs, then keep it in sync with the code
> (especially the DIP-switch mapping and the repeat-rate table).

## 1. Functional requirements

| # | Requirement | Source |
|---|-------------|--------|
| R1 | The DIP switches encode a command; the design decodes it. | topic |
| R2 | A push button (S1) loads the selected command into a command register and starts execution. | topic |
| R3 | The command repeats at a selectable frequency while running. | topic |
| R4 | Pressing the button again stops the repetition. | topic |
| R5 | Command set: load, clear, count up, count down, shift, rotate, hold, reset. | topic |
| R6 | The data register is 8 bits wide. | topic |
| R7 | The 7-segment display shows the current command / execution status. | topic |
| R8 | The LED row shows the data register value. | topic |
| R9 | PMOD outputs expose: command valid, execute active, operation done, a status signal, data register content. | topic |
| R10 | At least one clocked process / FSM (no purely combinational design). | rules |

## 2. DIP-switch mapping (RECOMMENDED — confirm and finalise)

| Bits | Meaning |
|------|---------|
| `dip(7:5)` | command select (000=LOAD … 111=RESET) |
| `dip(4:3)` | FREQ_SEL (repeat rate) |
| `dip(2:0)` | payload nibble for LOAD (zero-extended) — TODO confirm |

Command codes: see `src/command_pkg.vhd` (CMD_* constants).

Board note: DIP lower position = logic '0', upper = '1' (pull-ups). **Verify.**

## 3. Repeat-rate table (TODO finalise in tick_generator)

| FREQ_SEL | Repeat rate |
|----------|-------------|
| 00 | 1 Hz (TODO) |
| 01 | 2 Hz (TODO) |
| 10 | 5 Hz (TODO) |
| 11 | 10 Hz (TODO) |

## 4. Clock

- `clk_in` = 24 MHz on-board oscillator (site 53). Single clock domain.
- Async inputs (buttons, DIP) are synchronized before use.

## 5. PMOD signal assignment (document directions — report requires it)

| Pin | Signal | Direction |
|-----|--------|-----------|
| pmod[0] | command_valid | FPGA → scope |
| pmod[1] | execute_active | FPGA → scope |
| pmod[2] | operation_done | FPGA → scope |
| pmod[3] | status (tick) | FPGA → scope |
| pmod[7:4] | data_value[3:0] | FPGA → scope |

(Pin sites are tentative — see LPF.)

## 6. Non-functional / constraints

- All I/O 3.3 V LVCMOS33.
- PMOD is output-only, never driven externally, common ground when probing.
