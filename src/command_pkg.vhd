-- Module Name: command_pkg.vhd
-- ##########################################################################
--  Shared package for the "Command Interpreter for DIP-Switch Commands"
--  project (ESE-HSCD, Lattice XP2-17 board).
--
--  Everything that more than one module needs to agree on lives here:
--    - the data register width
--    - the command op-codes (so the decoder, the command register, the
--      data path and the FSM all use the SAME numbers)
--    - a couple of handy constants for the clock / tick generator
--    - the 7-segment encode helper (declaration only, body below)
--
--  Keep this file as the single source of truth. If you change a command
--  code, change it ONCE here and every module follows automatically.
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package command_pkg is

    ----------------------------------------------------------------------
    -- Bus widths
    ----------------------------------------------------------------------
    constant DATA_WIDTH : natural := 8;   -- data register is 8 bit (see homework)
    constant CMD_WIDTH  : natural := 4;   -- 4 bit op-code -> room for up to 16 commands

    ----------------------------------------------------------------------
    -- Command op-codes
    -- These are the "machine codes" the execution FSM understands.
    -- The command_decoder turns the DIP-switch setting into one of these.
    ----------------------------------------------------------------------
    constant CMD_LOAD       : std_logic_vector(CMD_WIDTH-1 downto 0) := "0000"; -- load PAYLOAD into data register
    constant CMD_CLEAR      : std_logic_vector(CMD_WIDTH-1 downto 0) := "0001"; -- data register <= 0
    constant CMD_COUNT_UP   : std_logic_vector(CMD_WIDTH-1 downto 0) := "0010"; -- data register +1 each tick
    constant CMD_COUNT_DOWN : std_logic_vector(CMD_WIDTH-1 downto 0) := "0011"; -- data register -1 each tick
    constant CMD_SHIFT      : std_logic_vector(CMD_WIDTH-1 downto 0) := "0100"; -- logic shift left (0 in)
    constant CMD_ROTATE     : std_logic_vector(CMD_WIDTH-1 downto 0) := "0101"; -- rotate left (wrap around)
    constant CMD_HOLD       : std_logic_vector(CMD_WIDTH-1 downto 0) := "0110"; -- keep value, do nothing
    constant CMD_RESET      : std_logic_vector(CMD_WIDTH-1 downto 0) := "0111"; -- reset whole datapath to default

    ----------------------------------------------------------------------
    -- Clock / repeat-rate constants
    --  CLK_HZ      : frequency of clk_in on the board (24 MHz oscillator).
    --  The tick_generator divides this down to the "repeat frequency"
    --  with which a command is re-executed while the FSM is running.
    --  FREQ_SEL (2 bit) chooses one of four speeds -> see tick_generator.
    ----------------------------------------------------------------------
    constant SYS_CLK_HZ : natural := 24_000_000;

    ----------------------------------------------------------------------
    -- 7-segment helper
    --  Converts a 4-bit value (0x0..0xF) into the 8 segment lines of one
    --  digit. Bit order used everywhere in this project:
    --      bit 0 = a
    --      bit 1 = b
    --      bit 2 = c
    --      bit 3 = d
    --      bit 4 = e
    --      bit 5 = f
    --      bit 6 = g
    --      bit 7 = dp (decimal point)
    --
    --  NOTE (board doc, section 7): "The electrical polarity of the
    --  segments should be verified before using the display." So once we
    --  test on hardware we may have to INVERT the pattern. Keep the
    --  polarity choice in ONE place (constant SEG_ON / SEG_OFF below) so
    --  flipping it later is a one-line change.
    ----------------------------------------------------------------------
    constant SEG_ON  : std_logic := '1';   -- TODO verify on hardware (maybe '0')
    constant SEG_OFF : std_logic := '0';   -- TODO verify on hardware (maybe '1')

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
    --   * Fill in the case statement so each hex digit lights the correct
    --     segments. Use SEG_ON / SEG_OFF, never hard-coded '0'/'1', so the
    --     polarity stays adjustable.
    --   * Bit order is (dp,g,f,e,d,c,b,a) = (7..0). Example for "0":
    --        segments a,b,c,d,e,f ON ; g, dp OFF.
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

            -- TODO: add "0010".."1111" (2..9 and A..F)

            when others =>
                seg := (others => SEG_OFF);   -- blank / unknown
        end case;
        return seg;
    end function seg7_encode;

end package body command_pkg;
