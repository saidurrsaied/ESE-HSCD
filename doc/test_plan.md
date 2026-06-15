# Test plan (template)

> Deliverable. The simulation testbenches must perform this plan.

## A. Simulation tests

### A1. Data register unit test (`data_register_tb`)
| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset | DATA_OUT = 0x00 |
| 2 | CMD_LOAD, PAYLOAD=0x55, OP_EN pulse | DATA_OUT = 0x55 |
| 3 | CMD_COUNT_UP × 3 | 0x56, 0x57, 0x58 |
| 4 | CMD_COUNT_DOWN × 1 | 0x57 |
| 5 | CMD_SHIFT | left shift, 0 in |
| 6 | CMD_ROTATE | left rotate, MSB → LSB |
| 7 | CMD_CLEAR / CMD_RESET | 0x00 |
| 8 | CMD_HOLD | unchanged |

### A2. FSM test (`execution_fsm_tb`) — central part
| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset | state IDLE, EXEC_ACTIVE=0 |
| 2 | START_STOP pulse with CMD_VALID=1 | LOAD_CMD pulses, EXEC_ACTIVE=1 (RUN) |
| 3 | TICK pulses | one OP_EN + OP_DONE per tick |
| 4 | START_STOP pulse again | back to IDLE, EXEC_ACTIVE=0 |
| 5 | START_STOP with CMD_VALID=0 | stays IDLE (no start) |

### A3. Full system (`command_interpreter_top_tb`) — board mimic
| Step | Stimulus | Expected |
|------|----------|----------|
| 1 | reset | led = 0x00 |
| 2 | dip = COUNT_UP + rate, press S1 | led counts up at the selected rate |
| 3 | press S1 again | counting stops |
| 4 | dip = LOAD + payload, press S1 | led shows payload |
| 5 | toggle display_sel | right 7-seg digit view changes |
| 6 | observe pmod | command_valid / execute_active / op_done behave |

## B. Hardware tests (lab)

| # | Check |
|---|-------|
| H1 | Each command visibly works on the LEDs. |
| H2 | 7-seg shows the command / status (after fixing segment polarity). |
| H3 | Repeat rate changes with FREQ_SEL. |
| H4 | Oscilloscope on PMOD shows execute_active / op_done / tick as expected. |
| H5 | Start/stop toggling is clean (debounce works). |

## C. Things to confirm before/while testing
- Segment polarity (SEG_ON/SEG_OFF), LED polarity, button polarity.
- Real PMOD pin numbers.
- Clock-section jumper setting (see clock_jumper_config.md).
