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

entity minicalc_tb is
end entity;

architecture sim of minicalc_tb is
  component minicalc is
    port (
      clk    : in  std_logic;                    -- clock input
      reset  : in  std_logic;                    -- reset input
      data   : in  std_logic_vector(3 downto 0); -- hex kbd data
      strobe : in  std_logic;                    -- hex kbd strobe
      seg    : out std_logic_vector(6 downto 0); -- Segments
      dp     : out std_logic;                    -- Decimal point
      an     : out std_logic_vector(3 downto 0)  -- Digit to display
      );
  end component;


  -- DUT I/O:
  signal clk            : std_logic := '1';
  signal reset          : std_logic;
  signal data           : std_logic_vector(3 downto 0);
  signal strobe         : std_logic;
  
  signal seg            : std_logic_vector(6 downto 0); -- Segments
  signal dp             : std_logic;                    -- Decimal point
  signal an             : std_logic_vector(3 downto 0); -- Digit to display

--  signal display        : unsigned(1 downto 0);
--  signal digit          : std_logic_vector(0 to 7);

  signal done           : boolean   := false;

  signal siffra            : unsigned(3 downto 0);         -- digit converted to unsigned.


begin

  clk <= not clk after 100 us when not done;             -- 10kHz

  process
  begin
    print("/--------------------- 4.2: Mini calclulator --------------------------");

    -------------------------- 0: Reset the circuit
    print("| 0: Reset the circuit.");
    reset <= '1', '0' after 2 ms;
    data <= "0000";
    strobe <= '0';
    wait for 10 ms;

    verify(siffra = 0, "0a: siffra not 0 after reset.", "");
    
    -------------------------- 1: Apply hex keyboard input
    print("| 1: Pressing key 6.");
    data <= "0110";      -- 6
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 1: Released key 6.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 6, "1a: Expected siffra=6", "");    

    -------------------------- 2: Apply hex keyboard input
    print("| 2: Pressing key F (+).");
    data <= "1111";      -- F
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 2: Released key F.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 6, "2a: Expected siffra=6", "");    

    -------------------------- 3: Apply hex keyboard input
    print("| 3: Pressing key 2.");
    data <= "0010";      -- 2
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 3: Released key 2.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 2, "3a: Expected siffra=2", "");    

    -------------------------- 4: Apply hex keyboard input
    print("| 4: Pressing key D (=).");
    data <= "1101";      -- D
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 4: Released key D.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 8, "4a: Expected siffra=8", "");    

    -------------------------- 5: Apply hex keyboard input
    print("| 5: Pressing key E (-).");
    data <= "1110";      -- E
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 5: Released key E.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 8, "4a: Expected siffra=8", "");    

    -------------------------- 6: Apply hex keyboard input
    print("| 6: Pressing key 3.");
    data <= "0011";      -- 3
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 6: Released key 3.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 3, "6a: Expected siffra=3", "");    

    -------------------------- 7: Apply hex keyboard input
    print("| 7: Pressing key D (=).");
    data <= "1101";      -- D
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 7: Released key D.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 5, "7a: Expected siffra=5", "");    

    -------------------------- 8: Apply hex keyboard input
    print("| 8: Pressing key C (CLR).");
    data <= "1100";      -- D
    wait for 1 ms;        
    strobe <= '1';
    wait for 10 ms;
    strobe <= '0';
    print("| 8: Released key C.");
    wait for 1 ms;
    wait_after_edge(clk, delay_after_edge => 50 us);
    verify(siffra = 0, "8a: Expected siffra=0", "");    


    -- Done
    print("\---- TEST BENCH DONE. Did you get any error message? -----------");
    done <= true;
    wait;

  end process;


  -- Device under test:
  DUT: minicalc
    port map (
      clk            => clk,
      reset          => reset,
      data           => data,
      strobe         => strobe,
      an             => an,
      seg            => seg,
      dp             => dp
      );

  -- Drivers (convert display+digit to an integer in range 0-9999):
  with seg select
    siffra <= "0000" when "1000000", -- 0
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
              "XXXX" when others;    -- Invalid

end architecture;
