library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debug_leds is
  port (
        clk : in std_logic;
        rst : in std_logic;

        -- signals to debug
        uart_rx_stop_bit_error : in std_logic;
        uart_rx_valid : in std_logic;
        uart_tx_busy : in std_logic;

        -- LED outputs
        led_1 : out std_logic; -- UART_RX stop bit error
        led_2 : out std_logic; -- sticky version of led_1
        led_3 : out std_logic; -- UART_RX valid pulsed while busy was '1'
        led_4 : out std_logic; -- sticky version of led_3
        led_5 : out std_logic -- power ON LED, always on
  );
end debug_leds; 

architecture rtl of debug_leds is

begin

    -- concurrent assignment
    led_5 <= '1';

    PROC_LEDS : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                led_1 <= '0';
                led_2 <= '0';
                led_3 <= '0';
                led_4 <= '0';
            else

                -- pass through
                led_1 <= uart_rx_stop_bit_error;

                -- sticky version, only way to turn off is to reset FPGA
                if uart_rx_stop_bit_error = '1' then
                    led_2 <= '1';
                end if;

                -- assert led_3 if uart_rx is busy
                if uart_rx_valid = '1' then
                    led_3 <= uart_tx_busy;
                end if;

                -- sticky version of led_3
                if uart_rx_valid = '1' and uart_tx_busy = '1' then
                    led_4 <= '1';
                end if;
                
            end if;
        end if;
    end process;

end architecture;