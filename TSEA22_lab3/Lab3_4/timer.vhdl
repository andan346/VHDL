-- timer.vhdl
-- Tryckknapp (T0) "startknapp" startar nedräkningen av timern från 8.
-- Timern räknar sedan ned autonomt till 0 och stannar.
-- Utsignal "alarm" tänds när timern visar 0
-- Typically connect the following at the connector area of DigiMod
-- sclk <-- 1Hz

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity timer is
  port (clk        : in  std_logic; -- clk is 1 Hz
        reset      : in  std_logic; -- aktiv hög
        startknapp : in  std_logic; -- aktiv hög
        alarm      : out std_logic;
        seg        : out std_logic_vector(6 downto 0);
        dp         : out std_logic;
        an         : out std_logic_vector(3 downto 0)
       );
end entity;

architecture rtl of timer is
  signal start_sync0, start_sync : std_logic := '0';
  signal start_pulse : std_logic := '0';
  signal count : unsigned(3 downto 0) := (others => '0');
  signal should_count : std_logic := '0';

  type rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant mem : rom := (
    "1000000", -- 0
    "1111001", -- 1
    "0100100", -- 2
    "0110000", -- 3
    "0011001", -- 4
    "0010010", -- 5
    "0000010", -- 6
    "1111000", -- 7
    "0000000", -- 8
    "0010000", -- 9
    "0001000", -- A
    "0000011", -- b
    "1000110", -- C
    "0100001", -- d
    "0000110", -- E
    "0001110"  -- F
  );
begin
  -- Synkronisera och enpulsa startsignal
  process(clk, reset) begin
    if reset = '1' then
      start_sync0 <= '0';
      start_sync <= start_sync0;
    elsif rising_edge(clk) then
      start_sync0 <= startknapp;
      start_sync <= start_sync0;
    end if;
  end process;

  start_pulse <= start_sync0 and not start_sync;


  -- Börja från 8, räkna ner 1 per klockflank tills den nått 0
  process(clk, reset) begin
    if reset = '1' then
      count <= "0000";
      should_count <= '0';
    elsif rising_edge(clk) then
      if start_pulse = '1' and should_count = '0' then
        count <= "1000";
        should_count <= '1';
      elsif count = "0000" then
        should_count <= '0';
      else
        count <= count - 1;
      end if;
    end if;
  end process;

  -- Utsignaler
  seg <= mem(to_integer(count));
  dp  <= '1';  -- Ingen punkt
  an  <= "1110";  -- Välj sista siffran
  alarm <= '1' when count = "0000" else '0';
end architecture;
