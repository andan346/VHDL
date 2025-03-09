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
  signal hundradelspuls_sync0 : std_logic;
  signal hundradelspuls_sync : std_logic;
  signal hundradelspuls_ep : std_logic;

  signal muxfrekvens_sync0 : std_logic;
  signal muxfrekvens_sync : std_logic;
  signal muxfrekvens_ep : std_logic;
  
  signal start_stopp_sync0 : std_logic;
  signal start_stopp_sync : std_logic;
  signal start_stopp_ep : std_logic;
  signal start_stopp_state : std_logic;

  signal nollstallning_sync0 : std_logic;
  signal nollstallning_sync : std_logic;
  signal nollstallning_ep : std_logic;

  signal visningslage_sync : std_logic;

  signal centi_counter0 : unsigned(3 downto 0) := (others => '0');
  signal centi_carry0 : std_logic := '0';
  signal centi_counter1 : unsigned(3 downto 0) := (others => '0');
  signal centi_carry1 : std_logic := '0';

  signal second_counter0 : unsigned(3 downto 0) := (others => '0');
  signal second_carry0 : std_logic;
  signal second_counter1 : unsigned(2 downto 0) := (others => '0');
  signal second_carry1 : std_logic;

  signal minute_counter0 : unsigned(3 downto 0) := (others => '0');
  signal minute_carry0 : std_logic;
  signal minute_counter1 : unsigned(2 downto 0) := (others => '0');

  signal mux_counter : unsigned(2 downto 0) := (others => '0');

  type digit_rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant to_display : digit_rom := (
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

  type an_rom is array (0 to 3) of std_logic_vector(3 downto 0);
  constant to_an : an_rom := (
  "1110", -- 1:a siffran
  "1101", -- 2:a
  "1011", -- 3:e
  "0111"  -- 4:e
);

begin

  -- Synka insignaler
  process(clk, reset) begin

    if rising_edge(clk) then

      start_stopp_sync0 <= start_stopp;
      start_stopp_sync <= start_stopp_sync0;

      nollstallning_sync0 <= nollstallning;
      nollstallning_sync <= nollstallning_sync0;

      visningslage_sync <= visningslage;


      hundradelspuls_sync0 <= hundradelspuls;
      hundradelspuls_sync <= hundradelspuls_sync0;

      muxfrekvens_sync0 <= muxfrekvens;
      muxfrekvens_sync <= muxfrekvens_sync0;


    end if;

    if reset = '1' then
      --hundradelspuls_sync <= '0';
      --hundradelspuls_sync0 <= '0';

      --muxfrekvens_sync <= '0';
      --muxfrekvens_sync0 <= '0';

      start_stopp_sync0 <= '0';
      start_stopp_sync <= '0';

      nollstallning_sync0 <= '0';
      nollstallning_sync <= '0';

      visningslage_sync <= '0';

    end if;

  end process;

  -- Enpulsa signaler
  hundradelspuls_ep <= hundradelspuls_sync0 and (not hundradelspuls_sync) and start_stopp_state;
  muxfrekvens_ep <= muxfrekvens_sync0 and (not muxfrekvens_sync);
  start_stopp_ep <= start_stopp_sync0 and (not start_stopp_sync);
  nollstallning_ep <= nollstallning_sync0 and (not nollstallning_sync);


  -- Start/stopp
  process(clk, reset) begin

    if (reset = '1') then
      start_stopp_state <= '0';

    elsif rising_edge(clk) then

      if (start_stopp_ep = '1') then
        start_stopp_state <= not(start_stopp_state);
      end if;

    end if;

  end process;


  -- Hundradelar
  process(clk) begin
    if rising_edge(clk) then

      centi_carry0 <= '0';

      if (nollstallning_ep = '1') then
        centi_counter0 <= (others => '0');

      elsif (hundradelspuls_ep = '1') then

        if (centi_counter0 = 9) then
          centi_counter0 <= (others => '0');
          centi_carry0 <= '1';

        else 
          centi_counter0 <= centi_counter0 + 1;

        end if;

      end if;

    end if;
  end process;

  process(clk, reset) begin
    if rising_edge(clk) then

      centi_carry1 <= '0';

      if (nollstallning_ep = '1') then
        centi_counter1 <= (others => '0');

      elsif (centi_carry0 = '1') then

        if (centi_counter1 = 9) then
          centi_counter1 <= (others => '0');
          centi_carry1 <= '1';

        else
          centi_counter1 <= centi_counter1 + 1;

        end if;

      end if;

    end if;
  end process;

  -- Sekunder
  process(clk) begin
    if rising_edge(clk) then

      second_carry0 <= '0';

      if (nollstallning_ep = '1') then
        second_counter0 <= (others => '0');

      elsif (centi_carry1 = '1') then

        if (second_counter0 = 9) then
            second_counter0 <= (others => '0');
            second_carry0 <= '1';

        else
          second_counter0 <= second_counter0 + 1;

        end if;

      end if;

    end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then

      second_carry1 <= '0';

      if (nollstallning_ep = '1') then
        second_counter1 <= (others => '0');

      elsif (second_carry0 = '1') then

        if (second_counter1 = 5) then
            second_counter1 <= (others => '0');
            second_carry1 <= '1';

        else
          second_counter1 <= second_counter1 + 1;

        end if;

      end if;

    end if;
  end process;

  -- Minuter
  process(clk) begin
    if rising_edge(clk) then

      minute_carry0 <= '0';

      if (nollstallning_ep = '1') then
        minute_counter0 <= (others => '0');

      elsif (second_carry1 = '1') then

        if (minute_counter0) = 9 then
          minute_counter0 <= (others => '0');
          minute_carry0 <= '1';

        else
          minute_counter0 <= minute_counter0 + 1;
          
        end if;

      end if;

    end if;
  end process;

  process(clk) begin
    if rising_edge(clk) then

      if (nollstallning_ep = '1') then
        minute_counter1 <= (others => '0');

      elsif (minute_carry0 = '1') then

        if (minute_counter1) = 5 then
          minute_counter1 <= (others => '0');

        else
          minute_counter1 <= minute_counter1 + 1;
          
        end if;

      end if;

    end if;
  end process;


  -- Välj siffra på displayen att visa
  process(clk) begin
    if rising_edge(clk) then

      if (muxfrekvens_ep = '1') then

        -- Välj segment
        if (mux_counter = 3) then
          mux_counter <= (others => '0');

        else
          mux_counter <= mux_counter + 1;

        end if;

        an <= to_an(to_integer(mux_counter));

        -- Sätt segment till rätt siffra beroende på visningsläge
        if (visningslage_sync = '0') then

          if (mux_counter = 0) then
            seg <= to_display(to_integer(centi_counter0));
          end if;
          if (mux_counter = 1) then
            seg <= to_display(to_integer(centi_counter1));
          end if;
          if (mux_counter = 2) then
            seg <= to_display(to_integer(second_counter0));
          end if;
          if (mux_counter = 3) then
            seg <= to_display(to_integer(second_counter1));
          end if;

        elsif (visningslage_sync = '1') then

          if (mux_counter = 0) then
            seg <= to_display(to_integer(second_counter0));
          end if;
          if (mux_counter = 1) then
            seg <= to_display(to_integer(second_counter1));
          end if;
          if (mux_counter = 2) then
            seg <= to_display(to_integer(minute_counter0));
          end if;
          if (mux_counter = 3) then
            seg <= to_display(to_integer(minute_counter1));
          end if;

        end if;


      end if;

    end if;
  end process;

  -- Övrigt
  dp <= '1';
  raknar <= start_stopp_state;

end architecture;
