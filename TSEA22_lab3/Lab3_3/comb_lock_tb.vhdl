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
      print("|     # NOK: " & msg & "                        :-(", unit => unit);
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

entity comb_lock_tb is
end entity;

architecture sim of comb_lock_tb is
  -- DUT
  component comb_lock is
    port (clk   : in  std_logic; -- "fast enough"
          reset : in  std_logic; -- active high
          x1    : in  std_logic; -- x1 is left
          x0    : in  std_logic; -- x0 is right
          u     : out std_logic
         );
  end component;

  -- DUT I/O:
  signal clk, reset : std_logic := '1';
  signal x1, x0     : std_logic;
  signal u          : std_logic;

  -- test bench signals:
  signal x    : std_logic_vector(1 downto 0);
  signal done : boolean := false;
begin
  clk <= not clk after 100 ms when not done; -- 5 Hz

  x1 <= x(1);
  x0 <= x(0);

  process
  begin
    print("/--------------------- 3.3: Comb lock --------------------------");
    print("| If you get an error, you have to look in your FSM diagram, and follow the jumps/states.");
    print("| Performing a number of actions/tests...");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 500 ms;
    x <= "00";
    wait for 1 sec;
    wait_after_edge(clk);

    -------------------------- 1: Test to unlock normally:
    print("| 1: Test to unlock normally. 5 clock cycles between each action.");
    x <= "00";
    wait for 1 sec;
    verify(u = '0', "1a: u should be 0 after reset + x:00.", "", done);
    x <= "01";
    wait for 1 sec;
    verify(u = '0', "1b: u should be 0 after reset + x:00->01.", "", done);
    x <= "11";
    wait for 1 sec;
    verify(u = '1', "1c: u should be 1 after reset + x:00->01->11.", "Did you swap x0 and x1?", done);
    wait_after_edge(clk); -- stop here if there was an error.

    -------------------------- 2: test that it stays unlocked:
    print("| 2: Test that it stays unlocked.");
    x <= "10";
    wait for 1 sec;
    verify(u = '1', "2a: u should stay at on after x:11->10.", "", done);
    x <= "11";
    wait for 1 sec;
    verify(u = '1', "2b: u should stay at on after x:11->10->11.", "", done);
    x <= "01";
    wait for 1 sec;
    verify(u = '1', "2c: u should stay at on after x:11->10->11->01.", "", done);
    wait_after_edge(clk); -- stop here if there was an error.

    -------------------------- 3: test to lock
    print("| 3: Test to lock.");
    x <= "00";
    wait for 1 sec;
    verify(u = '0', "3a: u should go back to off after x:->00.", "", done);
    wait_after_edge(clk); -- stop here if there was an error.

    -------------------------- 4: test the error state:
    print("| 4: Test to enter invalid code.");
    x <= "10";
    wait for 1 sec;
    verify(u = '0', "4a: u should be 0 after x:00->10.", "", done);
    x <= "11";
    wait for 1 sec;
    verify(u = '0', "4b: u should be 0 after x:00->10->11.", "", done);
    x <= "01";
    wait for 1 sec;
    verify(u = '0', "4c: u should be 0 after x:00->10->11->01.", "", done);
    x <= "11";
    wait for 1 sec;
    verify(u = '0', "4d: u should be 0 after x:00->10->11->01->11.", "", done);
    wait_after_edge(clk); -- stop here if there was an error.

    -------------------------- 5: test that x=00 is really tested after reset:
    print("| 5: Test that x=00 is tested after reset.");
    print("|   ({reset, x=01} -> x=01 -> x=11 -> should stay locked)");
    reset <= '1', '0' after 250 ms;
    x <= "01";
    wait for 1 sec;
    x <= "11";
    wait for 1 sec;
    verify(u = '0', "5a: u should be off after reset + x:01->11.", "", done);
    wait_after_edge(clk); -- stop here if there was an error.

    -------------------------- 6: test sequence 00->01->11->10->10 with one clock cycle per step:
    print("| 6: Test with one clock cycle per input.");
    reset <= '1', '0' after 500 ms;
    x <= "00";
    wait until reset = '0';
    wait_after_edge(clk);
    x <= "01";
    wait_after_edge(clk);
    x <= "11";
    wait_after_edge(clk);
    x <= "10";
    wait_after_edge(clk);
    x <= "10";
    wait_after_edge(clk);
    x <= "10";
    wait_after_edge(clk);
    verify(u = '1', "6a: u should be '1' after reset + x:00->01->11->10->10->10", "Have you moved too much things into processes?", done);

    -- Done
    wait_after_edge(clk); -- If last test failes, then the process will freeze in this wait, instead of printing DONE.
    print("\---- TEST BENCH DONE. Did you get any error message? -----------");
    done <= true;
    wait;
  end process;

  -- This process checks that the output is synchronized to the clock:
  process (u)
  begin
    assert (clk = '1' and clk'last_event = 0 ms) or reset = '1' or now = 0 ms
      report "FAIL. An output changed without a rising_edge(clk).                      :-("
      severity failure;
  end process;

  -- Design under test:
  DUT: comb_lock
    port map (
      clk   => clk,
      reset => reset,
      x1    => x1,
      x0    => x0,
      u     => u);

end architecture;
