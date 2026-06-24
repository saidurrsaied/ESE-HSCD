-- Module Name: execution_fsm_tb.vhd
-- ##########################################################################
--  Testbench for the CENTRAL part of the design: the execution FSM.
--
--  The homework explicitly asks for a testbench of the central part that
--  "demonstrates that the main function works as intended". The four-phase
--  FSM is that central part, so this is the most important simulation.
--
--  WHAT TO CHECK (write these as stimulus + asserts):
--    1. After reset the FSM is in ENTER_DATA (STATE_CODE=ST_ENTER_DATA,
--       EXEC_ACTIVE='0').
--    2. PRESS -> DATA_LOAD_EN pulses, FSM moves to ENTER_CMD.
--    3. PRESS (with CMD_VALID='1') -> CMD_LOAD_EN pulses, FSM moves to READY.
--    4. PRESS -> FSM moves to RUN (EXEC_ACTIVE='1').
--    5. While in RUN, every TICK produces a one-clock OP_EN and OP_DONE.
--    6. PRESS -> FSM returns to ENTER_DATA (EXEC_ACTIVE='0').
--
--  GOTCHA (learned on the bundled QuestaSim): do NOT use `std.env.stop`
--  unless the sim is forced to VHDL-2008 - the default language mode rejects
--  it ("'env' is not compiled in library 'std'"). Instead end the run by
--  stopping the clock via a `sim_done` boolean (done below). This keeps the
--  TB compatible with VHDL-93/2002/2008.
--
--  OWNER: Person B (Core Logic) - you wrote the FSM, you test it.
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.command_pkg.all;

entity execution_fsm_tb is
end execution_fsm_tb;

architecture Simulation of execution_fsm_tb is

    component execution_fsm is
        Port ( CLK : in std_logic; RST : in std_logic;
               PRESS : in std_logic; CMD_VALID : in std_logic; TICK : in std_logic;
               CMD_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               DATA_LOAD_EN : out std_logic; CMD_LOAD_EN : out std_logic;
               OP_EN : out std_logic; OP_CODE : out std_logic_vector(CMD_WIDTH-1 downto 0);
               EXEC_ACTIVE : out std_logic; OP_DONE : out std_logic;
               STATE_CODE : out std_logic_vector(1 downto 0) );
    end component;

    -- DUT signals (use _tb suffix like the example project)
    signal CLK_tb          : std_logic := '0';
    signal RST_tb          : std_logic := '0';
    signal PRESS_tb        : std_logic := '0';
    signal CMD_VALID_tb    : std_logic := '1';
    signal TICK_tb         : std_logic := '0';
    signal CMD_CODE_tb     : std_logic_vector(CMD_WIDTH-1 downto 0) := CMD_COUNT_UP;

    signal DATA_LOAD_EN_tb : std_logic;
    signal CMD_LOAD_EN_tb  : std_logic;
    signal OP_EN_tb        : std_logic;
    signal OP_CODE_tb      : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal EXEC_ACTIVE_tb  : std_logic;
    signal OP_DONE_tb      : std_logic;
    signal STATE_CODE_tb   : std_logic_vector(1 downto 0);

    -- set true at the end of the scenario to stop the clock and end the run
    signal sim_done        : boolean := false;

begin

    -- Device under test
    dut : execution_fsm
        port map ( CLK => CLK_tb, RST => RST_tb,
                   PRESS => PRESS_tb, CMD_VALID => CMD_VALID_tb, TICK => TICK_tb,
                   CMD_CODE => CMD_CODE_tb,
                   DATA_LOAD_EN => DATA_LOAD_EN_tb, CMD_LOAD_EN => CMD_LOAD_EN_tb,
                   OP_EN => OP_EN_tb, OP_CODE => OP_CODE_tb,
                   EXEC_ACTIVE => EXEC_ACTIVE_tb, OP_DONE => OP_DONE_tb, STATE_CODE => STATE_CODE_tb );

    -- 100 MHz-ish clock (10 ns period). Stops when sim_done -> run ends.
    clockGen : process
    begin
        if sim_done then
            wait;
        end if;
        CLK_tb <= '0'; wait for 5 ns;
        CLK_tb <= '1'; wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- STIMULUS
    -- IMPLEMENTATION GUIDE (Person B): a PRESS is one clock high then low.
    --   pulse pattern:  PRESS_tb <= '1'; wait for 10 ns; PRESS_tb <= '0';
    --   After each press, wait a clock and assert the new STATE_CODE.
    --------------------------------------------------------------------
    stim : process
    begin
        -- 1) reset -> ENTER_DATA
        RST_tb <= '1'; wait for 20 ns;
        RST_tb <= '0'; wait for 20 ns;
        -- TODO: assert STATE_CODE_tb = ST_ENTER_DATA and EXEC_ACTIVE_tb = '0';

        -- 2) TODO: PRESS -> expect DATA_LOAD_EN pulse, STATE_CODE = ST_ENTER_CMD
        -- 3) TODO: PRESS (CMD_VALID='1') -> CMD_LOAD_EN pulse, ST_READY
        -- 4) TODO: PRESS -> ST_RUN, EXEC_ACTIVE='1'
        -- 5) TODO: drive a few TICK pulses, check OP_EN / OP_DONE appear
        -- 6) TODO: PRESS -> back to ST_ENTER_DATA

        wait for 100 ns;
        report "execution_fsm_tb finished" severity note;
        sim_done <= true;
        wait;
    end process;

end Simulation;
