-- Module Name: command_register.vhd
-- ##########################################################################
--  Command register.
--
--  The homework says: "The selected command shall be stored in a command
--  register before execution." That is exactly this module.
--
--  When LOAD_EN = '1' (the FSM pulses CMD_LOAD_EN for one clock when the
--  user presses in the ENTER_CMD phase) the current decoder outputs are
--  captured and then held, so the user is free to change the DIP switches
--  afterwards (and READY/RUN ignore them) without disturbing the command.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity command_register is
    Port (
        CLK          : in  std_logic;
        RST          : in  std_logic;
        LOAD_EN      : in  std_logic;                              -- capture pulse from FSM
        -- inputs from the decoder
        CMD_CODE_IN  : in  std_logic_vector(CMD_WIDTH-1 downto 0);
        PAYLOAD_IN   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        FREQ_SEL_IN  : in  std_logic_vector(1 downto 0);
        -- stored outputs (go to FSM / data path / tick generator)
        CMD_CODE_OUT : out std_logic_vector(CMD_WIDTH-1 downto 0);
        PAYLOAD_OUT  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        FREQ_SEL_OUT : out std_logic_vector(1 downto 0)
    );
end entity command_register;

architecture rtl of command_register is

    signal cmd_reg     : std_logic_vector(CMD_WIDTH-1 downto 0)  := CMD_HOLD;
    signal payload_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal freq_reg    : std_logic_vector(1 downto 0)            := (others => '0');

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person B):
    --   if RST='1' then load defaults (CMD_HOLD, 0, 0)
    --   elsif LOAD_EN='1' then capture *_IN into *_reg
    --   else hold.
    -------------------------------------------------------------------
    reg_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                cmd_reg     <= CMD_HOLD;
                payload_reg <= (others => '0');
                freq_reg    <= (others => '0');
            elsif LOAD_EN = '1' then
                -- TODO: cmd_reg <= CMD_CODE_IN; payload_reg <= PAYLOAD_IN; freq_reg <= FREQ_SEL_IN;
                null;
            end if;
        end if;
    end process reg_proc;

    CMD_CODE_OUT <= cmd_reg;
    PAYLOAD_OUT  <= payload_reg;
    FREQ_SEL_OUT <= freq_reg;

end architecture rtl;
