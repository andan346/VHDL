-- counter_top.vhdl
-- Tryckknapp (T0) "upp" räknar upp
-- upp=0 : inget
-- upp=1 : räkna upp
-- Tryckknapp (T1) "ner" räknar ner
-- ner=0 : inget
-- ner=1 : räkna ner
-- Typically connect the following at the connector area of DigiMod
-- sclk <-- 32kHz

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity counter is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    upp   : in  std_logic;
    ner   : in  std_logic;
    seg   : out std_logic_vector(6 downto 0);
    dp    : out std_logic;
    an    : out std_logic_vector(3 downto 0));
end entity;

architecture arch of counter is
  -- Synkroniserade insignaler
  signal upp_sync     : std_logic;

  signal count : unsigned(3 downto 0) := (others => '0'); -- R�knarens v�rde

  -- 7-segments avkodning, segments t�nds med 0
  type rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant mem : rom := (
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

  -- Synkronisera insignal
  process (clk)
  begin
    if rising_edge(clk) then
      upp_sync <= upp;
    end if;
  end process;

  -- R�knaren
  process (clk)
  begin
    if rising_edge(clk) then
      if upp_sync = '1' then
        count <= count + to_unsigned(1, 4);
      end if;
    end if;
  end process;

  -- Utsignaler
  seg <= mem(to_integer(count));
  dp  <= '1';  -- Ingen punkt
  an  <= "1110";  -- V�lj sista siffran

end architecture;
