-- Module Name: data_register_tb.vhd
-- ##########################################################################
--  Testbench for the 8-bit data register / data path.
--
--  Quick unit test so Person B can verify each operation in isolation
--  before integrating with the FSM.
--
--  WHAT TO CHECK:
--    * LOAD_EN         captures DATA_IN (the DIP word in ENTER_DATA)
--    * CMD_LOAD        loads PAYLOAD
--    * CMD_COUNT_UP    increments on each OP_EN
--    * CMD_COUNT_DOWN  decrements
--    * CMD_SHIFT_LEFT  shifts left, 0 comes in
--    * CMD_ROTATE_LEFT rotates left, MSB wraps to LSB
--    * CMD_CLEAR       gives 0
--    * CMD_INVERT      toggles all bits
--    * CMD_HOLD        keeps the value
--
--  GOTCHA: no `std.env.stop` (the bundled QuestaSim default mode rejects it).
--  End the run by stopping the clock via `sim_done` instead.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.command_pkg.all;

entity data_register_tb is
end data_register_tb;

architecture Simulation of data_register_tb is

    component data_register is
        Port ( CLK : in std_logic; RST : in std_logic;
               LOAD_EN : in std_logic;
               DATA_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
               OP_EN : in std_logic;
               OP_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD : in std_logic_vector(DATA_WIDTH-1 downto 0);
               DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0) );
    end component;

    signal CLK_tb      : std_logic := '0';
    signal RST_tb      : std_logic := '0';
    signal LOAD_EN_tb  : std_logic := '0';
    signal DATA_IN_tb  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal OP_EN_tb    : std_logic := '0';
    signal OP_CODE_tb  : std_logic_vector(CMD_WIDTH-1 downto 0) := CMD_HOLD;
    signal PAYLOAD_tb  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal DATA_OUT_tb : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal sim_done    : boolean := false;

begin

    dut : data_register
        port map ( CLK => CLK_tb, RST => RST_tb,
                   LOAD_EN => LOAD_EN_tb, DATA_IN => DATA_IN_tb,
                   OP_EN => OP_EN_tb, OP_CODE => OP_CODE_tb, PAYLOAD => PAYLOAD_tb,
                   DATA_OUT => DATA_OUT_tb );

    clockGen : process
    begin
        if sim_done then
            wait;
        end if;
        CLK_tb <= '0'; wait for 5 ns;
        CLK_tb <= '1'; wait for 5 ns;
    end process;

    stim : process
    begin
        RST_tb <= '1'; wait for 20 ns;
        RST_tb <= '0'; wait for 20 ns;

        -- Example pattern (Person B to extend):
        --   load 0x01 via the DIP path, then a rotate, a few count-ups, etc.
        -- DATA_IN_tb <= x"01"; LOAD_EN_tb <= '1'; wait for 10 ns; LOAD_EN_tb <= '0';
        -- OP_CODE_tb <= CMD_ROTATE_LEFT;
        -- OP_EN_tb <= '1'; wait for 10 ns; OP_EN_tb <= '0'; wait for 10 ns;

        -- TODO: exercise each operation and (optionally) add asserts

        wait for 100 ns;
        report "data_register_tb finished" severity note;
        sim_done <= true;
        wait;
    end process;

end Simulation;
