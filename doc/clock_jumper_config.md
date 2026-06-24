# Clock-section jumper configuration (deliverable)

The board has several clock sources (board doc, section 3):

| Signal | Site | Description |
|--------|------|-------------|
| `clk_in` | 53 | 24 MHz on-board oscillator |
| `jumper_clock` | 135 | selectable divided clock (1 Hz … 1 MHz) |
| `slow_clock` | 125 | NE555 slow clock / single-step |
| `x2_clock` | 164 | optional oscillator (only if populated) |

## What this design uses

This design uses **only `clk_in` (24 MHz, site 53)** as its single clock.
The "selectable repeat frequency" is produced **inside the FPGA** by
`tick_generator` (a clock-enable divider), so **no special clock jumper is
required** for normal operation.

### Jumper settings to document for the demo
- [ ] Confirm the board is set so `clk_in` (24 MHz) is available — TODO note the jumper position used.
- [ ] `jumper_clock` / `slow_clock` not used by this design — note their jumper state anyway for completeness.

> If you later decide to drive the repeat rate from `jumper_clock` or the
> NE555 `slow_clock` instead of the internal `tick_generator`, document the
> exact jumper positions here and remember those inputs are asynchronous and
> must be synchronized (see `synchronizer.vhd`).

**Finding (from the reference):** the NE555 `slow_clock` has a button, but it is a
**single-step** button (one pulse per press) selected by a jumper — it does **not**
set the slow-clock frequency (that is a trimmer pot, ~3–20 Hz). So it cannot be used
as a "change the repeat rate" control; generating the rate inside the FPGA is the
right call.
