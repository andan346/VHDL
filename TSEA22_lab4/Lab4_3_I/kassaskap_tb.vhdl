-- Utility functions

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.textio.all;

package sim_tools is
  procedure print(arg : in string; unit : in time := ms);
  procedure printif(tst : in boolean; arg : in string; unit : in time := ms);
  procedure verify(tst : in boolean; msg : in string; err_msg : in string; unit : in time := ms);
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

  procedure verify(tst : in boolean; msg : in string; err_msg : in string; unit : in time := ms) is
  begin
    if tst then
      --print("|     # PASS: " & msg, unit=>unit);
    else
      print("|     # NOK: " & msg & "                   :-(", unit => unit);
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

-- Actual testbench.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.sim_tools.all;

entity kassaskap_tb is
end entity;

architecture sim of kassaskap_tb is
  component kassaskap is
    port (clk          : in  std_logic;                    -- hög frekvens
          reset        : in  std_logic;                    -- aktivt hög
          oppna_stang  : in  std_logic;                    -- 1=öppna, 0=stäng
          spara        : in  std_logic;                    -- aktivt hög
          oppen_stangd : out std_logic;                    -- 1=olåst, 0=låst
          ny_kod_ok    : out std_logic;
          rota, rotb   : in  std_logic;
          seg          : out std_logic_vector(6 downto 0); -- Segments
          dp           : out std_logic;                    -- Decimal point
          an           : out std_logic_vector(3 downto 0)  -- Digit to display
         );
  end component;

  signal clk, reset   : std_logic                := '1';
  signal oppna_stang  : std_logic                := '0'; -- 1=öppna, 0=stäng
  signal spara        : std_logic                := '0'; -- aktivt hög
  signal oppen_stangd : std_logic;                       -- 1=olåst, 0=låst
  signal ny_kod_ok    : std_logic;
  signal ratt_ab      : std_logic_vector(0 to 1) := "00";
  signal siffra       : unsigned(3 downto 0);
  signal seg          : std_logic_vector(6 downto 0);    -- Segments
  signal dp           : std_logic;                       -- Decimal point
  signal an           : std_logic_vector(3 downto 0);    -- Digit to display

  signal done : boolean := false;
