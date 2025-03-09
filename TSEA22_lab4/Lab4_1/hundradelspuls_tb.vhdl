library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Testbench Entity
entity tb_10ms_pulse is
end tb_10ms_pulse;

architecture behavior of tb_10ms_pulse is

    -- Signal declaration
    signal hundradelspuls : std_logic := '0';
    signal clk : std_logic := '0';
    
    -- Constant for 10ms period
    constant clk_period : time := 10 ms;  -- 10ms clock period
    constant total_simulation_time : time := 10 sec;  -- 10 seconds simulation time
    
begin
    -- Clock Generation Process (for a 50% duty cycle)
    clk_process : process
    begin
        while now < total_simulation_time loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Generate hundradelspuls signal for 10 seconds at 10ms intervals
    hundradelspuls_process : process
    begin
        -- Enable hundradelspuls for 10ms every cycle for 10 seconds
        while now < total_simulation_time loop
            hundradelspuls <= '1';
            wait for 10 ms;  -- Active for 10ms
            hundradelspuls <= '0';
            wait for 10 ms;  -- Inactive for 10ms
        end loop;
        wait;
    end process;

end behavior;
