-- Module Name: command_pkg.vhd
-- ##########################################################################
--  Shared package for the "Command Interpreter for DIP-Switch Commands"
--  project (ESE-HSCD, Lattice XP2-17 board).
--
--  Everything that more than one module needs to agree on lives here:
--    - the data register width and command op-codes
--    - the hardware POLARITY constants (verified on the real board)
--    - the four FSM phase codes
--    - the 7-segment encode helper (declaration only, body below)
--
--  Keep this file as the single source of truth. Change a value ONCE here
--  and every module follows automatically.
--
--  =====================================================================
--  OPERATING MODEL  (this is what the whole design implements)
--  ---------------------------------------------------------------------
--  The interpreter is a small "program, then run" sequence driven by ONE
--  button (S1).  Four phases, walked by successive presses:
--
--    1. ENTER_DATA : dial an 8-bit value on the DIP switches (the LEDs
--                    preview it live); left 7-seg shows 'd'. Press -> the
--                    value is stored in the data register.
--    2. ENTER_CMD  : dial command (DIP 8..6) + speed (DIP 5..4);
--                    left 7-seg shows 'C'. Press -> command stored.
--    3. READY      : 7-seg shows command code + speed. Press -> start.
--    4. RUN        : the command repeats at the chosen rate (right dp lit).
--                    Press -> stop, back to ENTER_DATA.
--    S4 = reset (back to ENTER_DATA).
--  =====================================================================
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package command_pkg is

    ----------------------------------------------------------------------
    -- Bus widths
    ----------------------------------------------------------------------
    constant DATA_WIDTH : natural := 8;   -- data register is 8 bit (see homework)
    constant CMD_WIDTH  : natural := 3;   -- 3-bit op-code = exactly 8 commands
                                          --   (taken straight from DIP 8..6)

    ----------------------------------------------------------------------
    -- Command op-codes  (= DIP switches 8..6 in the ENTER_CMD phase)
    -- These are the "machine codes" the data path understands. Every one
    -- is clearly visible on the LED row.
    ----------------------------------------------------------------------
    constant CMD_LOAD        : std_logic_vector(CMD_WIDTH-1 downto 0) := "000"; -- data <= PAYLOAD
    constant CMD_CLEAR       : std_logic_vector(CMD_WIDTH-1 downto 0) := "001"; -- data <= 0
    constant CMD_COUNT_UP    : std_logic_vector(CMD_WIDTH-1 downto 0) := "010"; -- data +1 each tick
    constant CMD_COUNT_DOWN  : std_logic_vector(CMD_WIDTH-1 downto 0) := "011"; -- data -1 each tick
    constant CMD_SHIFT_LEFT  : std_logic_vector(CMD_WIDTH-1 downto 0) := "100"; -- logic shift left (0 in)
    constant CMD_ROTATE_LEFT : std_logic_vector(CMD_WIDTH-1 downto 0) := "101"; -- rotate left (wrap)
    constant CMD_INVERT      : std_logic_vector(CMD_WIDTH-1 downto 0) := "110"; -- toggle all bits (blink)
    constant CMD_HOLD        : std_logic_vector(CMD_WIDTH-1 downto 0) := "111"; -- keep value, do nothing

    ----------------------------------------------------------------------
    -- FSM phase codes (execution_fsm.STATE_CODE -> top level display/LED mux)
    ----------------------------------------------------------------------
    constant ST_ENTER_DATA : std_logic_vector(1 downto 0) := "00";
    constant ST_ENTER_CMD  : std_logic_vector(1 downto 0) := "01";
    constant ST_READY      : std_logic_vector(1 downto 0) := "10";
    constant ST_RUN        : std_logic_vector(1 downto 0) := "11";

    ----------------------------------------------------------------------
    -- Clock / repeat-rate constant
    --  SYS_CLK_HZ : frequency of clk_in on the board (24 MHz oscillator).
    --  tick_generator divides this down to the repeat rate (FREQ_SEL).
    --  A testbench overrides the top-level CLK_HZ generic with a tiny value
    --  so the slow ticks and the ~10 ms debounce simulate in microseconds.
    ----------------------------------------------------------------------
    constant SYS_CLK_HZ : natural := 24_000_000;

    ----------------------------------------------------------------------
    -- HARDWARE POLARITY CONSTANTS  --  *** VERIFIED ON THE REAL BOARD ***
    --
    --  These were all confirmed on the XP2-17. If a future board revision
    --  differs, flip the one matching constant and re-build - nothing else
    --  changes. (How we found the DIP/LED ones: with active-high assumed,
    --  command switches "110 00" decoded as "001 11" - an exact bit
    --  inversion - and CLEAR lit every LED. Both = active-low.)
    --
    --    BTN_PRESSED : level a push button shows when PRESSED. Buttons are
    --                  active-LOW (NO contact + pull-up reads '1' idle,
    --                  '0' pressed)            -> '0'
    --    DIP_ON      : level a DIP switch reads in its '1'/up position. This
    --                  board's DIP is active-LOW (up = '0'); the TOP LEVEL
    --                  inverts the synchronized word to active-high.  -> '0'
    --    LED_ON      : level that lights an LED. Row is active-LOW.    -> '0'
    --    SEG_ON/OFF  : 7-seg segment on/off. Active-HIGH (confirmed: digits
    --                  read correctly).                            -> '1'/'0'
    ----------------------------------------------------------------------
    constant BTN_PRESSED : std_logic := '0';
    constant DIP_ON      : std_logic := '0';
    constant LED_ON      : std_logic := '0';
    constant SEG_ON      : std_logic := '1';
    constant SEG_OFF     : std_logic := '0';

    ----------------------------------------------------------------------
    -- 7-segment helper
    --  Converts a 4-bit value (0x0..0xF) into the 8 segment lines of one
    --  digit. Bit order used everywhere in this project:
    --      bit 0 = a   bit 1 = b   bit 2 = c   bit 3 = d
    --      bit 4 = e   bit 5 = f   bit 6 = g   bit 7 = dp
    --
    --  The table MUST cover 0..F: the display shows hex 'C' (x"C") and 'd'
    --  (x"D") as the ENTER_CMD / ENTER_DATA indicators, plus 0..7 for the
    --  command code and 0..3 for the speed.
    ----------------------------------------------------------------------
    function seg7_encode(value : std_logic_vector(3 downto 0))
        return std_logic_vector;

