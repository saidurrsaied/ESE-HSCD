-- Module Name: data_register.vhd
-- ##########################################################################
--  Data register / data path  (the 8-bit thing the commands act on).
--
--  This is the "at least one data register or counter" the homework asks
--  for. It performs ONE operation every time OP_EN = '1' (the FSM feeds it
--  the repeat tick). The operation is chosen by OP_CODE (a CMD_* code).
--
--  Operation set (see command_pkg):
--      CMD_LOAD       data <= PAYLOAD
--      CMD_CLEAR      data <= 0
--      CMD_COUNT_UP   data <= data + 1
--      CMD_COUNT_DOWN data <= data - 1
--      CMD_SHIFT      data <= data(6 downto 0) & '0'      (logic shift left)
--      CMD_ROTATE     data <= data(6 downto 0) & data(7)  (rotate left)
--      CMD_HOLD       data <= data                        (no change)
--      CMD_RESET      data <= 0    (or a defined default)
--
--  The current value is shown on the 8 LEDs and is also a candidate for the
--  PMOD "data register content" signal.
--
--  OWNER: Person B (Core Logic)
-- ##########################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.command_pkg.all;

entity data_register is
    Port (
        CLK       : in  std_logic;
        RST       : in  std_logic;
        OP_EN     : in  std_logic;                              -- do one operation when '1'
        OP_CODE   : in  std_logic_vector(CMD_WIDTH-1 downto 0); -- which operation
        PAYLOAD   : in  std_logic_vector(DATA_WIDTH-1 downto 0);-- data for LOAD
        DATA_OUT  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity data_register;

architecture rtl of data_register is

    signal data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person B):
    --   if RST='1' then data <= 0;
    --   elsif OP_EN='1' then
    --        case OP_CODE is
    --            when CMD_LOAD       => data <= PAYLOAD;
    --            when CMD_CLEAR      => data <= (others => '0');
    --            when CMD_COUNT_UP   => data <= std_logic_vector(unsigned(data) + 1);
    --            when CMD_COUNT_DOWN => data <= std_logic_vector(unsigned(data) - 1);
    --            when CMD_SHIFT      => data <= data(DATA_WIDTH-2 downto 0) & '0';
    --            when CMD_ROTATE     => data <= data(DATA_WIDTH-2 downto 0) & data(DATA_WIDTH-1);
    --            when CMD_HOLD       => data <= data;
    --            when CMD_RESET      => data <= (others => '0');
    --            when others         => data <= data;
    --        end case;
    --   end if;
    -------------------------------------------------------------------
    datapath_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                data <= (others => '0');
            elsif OP_EN = '1' then
                -- TODO: implement the operation case statement above
                null;
            end if;
        end if;
    end process datapath_proc;

    DATA_OUT <= data;

end architecture rtl;
