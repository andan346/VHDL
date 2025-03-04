-- Utility functions.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

package sim_tools is
  function tostr(arg : integer) return string;
  procedure print(arg : in string; unit : in time := ms);
  procedure printif(tst : in boolean; arg : in string; unit : in time := ms);
  procedure verify(tst : in boolean; msg : in string; err_msg : in string; unit : in time := ms);
  procedure wait_after_edge(signal clk : in std_logic; npulses : in integer := 1; delay_after_edge : in time := 50 ms);
end package;

package body sim_tools is

  function tostr(arg : integer) return string is
  begin
    return integer'image(arg);
  end function;

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

  procedure verify(tst : in boolean; msg : in string; err_msg : in string; unit : in time := ms) is
  begin
    if tst then
      --print("|     # PASS: " & msg, unit=>unit);
    else
      print("|     # NOK: " & msg & "                     :-(", unit => unit);
      if err_msg'length > 0 then
        print("|     # msg: " & err_msg, unit => unit);
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

-- Actual testbench.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.sim_tools.all;

entity stopwatch_tb is
end entity;

architecture sim of stopwatch_tb is
  component stopwatch is
    port (clk            : in  std_logic;                    -- clk is "fast enough".
          reset          : in  std_logic;                    -- reset active high.
          hundradelspuls : in  std_logic;
          muxfrekvens    : in  std_logic;                    -- tic for multiplexing the display.
          start_stopp    : in  std_logic;
          nollstallning  : in  std_logic;                    -- clear counters. Active high
          visningslage   : in  std_logic;                    -- 1:show min/sec. 0: show sec/centisec
          seg            : out std_logic_vector(6 downto 0); -- Segments
          dp             : out std_logic;                    -- Decimal point
          an             : out std_logic_vector(3 downto 0); -- Digit to display
          raknar         : out std_logic);
  end component;
  -- DUT I/O:
  signal clk            : std_logic := '1';
  signal reset          : std_logic;
  signal hundradelspuls : std_logic := '1';
  signal muxfrekvens    : std_logic := '1';             -- tic for multiplexing the display.
  signal start_stopp    : std_logic;
  signal nollstallning  : std_logic;                    -- reset counters. Active high
  signal visningslage   : std_logic;                    -- 1:show min/sec. 0: show sec/centisec
  signal display        : unsigned(1 downto 0);
  signal digit          : std_logic_vector(0 to 7);     -- 0=top, 6=middle, 7=DP
  signal raknar         : std_logic;
  signal seg            : std_logic_vector(6 downto 0); -- Segments
  signal dp             : std_logic;                    -- Decimal point
  signal an             : std_logic_vector(3 downto 0); -- Digit to display
  signal done           : boolean   := false;
  signal bcd            : unsigned(3 downto 0);         -- digit converted to unsigned.
  signal BCD3           : integer;
  signal BCD2           : integer;
  signal BCD1           : integer;
  signal BCD0           : integer;
  signal BCD30          : integer;
