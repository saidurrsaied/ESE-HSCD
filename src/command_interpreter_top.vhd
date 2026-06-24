-- Module Name: command_interpreter_top.vhd
-- ##########################################################################
--  TOP LEVEL  -  Command Interpreter for DIP-Switch Commands
--  Target board: Lattice XP2-17  (LFXP2-17E-5QN208C),  Lattice Diamond
--
--  This is the entity the LPF pin-constraints file maps to. It only WIRES
--  the sub-modules together and applies the board POLARITY. The three of us
--  own the sub-modules:
--
--     Person A : synchronizer, debouncer, edge_detector, tick_generator
--     Person B : command_decoder, command_register, data_register,
--                execution_fsm
--     Person C : display_driver, pmod_out, this top level, LPF, testbench
--
--  OPERATING MODEL: "program, then run" in four phases driven by S1
--  (see command_pkg header). ENTER_DATA -> ENTER_CMD -> READY -> RUN.
--
--  DATA FLOW (overview):
--
--    DIP --sync--> dip_logic --+--> command_decoder --> command_register --+
--      (active-low, inverted)   |                                          |
--                               +--> data_register.DATA_IN (ENTER_DATA)    |
--    S1 --sync-deb-edge--> PRESS ----> execution_fsm <----- tick_generator-+
--                                         | data_load_en / op_en / op_code
--                                         v
--                                     data_register --> LEDs (LED_ON polarity)
--                                         |
--                  state_code + cmd/freq --> display_driver (7-seg) & pmod_out
--
--  OWNER: Person C (Output & Integration), but everyone reads it.
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity command_interpreter_top is
    generic (
        -- Real board = 24 MHz. A testbench overrides this with a small value
        -- (e.g. 200) so the tick generator and the ~10 ms debounce divide
        -- down quickly and the simulation finishes in microseconds.
        CLK_HZ : natural := SYS_CLK_HZ
    );
    Port (
        ------------------------------------------------------------------
        -- Clock  (board site 53, 24 MHz on-board oscillator)
        ------------------------------------------------------------------
        clk_in          : in  std_logic;

        ------------------------------------------------------------------
        -- Push buttons  (NO = normally-open contact of the change-over switch)
        --   btn_start_stop : S1 NO, site 17  -> the ONE operating button
        --                    (advance phase / start / stop)
        --   btn_display_sel: S2 NO, site 19  -> optional alternate RUN view
        --   btn_reset      : S4 NO, site 30  -> synchronous reset to ENTER_DATA
        ------------------------------------------------------------------
        btn_start_stop  : in  std_logic;
        btn_display_sel : in  std_logic;
        btn_reset       : in  std_logic;

        ------------------------------------------------------------------
        -- DIP switches (8) - data value (ENTER_DATA) or command+speed
        -- (ENTER_CMD).  dip_switch(0)=sw1 (LSB) .. dip_switch(7)=sw8 (MSB).
        ------------------------------------------------------------------
        dip_switch      : in  std_logic_vector(DATA_WIDTH-1 downto 0);

        ------------------------------------------------------------------
        -- LED row (8) - data register value (or live DIP preview in
        -- ENTER_DATA). led(0) = bit 0 = site 93.
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
        -- NOTE: the reference implementation SKIPS the PMOD; it is left
        -- here for the team to wire if the assignment wants scope signals.
        ------------------------------------------------------------------
        pmod            : out std_logic_vector(7 downto 0)
    );
end entity command_interpreter_top;


