-- Module Name: edge_detector.vhd
-- ##########################################################################
--  Rising / falling edge detector -> one-clock-wide pulse.
--
--  WHY:  The FSM needs a single "press event" pulse, not a level that
--        stays high for as long as the button is held. We compare the
--        current value with the value from the previous clock cycle.
--
--  Typical use in this project:
--        debounced button -> edge_detector -> RISING_PULSE
--        RISING_PULSE feeds the FSM "start/stop" toggle.
--
--  OWNER: Person A (Input & Timing)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity edge_detector is
    Port (
        CLK            : in  std_logic;
        RST            : in  std_logic;
        SIG_IN         : in  std_logic;   -- clean, debounced level
        RISING_PULSE   : out std_logic;   -- '1' for one clock on 0->1
        FALLING_PULSE  : out std_logic    -- '1' for one clock on 1->0
    );
end entity edge_detector;

architecture rtl of edge_detector is

    signal sig_d : std_logic := '0';   -- SIG_IN delayed by one clock

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person A):
    --   On each rising edge store: sig_d <= SIG_IN;
    --   Then (combinational or registered):
    --      RISING_PULSE  <= SIG_IN and (not sig_d);
    --      FALLING_PULSE <= (not SIG_IN) and sig_d;
    -------------------------------------------------------------------
    reg_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                sig_d <= '0';
            else
                -- TODO: sig_d <= SIG_IN;
                null;
            end if;
        end if;
    end process reg_proc;

    -- TODO: drive the two pulse outputs from SIG_IN and sig_d
    RISING_PULSE  <= '0';   -- placeholder
    FALLING_PULSE <= '0';   -- placeholder

end architecture rtl;
