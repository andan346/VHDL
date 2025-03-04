library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity kaskad is
    port(
        clk   : in  std_logic;
        reset : in  std_logic;
        seg   : out std_logic_vector(6 downto 0);
        dp    : out std_logic;
        an    : out std_logic_vector(3 downto 0));
end entity;

architecture arch of kaskad is
    signal c0, c1, c2 : unsigned(3 downto 0) := "0000";
    signal rco0, rco1 : std_logic := '0';
    signal refresh_counter : unsigned(1 downto 0) := "00";

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

    process(clk) begin
        if rising_edge(clk) then
            if rco0 = '1' or reset = '1' then
                c0 <= "0000";
            else
                c0 <= c0 + 1;
            end if;
        end if;
    end process;

    rco0 <= '1' when (c0 = 9) else '0';

    process(clk) begin
        if rising_edge(clk) then
            if rco1 = '1' or reset = '1' then
                c1 <= "0000";
            elsif rco0 = '1' then
                c1 <= c1 + 1;
            end if;
        end if;
    end process;

    rco1 <= '1' when (c1 = 5 and rco0 = '1') else '0';

    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                c2 <= "0000";
            elsif rco1 = '1' then
                c2 <= c2 + 1;
            end if;
        end if;
    end process;

    -- display
    process(clk) begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        
            case refresh_counter is
                when "00" =>
                    an <= "1110";
                    seg <= mem(to_integer(unsigned(c0)));
                when "01" =>
                    an <= "1101";
                    seg <= mem(to_integer(unsigned(c1)));
                when others =>
                    an <= "1011";
                    seg <= mem(to_integer(unsigned(c2)));
            end case;

            an <= "1000";
        end if;
    end process;

    dp <= '0';

end architecture;