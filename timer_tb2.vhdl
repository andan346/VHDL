library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_tb is
end entity;

architecture tb of timer_tb is
  -- Signaldeklaration
  signal clk        : std_logic := '0';
  signal reset      : std_logic := '0';
  signal startknapp : std_logic := '0';
  signal alarm      : std_logic;
  signal seg        : std_logic_vector(6 downto 0);
  signal dp         : std_logic;
  signal an         : std_logic_vector(3 downto 0);

  -- Klockfrekvens (1 Hz simulerad snabbare för test)
  constant clk_period : time := 100 ms; -- Snabbare än 1Hz för snabbare test

begin
  -- Instansiera "timer"-modulen
  uut: entity work.timer
    port map (
      clk        => clk,
      reset      => reset,
      startknapp => startknapp,
      alarm      => alarm,
      seg        => seg,
      dp         => dp,
      an         => an
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
    -- Steg 1: Reset timern
    reset <= '1';
    wait for 2 * clk_period;
    reset <= '0';

    -- Steg 2: Tryck på startknappen (startar nedräkningen)
    startknapp <= '1';
    wait for clk_period;
    startknapp <= '0';

    -- Vänta medan timern räknar ner till 0
    wait for 10 * clk_period;

    -- Stoppa simuleringen
    report "Simulation finished" severity note;
    wait;
  end process;
end architecture;
