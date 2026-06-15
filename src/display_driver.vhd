-- Module Name: display_driver.vhd
-- ##########################################################################
--  Two-digit 7-segment display driver.
--
--  IMPORTANT (board doc, section 7):
--    "Each segment and decimal point is connected separately to the FPGA"
--    and "The display is NOT driven through a standard display controller."
--    => There is NO time-multiplexing. We drive ALL 16 segment lines
--       (8 per digit) directly and continuously. Much simpler than a
--       typical scanned display!
--
--  WHAT TO SHOW (homework: "current command or execution status"):
--    Suggestion - left digit  = command code / state, right digit = data
--    or a status code. Exact choice is your call; a push button can switch
--    between views (see DISPLAY_SEL into the top level).
--
--  Bit order of each seg vector (see command_pkg.seg7_encode):
--    bit0=a bit1=b bit2=c bit3=d bit4=e bit5=f bit6=g bit7=dp
--
--  OWNER: Person C (Output & Integration)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity display_driver is
    Port (
        LEFT_VALUE  : in  std_logic_vector(3 downto 0);  -- hex digit for left  display
        RIGHT_VALUE : in  std_logic_vector(3 downto 0);  -- hex digit for right display
        SEG_LEFT    : out std_logic_vector(7 downto 0);  -- left  digit segments (a..dp)
        SEG_RIGHT   : out std_logic_vector(7 downto 0)   -- right digit segments (a..dp)
    );
end entity display_driver;

architecture rtl of display_driver is
begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person C):
    --   Each digit is independent and combinational - just call the shared
    --   encoder for each one:
    --        SEG_LEFT  <= seg7_encode(LEFT_VALUE);
    --        SEG_RIGHT <= seg7_encode(RIGHT_VALUE);
    --   Remember to finish the seg7_encode table in command_pkg first, and
    --   to check the segment polarity on real hardware (SEG_ON/SEG_OFF).
    -------------------------------------------------------------------

    -- TODO: replace placeholders with the seg7_encode calls above
    SEG_LEFT  <= (others => SEG_OFF);
    SEG_RIGHT <= (others => SEG_OFF);

end architecture rtl;
