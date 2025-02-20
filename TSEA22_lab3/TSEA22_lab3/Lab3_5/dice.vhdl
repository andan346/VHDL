-- dice.vhdl
-- Tryckknapp (T0) "roll" rullar tärningen
-- roll=0 : tärningen ligger stilla och visar ett värde
-- roll=1 : tärningen rullar
-- Strömbrytare (S0) "fake" väljer riktig eller falsk tärning
-- fake=0 : riktig tärning, dvs samma sannolikhet för 1,2,3,4,5 och 6
-- fake=1 : falsk tärning, dvs tre gånger högre sannolikhet för 6
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

begin
end architecture;
