-- Utility functions

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

package sim_tools is
  procedure print(arg : in string; unit : in time := ms);
  procedure printif(tst : in boolean; arg : in string; unit : in time := ms);
  procedure verify(tst : in boolean; msg : in string; err_msg : in string; signal done : out boolean; unit : in time := ms);
  procedure wait_after_edge(signal clk : in std_logic; npulses : in integer := 1; delay_after_edge : in time := 50 ms);
end package;

package body sim_tools is

  procedure print(arg : in string; unit : in time := ms) is
    variable l : line;
  begin
    write(l, value => now, justified => LEFT, field => 10, unit => unit); -- add time to line
    write(l, value => arg); -- add string
    writeline(output, l); -- send string to "output" (=transcript window)
  end procedure;

  procedure printif(tst : in boolean; arg : in string; unit : in time := ms) is
  begin
    if tst then
      print(arg, unit => unit);
    end if;
  end procedure;

  procedure verify(tst : in boolean; msg : in string; err_msg : in string; signal done : out boolean; unit : in time := ms) is
  begin
    if tst then
      --print("|     # PASS: " & msg, unit=>unit);
    else
      print("|     # NOK: " & msg & "                                            :-(", unit => unit);
      if err_msg'length > 0 then
        print("|     # msg: " & err_msg, unit => unit);
      end if;
      -- print("Signalling to stop the simulation.", unit => unit);
      -- done <= true;
    end if;
  end procedure;

  procedure wait_after_edge(signal clk : in std_logic; npulses : in integer := 1; delay_after_edge : in time := 50 ms) is
  begin
    for i in 1 to npulses loop
      wait until rising_edge(clk);
    end loop;
    wait for delay_after_edge;
  end procedure;

end package body;

-- Actual testbench

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.sim_tools.all;

entity timer_tb is
end entity;

architecture sim of timer_tb is
  component timer is
    port (clk, reset : in  std_logic; -- clk is 1 Hz. reset is active high.
          startknapp : in  std_logic; -- aktiv hög
          alarm      : out std_logic;
          seg        : out std_logic_vector(6 downto 0);
          dp         : out std_logic;
          an         : out std_logic_vector(3 downto 0));
  end component;
  -- DUT I/O:
  signal clk, reset : std_logic := '1';
  signal startknapp : std_logic;
  signal alarm      : std_logic;
  signal tidkvar    : unsigned(3 downto 0);
  signal seg        : std_logic_vector(6 downto 0);
  signal dp         : std_logic;
  signal an         : std_logic_vector(3 downto 0);

  -- test bench signals:
  signal done : boolean := false;
