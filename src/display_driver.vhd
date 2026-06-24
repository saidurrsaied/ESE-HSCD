-- Module Name: display_driver.vhd
-- ##########################################################################
--  Two-digit 7-segment display driver.
--
--  IMPORTANT (board doc, section 7):
--    "Each segment and decimal point is connected separately to the FPGA"
--    => There is NO time-multiplexing. We drive ALL 16 segment lines
--       (8 per digit) directly and continuously. Much simpler than a
--       typical scanned display!
--
--  This driver is deliberately dumb: it just encodes the two hex digits it
--  is given, blanks a digit when asked, and lights the right decimal point
--  as the "running" indicator. The TOP LEVEL decides WHAT to show in each
--  phase, because that depends on the FSM state:
--      ENTER_DATA : left = 'd', right blank
--      ENTER_CMD  : left = 'C', right blank
--      READY      : left = command code, right = speed
--      RUN        : left = command code, right = speed, right dp ON
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
        LEFT_BLANK  : in  std_logic;                     -- '1' = blank the left digit
        RIGHT_BLANK : in  std_logic;                     -- '1' = blank the right digit
        RIGHT_DP    : in  std_logic;                     -- '1' = light right decimal point
        SEG_LEFT    : out std_logic_vector(7 downto 0);  -- left  digit segments (a..dp)
        SEG_RIGHT   : out std_logic_vector(7 downto 0)   -- right digit segments (a..dp)
    );
end entity display_driver;

architecture rtl of display_driver is
    constant BLANK_DIGIT : std_logic_vector(7 downto 0) := (others => SEG_OFF);
begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person C):
    --   * Left digit:
    --        SEG_LEFT <= BLANK_DIGIT when LEFT_BLANK='1'
    --                    else seg7_encode(LEFT_VALUE);
    --   * Right digit + decimal point:
    --        right = seg7_encode(RIGHT_VALUE)
    --        SEG_RIGHT(6 downto 0) <= (others=>SEG_OFF) when RIGHT_BLANK='1'
    --                                 else right(6 downto 0);
    --        SEG_RIGHT(7) <= SEG_ON when (RIGHT_DP='1' and RIGHT_BLANK='0')
    --                        else SEG_OFF;
    --   Finish the seg7_encode table in command_pkg first (incl. 'C' and 'd').
    -------------------------------------------------------------------

    -- TODO: replace placeholders with the logic above
    SEG_LEFT  <= (others => SEG_OFF);
    SEG_RIGHT <= (others => SEG_OFF);

end architecture rtl;
