library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity combination_lock is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    x1    : in  std_logic;
    x0    : in  std_logic;
    u     : out std_logic);
end entity;

architecture arch of combination_lock is

  signal x1_sync : std_logic;
  signal x0_sync : std_logic;
  signal q1 : std_logic;
  signal q0 : std_logic;
  signal q1_sync : std_logic;
  signal q0_sync : std_logic;
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

  process (clk)
  begin
    if rising_edge(clk) then
      x1_sync <= x1;
      x0_sync <= x0;
    end if;
  end process;

  process (clk, reset)
  begin
    if rising_edge(clk) then
      q1_sync <= q1;
      q0_sync <= q0;
    end if;
    if reset = '1' then
      q1_sync <= '0';
      q0_sync <= '0';
    end if;
  end process;

  rom_out <= rom(to_integer(unsigned(q1_sync & q0_sync & x1_sync & x0_sync)));

  q1 <= rom_out(2);
  q0 <= rom_out(1);
  u <= rom_out(0);

end architecture;