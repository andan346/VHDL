-- Simple testbench for the dice that generates a clock and
-- some input signals.
-- No checking of results which makes it easy to just modify the
-- signal generation if wanted.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;

entity dice_tb is

end entity;

architecture bench of dice_tb is

  -- Clock period
  constant clk_period : time := 10 ns;

  -- Ports
  signal clk   : std_logic := '0';
  signal reset : std_logic;
  signal roll  : std_logic;
  signal fake  : std_logic;
  signal seg   : std_logic_vector(6 downto 0);
  signal dp    : std_logic;
  signal an    : std_logic_vector(3 downto 0);

  signal done : boolean := false;

begin
  -- Different type of instantiation compared to earlier testbenches
  -- No need for a component declaration
  dut: entity work.dice
    port map (
      clk   => clk,
      reset => reset,
      roll  => roll,
      fake  => fake,
      seg   => seg,
      dp    => dp,
      an    => an
    );

  main: process
  begin

    wait for 2 ns;

    reset <= '1';
    roll <= '0';
    fake <= '0';
    wait for 2 ns;

    reset <= '0';
    wait for 14 ns;

    -- Press roll for 200 ns in normal mode
    roll <= '1';
    wait for 200 ns;

    roll <= '0';
    wait for 20 ns;

    -- Press roll for 150 ns in fake mode
    fake <= '1';
    roll <= '1';
    wait for 150 ns;

    roll <= '0';
    wait for 20 ns;

    -- Press roll for 250 ns in normal mode
    fake <= '0';
    roll <= '1';
    wait for 250 ns;

    wait for 2 ns;
    done <= true;
  end process;

  clk <= not clk after clk_period / 2 when not done;

end architecture;
