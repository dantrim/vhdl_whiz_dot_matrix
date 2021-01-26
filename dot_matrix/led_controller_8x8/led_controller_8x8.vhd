library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dot_matrix;
use dot_matrix.types.all;
use dot_matrix.constants.all;

entity led_controller_8x8 is
  generic (
      PULSE_TIME_US : natural := led_pulse_time_us;
      DEADBAND_TIME_US : natural := led_deadband_time_us
  );
  port (
        clk : in std_logic;
        rst : in std_logic;
        led8x8 : in matrix_type;
        rows : out std_logic_vector(7 downto 0);
        cols : out std_logic_vector(7 downto 0)
  );
end led_controller_8x8; 

architecture rtl of led_controller_8x8 is

    constant clk_cycles_per_pulse : natural
      := natural((clock_frequency / 1.0e6)) * PULSE_TIME_US;

    constant clk_cycles_deadband : natural
      := natural((clock_frequency / 1.0e6)) * DEADBAND_TIME_US;

    subtype pulse_counter_type is natural range 0 to clk_cycles_per_pulse - 1;
    signal pulse_counter : pulse_counter_type;
    signal row_counter : unsigned(2 downto 0);

begin

    assert clk_cycles_per_pulse > 0 severity failure;
    assert clk_cycles_per_pulse < natural(clock_frequency) severity failure;
    assert clk_cycles_per_pulse > clk_cycles_deadband severity failure;

    PROC_COUNTER : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pulse_counter <= 0;
                row_counter <= (others => '0');
            else
                -- when pulse counter wraps
                if pulse_counter = pulse_counter_type'high then
                    pulse_counter <= 0;
                    row_counter <= row_counter + 1;
                else
                    pulse_counter <= pulse_counter + 1;
                end if;
            end if;
        end if;
    end process;

    PROC_OUTPUT : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rows <= (others => '0');
                cols <= (others => '0');
            else
                rows <= (others => '0');

                rows(to_integer(row_counter)) <= '1';
                cols <= led8x8(to_integer(row_counter));

                -- for the (initial) deadband time, force the rows and cols to all zeros
                if pulse_counter < clk_cycles_deadband then
                    rows <= (others => '0');
                    cols <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end architecture;