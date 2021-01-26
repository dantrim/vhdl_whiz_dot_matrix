library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dot_matrix;
use dot_matrix.constants.all;

entity uart_rx is
  port (
        clk : in std_logic;
        rst : in std_logic;
        rx : in std_logic;
        data : out std_logic_vector(7 downto 0);
        valid : out std_logic;
        stop_bit_error : out std_logic
  );
end uart_rx; 

architecture rtl of uart_rx is

    -- UART FSM
    type state_type is (
        DETECT_START,
        WAIT_START,
        WAIT_HALF_BIT,
        SAMPLE_DATA,
        WAIT_STOP,
        CHECK_STOP
    );
    signal state : state_type;

    -- For counting clock periods
    -- going to define how many clock cycles needed for a single bit
    -- VHDL cannot divide integer by integer
    constant clock_cycles_per_bit : integer := integer(clock_frequency / real(baud_rate));
    subtype clk_counter_type is integer range 0 to clock_cycles_per_bit - 1;
    signal clk_counter : clk_counter_type;


    -- for counting the number of transmitted bits
    signal bit_counter : integer range data'range;

    -- the rx signal delayed by one clock cycle
    signal rx_p1 : std_logic;

    signal shift_reg : std_logic_vector(data'range);

begin

    FSM_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rx_p1 <= '0';
                data <= (others => '0');
                valid <= '0';
                stop_bit_error <= '0';
                state <= DETECT_START;
                clk_counter <= 0;
                bit_counter <= 0;
                shift_reg <= (others => '0');
            else

                -- pulsed
                valid <= '0';
                rx_p1 <= rx;

                case state is

                    ------------------------------------------------------
                    -- wait for the falling edge on the rx signal
                    ------------------------------------------------------
                    when DETECT_START =>
                        -- RX has gone down but we have not gone the 1 clock cycle needed for rx_p1 to follow RX
                        if rx = '0' and rx_p1 = '1' then
                            state <= WAIT_START;
                            clk_counter <= 1;
                            stop_bit_error <= '0';
                        end if;
                        -- at the end of the DETECT_START state the clk_counter should be incremented to 1

                    ------------------------------------------------------
                    -- wait for the duration of the stop bit
                    ------------------------------------------------------
                    when WAIT_START =>
                        if clk_counter = clk_counter_type'high then
                            state <= WAIT_HALF_BIT;
                            clk_counter <= 0;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;

                    ------------------------------------------------------
                    -- wait for the duration of 1/2 clock, to be at the
                    -- middle of data bit 0
                    ------------------------------------------------------
                    when WAIT_HALF_BIT =>
                        if clk_counter = clk_counter_type'high / 2 then
                            state <= SAMPLE_DATA;
                            clk_counter <= clk_counter_type'high;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;

                    ------------------------------------------------------
                    -- sample the 8 data bits
                    ------------------------------------------------------
                    when SAMPLE_DATA =>
                        if clk_counter = clk_counter_type'high then
                            clk_counter <= 0;

                            -- shift the data in from high to low index
                            shift_reg(shift_reg'high) <= rx;
                            for i in shift_reg'high downto shift_reg'low + 1 loop
                                shift_reg(i-1) <= shift_reg(i);
                            end loop;

                            if bit_counter = data'high then
                                state <= WAIT_STOP;
                                bit_counter <= 0;
                            else
                                bit_counter <= bit_counter + 1;
                            end if;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;

                    ------------------------------------------------------
                    -- wait for the duration of one symbol until we
                    -- are in the middle of the stop bit
                    ------------------------------------------------------
                    when WAIT_STOP =>
                        if clk_counter = clk_counter_type'high then
                            state <= CHECK_STOP;
                            clk_counter <= 0;
                        else
                            clk_counter <= clk_counter + 1;
                        end if;

                    ------------------------------------------------------
                    -- check that the stop bit is 1, and output the data
                    ------------------------------------------------------
                    when CHECK_STOP =>
                        -- go back to the initial state of the FSM, and await transition of the next byte
                        state <= DETECT_START; 
                        data <= shift_reg;
                        valid <= '1';
                        shift_reg <= (others => '0');
                        if rx = '0' then
                            stop_bit_error <= '1';
                        end if;
                end case;
                
                
            end if;
        end if;
    end process;

end architecture;