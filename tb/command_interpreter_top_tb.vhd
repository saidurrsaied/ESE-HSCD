-- Module Name: command_interpreter_top_tb.vhd
-- ##########################################################################
--  Board-mimicking testbench for the whole design (top level).
--
--  This is the testbench the homework calls "a VHDL testbench mimicking the
--  FPGA board to a certain extent". It plays the role of the hardware:
--    * generates the clock (like the 24 MHz oscillator)
--    * presses the buttons (like a human)
--    * sets the DIP switches
--    * and lets us watch the LEDs, 7-seg and PMOD outputs in the waveform.
--
--  TRICK: we override the CLK_HZ generic with a SMALL number so the tick
--  generator divides down in a few cycles instead of millions. That keeps
--  the simulation fast. (Functional behaviour is identical, only the time
--  scale changes.)
--
--  OWNER: Person C (Output & Integration)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.stop;
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

    -- board-side signals
    signal clk_tb        : std_logic := '0';
    signal start_stop_tb : std_logic := '0';
    signal disp_sel_tb   : std_logic := '0';
    signal reset_tb      : std_logic := '0';
    signal dip_tb        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal led_tb        : std_logic_vector(7 downto 0);
    signal seg_left_tb   : std_logic_vector(7 downto 0);
    signal seg_right_tb  : std_logic_vector(7 downto 0);
    signal pmod_tb       : std_logic_vector(7 downto 0);

begin

    -- Override CLK_HZ so 1 tick = only a few hundred clocks in sim.
    dut : command_interpreter_top
        generic map ( CLK_HZ => 1000 )
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

    -- 24 MHz-ish clock (period ~41.7 ns). 10 ns is fine for simulation.
    clockGen : process
    begin
        clk_tb <= '0'; wait for 5 ns;
        clk_tb <= '1'; wait for 5 ns;
    end process;

    --------------------------------------------------------------------
    -- STIMULUS  (Person C to complete)
    -- A realistic sequence:
    --   1. assert reset for a few clocks, then release.
    --   2. set DIP switches to a COUNT_UP command at some repeat rate.
    --   3. press & release btn_start_stop (remember: real presses bounce,
    --      but after our debouncer a clean press is enough in simulation;
    --      hold it for at least a few clocks).
    --   4. wait and watch the LEDs count up in the waveform.
    --   5. press btn_start_stop again to stop.
    --   6. optionally toggle btn_display_sel and try other commands.
    --------------------------------------------------------------------
    stim : process
    begin
        -- 1) reset
        reset_tb <= '1'; wait for 50 ns;
        reset_tb <= '0'; wait for 50 ns;

        -- 2) TODO: dip_tb <= "..."; -- choose a command + freq + payload

        -- 3) TODO: press start: start_stop_tb <= '1'; wait ...; start_stop_tb <= '0';

        -- 4) TODO: wait and observe led_tb

        -- 5) TODO: press start again to stop

        wait for 2 us;
        report "command_interpreter_top_tb finished" severity note;
        stop;
    end process;

end Simulation;
