-- Module Name: data_register.vhd
-- ##########################################################################
--  Data register / data path  (the 8-bit thing the commands act on).
--
--  This is the "at least one data register or counter" the homework asks
--  for. It changes in TWO ways:
--
--    LOAD_EN='1' : the user dialled a value on the DIP switches in the
--                  ENTER_DATA phase and pressed -> capture DATA_IN (the
--                  live, polarity-corrected DIP word) as the start value.
--    OP_EN='1'   : the FSM is running -> perform ONE operation, chosen by
--                  OP_CODE (a CMD_* code), driven by the repeat tick.
--
--  Operation set (see command_pkg):
--      CMD_LOAD        data <= PAYLOAD     (the stored command-phase word)
--      CMD_CLEAR       data <= 0
--      CMD_COUNT_UP    data <= data + 1
--      CMD_COUNT_DOWN  data <= data - 1
--      CMD_SHIFT_LEFT  data <= data(6 downto 0) & '0'      (logic shift left)
--      CMD_ROTATE_LEFT data <= data(6 downto 0) & data(7)  (rotate left)
--      CMD_INVERT      data <= not data                    (toggle/blink)
--      CMD_HOLD        data <= data                        (no change)
--
--  Reset value is 0x01 (one lit LED) so SHIFT/ROTATE still show a moving
--  LED even if the user never loads a value. The current value drives the
--  8 LEDs (and is a candidate for the PMOD "data content" signal).
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
        LOAD_EN   : in  std_logic;                              -- capture DATA_IN (ENTER_DATA phase)
        DATA_IN   : in  std_logic_vector(DATA_WIDTH-1 downto 0);-- live DIP word to load
        OP_EN     : in  std_logic;                              -- do one operation when '1'
        OP_CODE   : in  std_logic_vector(CMD_WIDTH-1 downto 0); -- which operation
        PAYLOAD   : in  std_logic_vector(DATA_WIDTH-1 downto 0);-- operand for CMD_LOAD
        DATA_OUT  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity data_register;

architecture rtl of data_register is

    constant SEED : std_logic_vector(DATA_WIDTH-1 downto 0) := (0 => '1', others => '0'); -- 0x01
    signal data : std_logic_vector(DATA_WIDTH-1 downto 0) := SEED;

begin

    -------------------------------------------------------------------
    -- IMPLEMENTATION GUIDE (Person B):
    --   if RST='1' then data <= SEED;
    --   elsif LOAD_EN='1' then data <= DATA_IN;        -- store the DIP value
    --   elsif OP_EN='1' then
    --        case OP_CODE is
    --            when CMD_LOAD        => data <= PAYLOAD;
    --            when CMD_CLEAR       => data <= (others => '0');
    --            when CMD_COUNT_UP    => data <= std_logic_vector(unsigned(data) + 1);
    --            when CMD_COUNT_DOWN  => data <= std_logic_vector(unsigned(data) - 1);
    --            when CMD_SHIFT_LEFT  => data <= data(DATA_WIDTH-2 downto 0) & '0';
    --            when CMD_ROTATE_LEFT => data <= data(DATA_WIDTH-2 downto 0) & data(DATA_WIDTH-1);
    --            when CMD_INVERT      => data <= not data;
    --            when CMD_HOLD        => data <= data;
    --            when others          => data <= data;
    --        end case;
    --   end if;
    --   (LOAD_EN has priority over OP_EN; they never assert in the same phase.)
    -------------------------------------------------------------------
    datapath_proc : process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                data <= SEED;
            elsif LOAD_EN = '1' then
                -- TODO: data <= DATA_IN;
                null;
            elsif OP_EN = '1' then
                -- TODO: implement the operation case statement above
                null;
            end if;
        end if;
    end process datapath_proc;

    DATA_OUT <= data;

end architecture rtl;
