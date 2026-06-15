-- Module Name: execution_fsm.vhd
-- ##########################################################################
--  Execution FSM - the brain of the command interpreter.
--
--  BEHAVIOUR (from the homework):
--    * A push button LOADS and EXECUTES the selected command.
--    * The command REPEATS with the selectable frequency until the push
--      button is pressed AGAIN (toggle: press = start, press = stop).
--
--  SUGGESTED STATES:
--    IDLE     : nothing running. Waiting for a button press.
--               On START_STOP pulse (and CMD_VALID='1') -> latch command
--               (LOAD_CMD='1') and go to LOAD.
--    LOAD     : one cycle to let command_register capture the command.
--               Then go to RUN. (You may also do one immediate operation
--               here so the user sees an instant reaction.)
--    RUN      : EXEC_ACTIVE='1'. Every time TICK='1' pulse OP_EN so the
--               data_register performs one operation, and pulse OP_DONE.
--               On START_STOP pulse -> go back to IDLE (stop).
--
--  This is a Moore-ish FSM. Below it is split into the usual two processes
--  (state register + next-state/output logic) like in the example project.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity execution_fsm is
    Port (
        CLK            : in  std_logic;
        RST            : in  std_logic;
        -- control inputs
        START_STOP     : in  std_logic;                              -- 1-clk pulse from button edge
        CMD_VALID      : in  std_logic;                              -- from decoder
        TICK           : in  std_logic;                              -- repeat-rate enable
        CMD_CODE       : in  std_logic_vector(CMD_WIDTH-1 downto 0); -- stored command (from cmd reg)
        -- control outputs
        LOAD_CMD       : out std_logic;                              -- pulse: capture command into reg
        OP_EN          : out std_logic;                              -- pulse: do one data-path op
        OP_CODE        : out std_logic_vector(CMD_WIDTH-1 downto 0); -- which op the data path runs
        -- status / observation outputs (also used by 7-seg and PMOD)
        EXEC_ACTIVE    : out std_logic;                              -- '1' while running
        OP_DONE        : out std_logic;                              -- 1-clk pulse after each op
        STATE_CODE     : out std_logic_vector(3 downto 0)           -- current state as a number
    );
end entity execution_fsm;

architecture rtl of execution_fsm is

    -- FSM state type (same idea as cpu_state_type in the example project)
    type exec_state_type is (IDLE, LOAD, RUN);
    signal state, next_state : exec_state_type := IDLE;

begin

    -------------------------------------------------------------------
    -- STATE REGISTER
    -- IMPLEMENTATION GUIDE (Person B):
    --   if RST='1' then state <= IDLE; else state <= next_state; end if;
    -------------------------------------------------------------------
    state_reg : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                state <= IDLE;
            else
                -- TODO: state <= next_state;
                null;
            end if;
        end if;
    end process state_reg;

    -------------------------------------------------------------------
    -- NEXT-STATE + OUTPUT LOGIC (combinational)
    -- IMPLEMENTATION GUIDE (Person B):
    --   * Start every branch by giving ALL outputs a default value
    --     (LOAD_CMD<='0'; OP_EN<='0'; EXEC_ACTIVE<='0'; OP_DONE<='0';
    --      next_state<=state;) so you never create accidental latches.
    --   * IDLE: if START_STOP='1' and CMD_VALID='1' then
    --                LOAD_CMD <= '1'; next_state <= LOAD;
    --   * LOAD: next_state <= RUN;  (command is now in the register)
    --   * RUN : EXEC_ACTIVE <= '1';
    --           if START_STOP='1' then next_state <= IDLE;        -- stop
    --           elsif TICK='1'    then OP_EN <= '1'; OP_DONE <= '1';
    --   * OP_CODE <= CMD_CODE (the data path always uses the stored command)
    -------------------------------------------------------------------
    next_logic : process(state, START_STOP, CMD_VALID, TICK, CMD_CODE)
    begin
        -- safe defaults
        next_state  <= state;
        LOAD_CMD    <= '0';
        OP_EN       <= '0';
        OP_DONE     <= '0';
        EXEC_ACTIVE <= '0';

        case state is
            when IDLE =>
                -- TODO: detect start, pulse LOAD_CMD, go to LOAD
                null;
            when LOAD =>
                -- TODO: next_state <= RUN;
                null;
            when RUN =>
                -- TODO: stop on START_STOP, otherwise OP_EN on TICK
                null;
        end case;
    end process next_logic;

    -- the data path always executes the command we stored
    OP_CODE <= CMD_CODE;

    -------------------------------------------------------------------
    -- STATE_CODE: expose the state as a small number so the 7-seg display
    -- and/or PMOD "selected internal status signal" can show it.
    -- TODO: map each state to a value, e.g. IDLE=0, LOAD=1, RUN=2.
    -------------------------------------------------------------------
    STATE_CODE <= (others => '0');   -- placeholder

end architecture rtl;