begin
  clk <= not clk after 500 ms when not done; -- 1 Hz.

  process
  begin
    print("/--------------------- 3.4: Timer --------------------------");
    print("| Performing a number of tests...");
    print("| Note: A separate process tests that LED <=> tidkvar = 0.");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 400 ms;
    startknapp <= '0';
    wait until reset = '0';
    verify(tidkvar = 0, "0a: tidkvar should be = 0 after reset.", "Did you forget to reset? Or did you not assign tidkvar at all?", done);
    wait_after_edge(clk, npulses => 2); -- wait a few clock pulses, plus 50 ms.
    verify(tidkvar = 0, "0b: tidkvar should be = 0 after reset + no input.", "Did you start to count despite startknapp=0?", done);

    -------------------------- 1: Run one loop:
    print("| 1: Test that is starts at all.");
    startknapp <= '1';
    wait_after_edge(clk, 1); -- one clock cycle. Expect the one-pulse to operate now, and output counter to start the next cycle.
    verify(tidkvar = 0, "1a: tidkvar should be = 0 one cc after startknapp.", "Did you forget to syncronize the input? Or did you forget a rising_edge(clk)?", done);
    wait_after_edge(clk, 2); -- give it two more clock cycles to start
    verify(tidkvar > 0, "1b: tidkvar should be > 0 after some clock cycles.", "", done);
    startknapp <= '0';
    wait_after_edge(clk, 2); -- another two clock cycles
    verify(tidkvar < 7, "1c: tidkvar should be < 7 after some clock cycles.", "Did you forget to 1-pulse startknapp?", done);
    verify(tidkvar >= 5, "1d: tidkvar should be >= 5 now.", "Did you forget rising_edge(clk) in counter?", done);
    -- now, tidkvar = 5 (or possibly 6).
    -------------------------- 2: Test to restart while counting
    print("| 2: Test to restart while counting.");
    startknapp <= '1';
    wait_after_edge(clk, 3); -- expect tidkvar = 2 (or possibly 3).
    verify(tidkvar < 4, "2a: tidkvar should be < 4 despite new startknapp.", "Did you restart while counting?", done);

    -------------------------- 3: Test that it stays at 0, despite startknapp = 1.
    print("| 3: Test that it stays at 0, despite startknapp = '1'.");
    wait_after_edge(clk, 5); -- now it should definitely have landed at zero.
    verify(tidkvar = 0, "3a: by now it should have timed out, and tidkvar = 0.", "Remember that startknapp must be one-pulsed.", done);

    -------------------------- 4: Reset while startknapp = 1, should not start.
    print("| 4: Test to reset while startknapp = 1. Should not start.");
    reset <= '1', '0' after 1 sec;
    wait_after_edge(clk, 5); -- enough time for a false one-puls signal to be visible on the counter
    verify(tidkvar = 0, "4a: It did restart. You must not use reset on the one-pulser.", "", done);

    -------------------------- 5: Start. Short reset pulse while counting.
    print("| 5: Test to restart while counting.");
    startknapp <= '0';
    wait_after_edge(clk);
    startknapp <= '1';
    wait_after_edge(clk, npulses => 3, delay_after_edge => 200 ms);
    reset <= '1', '0' after 200 ms; -- between clock flanks.
    wait_after_edge(clk);
    verify(tidkvar = 0, "5a: Expected tidkvar = 0 after anynchronous reset pulse.", "", done);

    -- Done
    wait_after_edge(clk); -- If last test failes, then the process will freeze in this wait, instead of printing DONE.
    print("\---- TEST BENCH DONE. Did you get any error message? -----------");
    done <= true;
    wait;
  end process;

  -- Denna process kollar att alarm = 1 <=> tidkvar = 0.
  process
  begin
    -- this process starts over and over again.
    wait until tidkvar'event or alarm'event;
    wait for 100 ms; -- this is to avoid problems with the so called delta cycles.
    if tidkvar = 0 and alarm /= '1' then
      report "FAIL: Alarm /= 1 and tidkvar = 0.                                       :-(" severity failure;
    elsif tidkvar > 0 and alarm /= '0' then
      report "FAIL: Alarm /= 0 and tidkvar > 0.                                       :-(" severity error;
    end if;
  end process;

  -- This process checks that all outputs are synchronized to the clock:
  process (tidkvar, alarm)
  begin
    assert (clk = '1' and clk'last_event = 0 ms) or reset = '1' or now = 0 ms
      report "FAIL. An output changed without a rising_edge(clk).                      :-("
      severity failure;
  end process;

  -- Design under test:
  DUT: timer
    port map (
      clk        => clk,
      reset      => reset,
      startknapp => startknapp,
      alarm      => alarm,
      seg        => seg,
      dp         => dp,
      an         => an);

  with seg select
    tidkvar <= "0000" when "1000000", -- 0
               "0001" when "1111001", -- 1
               "0010" when "0100100", -- 2
               "0011" when "0110000", -- 3
               "0100" when "0011001", -- 4
               "0101" when "0010010", -- 5
               "0110" when "0000010", -- 6
               "0111" when "1111000", -- 7
               "1000" when "0000000", -- 8
               "1001" when "0010000", -- 9
               "1010" when "0001000", -- A
               "1011" when "0000011", -- b
               "1100" when "1000110", -- C
               "1101" when "0100001", -- d
               "1110" when "0000110", -- E
               "1111" when others; -- F
end architecture;