architecture structural of command_interpreter_top is

    -- ================= internal signals =================================
    signal rst             : std_logic;                              -- global synchronous reset (active high)

    -- synchronized / cleaned inputs
    signal dip_sync        : std_logic_vector(DATA_WIDTH-1 downto 0); -- raw, synchronized
    signal dip_logic       : std_logic_vector(DATA_WIDTH-1 downto 0); -- polarity-corrected (active-high)
    signal press_sync      : std_logic;
    signal press_clean     : std_logic;
    signal press_pulse     : std_logic;
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
    signal data_load_en    : std_logic;
    signal cmd_load_en     : std_logic;
    signal op_en           : std_logic;
    signal op_code         : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal exec_active     : std_logic;
    signal op_done         : std_logic;
    signal state_code      : std_logic_vector(1 downto 0);
    signal tick            : std_logic;

    -- datapath output + LED mux
    signal data_value      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal led_value       : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- display
    signal disp_left       : std_logic_vector(3 downto 0);
    signal disp_right      : std_logic_vector(3 downto 0);
    signal disp_left_blank : std_logic;
    signal disp_right_blank: std_logic;
    signal disp_right_dp   : std_logic;

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
               PRESS : in std_logic; CMD_VALID : in std_logic; TICK : in std_logic;
               CMD_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               DATA_LOAD_EN : out std_logic; CMD_LOAD_EN : out std_logic;
               OP_EN : out std_logic; OP_CODE : out std_logic_vector(CMD_WIDTH-1 downto 0);
               EXEC_ACTIVE : out std_logic; OP_DONE : out std_logic;
               STATE_CODE : out std_logic_vector(1 downto 0) );
    end component;

    component data_register is
        Port ( CLK : in std_logic; RST : in std_logic;
               LOAD_EN : in std_logic;
               DATA_IN : in std_logic_vector(DATA_WIDTH-1 downto 0);
               OP_EN : in std_logic;
               OP_CODE : in std_logic_vector(CMD_WIDTH-1 downto 0);
               PAYLOAD : in std_logic_vector(DATA_WIDTH-1 downto 0);
               DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0) );
    end component;

    component display_driver is
        Port ( LEFT_VALUE : in std_logic_vector(3 downto 0);
               RIGHT_VALUE : in std_logic_vector(3 downto 0);
               LEFT_BLANK : in std_logic;
               RIGHT_BLANK : in std_logic;
               RIGHT_DP : in std_logic;
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
    -- Reset: synchronize the reset button, convert to active-high rst
    -- using the verified button polarity.
    --------------------------------------------------------------------
    sync_reset : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in,
                   ASYNC_IN(0) => btn_reset,
                   SYNC_OUT(0) => reset_sync );
    rst <= '1' when reset_sync = BTN_PRESSED else '0';

    --------------------------------------------------------------------
    -- DIP switches: synchronize the whole 8-bit word, then correct the
    -- polarity. This board's switches are active-low (DIP_ON='0'), so we
    -- invert to get an active-high logical word ('1' = switch up/ON).
    -- EVERYTHING downstream uses dip_logic, never the raw dip_sync.
    --------------------------------------------------------------------
    sync_dip : synchronizer
        generic map ( WIDTH => DATA_WIDTH )
        port map ( CLK => clk_in, ASYNC_IN => dip_switch, SYNC_OUT => dip_sync );

    dip_logic <= dip_sync when DIP_ON = '1' else (not dip_sync);

    --------------------------------------------------------------------
    -- S1 (the one operating button): sync -> debounce -> rising-edge pulse.
    -- The edge detector turns "held" into a single 1-clock PRESS pulse, so
    -- each physical press advances the FSM exactly one phase.
    --------------------------------------------------------------------
    sync_ss : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in, ASYNC_IN(0) => btn_start_stop, SYNC_OUT(0) => press_sync );

    deb_ss : debouncer
        port map ( CLK => clk_in, RST => rst, NOISY_IN => press_sync, CLEAN_OUT => press_clean );

    edge_ss : edge_detector
        port map ( CLK => clk_in, RST => rst, SIG_IN => press_clean,
                   RISING_PULSE => press_pulse, FALLING_PULSE => open );

    --------------------------------------------------------------------
    -- S2 (optional): sync + debounce. Available to pick an alternate RUN
    -- view on the right 7-seg digit if you want one (e.g. data nibble vs
    -- speed). The four-phase display below does not require it.
    --------------------------------------------------------------------
    sync_ds : synchronizer
        generic map ( WIDTH => 1 )
        port map ( CLK => clk_in, ASYNC_IN(0) => btn_display_sel, SYNC_OUT(0) => dispsel_sync );

    deb_ds : debouncer
        port map ( CLK => clk_in, RST => rst, NOISY_IN => dispsel_sync, CLEAN_OUT => dispsel_clean );

    --------------------------------------------------------------------
    -- Command decoder (combinational) - works on the corrected dip_logic
    --------------------------------------------------------------------
    u_decoder : command_decoder
        port map ( DIP_VALUE => dip_logic,
                   CMD_CODE => dec_cmd_code, PAYLOAD => dec_payload,
                   FREQ_SEL => dec_freq_sel, CMD_VALID => dec_cmd_valid );

    --------------------------------------------------------------------
    -- Command register (captured in ENTER_CMD on cmd_load_en)
    --------------------------------------------------------------------
    u_cmdreg : command_register
        port map ( CLK => clk_in, RST => rst, LOAD_EN => cmd_load_en,
                   CMD_CODE_IN => dec_cmd_code, PAYLOAD_IN => dec_payload, FREQ_SEL_IN => dec_freq_sel,
                   CMD_CODE_OUT => reg_cmd_code, PAYLOAD_OUT => reg_payload, FREQ_SEL_OUT => reg_freq_sel );

    --------------------------------------------------------------------
    -- Repeat-rate tick generator (runs only while EXEC_ACTIVE in RUN)
    --------------------------------------------------------------------
    u_tick : tick_generator
        generic map ( CLK_HZ => CLK_HZ )
        port map ( CLK => clk_in, RST => rst, ENABLE => exec_active,
                   FREQ_SEL => reg_freq_sel, TICK => tick );

    --------------------------------------------------------------------
    -- Execution FSM (four phases)
    --------------------------------------------------------------------
    u_fsm : execution_fsm
        port map ( CLK => clk_in, RST => rst,
                   PRESS => press_pulse, CMD_VALID => dec_cmd_valid, TICK => tick,
                   CMD_CODE => reg_cmd_code,
                   DATA_LOAD_EN => data_load_en, CMD_LOAD_EN => cmd_load_en,
                   OP_EN => op_en, OP_CODE => op_code,
                   EXEC_ACTIVE => exec_active, OP_DONE => op_done, STATE_CODE => state_code );

    --------------------------------------------------------------------
    -- Data register / data path. Loads the live DIP word in ENTER_DATA
    -- (data_load_en), otherwise performs the stored command on each op.
    --------------------------------------------------------------------
    u_data : data_register
        port map ( CLK => clk_in, RST => rst,
                   LOAD_EN => data_load_en, DATA_IN => dip_logic,
                   OP_EN => op_en, OP_CODE => op_code, PAYLOAD => reg_payload,
                   DATA_OUT => data_value );

    --------------------------------------------------------------------
    -- LED row: preview the live DIP value while entering data, otherwise
    -- show the data register. Then apply the verified LED polarity.
    --------------------------------------------------------------------
    led_value <= dip_logic when state_code = ST_ENTER_DATA else data_value;
    led <= led_value when LED_ON = '1' else (not led_value);

    --------------------------------------------------------------------
    -- 7-segment content per phase:
    --   ENTER_DATA : left = 'd', right blank
    --   ENTER_CMD  : left = 'C', right blank
    --   READY      : left = command code, right = speed
    --   RUN        : left = command code, right = speed, right dp lit
    --------------------------------------------------------------------
    display_sel : process(state_code, reg_cmd_code, reg_freq_sel, exec_active)
    begin
        -- defaults: show command code + speed, both digits visible
        disp_left        <= "0"  & reg_cmd_code;   -- command 0..7 as a hex digit
        disp_right       <= "00" & reg_freq_sel;   -- speed 0..3 as a hex digit
        disp_left_blank  <= '0';
        disp_right_blank <= '0';
        disp_right_dp    <= exec_active;            -- dp lit only in RUN

        case state_code is
            when ST_ENTER_DATA =>
                disp_left        <= x"D";           -- 'd'
                disp_right_blank <= '1';
            when ST_ENTER_CMD =>
                disp_left        <= x"C";           -- 'C'
                disp_right_blank <= '1';
            when others =>                          -- READY / RUN
                null;
        end case;
    end process display_sel;

    u_disp : display_driver
        port map ( LEFT_VALUE => disp_left, RIGHT_VALUE => disp_right,
                   LEFT_BLANK => disp_left_blank, RIGHT_BLANK => disp_right_blank,
                   RIGHT_DP => disp_right_dp,
                   SEG_LEFT => seg_left, SEG_RIGHT => seg_right );

    --------------------------------------------------------------------
    -- PMOD oscilloscope outputs (optional - reference design omits these)
    --------------------------------------------------------------------
    u_pmod : pmod_out
        port map ( COMMAND_VALID => dec_cmd_valid, EXECUTE_ACTIVE => exec_active,
                   OPERATION_DONE => op_done, STATUS_SIGNAL => tick,
                   DATA_VALUE => data_value, PMOD => pmod );

end architecture structural;
