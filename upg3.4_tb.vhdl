library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_tb is
end entity;

architecture tb of counter_tb is
  signal clk   : std_logic := '0';
  signal reset : std_logic := '0';
  signal start : std_logic := '0';
  signal seg   : std_logic_vector(6 downto 0);
  signal dp    : std_logic;
  signal an    : std_logic_vector(3 downto 0);
  signal lamp  : std_logic;

  -- Klocksignal (100 MHz exempel)
  constant clk_period : time := 10 ns;

begin
  -- Instansiera din räknare
  uut: entity work.counter
    port map (
      clk   => clk,
      reset => reset,
      start => start,
      seg   => seg,
      dp    => dp,
      an    => an,
      lamp  => lamp
    );

  -- Klockprocess
  process
  begin
    while true loop
      clk <= not clk;
      wait for clk_period / 2;
    end loop;
  end process;

  -- Testfall
  process
  begin
    -- Nollställ räknaren
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    -- Starta räknaren
    start <= '1';
    wait for 10 ns;
    start <= '0';

    -- Vänta medan räknaren räknar ned
    wait for 100 ns;

    -- Sätt på reset igen
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    -- Vänta och stoppa simuleringen
    wait for 50 ns;
    report "Simulation finished" severity note;
    wait;
  end process;
end architecture;
