# Lessons learned — hardware & tooling gotchas

Collected while building and bringing up the **reference** implementation on the
real XP2-17 board. None of these are obvious from the datasheet; capture-once so
nobody on the team loses hours rediscovering them. (The full reference project is
in `command_interpreter_ref/`.)

---

## 1. Hardware polarities (VERIFIED on the board)

All live in `src/command_pkg.vhd` as one-line constants:

| Constant | Value | Meaning |
|----------|-------|---------|
| `BTN_PRESSED` | `'0'` | buttons are **active-low** (NO contact + pull-up) |
| `DIP_ON` | `'0'` | DIP switches are **active-low** (up = '0') |
| `LED_ON` | `'0'` | LED row is **active-low** (lit by '0') |
| `SEG_ON` / `SEG_OFF` | `'1'` / `'0'` | 7-seg is **active-high** (digits read correctly) |

**How the DIP/LED ones were found:** with active-high assumed, dialling the command
switches to `110 00` (INVERT @ 1 Hz) decoded as `001 11` (CLEAR @ 8 Hz) — an *exact
bit inversion* — and CLEAR lit **every** LED. Both symptoms = active-low DIP **and**
active-low LEDs.

**Design rule:** the DIP word is inverted **once** in the top level
(`dip_logic <= not dip_sync`), so every downstream module decodes active-high. The
LED output applies `LED_ON`. Keep polarity in these constants — never hard-code.

---

## 2. Bit / pin mapping (so the LEDs make sense)

- DIP `sw1 = dip_switch[0] = data bit 0 (LSB)` … `sw8 = dip_switch[7] = bit 7 (MSB)`.
- LED `led[0]` is at **site 93** (= data bit 0); `led[7]` at site 104.
- So in ENTER_DATA, flipping **sw1 up lights the LED at site 93**.
- Command field = DIP 8·7·6 (`dip(7:5)`), speed = DIP 5·4 (`dip(4:3)`).
- See `command_interpreter_ref/boardrun.md` for a full per-command board walkthrough.

---

## 3. Lattice Diamond project mechanics

- Diamond **copies** your sources into `impl1/source/` on import and compiles the
  copies. After the project exists, edit the copies (or re-import) — editing a stray
  top-level `src/` does nothing.
- It rewrites the `.ldf` on reopen (LPF reference, sim files). Set the **active LPF**
  via the GUI so it sticks.
- The XP2 is **flash-based**: the bitstream is a **JEDEC `.jed`** file. Generate via
  `Export Files → JEDEC File`; program with *FLASH Erase, Program, Verify* (persists
  across power-off).

---

## 4. Simulation with the bundled QuestaSim

- **`std.env.stop` is rejected** in the default language mode
  (`'env' is not compiled in library 'std'`). Don't use it. End a TB by stopping the
  clock via a `sim_done` boolean (see the `tb/` files). Works in VHDL-93/2002/2008.
- **Licensing:** Diamond only sets `LATTICE_LICENSE_FILE`; the bundled Questa also
  needs `LM_LICENSE_FILE` and `MGLS_LICENSE_FILE` pointing at the same
  `.../diamond/<ver>/license/license.dat`. Set them before launching, or Questa
  silently won't open / "Run simulator" does nothing.
- **Waveform visibility:** run `vsim -voptargs=+acc ...` or the optimizer strips
  observe-only signals (the 7-seg outputs are read by nobody, so `add wave` fails on
  them and can abort the macro). Guard `add wave` lines with `catch {}` too.
- **Fast sims:** the top has a generic `CLK_HZ`; a TB overrides it with a tiny value
  (e.g. 200) so the slow ticks and the ~10 ms debounce simulate in microseconds.

---

## 5. Programming the board on Linux (Mint/Ubuntu)

The "Programmer greyed out / cable not found" rabbit hole — **none of it was licensing**:

1. **`libdvmapp.so: libusb-0.1.so.4: cannot open shared object file`** → the legacy
   libusb is missing on modern distros. Fix: `sudo apt install libusb-0.1-4`. This
   also un-greys `Tools → Programmer`.
2. **The cable is a Cypress-FX2 type, not FTDI.** This board's on-board programmer
   enumerates as USB **`1134:8001`** (vendor-specific, 6 endpoints). There is no FTDI
   `0403:xxxx` device. In Programmer pick cable type **`USB`** (port `EzUSB-0`), **not**
   `USB2` (USB2 = the FTDI HW-USBN-2B cable, which this board lacks).
3. **`Detect Cable` finds nothing → USB permissions.** The device node is `root:root`
   (others read-only); the programmer needs read/write. Add a udev rule (you're in
   `plugdev`) and replug:
   ```
   sudo tee /etc/udev/rules.d/99-lattice-usb.rules >/dev/null <<'EOF'
   SUBSYSTEM=="usb", ATTR{idVendor}=="1134", ATTR{idProduct}=="8001", GROUP="plugdev", MODE="0660"
   SUBSYSTEM=="usb", ATTR{idVendor}=="04b4", ATTR{idProduct}=="8613", GROUP="plugdev", MODE="0660"
   EOF
   sudo udevadm control --reload-rules && sudo udevadm trigger
   ```
- The board is configured over the **same USB that powers it** (keep the power jumper
  on "USB").

---

## 6. Design notes worth knowing

- **`CMD_LOAD` is mostly legacy** in the four-phase flow: you already set the data in
  ENTER_DATA, and LOAD reloads the *command-phase* word each tick (top 5 bits are
  command+speed, so it can only show `0x00–0x1F`). **Use `HOLD` to display an
  arbitrary fixed value.**
- The data register resets to **`0x01`** so SHIFT/ROTATE still show a moving LED even
  if no value was entered.
- One clock domain only (`clk_in`, 24 MHz). The repeat rate is an internal
  clock-enable (`tick_generator`), not a second clock — see `clock_jumper_config.md`.
