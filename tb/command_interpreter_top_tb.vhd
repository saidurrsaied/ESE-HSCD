-- Module Name: command_interpreter_top_tb.vhd
-- ##########################################################################
--  Board-mimicking testbench for the whole design (top level).
--
--  This is the testbench the homework calls "a VHDL testbench mimicking the
--  FPGA board to a certain extent". It plays the role of the hardware:
--    * generates the clock (like the 24 MHz oscillator)
--    * presses the buttons (like a human)
--    * sets the DIP switches at the REAL (active-low) pin levels
--    * and lets us watch the LEDs / 7-seg / PMOD in the waveform.
--
--  Two things make this TB faithful AND fast:
--    * CLK_HZ generic is overridden with a SMALL number (200) so the tick
--      generator and the ~10 ms debounce divide down in microseconds.
--    * It drives PHYSICAL pin levels through the polarity constants
--      (dip_phys / led_logic / BTN_PRESSED), so it stays correct no matter
--      how those constants are set.
--
--  GOTCHA (bundled QuestaSim): NO `std.env.stop` - the default language mode
--  rejects it ("'env' is not compiled in library 'std'"). End the run by
--  stopping the clock via a `sim_done` boolean instead. Also, in the .do
--  file, run vsim with `-voptargs=+acc` so observe-only outputs (7-seg) stay
--  visible in the waveform.
--
--  OWNER: Person C (Output & Integration)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.command_pkg.all;

entity command_interpreter_top_tb is
end command_interpreter_top_tb;

architecture Simulation of command_interpreter_top_tb is

    component command_interpreter_top is
        generic ( CLK_HZ : natural := SYS_CLK_HZ );
        Port (
            clk_in          : in  std_logic;
            btn_start_stop  : in  std_logic;
            btn_display_sel : in  std_logic;
            btn_reset       : in  std_logic;
            dip_switch      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            led             : out std_logic_vector(7 downto 0);
            seg_left        : out std_logic_vector(7 downto 0);
            seg_right       : out std_logic_vector(7 downto 0);
            pmod            : out std_logic_vector(7 downto 0)
        );
    end component;

    -- board-side signals (buttons idle = released = not BTN_PRESSED)
    signal clk_tb        : std_logic := '0';
    signal start_stop_tb : std_logic := not BTN_PRESSED;
    signal disp_sel_tb   : std_logic := not BTN_PRESSED;
    signal reset_tb      : std_logic := not BTN_PRESSED;
    signal dip_tb        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal led_tb        : std_logic_vector(7 downto 0);
    signal seg_left_tb   : std_logic_vector(7 downto 0);
    signal seg_right_tb  : std_logic_vector(7 downto 0);
    signal pmod_tb       : std_logic_vector(7 downto 0);

    signal sim_done      : boolean := false;

    constant SIM_CLK_HZ  : natural := 200;   -- tiny clock so 1 "Hz" tick = 200 clocks

    ----------------------------------------------------------------------
    -- Board-polarity helpers (model the REAL pin levels, stay correct no
    -- matter how the polarity constants are set):
    --   dip_phys  : logical switch word     -> physical DIP pin levels
    --   led_logic : physical LED pin levels -> logical data value
    ----------------------------------------------------------------------
    function dip_phys(v : std_logic_vector) return std_logic_vector is
    begin
        if DIP_ON = '1' then return v; else return not v; end if;
    end function;

    function led_logic(p : std_logic_vector) return std_logic_vector is
    begin
        if LED_ON = '1' then return p; else return not p; end if;
    end function;

    ----------------------------------------------------------------------
    -- press the start/stop button once (held long enough to debounce)
    ----------------------------------------------------------------------
    procedure press_button(signal btn : out std_logic) is
    begin
        btn <= BTN_PRESSED;
        wait for 300 ns;                 -- hold > debounce -> one PRESS pulse
        btn <= not BTN_PRESSED;
        wait for 500 ns;                 -- release + settle before next press
    end procedure;

    ----------------------------------------------------------------------
    -- full operate cycle for one command:
    --   load DATA -> load CMD+FREQ -> start -> run -> stop
    ----------------------------------------------------------------------
    procedure run_command(
        constant name     : in    string;
        constant data     : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        constant cmd      : in    std_logic_vector(CMD_WIDTH-1 downto 0);
        constant freq     : in    std_logic_vector(1 downto 0);
        constant run_time : in    time;
        signal   dip      : out   std_logic_vector(DATA_WIDTH-1 downto 0);
        signal   btn      : out   std_logic) is
    begin
        report "TEST: " & name severity note;
        -- 1) ENTER_DATA: dial the data value (drive PHYSICAL levels), save it
        dip <= dip_phys(data);          wait for 400 ns;
        press_button(btn);              -- -> ENTER_CMD
        -- 2) ENTER_CMD: dial command + speed, save it
        dip <= dip_phys(cmd & freq & "000");  wait for 400 ns;
        press_button(btn);              -- -> READY
        -- 3) READY -> start
        press_button(btn);              -- -> RUN
        -- 4) RUN: watch the LEDs (compare led_logic(led_tb) against your
        --    expected LOGICAL value if you want self-checking asserts)
        wait for run_time;
        press_button(btn);              -- stop -> ENTER_DATA
        wait for 2 us;
    end procedure;

begin

    -- Override CLK_HZ so 1 tick = only a few hundred clocks in sim.
    dut : command_interpreter_top
        generic map ( CLK_HZ => SIM_CLK_HZ )
        port map (
            clk_in          => clk_tb,
            btn_start_stop  => start_stop_tb,
            btn_display_sel => disp_sel_tb,
            btn_reset       => reset_tb,
            dip_switch      => dip_tb,
            led             => led_tb,
            seg_left        => seg_left_tb,
            seg_right       => seg_right_tb,
            pmod            => pmod_tb
        );

    -- clock (stops when sim_done -> run ends, no std.env needed)
    clockGen : process
    begin
        if sim_done then
            wait;
        end if;
        clk_tb <= '0'; wait for 5 ns;
        clk_tb <= '1'; wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- STIMULUS  (Person C: extend to all eight commands)
    --------------------------------------------------------------------
    stim : process
    begin
        -- reset (press S4) -> FSM in ENTER_DATA
        reset_tb <= BTN_PRESSED;     wait for 200 ns;
        reset_tb <= not BTN_PRESSED; wait for 500 ns;

        -- Example: rotate a single LED at 4 Hz.
        run_command("ROTATE_LEFT", x"01", CMD_ROTATE_LEFT, "10", 6 us,
                    dip_tb, start_stop_tb);

        -- TODO: add the other commands, e.g.
        --   run_command("CLEAR",      x"FF", CMD_CLEAR,      "10", 6 us, dip_tb, start_stop_tb);
        --   run_command("COUNT_DOWN", x"0A", CMD_COUNT_DOWN, "01", 6 us, dip_tb, start_stop_tb);
        --   run_command("INVERT",     x"A5", CMD_INVERT,     "01", 6 us, dip_tb, start_stop_tb);
        --   run_command("HOLD",       x"3C", CMD_HOLD,       "00", 6 us, dip_tb, start_stop_tb);
        --   ... (LOAD, COUNT_UP, SHIFT_LEFT)

        report "command_interpreter_top_tb finished" severity note;
        sim_done <= true;
        wait;
    end process;

end Simulation;
