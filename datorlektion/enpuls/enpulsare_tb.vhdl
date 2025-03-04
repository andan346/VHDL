library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

package sim_tools is
  procedure print(arg : in string);
  procedure verify(tst : in boolean; msg : in string; err_msg : in string);
  procedure wait_after_edge(signal clk : in std_logic; npulses : in integer := 1; delay_after_edge : in time := 50 ms);
end package;

package body sim_tools is
  procedure print(arg : in string) is
    variable l : line;
  begin
    write(l, value => now, justified => LEFT, field => 10, unit => 1 ms); -- add time to line
    write(l, value => arg); -- add string
    writeline(output, l); -- send string to "output" (=transcript window)
  end procedure;

  procedure verify(tst : in boolean; msg : in string; err_msg : in string) is
  begin
    if tst then
      --print("|    PASS: " & msg);
    else
      print("|    NOK: " & msg & "                                            :-(");
      if err_msg'length > 0 then
        print("|      msg: " & err_msg);
      end if;
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

library ieee;
  use ieee.std_logic_1164.all;
library work;
  use work.sim_tools.all;

entity enpulsare_tb is
end entity;

architecture sim of enpulsare_tb is
  component enpulsare is
    port (clk : in  std_logic;
          x   : in  std_logic;
          u   : out std_logic);
  end component;
  -- DUT I/O:
  signal clk : std_logic := '1';
  signal x   : std_logic;
  signal u   : std_logic;

  -- test bench signals:
  signal done : boolean := false;
begin
  clk <= not clk after 100 ms when not done; -- 5 Hz

  -- clk:    ___---___---___---___---___---___---___---__
  -- x:      _____--------------------------_____________
  -- x_sync: _________------------------------___________
  -- x_s_old:_______________------------------------_____
  -- u:      _________------_____________________________

  -- test nr:   1   2 3     4     5
  process
  begin
    print("/--------------------- D1: Enpulsare --------------------------");
    print("| I'm running the following tests:");

    --------------------------- 1: output = 0 after long 0-input
    print("| 1: Output = 0 after long x=0.");
    x <= '0';
    wait for 1 sec;
    wait_after_edge(clk); -- pos-edge + 50 ms. Hence, it is 50 ms left to negative edge.
    verify(u /= 'U', "1a. u has undefined value", "Do you simulate the correct file?");
    verify(u = '0', "1b. u should be 0 after several clock cycles of x=0", "");

    ---------------------------- 2: effect when setting x='1'
    print("| 2: Set x=1 and check the result.");
    x <= '1';
    wait for 10 ms; -- now the x pulse has started, but yet no flank. 40 ms left to negative edge.
    verify(u = '0', "2a. u should still be 0.", "Did you use 'x' directly?");
    wait for 100 ms; -- now after the negative clock edge
    verify(u = '0', "2b. u should still be 0.", "Did you forget 'rising_edge(clk)'?");
    -- Check each clock cycle:
    wait_after_edge(clk);
    verify(u = '1', "2c. u should now be '1'", "Check for logic error.");
    wait_after_edge(clk);
    verify(u = '0', "2d. u should now be '0'", "Check for logic error.");
    wait_after_edge(clk);
    verify(u = '0', "2e. u should now be '0'", "Check for logic error.");

    ---------------------------- 3: effect when setting x='0'
    print("| 3: Set x=0 and check the result.");
    x <= '0';
    -- Check each clock cycle:
    wait_after_edge(clk);
    verify(u = '0', "3a. u should remain '0'", "Check for logic error.");
    wait_after_edge(clk);
    verify(u = '0', "3b. u should remain '0'", "Check for logic error.");
    wait_after_edge(clk);
    verify(u = '0', "3c. u should remain '0'", "Check for logic error.");

    ---------------------------- Done
    wait_after_edge(clk);
    print("\---- TEST BENCH DONE. Did you get any NOK message? -----------");
    done <= true;
    wait;
  end process;

  -- This process checks that all outputs are synchronized to the clock:
  process (u)
  begin
    assert (clk = '1' and clk'last_event = 0 ms) or now = 0 ms
      report "FAIL. An output changed without a rising_edge(clk).                      :-("
      severity failure;
  end process;

  -- Design under test:
  DUT: enpulsare
    port map (
      clk => clk,
      x   => x,
      u   => u);

end architecture;

