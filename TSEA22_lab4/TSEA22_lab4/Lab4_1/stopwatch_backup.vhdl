-- Sekunder
  process(centi_carry) begin
    if rising_edge(second_carry) or nollstallning_sync = '1' then
      second_counter <= "000000";
    elsif centi_carry = '0' then
      second_counter <= second_counter + 1;
    end if;
  end process;

  second_carry <= '1' when (second_counter = 60) else '0';

  -- Minuter
  process(second_carry) begin
    if minute_carry = '1' or nollstallning_sync = '1' then
      minute_counter <= "000000";
    elsif minute_carry = '0' then
      minute_counter <= minute_counter + 1;
    end if;
  end process;

  minute_carry <= '1' when (minute_counter = 60) else '0';

  -- Nollställ vid 1 timme
  process(minute_carry) begin
    if minute_carry = '1' then
      nollstallning_sync <= '0';
    end if;
  end process;