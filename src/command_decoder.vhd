-- Module Name: command_decoder.vhd
-- ##########################################################################
--  Command decoder - turns the 8 DIP switches into a command + operand.
--
--  This is purely COMBINATIONAL. It does NOT store anything; storing the
--  chosen command happens later in command_register (only when the user
--  presses the button). The FSM decides WHEN to latch.
--
--  RECOMMENDED DIP-SWITCH MAPPING  (you may change it - just keep this
--  comment and doc/requirements.md in sync!):
--
--      dip(7 downto 5) : command select (3 bits -> 8 commands)
--                          000 LOAD     001 CLEAR
--                          010 COUNT_UP 011 COUNT_DOWN
--                          100 SHIFT    101 ROTATE
--                          110 HOLD     111 RESET
--      dip(4 downto 3) : FREQ_SEL  (repeat rate for tick_generator)
--      dip(2 downto 0) : payload nibble for the LOAD command
--                          (zero-extended to 8 bit; or wire the whole
--                           dip word as payload - your design choice)
--
--  Board note (section 5): DIP lower position = logic '0', upper = '1',
--  internal pull-ups. Verify the real polarity on hardware before trusting
--  the numbers above.
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
    --   * Look at DIP_VALUE(7 downto 5) and map each pattern to a CMD_*
    --     constant from command_pkg (use a case statement).
    --   * Set CMD_VALID = '1' for every recognised pattern. (With a full
    --     3-bit -> 8-command map every pattern is valid; CMD_VALID still
    --     useful if you later use fewer than 8 commands.)
    --   * FREQ_SEL  <= DIP_VALUE(4 downto 3);
    --   * PAYLOAD    <= "00000" & DIP_VALUE(2 downto 0);  -- or full word
    -------------------------------------------------------------------

    -- TODO: replace these safe defaults with the real decode logic
    CMD_CODE  <= CMD_HOLD;            -- default = do nothing
    PAYLOAD   <= (others => '0');
    FREQ_SEL  <= (others => '0');
    CMD_VALID <= '0';

end architecture rtl;