begin
  -- scale up time a factor 1000. Except the clock.
  clk            <= not clk after 100 us when not done;          -- 5 kHz rather than 8 MHz
  hundradelspuls <= not hundradelspuls after 5 ms when not done; -- 100 Hz
  muxfrekvens    <= not muxfrekvens after 300 us when not done;  -- 1.67 kHz. All screen updated within 2.4 ms. <= IMPORTANT!

  process
  begin
    print("/--------------------- 4.1: Stop watch --------------------------");
    print("| Note: Signals BCD3, ..., BCD0 are the value on each of the HEX dispays.");
    print("| Note: Signal BCD30 is BCD3..BCD0 coded as an integer range 0 to 9999.");
    print("| Performing a number of actions/tests...");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 2 ms;
    visningslage <= '0'; -- show ss:cc (cc = centiseconds)
    nollstallning <= '1', '0' after 5 ms; -- clear
    start_stopp <= '0';
    wait for 10 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(BCD30 = 0000, "0a: BCD not 0 after reset + clear.", "");
    verify(raknar = '0', "0b: raknar should be '0' after reset + clear.", "");

    -------------------------- 1: Start the timer. Check the digits.
    print("| 1: Start the timer in ss:cc mode (cc=centiseconds), check digits.");
    wait until falling_edge(hundradelspuls);
    wait_after_edge(clk, delay_after_edge => 50 us);
    start_stopp <= '1', '0' after 50 ms;
    wait for 1 ms;
    verify(raknar = '1', "1a: Expected 'raknar' to have started", "");
    wait for 10 ms;
    verify(BCD0 = 1, "1b: Expect BCD0=1 after 0.01 s when running.", "");
    wait_after_edge(clk, delay_after_edge => 50 us);
    wait for 10 ms;
    verify(BCD0 = 2, "1c: Expect BCD0=2 after 0.02 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 3, "1d: Expect BCD0=3 after 0.03 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 4, "1e: Expect BCD0=4 after 0.04 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 5, "1f: Expect BCD0=5 after 0.05 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 6, "1g: Expect BCD0=6 after 0.06 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 7, "1h: Expect BCD0=7 after 0.07 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 8, "1i: Expect BCD0=8 after 0.08 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 9, "1j: Expect BCD0=9 after 0.09 s when running.", "");
    wait for 10 ms;
    verify(BCD0 = 0, "1k: Expect BCD0=0 after 0.10 s when running.", "");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -------------------------- 2: Run until 01:50.
    print("| 2: Run until 12:34 (it's now on 00:10).");
    wait for 12.24 sec; -- run for the remaining time.
    verify(BCD30 = 1234, "2a: Expected BCD30 = 1234 after 12.34 s of running.", "");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -------------------------- 3: Clear again
    print("| 3: Clear the counters while running. Run for 1 min, 13 sec.");
    nollstallning <= '1', '0' after 1000 ms;
    wait for 73 sec; -- 73 sec => should show 13:00 (01:13:00 if one more hex pair).
    verify(BCD30 = 1300, "3a. Expected BCD30 = 1300 after 73 sec after clear.", "");
    printif(BCD30 = 1200, "| ... hmmm. Didn't you one-pulse the clear input?.");
    printif(raknar /= '1', "| ... hmmm. 'raknar' is off.");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -------------------------- 4: Stop and start the watch.
    print("| 4: Stop and start the watch - pause it for 150 cs (centisecond).");
    start_stopp <= '1', '0' after 300 ms, '1' after 1500 ms, '0' after 2000 ms;
    wait for 10 sec; --73 s + 10 s - 1.5 s = 81.5 s
    verify(BCD30 = 2150, "4a. Expected BCD30 = 2150. You paused for " & tostr(2300 - BCD30) & " cs.", "");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -------------------------- 5: mm:ss mode
    print("| 5: Switching to mm:ss mode.");
    visningslage <= '1';
    wait for 5 ms; -- wait for screen to update. 81.51 s = 01:21.51
    verify(BCD30 = 0121, "5a. Expected BCD30 = 0121 (from 01:21:51)", "");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -------------------------- 6: One hour
    print("| 6: Now simulate one hour. That will take a while (it's 3600 million us, look in bottom left corner).");
    wait for 30 min;
    verify(BCD30 = 3121, "6a. BCD not 31:21 half an hour after 01:21", "");
    wait_after_edge(clk, delay_after_edge => 50 us);
    wait for 30 min;
    verify(BCD30 = 0121, "6b. BCD not 01:21 one hour after 01:21", "");
    wait_after_edge(clk, delay_after_edge => 50 us);

    -- Done
    print("\---- TEST BENCH DONE. Did you get any error message? -----------");
    done <= true;
    wait;
  end process;

  -- Break the simulation if there are invalid digits:
  -- FIXME: Does not work with Vivado
  -- process
  -- begin
  --   wait until bcd'event;
  --  wait for 100 us;
  --  assert bcd /= "XXXX"
  --    report "Oups, I cannot recognize the current digit.                           :-("
  --    severity failure;
  -- end process;

  -- Bake together the digits+display to a four-digit number:
  process (clk)
  begin
    -- To test that the multiplexing is running, use the following form:
    --   BCD0 <= to_integer(bcd), -1 after 5 ms;
    -- This means that BCD0 gets value -1 after 5 ms, unless updated again
    -- before that. It should be updated every 2.4 ms.
    if display = 0 then
      BCD0 <= to_integer(bcd), - 1 after 5 ms;
    elsif display = 1 then
      BCD1 <= to_integer(bcd), - 1 after 5 ms;
    elsif display = 2 then
      BCD2 <= to_integer(bcd), - 1 after 5 ms;
    elsif display = 3 then
      BCD3 <= to_integer(bcd), - 1 after 5 ms;
    end if;
  end process;
  BCD30 <= 1000 * BCD3 + 100 * BCD2 + 10 * BCD1 + 1 * BCD0;

  -- Verify the display rate (should be 600 us):
  process
    variable last_time : time;
  begin
    wait until reset = '0'; -- wait until reset releases.
    wait for 2 ms; -- wait a little longer to let things stabalize
    wait until display'event;
    last_time := now; -- current simulation time.
    while true loop
      wait until display'event;
      assert now - last_time = 600 us
        report "display rate = " & to_string(now - last_time, unit => us) & " /= 600 us.        :-("
        severity error;
      last_time := now;
      wait for 1 us; -- to avoid errors of type "display rate = 0 us".
    end loop;
  end process;

  -- This process checks that all outputs are synchronized to the clock:
  process (display, digit, raknar)
  begin
    assert (clk = '1' and clk'last_event = 0 ns) or reset = '1' or now = 0 ns
      report "FAIL. An output changed without a rising_edge(clk).                      :-("
      severity failure;
  end process;

  -- Design under test:
  DUT: stopwatch
    port map (
      clk            => clk,
      reset          => reset,
      hundradelspuls => hundradelspuls,
      muxfrekvens    => muxfrekvens,
      start_stopp    => start_stopp,
      nollstallning  => nollstallning,
      visningslage   => visningslage,
      an             => an,
      seg            => seg,
      dp             => dp,
      raknar         => raknar);

  -- Drivers (convert display+digit to an integer in range 0-9999):
  with seg select
    bcd <= "0000" when "1000000", -- 0
           "0000" when "1111111", -- blank
           "0001" when "1111001", -- 1
           "0010" when "0100100", -- 2
           "0011" when "0110000", -- 3
           "0100" when "0011001", -- 4
           "0101" when "0010010", -- 5
           "0110" when "0000010", -- 6
           "0110" when "0000011", -- 6 without top segment
           "0111" when "1111000", -- 7
           "0111" when "1011000", -- 7 with segment F
           "1000" when "0000000", -- 8
           "1001" when "0010000", -- 9
           "1001" when "0011000", -- 9 without bottom segment
           "XXXX" when others; -- Invalild

  with an select
    display <= "00" when "1110",
               "01" when "1101",
               "10" when "1011",
               "11" when "0111",
               "XX" when others;
end architecture;
