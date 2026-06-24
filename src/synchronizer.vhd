-- Module Name: synchronizer.vhd
-- ##########################################################################
--  Two-flip-flop synchronizer.
--
--  WHY WE NEED THIS (board doc, sections 4 & 5):
--    The push buttons and DIP switches are operated by hand, so they are
--    ASYNCHRONOUS to our 24 MHz clock. Feeding an async signal straight
--    into clocked logic can cause metastability. The classic fix is to
--    pass the signal through two flip-flops first.
--
--  This module is generic in width so it can synchronize a single button
--  (WIDTH = 1) or the whole DIP-switch word (WIDTH = 8) in one instance.
--
--  WHY TWO FLIP-FLOPS: ff1 may go metastable when ASYNC_IN changes near the
--  clock edge; the SECOND flip-flop gives ff1 a full clock period to resolve
--  before anything downstream sees it, so ff1's only load is ff2. The
--  `SYNC_OUT <= ff2` line is just a wire (ff2 is already registered), not a
--  third sampling stage. Caveat: a 2-FF sync is correct for single bits and
--  for SLOW/quasi-static buses like DIP switches; it does not guarantee all
--  bits of a fast-changing bus update on the same cycle. It also does NOT
--  fix polarity - the top level does that (DIP_ON) - or debounce.
--
--  OWNER: Person A (Input & Timing)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity synchronizer is
    generic (
        WIDTH : natural := 1
    );
    Port (
        CLK       : in  std_logic;
        ASYNC_IN  : in  std_logic_vector(WIDTH-1 downto 0);
        SYNC_OUT  : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity synchronizer;

architecture rtl of synchronizer is

    -- two register stages
    signal ff1 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal ff2 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person A):
    --   On every rising edge:  ff1 <= ASYNC_IN;  ff2 <= ff1;
    --   Drive SYNC_OUT from ff2.
    -------------------------------------------------------------------
    sync_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            -- TODO: ff1 <= ASYNC_IN;
            -- TODO: ff2 <= ff1;
            null;
        end if;
    end process sync_proc;

    SYNC_OUT <= ff2;

end architecture rtl;
