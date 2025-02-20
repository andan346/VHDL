-- comb_lock.vhdl
-- x1 styrs av vänster skjutomkopplare S1
-- x0 styrs av höger skjutomkopplare S0
-- Typically connect the following at the connector area of DigiMod
-- sclk <-- 32kHz

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity comb_lock is
  port (clk   : in  std_logic; -- "fast enough"
        reset : in  std_logic; -- active high
        x1    : in  std_logic; -- x1 is left
        x0    : in  std_logic; -- x0 is right
        u     : out std_logic
       );
end entity;

architecture rtl of comb_lock is
  signal x1_sync, x0_sync : std_logic := '0';
  signal q1, q1_plus : std_logic := '0';
  signal q0, q0_plus : std_logic := '0';
  signal rom_out : std_logic_vector(2 downto 0);

  type rom is array (0 to 15) of std_logic_vector(2 downto 0);
  constant mem : rom := (
    "010", -- 0
    "000", -- 1
    "000", -- 2
    "000", -- 3
    "010", -- 4
    "100", -- 5
    "000", -- 6
    "000", -- 7
    "010", -- 8
    "100", -- 9
    "000", -- A
    "110", -- b
    "011", -- C
    "111", -- d
    "111", -- E
    "111"  -- F
  );
begin

  -- Synka input
  process(clk) begin
    if rising_edge(clk) then
      x1_sync <= x1;
      x0_sync <= x0;
    end if;
  end process;

  -- D-vippor för state med q0 och q1 samt reset
  process(clk, reset) begin
    if reset = '1' then
      q1 <= '0';
      q0 <= '0';
    elsif rising_edge(clk) then
      q1 <= q1_plus;
      q0 <= q0_plus;
    end if;
  end process;

  rom_out <= mem(to_integer(unsigned(std_logic_vector'(q1 & q0 & x1_sync & x0_sync))));

  u <= rom_out(0);
  q0_plus <= rom_out(1);
  q1_plus <= rom_out(2);

end architecture;
