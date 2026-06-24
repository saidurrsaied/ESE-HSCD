-- Module Name: command_decoder.vhd
-- ##########################################################################
--  Command decoder - turns the 8 DIP switches into a command + operand.
--
--  This is purely COMBINATIONAL. It does NOT store anything; storing the
--  chosen command happens later in command_register (only when the user
--  presses the button in the ENTER_CMD phase). The FSM decides WHEN to latch.
--
--  It works on the polarity-CORRECTED DIP word (the top level feeds it
--  `dip_logic`, i.e. active-high), so '1' here always means "switch up".
--
--  DIP-SWITCH MAPPING in the ENTER_CMD phase:
--
--      dip(7 downto 5) : command select  -> CMD_CODE (3 bits = 8 commands)
--                          000 LOAD       001 CLEAR
--                          010 COUNT_UP   011 COUNT_DOWN
--                          100 SHIFT_LEFT 101 ROTATE_LEFT
--                          110 INVERT     111 HOLD
--      dip(4 downto 3) : FREQ_SEL  (repeat rate for tick_generator)
--      dip(7 downto 0) : whole word -> PAYLOAD (used by CMD_LOAD)
--
--  (In the ENTER_DATA phase the same 8 switches are the data value; that
--  path goes straight to the data register, not through here.)
--
--  Board note: this board's DIP switches are active-LOW, but that is already
--  undone upstream (DIP_ON='0' -> top inverts), so decode as active-high.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity command_decoder is
    Port (
        DIP_VALUE  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- 8 DIP switches
        CMD_CODE   : out std_logic_vector(CMD_WIDTH-1 downto 0);   -- one of CMD_* codes
        PAYLOAD    : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- operand for LOAD
        FREQ_SEL   : out std_logic_vector(1 downto 0);             -- repeat-rate select
        CMD_VALID  : out std_logic                                 -- '1' if recognised
    );
end entity command_decoder;

architecture rtl of command_decoder is
begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person B):
    --   * CMD_CODE  <= DIP_VALUE(7 downto 5);   -- top 3 switches = command
    --   * FREQ_SEL  <= DIP_VALUE(4 downto 3);   -- next 2 = speed
    --   * PAYLOAD   <= DIP_VALUE;               -- whole word (CMD_LOAD uses it)
    --   * CMD_VALID <= '1';                     -- every 3-bit code is valid here
    --   (Simple direct slicing - no case statement needed because all 8
    --    codes map 1:1. Keep CMD_VALID as a port in case you later reserve
    --    some patterns.)
    -------------------------------------------------------------------

    -- TODO: replace these safe defaults with the real decode logic
    CMD_CODE  <= CMD_HOLD;            -- default = do nothing
    PAYLOAD   <= (others => '0');
    FREQ_SEL  <= (others => '0');
    CMD_VALID <= '0';

end architecture rtl;
