-- Module Name: execution_fsm.vhd
-- ##########################################################################
--  Execution FSM - the brain of the command interpreter.
--
--  Operated as a "program, then run" sequence by ONE button (PRESS = a
--  1-clock pulse from the S1 edge detector). Four phases:
--
--    ENTER_DATA : user dials a value on the DIP switches (LEDs preview it,
--                 left 7-seg = 'd'). PRESS pulses DATA_LOAD_EN so the data
--                 register captures the DIP word, then -> ENTER_CMD.
--    ENTER_CMD  : user dials command (DIP 8..6) + speed (DIP 5..4),
--                 left 7-seg = 'C'. PRESS (with CMD_VALID) pulses CMD_LOAD_EN
--                 so the command register captures it, then -> READY.
--    READY      : everything stored, nothing runs. PRESS -> RUN.
--    RUN        : EXEC_ACTIVE='1'. Each TICK pulses OP_EN (one data-path
--                 operation) and OP_DONE. PRESS -> stop, back to ENTER_DATA.
--
--  STATE_CODE (2 bit) is published so the top level picks the display and
--  the LED preview (ST_ENTER_DATA / ST_ENTER_CMD / ST_READY / ST_RUN).
--
--  Two-process Moore FSM (state register + next-state/output logic) like in
--  the example project.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity execution_fsm is
    Port (
        CLK          : in  std_logic;
        RST          : in  std_logic;
        -- control inputs
        PRESS        : in  std_logic;                              -- 1-clk pulse from S1 edge
        CMD_VALID    : in  std_logic;                              -- from decoder
        TICK         : in  std_logic;                              -- repeat-rate enable
        CMD_CODE     : in  std_logic_vector(CMD_WIDTH-1 downto 0); -- stored command (from cmd reg)
        -- control outputs
        DATA_LOAD_EN : out std_logic;                              -- pulse: capture DIP word into data reg
        CMD_LOAD_EN  : out std_logic;                              -- pulse: capture command into cmd reg
        OP_EN        : out std_logic;                              -- pulse: do one data-path op
        OP_CODE      : out std_logic_vector(CMD_WIDTH-1 downto 0); -- which op the data path runs
        -- status / observation outputs (also used by 7-seg and PMOD)
        EXEC_ACTIVE  : out std_logic;                              -- '1' while running (RUN)
        OP_DONE      : out std_logic;                              -- 1-clk pulse after each op
        STATE_CODE   : out std_logic_vector(1 downto 0)            -- current phase (ST_* codes)
    );
end entity execution_fsm;

architecture rtl of execution_fsm is

    -- FSM state type (one per operating phase)
    type exec_state_type is (ENTER_DATA, ENTER_CMD, READY, RUN);
    signal state, next_state : exec_state_type := ENTER_DATA;

begin

    -------------------------------------------------------------------
    -- STATE REGISTER
    -- IMPLEMENTATION GUIDE (Person B):
    --   if RST='1' then state <= ENTER_DATA; else state <= next_state;
    -------------------------------------------------------------------
    state_reg : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                state <= ENTER_DATA;
            else
                -- TODO: state <= next_state;
                null;
            end if;
        end if;
    end process state_reg;

    -------------------------------------------------------------------
    -- NEXT-STATE + OUTPUT LOGIC (combinational)
    -- IMPLEMENTATION GUIDE (Person B):
    --   * Start with safe defaults for EVERY output (already done below) so
    --     you never create accidental latches.
    --   * ENTER_DATA: if PRESS='1' then DATA_LOAD_EN<='1';
    --                                   next_state<=ENTER_CMD;
    --   * ENTER_CMD : if PRESS='1' and CMD_VALID='1' then
    --                      CMD_LOAD_EN<='1'; next_state<=READY;
    --   * READY     : if PRESS='1' then next_state<=RUN;
    --   * RUN       : EXEC_ACTIVE<='1';
    --                 if PRESS='1' then next_state<=ENTER_DATA;   -- stop
    --                 elsif TICK='1' then OP_EN<='1'; OP_DONE<='1';
    --   NOTE: the PRESS that stops RUN must NOT also assert DATA_LOAD_EN -
    --   that is automatic here because DATA_LOAD_EN is only set in ENTER_DATA.
    -------------------------------------------------------------------
    next_logic : process(state, PRESS, CMD_VALID, TICK, CMD_CODE)
    begin
        -- safe defaults
        next_state   <= state;
        DATA_LOAD_EN <= '0';
        CMD_LOAD_EN  <= '0';
        OP_EN        <= '0';
        OP_DONE      <= '0';
        EXEC_ACTIVE  <= '0';

        case state is
            when ENTER_DATA =>
                -- TODO: on PRESS -> DATA_LOAD_EN, go to ENTER_CMD
                null;
            when ENTER_CMD =>
                -- TODO: on PRESS (and CMD_VALID) -> CMD_LOAD_EN, go to READY
                null;
            when READY =>
                -- TODO: on PRESS -> RUN
                null;
            when RUN =>
                -- TODO: EXEC_ACTIVE; stop on PRESS; else OP_EN/OP_DONE on TICK
                null;
        end case;
    end process next_logic;

    -- the data path always executes the command we stored
    OP_CODE <= CMD_CODE;

    -------------------------------------------------------------------
    -- STATE_CODE: expose the phase so the top level drives the 7-seg
    -- ('d'/'C'/cmd+speed) and the LED preview.
    -- TODO: map  ENTER_DATA->ST_ENTER_DATA, ENTER_CMD->ST_ENTER_CMD,
    --            READY->ST_READY, RUN->ST_RUN.
    -------------------------------------------------------------------
    STATE_CODE <= ST_ENTER_DATA;   -- placeholder

end architecture rtl;
