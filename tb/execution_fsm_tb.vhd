-- Module Name: execution_fsm_tb.vhd
-- ##########################################################################
--  Testbench for the CENTRAL part of the design: the execution FSM.
--
--  The homework explicitly asks for a testbench of the central part that
--  "demonstrates that the main function works as intended". The FSM is that
--  central part, so this is the most important simulation.
--
--  WHAT TO CHECK (write these as stimulus + asserts):
--    1. After reset the FSM is in IDLE (EXEC_ACTIVE = '0').
--    2. A START_STOP pulse with CMD_VALID='1' makes LOAD_CMD pulse and the
--       FSM move to RUN (EXEC_ACTIVE='1').
--    3. While in RUN, every TICK produces a one-clock OP_EN and OP_DONE.
--    4. A second START_STOP pulse returns the FSM to IDLE (EXEC_ACTIVE='0').
--
--  OWNER: Person B (Core Logic) - you wrote the FSM, you test it.
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.stop;
use work.command_pkg.all;

entity execution_fsm_tb is
end execution_fsm_tb;

architecture Simulation of execution_fsm_tb is

    component execution_fsm is
        Port ( CLK : in std_logic; RST : in std_logic;
               START_STOP : in std_logic; CMD_VALID : in std_logic; TICK : in std_logic;
               CMD_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               LOAD_CMD : out std_logic; OP_EN : out std_logic;
               OP_CODE : out std_logic_vector(CMD_WIDTH-1 downto 0);
               EXEC_ACTIVE : out std_logic; OP_DONE : out std_logic;
               STATE_CODE : out std_logic_vector(3 downto 0) );
    end component;

    -- DUT signals (use _tb suffix like the example project)
    signal CLK_tb         : std_logic := '0';
    signal RST_tb         : std_logic := '0';
    signal START_STOP_tb  : std_logic := '0';
    signal CMD_VALID_tb   : std_logic := '0';
    signal TICK_tb        : std_logic := '0';
    signal CMD_CODE_tb    : std_logic_vector(CMD_WIDTH-1 downto 0) := CMD_COUNT_UP;

    signal LOAD_CMD_tb    : std_logic;
    signal OP_EN_tb       : std_logic;
    signal OP_CODE_tb     : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal EXEC_ACTIVE_tb : std_logic;
    signal OP_DONE_tb     : std_logic;
    signal STATE_CODE_tb  : std_logic_vector(3 downto 0);

begin

    -- Device under test
    dut : execution_fsm
        port map ( CLK => CLK_tb, RST => RST_tb,
                   START_STOP => START_STOP_tb, CMD_VALID => CMD_VALID_tb, TICK => TICK_tb,
                   CMD_CODE => CMD_CODE_tb,
                   LOAD_CMD => LOAD_CMD_tb, OP_EN => OP_EN_tb, OP_CODE => OP_CODE_tb,
                   EXEC_ACTIVE => EXEC_ACTIVE_tb, OP_DONE => OP_DONE_tb, STATE_CODE => STATE_CODE_tb );

    -- 100 MHz-ish clock (10 ns period)
    clockGen : process
    begin
        CLK_tb <= '0'; wait for 5 ns;
        CLK_tb <= '1'; wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- STIMULUS
    -- IMPLEMENTATION GUIDE (Person B): fill in the steps. A pulse helper
    -- pattern: set signal '1' for one clock, then back to '0'.
    --------------------------------------------------------------------
    stim : process
    begin
        -- 1) reset
        RST_tb <= '1'; wait for 20 ns;
        RST_tb <= '0'; wait for 20 ns;

        -- 2) TODO: pulse START_STOP with CMD_VALID='1' and check we enter RUN

        -- 3) TODO: drive a few TICK pulses, check OP_EN / OP_DONE appear

        -- 4) TODO: pulse START_STOP again, check we return to IDLE

        wait for 100 ns;
        report "execution_fsm_tb finished" severity note;
        stop;
    end process;

end Simulation;
