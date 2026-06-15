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
