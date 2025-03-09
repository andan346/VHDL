library IEEE;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- entity

entity minicalc is
  port (
    clk    : in  std_logic;                    -- clock input
    reset  : in  std_logic;                    -- reset input
    data   : in  std_logic_vector(3 downto 0); -- hex kbd data
    strobe : in  std_logic;                    -- hex kbd strobe
    seg    : out std_logic_vector(6 downto 0); -- Segments
    dp     : out std_logic;                    -- Decimal point
    an     : out std_logic_vector(3 downto 0)  -- Digit to display
  );
end entity;

architecture func of minicalc is

  signal strobe_sync0, strobe_sync, strobe_ep : std_logic;
  signal operator : unsigned(3 downto 0) := (others => '0');
  signal number, result : unsigned(4 downto 0) := (others => '0');

  type digit_rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant to_display : digit_rom := (
  "1000000", -- 0
  "1111001", -- 1
  "0100100", -- 2
  "0110000", -- 3
  "0011001", -- 4
  "0010010", -- 5
  "0000010", -- 6
  "1111000", -- 7
  "0000000", -- 8
  "0010000", -- 9
  "0001000", -- A
  "0000011", -- b
  "1000110", -- C
  "0100001", -- d
  "0000110", -- E
  "0001110" -- F
);

begin

  -- Synka och enpulsa strobe
  process(clk) begin

    if rising_edge(clk) then
      strobe_sync0 <= strobe;
      strobe_sync <= strobe_sync0;
    end if;

  end process;
  strobe_ep <= strobe_sync0 and (not strobe_sync);

  -- Process för nummer- och operator-manipulation
  process(clk, reset)
  begin

    -- Reset
    if reset = '1' then
      -- Gör nåt här
      
    -- Vid strobe-puls
    elsif rising_edge(clk) then
      if strobe_ep = '1' then

        -- (0-9) Indata är en siffra
        if unsigned(data) <= 9 then

          -- Applicera operator
          if operator = 15 then
            result <= (number + unsigned(data));
          elsif operator = 14 then
            result <= (number - unsigned(data));
          end if;

          -- Sätt nummer till indata
          number <= resize(unsigned(data), 5);

        -- (F-C) Indata är en operator
        elsif unsigned(data) >= 12 then

          -- (=) Sätt resultatet till senaste nummer
          if unsigned(data) = 13 then
            number <= result;
          end if;

          -- (clr) Vid operator "clr"
          if unsigned(data) = 12 then
            number <= (others => '0');
            result <= (others => '0');
          end if;

          -- Sätt operator till indata
          operator <= unsigned(data);

        end if;
        
      end if;
    end if;
  end process;

  -- Display
  seg <= to_display(to_integer(number));
  dp <= '1';
  an <= "1110";

end architecture;
