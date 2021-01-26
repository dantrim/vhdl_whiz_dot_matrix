library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dot_matrix;
use dot_matrix.constants.all;

entity uart_tx is
  port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        data : in std_logic_vector(7 downto 0);
        busy : out std_logic;
        tx : out std_logic
  );
end uart_tx; 

architecture rtl of uart_tx is

    -- For counting clock periods
    -- going to define how many clock cycles needed for a single bit
    -- VHDL cannot divide integer by integer
    constant clock_cycles_per_bit : integer := integer(clock_frequency / real(baud_rate));
    subtype clk_counter_type is integer range 0 to clock_cycles_per_bit - 1;
    signal clk_counter : clk_counter_type;

    type state_type is (
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    );
    signal state : state_type;

    -- for sampling the data input
    signal data_sampled : std_logic_vector(data'range);

    -- for counting the number of transmitted bits
    signal bit_counter : integer range(data'range);

begin

    FSM_PROC : process(clk)

        -- increment clock counter
        -- return true if the counter wrapped
        impure function clk_counter_wrapped return boolean is
        begin
            if clk_counter = clk_counter_type'high then
                clk_counter <= 0;
                return true;
            else
                clk_counter <= clk_counter + 1;
                return false;
            end if;
        end function;

    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                busy <= '1';
                tx <= '1';
                data_sampled <= (others => '0');
                bit_counter <= 0;
            else

                -- default busy state
                busy <= '1';
                tx <= '1';

                case state is
                    --------------------------------------------------
                    -- wait for the start signal
                    --------------------------------------------------
                    when IDLE =>
                        busy <= '0';
                        if start = '1' then
                            state <= START_BIT;
                            data_sampled <= data;
                            busy <= '1';
                        end if;

                    --------------------------------------------------
                    -- transmit the start bit
                    --------------------------------------------------
                    when START_BIT =>
                        tx <= '0';
                        if clk_counter_wrapped then
                            state <= DATA_BITS;
                        end if;

                    --------------------------------------------------
                    -- transmit the data bits
                    --------------------------------------------------
                    when DATA_BITS =>
                        tx <= data_sampled(bit_counter);
                        if clk_counter_wrapped then
                            if bit_counter = data'high then
                                state <= STOP_BIT;
                                bit_counter <= 0;
                            else
                                bit_counter <= bit_counter + 1;
                            end if;
                        end if;

                    --------------------------------------------------
                    -- transmit the stop bit
                    --------------------------------------------------
                    when STOP_BIT =>
                        if clk_counter_wrapped then
                            state <= IDLE;
                            busy <= '0';
                        end if;
                end case;
                
                
            end if;
        end if;
    end process;

end architecture;