library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dot_matrix;
use dot_matrix.constants.all;
use dot_matrix.types.all;

entity top is
  generic (
      PULSE_TIME_US : natural := led_pulse_time_us;
      DEADBAND_TIME_US : natural := led_deadband_time_us
  );
  port (
        clk : in std_logic;
        rst_button : in std_logic;

        -- UART 
        uart_rx : in std_logic;
        uart_tx : out std_logic;

        -- Debug LEDs
        led_1 : out std_logic;
        led_2 : out std_logic;
        led_3 : out std_logic;
        led_4 : out std_logic;
        led_5 : out std_logic;

        -- Dot matrix controls
        rows : out std_logic_vector(7 downto 0);
        cols : out std_logic_vector(7 downto 0)
  );
end top; 

-- 'str' is 'structural', meaning that this module does not implement any logic, but
-- only instantiates other logic blocks
architecture str of top is

    signal rst : std_logic;

    signal uart_rx_data : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;
    signal uart_rx_stop_bit_error : std_logic;

    signal uart_tx_busy : std_logic;

    signal char_buf_data_out : std_logic_vector(7 downto 0);
    signal char_rom_addr : char_range;
    signal led8x8 : matrix_type;

begin

    -- concurrent assignments
    char_rom_addr <= to_integer(unsigned(char_buf_data_out(6 downto 0))); -- use only the 7 highest bits to keep < 128

    ---------------------------------------------------
    -- RESET instantiation
    ---------------------------------------------------
    RESET : entity dot_matrix.reset(rtl)
    port map (
        clk => clk,
        rst_in => rst_button,
        rst_out => rst
    );

    ---------------------------------------------------
    -- DEBUG instantiation
    ---------------------------------------------------
    DEBUG_LEDS : entity dot_matrix.debug_leds(rtl)
    port map (
        clk => clk, 
        rst => rst, 
        uart_rx_stop_bit_error => uart_rx_stop_bit_error,
        uart_rx_valid => uart_rx_valid,
        uart_tx_busy => uart_tx_busy,
        led_1 => led_1,
        led_2 => led_2, 
        led_3 => led_3, 
        led_4 => led_4, 
        led_5 => led_5
    );

    ---------------------------------------------------
    -- UART instantiation
    ---------------------------------------------------
    UART_RX_INST : entity dot_matrix.uart_rx(rtl)
    port map (
        clk => clk,
        rst => rst,
        rx  => uart_rx,
        data => uart_rx_data,
        valid => uart_rx_valid,
        stop_bit_error => uart_rx_stop_bit_error
    );

    UART_TX_INST : entity dot_matrix.uart_tx(rtl)
    port map (
        clk => clk,
        rst => rst,
        start => uart_rx_valid,
        data => uart_rx_data,
        busy => uart_tx_busy,
        tx => uart_tx
    );

    ---------------------------------------------------
    -- CHAR_BUF instantiation
    ---------------------------------------------------
    CHAR_BUF : entity dot_matrix.char_buf(rtl)
    port map(
        clk => clk,
        rst => rst,
        wr => uart_rx_valid,
        din => uart_rx_data,
        dout => char_buf_data_out
    );
  
    ---------------------------------------------------
    -- CHAR_ROM instantiation
    ---------------------------------------------------
    CHAR_ROM : entity dot_matrix.char_rom(rtl)
    port map (
        clk => clk,
        addr => char_rom_addr,
        dout => led8x8
    );
  
    ---------------------------------------------------
    -- LED_CONTROLLER_8X8 instantiation
    ---------------------------------------------------
    LED_CONTROLLER_8X8 : entity dot_matrix.led_controller_8x8(rtl)
    generic map (
        PULSE_TIME_US => PULSE_TIME_US,
        DEADBAND_TIME_US => DEADBAND_TIME_US 
    )
    port map (
        clk => clk,
        rst => rst, 
        led8x8 => led8x8,
        rows => rows,
        cols => cols
    );

end architecture;