end package command_pkg;


-- ##########################################################################
--  Package body
-- ##########################################################################
package body command_pkg is

    ----------------------------------------------------------------------
    -- seg7_encode
    --  IMPLEMENTATION GUIDE (Person C):
    --   * Fill in the case statement so each hex digit 0..F lights the
    --     correct segments. Use SEG_ON / SEG_OFF, never hard-coded '0'/'1',
    --     so the polarity stays in one place.
    --   * Bit order is (dp,g,f,e,d,c,b,a) = (7..0). Example for "0":
    --        segments a,b,c,d,e,f ON ; g, dp OFF.
    --   * You MUST include x"C" ('C') and x"D" ('d') - the FSM phase
    --     indicators use them. (dp is returned OFF here; the display driver
    --     overrides the dp bit for the "running" indicator.)
    --   * Two example entries are given. Complete 2..F yourself.
    ----------------------------------------------------------------------
    function seg7_encode(value : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable seg : std_logic_vector(7 downto 0) := (others => SEG_OFF);
    begin
        case value is
            --                 dp  g  f  e  d  c  b  a
            when "0000" =>  -- "0"
                seg := (7 => SEG_OFF, 6 => SEG_OFF,
                        5 => SEG_ON,  4 => SEG_ON, 3 => SEG_ON,
                        2 => SEG_ON,  1 => SEG_ON, 0 => SEG_ON);
            when "0001" =>  -- "1"
                seg := (2 => SEG_ON, 1 => SEG_ON, others => SEG_OFF);

            -- TODO: add "0010".."1111" (2..9 and A..F).
            --       Don't forget "1100" = 'C' and "1101" = 'd'.

            when others =>
                seg := (others => SEG_OFF);   -- blank / unknown
        end case;
        return seg;
    end function seg7_encode;

end package body command_pkg;
