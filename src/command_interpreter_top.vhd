-- Module Name: command_interpreter_top.vhd
-- ##########################################################################
--  TOP LEVEL  -  Command Interpreter for DIP-Switch Commands
--  Target board: Lattice XP2-17  (LFXP2-17E-5QN208C),  Lattice Diamond
--
--  This is the entity the LPF pin-constraints file maps to. It only WIRES
--  the sub-modules together; there is (almost) no logic in here. The real
--  work lives in the sub-modules, which the three of us own:
--
--     Person A : synchronizer, debouncer, edge_detector, tick_generator
--     Person B : command_decoder, command_register, data_register,
--                execution_fsm
--     Person C : display_driver, pmod_out, this top level, LPF, testbench
--
--  DATA FLOW (overview):
--
--    DIP --> sync --> command_decoder --> command_register --+--> execution_fsm
--                                                            |        |
--    btn S1 --> sync --> debounce --> edge --> start/stop ---+        | op_en/op_code
--                                                                     v
--                                              tick_generator --> data_register --> LEDs
--                                                                     |
--                              status signals --> display_driver (7-seg) & pmod_out
--
--  OWNER: Person C (Output & Integration), but everyone reads it.
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity command_interpreter_top is
    generic (
        -- Real board = 24 MHz. A testbench may override this with a small
        -- value (e.g. 1000) so the tick generator divides down quickly and
        -- the simulation does not take forever.
        CLK_HZ : natural := SYS_CLK_HZ
    );
    Port (
        ------------------------------------------------------------------
        -- Clock  (board site 53, 24 MHz on-board oscillator)
        ------------------------------------------------------------------
        clk_in          : in  std_logic;

        ------------------------------------------------------------------
        -- Push buttons  (NO = normally-open contact of the change-over switch)
        --   btn_start_stop : S1 NO, site 17  -> start / stop the execution
        --   btn_display_sel: S2 NO, site 19  -> switch 7-seg view
        --   btn_reset      : S4 NO, site 30  -> synchronous reset
        -- (S3 is left as a spare for now.)
        ------------------------------------------------------------------
        btn_start_stop  : in  std_logic;
        btn_display_sel : in  std_logic;
        btn_reset       : in  std_logic;

        ------------------------------------------------------------------
        -- DIP switches (8) - the "command word".  dip_switch(0)=S1..(7)=S8
        ------------------------------------------------------------------
        dip_switch      : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        ------------------------------------------------------------------
        -- LED row (8) - shows the data register value (homework requirement)
        ------------------------------------------------------------------
        led             : out std_logic_vector(7 downto 0);

        ------------------------------------------------------------------
        -- Two-digit 7-segment display, all segments driven directly.
        -- Bit order per digit: 0=a 1=b 2=c 3=d 4=e 5=f 6=g 7=dp
        ------------------------------------------------------------------
        seg_left        : out std_logic_vector(7 downto 0);
        seg_right       : out std_logic_vector(7 downto 0);

        ------------------------------------------------------------------
        -- PMOD / external logic connector (8) - oscilloscope outputs only.
        ------------------------------------------------------------------
        pmod            : out std_logic_vector(7 downto 0)
    );
end entity command_interpreter_top;


