-- dice.vhdl
-- Tryckknapp (T0) "roll" rullar t�rningen
-- roll=0 : t�rningen ligger stilla och visar ett v�rde
-- roll=1 : t�rningen rullar
-- Str�mbrytare (S0) "fake" v�ljer riktig eller falsk t�rning
-- fake=0 : riktig t�rning, dvs samma sannolikhet f�r 1,2,3,4,5 och 6
-- fake=1 : falsk t�rning, dvs tre g�nger h�gre sannolikhet f�r 6
-- Typically connect the following at the connector area of DigiMod
-- sclk <-- 32kHz

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dice is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    roll  : in  std_logic;
    fake  : in  std_logic;
    seg   : out std_logic_vector(6 downto 0);
    dp    : out std_logic;
    an    : out std_logic_vector(3 downto 0));
end entity;

architecture arch of dice is
  -- signals etc
  signal roll_sync, fake_sync : std_logic := '0';
  signal count : unsigned(3 downto 0) := (others => '0');

  type rom is array (0 to 8) of std_logic_vector(6 downto 0);
  constant mem : rom := (
    "1000000", -- 0
    "1111001", -- 1
    "0100100", -- 2
    "0110000", -- 3
    "0011001", -- 4
    "0010010", -- 5
    "0000010", -- 6
    "0000010", -- 6
    "0000010"  -- 6
  );
begin

  -- Synka roll och fake
  process(clk, reset) begin
    if reset = '1' then
      roll_sync <= '0';
      fake_sync <= '0';
    elsif rising_edge(clk) then
      roll_sync <= roll;
      fake_sync <= fake;
    end if;
  end process;

  -- Välj från 8 om fake, annars från de normala 6
  process(clk, reset) begin
    if reset = '1' then
      count <= "0001";
    elsif rising_edge(clk) then
      if roll_sync = '1' then
        if fake_sync = '1' then
          -- Räkna från 1 till 8 om och om
          if count = "1000" then
            count <= "0001";
          else 
            count <= count + 1;
          end if;
        else
          -- Räkna från 1 till 6 om och om
          if count = "0110" then
            count <= "0001";
          else
            count <= count + "0001";
          end if;
        end if;
      end if;
    end if;
  end process;

  seg <= mem(to_integer(count));
  dp  <= '1';  -- Ingen punkt
  an  <= "1110";  -- Välj sista siffran

end architecture;
