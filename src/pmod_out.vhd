-- Module Name: pmod_out.vhd
-- ##########################################################################
--  PMOD / external-logic-connector output router.
--
--  RULES (board doc, sections 5 & 10):
--    * The PMOD connector is OUTPUT ONLY for this assignment.
--    * 8 logic signals, 3.3 V LVCMOS. Never drive it with external/5 V.
--
--  The homework suggests these oscilloscope signals for our topic:
--      - command valid
--      - execute active
--      - operation done
--      - selected internal status signal
--      - data register content (all 8 bits or a sub-vector)
--
--  We have exactly 8 PMOD pins. One sensible assignment (you can change
--  it - just keep doc/test_plan.md in sync because the report must state
--  signal directions and meaning):
--      PMOD(0) = command_valid
--      PMOD(1) = execute_active
--      PMOD(2) = operation_done
--      PMOD(3) = status_signal (e.g. tick, or one STATE_CODE bit)
--      PMOD(7 downto 4) = data_register(3 downto 0)   -- a 4-bit sub-vector
--
--  OWNER: Person C (Output & Integration)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.command_pkg.all;

entity pmod_out is
    Port (
        COMMAND_VALID  : in  std_logic;
        EXECUTE_ACTIVE : in  std_logic;
        OPERATION_DONE : in  std_logic;
        STATUS_SIGNAL  : in  std_logic;
        DATA_VALUE     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        PMOD           : out std_logic_vector(7 downto 0)
    );
end entity pmod_out;

architecture rtl of pmod_out is
begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person C):
    --   Pure wiring. Drive each PMOD bit from the inputs as documented
    --   above, e.g.:
    --        PMOD(0) <= COMMAND_VALID;
    --        PMOD(1) <= EXECUTE_ACTIVE;
    --        PMOD(2) <= OPERATION_DONE;
    --        PMOD(3) <= STATUS_SIGNAL;
    --        PMOD(7 downto 4) <= DATA_VALUE(3 downto 0);
    -------------------------------------------------------------------

    -- TODO: replace placeholder with the wiring above
    PMOD <= (others => '0');

end architecture rtl;
