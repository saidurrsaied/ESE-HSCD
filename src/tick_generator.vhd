-- Module Name: tick_generator.vhd
-- ##########################################################################
--  Selectable repeat-rate generator (clock-enable / "tick" producer).
--
--  WHAT IT DOES:
--    The homework says the command "repeats with a selectable frequency".
--    Instead of making a second, slower CLOCK (bad practice on an FPGA) we
--    keep the single 24 MHz clock and generate a one-cycle ENABLE pulse
--    (TICK) at the wanted rate. The data path only acts when TICK = '1',
--    so it effectively runs at the slow rate while still being fully
--    synchronous to clk_in.
--
--    FREQ_SEL (2 bit) selects one of four repeat rates. The reference design
--    uses powers of two (all clearly visible on the LEDs):
--        "00" -> 1 Hz
--        "01" -> 2 Hz
--        "10" -> 4 Hz
--        "11" -> 8 Hz
--    (documented in doc/requirements.md - keep them in sync)
--
--  ALTERNATIVE: the board also has a hardware "jumper_clock" (1 Hz..1 MHz)
--  and the NE555 "slow_clock". Those could drive the repeat rate too, but
--  generating TICK internally keeps everything in one clock domain and is
--  easier to simulate. We go with the internal divider.
--
--  GENERIC CLK_HZ lets the testbench use a tiny clock so simulations are
--  fast (e.g. set CLK_HZ = 1000 in the TB instead of 24_000_000).
--
--  OWNER: Person A (Input & Timing)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity tick_generator is
    generic (
        CLK_HZ : natural := SYS_CLK_HZ   -- defaults to the board's 24 MHz
    );
    Port (
        CLK       : in  std_logic;
        RST       : in  std_logic;
        ENABLE    : in  std_logic;                       -- only count while running
        FREQ_SEL  : in  std_logic_vector(1 downto 0);    -- selects repeat rate
        TICK      : out std_logic                        -- 1 clock-wide enable pulse
    );
end entity tick_generator;

architecture rtl of tick_generator is

    -- The number of clk_in cycles between two ticks for the selected rate.
    -- Compute from CLK_HZ so it scales automatically in simulation.
    signal divisor : unsigned(31 downto 0) := (others => '0');
    signal counter : unsigned(31 downto 0) := (others => '0');

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person A):
    --
    -- 1) Map FREQ_SEL to a divisor (combinational), e.g.
    --        "00" -> divisor <= to_unsigned(CLK_HZ / 1 - 1, 32);  -- 1 Hz
    --        "01" -> divisor <= to_unsigned(CLK_HZ / 2 - 1, 32);  -- 2 Hz
    --        "10" -> divisor <= to_unsigned(CLK_HZ / 4 - 1, 32);  -- 4 Hz
    --        "11" -> divisor <= to_unsigned(CLK_HZ / 8 - 1, 32);  -- 8 Hz
    --
    -- 2) In a clocked process:
    --        if RST='1' or ENABLE='0' then counter <= 0; TICK <= '0';
    --        elsif counter >= divisor then counter <= 0;   TICK <= '1';
    --        else                          counter <= counter + 1; TICK <= '0';
    --        end if;
    --
    -- 3) TICK must be high for exactly ONE clock cycle each period.
    -------------------------------------------------------------------

    -- TODO: combinational divisor selection from FREQ_SEL
    divisor <= (others => '0');   -- placeholder

    tick_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                counter <= (others => '0');
            else
                -- TODO: implement the counter + TICK pulse described above
                null;
            end if;
        end if;
    end process tick_proc;

    TICK <= '0';   -- placeholder, drive from the process instead

end architecture rtl;
