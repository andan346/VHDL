library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity kassaskap is
  port (clk          : in  std_logic;                    -- "high" frequency
        reset        : in  std_logic;                    -- active high
        oppna_stang  : in  std_logic;                    -- 1=open, 0=close
        spara        : in  std_logic;                    -- active high
        oppen_stangd : out std_logic;                    -- 1=open, 0=closed
        ny_kod_ok    : out std_logic;
        rota, rotb   : in  std_logic;
        seg          : out std_logic_vector(6 downto 0); -- Segments
        dp           : out std_logic;                    -- Decimal point
        an           : out std_logic_vector(3 downto 0)  -- Digit to display
       );
end entity;

architecture rtl of kassaskap is

  -- OBS. För att testbänken ska fungera, så måste koden sättas till 00 vid reset.

begin

end architecture;