begin

  clk <= not clk after 10 ms when not done; -- 50 Hz

  process
    -- Here comes two functionalities to rotate the encoder right and left respectively
    procedure rot_r is
    begin
      wait_after_edge(clk, delay_after_edge => 5 ms); -- probably 20 ms
      ratt_ab <= "10", "11" after 100 ms, "01" after 200 ms, "00" after 300 ms; -- normal right
      wait for 380 ms;
    end procedure;
    procedure rot_l is
    begin
      wait_after_edge(clk, delay_after_edge => 5 ms);
      ratt_ab <= "01", "11" after 100 ms, "10" after 200 ms, "00" after 300 ms; -- normal left
      wait for 380 ms;
    end procedure;
  begin
    print("/--------------------- 4.3 I: Safe --------------------------");
    print("| Performing a number of actions/tests...");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 103 ms;
    wait until reset = '0';
    wait_after_edge(clk, delay_after_edge => 5 ms);
    verify(siffra = 0, "0a: siffra not 0 after reset.", "");

    -------------------------- 1: Close + open the lock
    print("| 1: Close + open the lock.");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 4, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "1a: oppen_stangd should be '0' after oppna_stang=0.", "");
    print("|   (enter code '00' by pressing 'spara' twice)");
    spara <= '1', '0' after 50 ms, '1' after 100 ms, '0' after 150 ms; -- 2.5 cc per level
    wait for 200 ms;
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 4, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "1b: oppen_stangd should be '1' after oppna_stang=1.", "");

    -------------------------- 2: Rotate the knob and check the result.
    print("| 2: Rotate the knob r->l->l->r and check siffra: 0 -> 1 -> 0 -> 9 -> 0.");
    verify(siffra = 0, "2a: Want siffra = 0 before rotation starts.", "");
    -- "rot_r" and "rot_l" are procedures above. They take 200 ms each.
    rot_r;
    verify(siffra = 1, "2b: Want siffra = 1 after right turn.", "");
    rot_l;
    verify(siffra = 0, "2c: Want siffra = 0 after right,left turn.", "");
    rot_l;
    verify(siffra = 9, "2d: Want siffra = 9 after right,left,left turn.", "");
    rot_r;
    verify(siffra = 0, "2e: Want siffra = 0 after right,left,left,right turn.", "");

    -------------------------- 3: Rotate with +- one clock cycle between A and B
    print("| 3: [this test is discarded]"); -- TODO: What to do here? Remove or modify to fit Digimod?
    --print("| 3: One clock cycle between A and B");
    --wait_after_edge(clk, delay_after_edge => 5 ms); -- remember: A clock cycle is 20 ms.
    --ratt_ab <= "10", "00" after 50 ms, "10" after 100 ms, "11" after 120 ms; -- rot right, 00->10->11
    --wait for 180 ms;
    --verify(siffra = 1, "3a: Want siffra = 1 after rot right, with 00->10->11 transision.", "");
    --
    --wait_after_edge(clk, delay_after_edge => 5 ms);
    --ratt_ab <= "01", "00" after 50 ms, "01" after 100 ms, "11" after 120 ms; -- rot right, 00->01->11
    --wait for 180 ms;
    --verify(siffra = 2, "3b: Want siffra = 2 after rot right,right, with 00->01->11 transision.", "");
    --
    --wait_after_edge(clk, delay_after_edge => 5 ms);
    --ratt_ab <= "01", "00" after 20 ms, "01" after 70 ms, "11" after 120 ms; -- rot left, 11->01->00
    --wait for 180 ms;
    --verify(siffra = 1, "3c: Want siffra = 1 after rot right,right,left, with 11->01->00 transision.", "");
    --
    --wait_after_edge(clk, delay_after_edge => 5 ms);
    --ratt_ab <= "10", "00" after 20 ms, "01" after 70 ms, "11" after 120 ms; -- rot left, 11->10->00
    --wait for 180 ms;
    --verify(siffra = 0, "3d: Want siffra = 0 after rot right,right,left,left, with 11->10->00 transision.", "");

    -------------------------- 4: Change code to 42. Lock.
    print("| 4: Change the code to 42. Lock");
    verify(oppen_stangd = '1', "4a: Unexpected: The lock should be open now.", "When did oppen_stangd turn 0? And why?");

    print("|   (rotate right 14 pulses, to go from siffra=0 to siffra=4. spara=1)");
    for i in 1 to 14 loop
      rot_r;
    end loop;
    verify(siffra = 4, "4b: Want Siffra = 4.", "");
    -- Spara:
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (rotate left 12 pulses, to go from siffra=4 to siffra=2. spara=1)");
    for i in 1 to 12 loop
      rot_l;
    end loop;
    verify(siffra = 2, "4c: Want Siffra = 2.", "");
    -- Spara:
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (lock. Please verify that the code changed to 42)");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(siffra = 0, "4d: Want Siffra = 0 after locking.", "");
    verify(oppen_stangd = '0', "4e: Want Oppen_stangd = 0 after locking", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 5: Rotate to 42. Unlock.
    print("| 5: Rotate to 42. Unlock");
    print("|   (four right to go from 0 to 4)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    verify(siffra = 4, "5a: Expected siffra=4", "");
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (two left to go from 4 to 2)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    verify(siffra = 2, "5b: Expected siffra=2", "");
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(siffra = 2, "5c: Want Siffra = still 2 after unlocking.", "");
    verify(oppen_stangd = '1', "5d: Want Oppen_stangd = 1 after unlocking", "Verify that the code changed to 42 in test 4.");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 6: Lock, rotate to 11. Fail to unlock.
    print("| 6: Lock, Rotate to 11. Fail to unlock.");
    print("|   (lock)");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(siffra = 0, "6a: Expected siffra=0", "");
    verify(oppen_stangd = '0', "6a: Expected oppen_stangd=0", "");

    print("|   (one right to go 0->1, spara, spara)");
    rot_r;
    verify(siffra = 1, "6b: Expected siffra=1", "");
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(siffra = 1, "6c: Expected siffra = still 1", "");

    print("|   (trying to unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "6d: Want oppen_stangd = 0, when tried with wrong code.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 7: Try change code to 23. Lock.
    print("| 7: Trying to change the code to 23 while oppna_stang=1 but oppen_stangd=0.");
    verify(siffra = 1, "7a: Expected siffra = still 1", "");

    print("|   (1 right: 1 -> 2. Spara)");
    rot_r;
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (1 right: 2 -> 3. Spara)");
    rot_r;
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (lock. Please verify that the code is still 42)");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(siffra = 0, "7b: Want Siffra = 0 after locking.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 8: Rotate to 42. Unlock.
    print("| 8: Rotate to 42. Unlock");
    print("|   (four right to go from 0 to 4. Spara)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (two left to go from 4 to 2. Spara)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    spara <= '1', '0' after 100 ms;
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);

    print("|   (unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 10, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "8a: Want Oppen_stangd = 1 after unlocking", "Verify that the code did not change in test 7.");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -- Done
    print("\---- TEST BENCH DONE. Did you get any error message? -----------");
    done <= true;
    wait;
  end process;

  -- Design under test:
  dut: kassaskap
    port map (
      clk          => clk,
      reset        => reset,
      oppna_stang  => oppna_stang,
      spara        => spara,
      oppen_stangd => oppen_stangd,
      ny_kod_ok    => ny_kod_ok,
      rota         => ratt_ab(0),
      rotb         => ratt_ab(1),
      seg          => seg,
      an           => an,
      dp           => dp);

  with seg select
    siffra <= "0000" when "1000000", -- 0
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
