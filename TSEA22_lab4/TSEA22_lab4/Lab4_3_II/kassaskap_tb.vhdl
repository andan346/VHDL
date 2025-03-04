-- Utility functions.

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
    print("/--------------------- 4.3 II: Safe --------------------------");
    print("| Performing a number of actions/tests...");
    print("| (note: Look at ratt_a and ratt_b to find the rotation pulses)");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 103 ms;
    wait until reset = '0';
    wait_after_edge(clk, delay_after_edge => 5 ms);
    verify(siffra = 0, "0a: Want siffra = 0 after reset.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 1: Rotate the knob and check the result.
    print("| 1: Rotate the knob r->l->l->r and check siffra: 0 -> 1 -> 0 -> 9 -> 0.");
    verify(siffra = 0, "1a: Want siffra = 0 before rotation starts.", "");
    -- "rot_r" and "rot_l" are procedures above. They take 200 ms each.
    rot_r;
    verify(siffra = 1, "1b: Want siffra = 1 after right turn.", "");
    rot_l;
    verify(siffra = 0, "1c: Want siffra = 0 after right,left turn.", "");
    rot_l;
    verify(siffra = 9, "1d: Want siffra = 9 after right,left,left turn.", "");
    rot_r;
    verify(siffra = 0, "1e: Want siffra = 0 after right,left,left,right turn.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 2: Rotate with +- one clock cycle between A and B
    print("| 2: [this test is discarded]"); -- TODO: What to do here? Remove or modify to fit Digimod?
--    print("| 2: One clock cycle between A and B");
--    wait_after_edge(clk, delay_after_edge => 5 ms); -- remember: A clock cycle is 20 ms.
--    ratt_ab <= "01", "00" after 50 ms, "10" after 100 ms, "11" after 120 ms; -- rot right, 00->10->11
--    wait for 180 ms;
--    verify(siffra = 1, "2a: Want siffra = 1 after rot right, with 00->10->11 transision.", "");
--
--    wait_after_edge(clk, delay_after_edge => 5 ms);
--    ratt_ab <= "01", "00" after 50 ms, "01" after 100 ms, "11" after 120 ms; -- rot right, 00->01->11
--    wait for 180 ms;
--    verify(siffra = 2, "2b: Want siffra = 2 after rot right,right, with 00->01->11 transision.", "");
--
--    wait_after_edge(clk, delay_after_edge => 5 ms);
--    ratt_ab <= "01", "00" after 20 ms, "01" after 70 ms, "11" after 120 ms; -- rot left, 11->01->00
--    wait for 180 ms;
--    verify(siffra = 1, "2c: Want siffra = 1 after rot right,right,left, with 11->01->00 transision.", "");
--
--    wait_after_edge(clk, delay_after_edge => 5 ms);
--    ratt_ab <= "10", "00" after 20 ms, "01" after 70 ms, "11" after 120 ms; -- rot left, 11->10->00
--    wait for 180 ms;
--    verify(siffra = 0, "2d: Want siffra = 0 after rot right,right,left,left, with 11->10->00 transision.", "");
--    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 3: Fail open + close + working open.
    print("| 3: FailedUnlock, lock, then unlock the safe.");

    print("|   (clear input counter by a try of open+lock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "3a: oppen_stangd should be '0' after failed try to open.", "");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "3b: oppen_stangd should be '0' after locked.", "");
    verify(siffra = 0, "3c: Unexpected: 'siffra' should be 0 by now", "");

    print("|   (enter code '00' by rotating 10 rights, then 10 lefts, then 10 rights again)");
    for i in 1 to 10 loop
      rot_r;
    end loop;
    for i in 1 to 10 loop
      rot_l;
    end loop;
    for i in 1 to 10 loop
      rot_r;
    end loop;
    verify(siffra = 0, "3d: Unexpected: 'siffra' should be 0 by now", "");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "3e: oppen_stangd should be '1' after sucessfull open.", "Was code '00' registered? Is code '00' the correct code?");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 4: Change code to 42. Lock.
    print("| 4: Change the code to 42. Lock");
    verify(ny_kod_OK = '0', "4a: Expect ny_kod_OK = 0 before changing code.", "ny_kod_OK should have been off all simulation so far.");
    print("|   (rotate right 14 pulses, to go from siffra=0 to siffra=4)");
    for i in 1 to 14 loop
      rot_r;
    end loop;
    verify(siffra = 4, "4b: Expected siffra = 4.", "");

    print("|   (rotate left 12 pulses, to go from siffra=4 to siffra=2)");
    for i in 1 to 12 loop
      rot_l;
    end loop;
    verify(siffra = 2, "4c: Expected siffra = 2.", "");

    print("|   (rotate right 8 pulses, to go from siffra=2 to siffra=0)");
    for i in 1 to 8 loop
      rot_r;
    end loop;
    verify(siffra = 0, "4d: Expected siffra = 0.", "");

    print("|   ('spara' pulse, to change code to 42)");
    spara <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "4e: Expect open_stangd = still 1 after changing code.", "");
    verify(ny_kod_OK = '1', "4f: Expect ny_kod_OK = 1 after changing code.", "");

    print("|   (Lock the safe)");
    spara <= '0';
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "4g: Expect open_stangd = 0 after locking.", "");
    verify(siffra = 0, "4h: Expect siffra = 0 after locking.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 5: Rotate to 42+0. Unlock. Lock
    print("| 5: Rotate to 42+0, unlock, lock");
    print("|   (four right to go from 0 to 4)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    print("|   (two left to go from 4 to 2)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    print("|   (eight right to go from 2 to 0)");
    for i in 1 to 8 loop
      rot_r;
    end loop;
    verify(siffra = 0, "5a: Want Siffra = 0 after the rotations.", "");
    print("|   (unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "5b: Want Oppen_stangd = 1 after unlocking", "Verify that the code changed to 42 in test 4.");
    print("|   (lock)");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "5c: Want Oppen_stangd = 0 after locking", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 6.1: Rotate to 42+3. Failed unlock.
    print("| 6: Here comes a number of bad tries to unlock, which should all fail.");
    print("| 6.1: Rotate to 42+3 ('3' instead of tailing '0'), failed unlock");
    print("|   (four right to go from 0 to 4)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    print("|   (two left to go from 4 to 2)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    print("|   (one right to go from 2 to 3)");
    rot_r;
    print("|   (fail to unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "6.1a: Want Oppen_stangd = 0 after failed unlocking", "Remember requirement to rotate right to 0 before unlocking.");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);

    -------------------------- 6.2: Rotate to 21+0. Failed unlock.
    print("| 6.2: Rotate to 21+0, failed unlock");
    print("|   (two right to go from 0 to 2)");
    for i in 1 to 2 loop
      rot_r;
    end loop;
    print("|   (one left to go from 2 to 1)");
    rot_l;
    print("|   (nine right to go from 1 to 0)");
    for i in 1 to 9 loop
      rot_r;
    end loop;
    print("|   (fail to unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "6.2a: Want Oppen_stangd = 0 after failed unlocking", "Check the code matching requierment.");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);

    -------------------------- 6.3: Rotate to 42+0 in wrong direction. Failed unlock.
    print("| 6.3: Rotate to 42+0 in wrong direction, failed unlock.");
    print("|   (six left to go from 0 to 4)");
    for i in 1 to 6 loop
      rot_l;
    end loop;
    print("|   (eight right to go from 4 to 2)");
    for i in 1 to 8 loop
      rot_r;
    end loop;
    print("|   (two left to go from 2 to 0)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    print("|   (fail to unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "6.3a: Want Oppen_stangd = 0 after failed unlocking", "Remember requirement to rotate RIGHT to 0 before unlocking.");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);

    -------------------------- 6.4: Rotate to 4242+0. Failed unlock.
    print("| 6.4: Rotate to 4242+0, failed unlock");
    print("|   (four right to go from 0 to 4)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    print("|   (two left to go from 4 to 2)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    print("|   (two right to go from 2 to 4)");
    for i in 1 to 2 loop
      rot_r;
    end loop;
    print("|   (two left to go from 4 to 2)");
    for i in 1 to 2 loop
      rot_l;
    end loop;
    print("|   (eight right to go from 2 to 0)");
    for i in 1 to 8 loop
      rot_r;
    end loop;
    print("|   (fail to unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "6.4a: Want Oppen_stangd = 0 after failed unlocking", "Remember requirement with too long sequence.");

    -------------------------- 7: Try to change code to 21. Lock.
    print("| 7: Try to change the code to 21 while safe is locked. Lock");
    print("|   (rotate right 2 to '2', left 1 to '1', right 9 to '0', then save)");
    rot_r;
    rot_r;
    rot_l;
    for i in 1 to 9 loop
      rot_r;
    end loop;
    verify(siffra = 0, "7a: Expected siffra = 0 after rotations.", "");
    spara <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(ny_kod_OK = '0', "7b: Expect ny_kod_OK = 0 after trying to change code while locked.", "");

    print("|   (Lock the safe)");
    spara <= '0';
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "7c: Expect open_stangd = 0 after locking.", "");
    verify(siffra = 0, "7d: Expect siffra = 0 after locking.", "");
    wait_after_edge(clk, delay_after_edge => 5 ms);

    -------------------------- 8: Rotate to 42+0. Unlock. Lock
    print("| 8: Rotate to 42+0, unlock, lock");
    print("|   (4 right, 2 left, wight right, unlock)");
    for i in 1 to 4 loop
      rot_r;
    end loop;
    for i in 1 to 2 loop
      rot_l;
    end loop;
    for i in 1 to 8 loop
      rot_r;
    end loop;
    verify(siffra = 0, "8a: Want Siffra = 0 after the rotations.", "");

    print("|   (unlock)");
    oppna_stang <= '1';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '1', "8b: Want Oppen_stangd = 1 after unlocking", "Verify that the code did not change to 21 in test 7.");

    print("|   (lock)");
    oppna_stang <= '0';
    wait_after_edge(clk, npulses => 5, delay_after_edge => 5 ms);
    verify(oppen_stangd = '0', "8c: Want Oppen_stangd = 0 after locking", "");
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
      rota       => ratt_ab(0),
      rotb       => ratt_ab(1),
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
