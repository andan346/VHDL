library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity stopwatch is
  port (clk            : in  std_logic;                    -- clk is "fast enough".
        reset          : in  std_logic;                    -- reset is active high.
        hundradelspuls : in  std_logic;
        muxfrekvens    : in  std_logic;                    -- tic for multiplexing the display.
        start_stopp    : in  std_logic;
        nollstallning  : in  std_logic;                    -- restart from 00:00:00
        visningslage   : in  std_logic;                    -- 1:show min/sec. 0: show sec/centisec
        seg            : out std_logic_vector(6 downto 0); -- Segments
        dp             : out std_logic;                    -- Decimal point
        an             : out std_logic_vector(3 downto 0); -- Digit to display
        raknar         : out std_logic                     -- Connected to an LED
       );
end entity;

architecture rtl of stopwatch is
  signal start_stopp_sync : std_logic;
  signal nollstallning_sync : std_logic;
  signal visningslage_sync : std_logic;

  signal centi_counter : unsigned(6 downto 0) := (others => '0');
  signal centi_carry : std_logic := '0';
  signal second_counter : unsigned(5 downto 0) := (others => '0');
  signal second_carry : std_logic;
  signal minute_counter : unsigned(5 downto 0) := (others => '0');
  signal minute_carry : std_logic;

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
  "0001110" -- F
);
begin

  -- Synka insignaler
  process(clk, reset) begin
    if reset = '1' then
      start_stopp_sync <= '0';
      nollstallning_sync <= '0';
      visningslage_sync <= '0';
    elsif rising_edge(clk) then
      start_stopp_sync <= start_stopp;
      nollstallning_sync <= nollstallning;
      visningslage_sync <= visningslage;
    end if;
  end process;

  -- Hundradelar
  process(hundradelspuls, nollstallning_sync) begin

    if nollstallning_sync = '1' then
      centi_counter <= "0000000";

    elsif rising_edge(hundradelspuls) then

      if (centi_carry = '0') then
        centi_counter <= centi_counter + 1;
      elsif (centi_carry = '1') then
        centi_counter <= "0000000";
      end if;

    end if;

  end process;

  centi_carry <= '1' when (centi_counter = 99) else '0';

  -- Sekunder
  process(centi_carry, nollstallning_sync) begin

    if nollstallning_sync = '1' then
      minute_counter <= "0000000";

    elsif centi_carry = '1' then

      second_counter <= second_counter + 1;

    end if;

  end process;

  second_carry <= '1' when (second_counter = 59) else '0';



end architecture;