architecture structural of command_interpreter_top is

    -- ================= internal signals =================================
    signal rst             : std_logic;                              -- global synchronous reset (active high)

    -- synchronized / cleaned inputs
    signal dip_sync        : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal startstop_sync  : std_logic;
    signal startstop_clean : std_logic;
    signal startstop_pulse : std_logic;
    signal dispsel_sync    : std_logic;
    signal dispsel_clean   : std_logic;
    signal reset_sync      : std_logic;

    -- decoder outputs
    signal dec_cmd_code    : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal dec_payload     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dec_freq_sel    : std_logic_vector(1 downto 0);
    signal dec_cmd_valid   : std_logic;

    -- command register (stored) outputs
    signal reg_cmd_code    : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal reg_payload     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal reg_freq_sel    : std_logic_vector(1 downto 0);

    -- FSM <-> datapath
    signal load_cmd        : std_logic;
    signal op_en           : std_logic;
    signal op_code         : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal exec_active     : std_logic;
    signal op_done         : std_logic;
    signal state_code      : std_logic_vector(3 downto 0);
    signal tick            : std_logic;

    -- datapath output
    signal data_value      : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- display nibbles
    signal disp_left       : std_logic_vector(3 downto 0);
    signal disp_right      : std_logic_vector(3 downto 0);

    -- =================== component declarations =========================
    component synchronizer is
        generic ( WIDTH : natural := 1 );
        Port ( CLK : in std_logic;
               ASYNC_IN : in std_logic_vector(WIDTH-1 downto 0);
               SYNC_OUT : out std_logic_vector(WIDTH-1 downto 0) );
    end component;

    component debouncer is
        generic ( STABLE_COUNT : natural := 240_000 );
        Port ( CLK : in std_logic; RST : in std_logic;
               NOISY_IN : in std_logic; CLEAN_OUT : out std_logic );
    end component;

    component edge_detector is
        Port ( CLK : in std_logic; RST : in std_logic; SIG_IN : in std_logic;
               RISING_PULSE : out std_logic; FALLING_PULSE : out std_logic );
    end component;

    component tick_generator is
        generic ( CLK_HZ : natural := SYS_CLK_HZ );
        Port ( CLK : in std_logic; RST : in std_logic; ENABLE : in std_logic;
               FREQ_SEL : in std_logic_vector(1 downto 0); TICK : out std_logic );
    end component;

    component command_decoder is
        Port ( DIP_VALUE : in std_logic_vector(DATA_WIDTH-1 downto 0);
               CMD_CODE : out std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD : out std_logic_vector(DATA_WIDTH-1 downto 0);
               FREQ_SEL : out std_logic_vector(1 downto 0);
               CMD_VALID : out std_logic );
    end component;

    component command_register is
        Port ( CLK : in std_logic; RST : in std_logic; LOAD_EN : in std_logic;
               CMD_CODE_IN : in std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
               FREQ_SEL_IN : in std_logic_vector(1 downto 0);
               CMD_CODE_OUT : out std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0);
               FREQ_SEL_OUT : out std_logic_vector(1 downto 0) );
    end component;

    component execution_fsm is
        Port ( CLK : in std_logic; RST : in std_logic;
               START_STOP : in std_logic; CMD_VALID : in std_logic; TICK : in std_logic;
               CMD_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               LOAD_CMD : out std_logic; OP_EN : out std_logic;
               OP_CODE : out std_logic_vector(CMD_WIDTH-1 downto 0);
               EXEC_ACTIVE : out std_logic; OP_DONE : out std_logic;
               STATE_CODE : out std_logic_vector(3 downto 0) );
    end component;

    component data_register is
        Port ( CLK : in std_logic; RST : in std_logic; OP_EN : in std_logic;
               OP_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD : in std_logic_vector(DATA_WIDTH-1 downto 0);
               DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0) );
    end component;

    component display_driver is
        Port ( LEFT_VALUE : in std_logic_vector(3 downto 0);
               RIGHT_VALUE : in std_logic_vector(3 downto 0);
               SEG_LEFT : out std_logic_vector(7 downto 0);
               SEG_RIGHT : out std_logic_vector(7 downto 0) );
    end component;

    component pmod_out is
        Port ( COMMAND_VALID : in std_logic; EXECUTE_ACTIVE : in std_logic;
               OPERATION_DONE : in std_logic; STATUS_SIGNAL : in std_logic;
               DATA_VALUE : in std_logic_vector(DATA_WIDTH-1 downto 0);
               PMOD : out std_logic_vector(7 downto 0) );
    end component;

