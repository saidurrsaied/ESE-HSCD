-- Module Name: data_register_tb.vhd
-- ##########################################################################
--  Testbench for the 8-bit data register / data path.
--
--  Quick unit test so Person B can verify each operation in isolation
--  before integrating with the FSM.
--
--  WHAT TO CHECK:
--    * CMD_LOAD       loads PAYLOAD
--    * CMD_COUNT_UP   increments on each OP_EN
--    * CMD_COUNT_DOWN decrements
--    * CMD_SHIFT      shifts left, 0 comes in
--    * CMD_ROTATE     rotates left, MSB wraps to LSB
--    * CMD_CLEAR / CMD_RESET give 0
--    * CMD_HOLD       keeps the value
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.stop;
use work.command_pkg.all;

entity data_register_tb is
end data_register_tb;

architecture Simulation of data_register_tb is

    component data_register is
        Port ( CLK : in std_logic; RST : in std_logic; OP_EN : in std_logic;
               OP_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD : in std_logic_vector(DATA_WIDTH-1 downto 0);
               DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0) );
    end component;

    signal CLK_tb      : std_logic := '0';
    signal RST_tb      : std_logic := '0';
    signal OP_EN_tb    : std_logic := '0';
    signal OP_CODE_tb  : std_logic_vector(CMD_WIDTH-1 downto 0) := CMD_HOLD;
    signal PAYLOAD_tb  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal DATA_OUT_tb : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

    dut : data_register
        port map ( CLK => CLK_tb, RST => RST_tb, OP_EN => OP_EN_tb,
                   OP_CODE => OP_CODE_tb, PAYLOAD => PAYLOAD_tb, DATA_OUT => DATA_OUT_tb );

    clockGen : process
    begin
        CLK_tb <= '0'; wait for 5 ns;
        CLK_tb <= '1'; wait for 5 ns;
    end process;

    stim : process
    begin
        RST_tb <= '1'; wait for 20 ns;
        RST_tb <= '0'; wait for 20 ns;

        -- Example pattern (Person B to extend):
        --   load 0x55, then a few count-ups, then a rotate, etc.
        -- PAYLOAD_tb <= x"55"; OP_CODE_tb <= CMD_LOAD;
        -- OP_EN_tb <= '1'; wait for 10 ns; OP_EN_tb <= '0'; wait for 10 ns;

        -- TODO: exercise each operation and (optionally) add asserts

        wait for 100 ns;
        report "data_register_tb finished" severity note;
        stop;
    end process;

end Simulation;
