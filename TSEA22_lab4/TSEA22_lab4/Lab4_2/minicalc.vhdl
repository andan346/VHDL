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
  -- signals etc.

begin

end architecture;
