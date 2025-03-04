library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;

entity counter_tb is

end entity;

architecture bench of counter_tb is

  -- Klockperiod
  constant clk_period : time := 10 ns;
  signal done : boolean := false;

  -- Portar
  signal clk   : std_logic;
  signal reset : std_logic;
  signal upp   : std_logic;
  signal ner   : std_logic;
  signal seg   : std_logic_vector(6 downto 0);
  signal dp    : std_logic;
  signal an    : std_logic_vector(3 downto 0);

begin

  counter_inst: entity work.counter
    port map (
      clk   => clk,
      reset => reset,
      upp   => upp,
      ner   => ner,
      seg   => seg,
      dp    => dp,
      an    => an
    );

  main: process
  begin

    wait for 2 ns;

    -- Reset the circuit (just a short pulse):
    reset <= '1';
    upp <= '0';
    ner <= '0';
    wait for 2 ns;
    reset <= '0';
    
    wait for 14 ns;
    
    -- Provide "Upp" for some time (should count to 1):
    upp <= '1';
    wait for 50 ns;
    upp <= '0';
    
    wait for 50 ns;

    -- Provide "Upp" again for some time (should count to 2):
    upp <= '1';
    wait for 50 ns;
    upp <= '0';
    
    wait for 50 ns;

    -- Provide "Ner" for the rest of the simulation (should count to 1):
    ner <= '1';
    wait for 50 ns;
    
    -- Provide a short reset pulse (should immediately be set to 0):
    wait for 4 ns;
    reset <= '1';
    wait for 2 ns;
    reset <= '0';
    
    -- Wait for a few more clock cycles (should stay at 0)
    wait for 50 ns;

    done <= true;
    wait; -- stop here.

  end process;

  clk_process: process
  begin
    clk <= '1';
    wait for clk_period / 2;
    clk <= '0';
    wait for clk_period / 2;
    if done then
      wait; -- stop here.
    end if;
  end process;

end architecture;

