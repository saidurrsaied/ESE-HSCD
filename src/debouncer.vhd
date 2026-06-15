-- Module Name: debouncer.vhd
-- ##########################################################################
--  Single-bit debouncer.
--
--  WHY:  A mechanical push button "bounces" for a few milliseconds when
--        pressed/released, producing many fast edges. We only want ONE
--        clean level change. This module waits until the (already
--        synchronized) input has been stable for STABLE_COUNT clock
--        cycles before it updates its output.
--
--  Put this AFTER the synchronizer:   button -> synchronizer -> debouncer
--
--  Sizing STABLE_COUNT:
--        time = STABLE_COUNT / CLK_HZ.  For ~10 ms at 24 MHz that is
--        about 240_000 counts. The default below is a placeholder.
--
--  OWNER: Person A (Input & Timing)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity debouncer is
    generic (
        STABLE_COUNT : natural := 240_000   -- ~10 ms @ 24 MHz, tune later
    );
    Port (
        CLK        : in  std_logic;
        RST        : in  std_logic;
        NOISY_IN   : in  std_logic;   -- synchronized but still bouncing
        CLEAN_OUT  : out std_logic    -- stable, debounced level
    );
end entity debouncer;

architecture rtl of debouncer is

    signal counter   : unsigned(31 downto 0) := (others => '0');
    signal sample    : std_logic := '0';   -- last seen input level
    signal stable    : std_logic := '0';   -- current debounced output

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person A):
    --   if NOISY_IN /= sample then
    --        sample  <= NOISY_IN;
    --        counter <= 0;                    -- input changed, restart timer
    --   elsif counter = STABLE_COUNT then
    --        stable  <= sample;               -- stable long enough -> accept
    --   else
    --        counter <= counter + 1;
    --   end if;
    --   (and reset everything when RST = '1')
    -------------------------------------------------------------------
    debounce_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                counter <= (others => '0');
                sample  <= '0';
                stable  <= '0';
            else
                -- TODO: implement the debounce timer described above
                null;
            end if;
        end if;
    end process debounce_proc;

    CLEAN_OUT <= stable;

end architecture rtl;