-- ##########################################################################
begin
-- ##########################################################################

    --------------------------------------------------------------------
    -- Reset: synchronize the reset button. (Simple version: use its
    -- debounced/synced level directly as the active-high reset.)
    -- A single synchronizer is enough for a reset; add a debouncer too if
    -- you see glitches. Polarity of the button must be confirmed on HW.
    --------------------------------------------------------------------
    sync_reset : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in,
                   ASYNC_IN(0) => btn_reset,
                   SYNC_OUT(0) => reset_sync );
    rst <= reset_sync;   -- TODO confirm active level (maybe 'not reset_sync')

    --------------------------------------------------------------------
    -- DIP switches: synchronize the whole 8-bit word
    --------------------------------------------------------------------
    sync_dip : synchronizer
        generic map ( WIDTH => DATA_WIDTH )
        port map ( CLK => clk_in, ASYNC_IN => dip_switch, SYNC_OUT => dip_sync );

    --------------------------------------------------------------------
    -- Start/Stop button: sync -> debounce -> rising-edge pulse
    --------------------------------------------------------------------
    sync_ss : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in, ASYNC_IN(0) => btn_start_stop, SYNC_OUT(0) => startstop_sync );

    deb_ss : debouncer
        port map ( CLK => clk_in, RST => rst, NOISY_IN => startstop_sync, CLEAN_OUT => startstop_clean );

    edge_ss : edge_detector
        port map ( CLK => clk_in, RST => rst, SIG_IN => startstop_clean,
                   RISING_PULSE => startstop_pulse, FALLING_PULSE => open );

    --------------------------------------------------------------------
    -- Display-select button: sync -> debounce (level is enough)
    --------------------------------------------------------------------
    sync_ds : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in, ASYNC_IN(0) => btn_display_sel, SYNC_OUT(0) => dispsel_sync );

    deb_ds : debouncer
        port map ( CLK => clk_in, RST => rst, NOISY_IN => dispsel_sync, CLEAN_OUT => dispsel_clean );

    --------------------------------------------------------------------
    -- Command decoder (combinational)
    --------------------------------------------------------------------
    u_decoder : command_decoder
        port map ( DIP_VALUE => dip_sync,
                   CMD_CODE => dec_cmd_code, PAYLOAD => dec_payload,
                   FREQ_SEL => dec_freq_sel, CMD_VALID => dec_cmd_valid );

    --------------------------------------------------------------------
    -- Command register (stores the selected command)
    --------------------------------------------------------------------
    u_cmdreg : command_register
        port map ( CLK => clk_in, RST => rst, LOAD_EN => load_cmd,
                   CMD_CODE_IN => dec_cmd_code, PAYLOAD_IN => dec_payload, FREQ_SEL_IN => dec_freq_sel,
                   CMD_CODE_OUT => reg_cmd_code, PAYLOAD_OUT => reg_payload, FREQ_SEL_OUT => reg_freq_sel );

    --------------------------------------------------------------------
    -- Repeat-rate tick generator (runs while the FSM is active)
    --------------------------------------------------------------------
    u_tick : tick_generator
        generic map ( CLK_HZ => CLK_HZ )
        port map ( CLK => clk_in, RST => rst, ENABLE => exec_active,
                   FREQ_SEL => reg_freq_sel, TICK => tick );

    --------------------------------------------------------------------
    -- Execution FSM
    --------------------------------------------------------------------
    u_fsm : execution_fsm
        port map ( CLK => clk_in, RST => rst,
                   START_STOP => startstop_pulse, CMD_VALID => dec_cmd_valid, TICK => tick,
                   CMD_CODE => reg_cmd_code,
                   LOAD_CMD => load_cmd, OP_EN => op_en, OP_CODE => op_code,
                   EXEC_ACTIVE => exec_active, OP_DONE => op_done, STATE_CODE => state_code );

    --------------------------------------------------------------------
    -- Data register / data path
    --------------------------------------------------------------------
    u_data : data_register
        port map ( CLK => clk_in, RST => rst, OP_EN => op_en,
                   OP_CODE => op_code, PAYLOAD => reg_payload, DATA_OUT => data_value );

    --------------------------------------------------------------------
    -- LED row shows the data register value
    --------------------------------------------------------------------
    led <= data_value;   -- TODO confirm LED polarity on hardware

    --------------------------------------------------------------------
    -- 7-segment view selection (Person C):
    --   default: left = command code, right = low nibble of data.
    --   Use dispsel_clean to switch the right digit between data low
    --   nibble / data high nibble / state code, etc.
    --------------------------------------------------------------------
    disp_left  <= reg_cmd_code;                 -- show stored command on left digit
    disp_right <= data_value(3 downto 0)        -- TODO: use dispsel_clean to pick view
                  when dispsel_clean = '0'
                  else data_value(7 downto 4);

    u_disp : display_driver
        port map ( LEFT_VALUE => disp_left, RIGHT_VALUE => disp_right,
                   SEG_LEFT => seg_left, SEG_RIGHT => seg_right );

    --------------------------------------------------------------------
    -- PMOD oscilloscope outputs
    --   STATUS_SIGNAL: pick something useful to watch, e.g. the tick.
    --------------------------------------------------------------------
    u_pmod : pmod_out
        port map ( COMMAND_VALID => dec_cmd_valid, EXECUTE_ACTIVE => exec_active,
                   OPERATION_DONE => op_done, STATUS_SIGNAL => tick,
                   DATA_VALUE => data_value, PMOD => pmod );

end architecture structural;
