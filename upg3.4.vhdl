library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    start : in  std_logic;
    seg   : out std_logic_vector(6 downto 0);
    dp    : out std_logic;
    an    : out std_logic_vector(3 downto 0);
    lamp  : out std_logic
  );
end entity;

architecture arch of counter is
  -- Synkroniserade insignaler
  signal start_sync, start_sync2 : std_logic := '0';
  signal start_pulse : std_logic := '0';
  signal count : unsigned(3 downto 0) := (others => '0'); -- Räknarens värde
  signal lamp_int : std_logic := '0';

  -- 7-segments avkodning, segment tänds med 0
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
  -- Synkronisera insignal
  process(clk)
  begin
    if rising_edge(clk) then
      start_sync  <= start;
      start_sync2 <= start_sync;
    end if;
  end process;

  start_pulse <= start_sync and not start_sync2 and lamp_int;

  -- Räkneprocess
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        count <= (others => '0');
        lamp_int <= '0';
      elsif start_pulse = '1' then
        count <= "1000";  -- Startvärde 8
        lamp_int <= '0';
      elsif count /= 0 then
        count <= count - 1;
      end if;

      -- Kontrollera om vi nått noll
      if count = "0000" then
        lamp_int <= '1';
      end if;
    end if;
  end process;

  -- Utsignaler
  seg <= mem(to_integer(count));
  dp  <= '1';  -- Ingen punkt
  an  <= "1110";  -- Välj sista siffran
  lamp <= lamp_int;

end architecture;
