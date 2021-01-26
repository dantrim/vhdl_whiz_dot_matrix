library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

library dot_matrix;

library dot_matrix_sim;
use dot_matrix_sim.sim_subprograms.all;
use dot_matrix_sim.sim_fifo.all;
use dot_matrix_sim.sim_constants.all;

entity uart_tb is
end uart_tb; 

architecture sim of uart_tb is

        -- common signals
        signal clk : std_logic := '1';
        signal rst : std_logic := '1';
        signal tx_rx : std_logic := '1';

        -- UART_RX signals
        signal rx_data : std_logic_vector(7 downto 0);
        signal rx_valid : std_logic;
        signal rx_stop_bit_error : std_logic;

        -- UART_TX signals
        signal tx_start : std_logic := '0';
        signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
        signal tx_busy : std_logic;

        -- TB FIFO for storing the transmitted characters
        shared variable fifo : sim_fifo;

begin

    ----------------------------------------
    -- gen clock from subprograms
    ----------------------------------------
    gen_clock(clk);

    UART_RX : entity dot_matrix.uart_rx(rtl)
    port map (
        clk => clk,
        rst => rst,
        rx  => tx_rx,
        data => rx_data,
        valid  => rx_valid,
        stop_bit_error => rx_stop_bit_error
    );

    UART_TX : entity dot_matrix.uart_tx(rtl)
    port map (
        clk => clk,
        rst => rst,
        start => tx_start,
        data => tx_data,
        busy => tx_busy,
        tx => tx_rx
  );

  ---------------------------------------------------------------------------
  -- transmit data to UART, test all possible input values
  ---------------------------------------------------------------------------
  PROC_SEQUENCER : process

    -- transmit procedure to push 1 data byte into the UART transceiver
    procedure transmit(constant data : std_logic_vector(tx_data'range)) is
    begin
        -- load the data byte and pulse the start signal
        tx_start <= '1';
        tx_data <= data;
        fifo.push(to_integer(unsigned(data)));
        report "Transmit: " & integer'image(to_integer(unsigned(data)));
        wait until rising_edge(clk);
        tx_start <= '0';

        -- set the data to invalid, to ensure that any invalid data sampling
        -- samples invalid data (should be caught by any possible assert statements in the TB)
        tx_data <= (others => 'X');
        wait until rising_edge(clk);
    end procedure;

    -- procedure to wait until the transmit fifo is empty
    procedure wait_until_fifo_empty is
    begin
        while not fifo.empty loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

    variable tx_data_var : tx_data'subtype := (others => '0');

  begin

    -- reset strobe
    wait for 10 * clock_period;
    rst <= '0';

    -- wait until UART TX is ready
    wait until tx_busy = '0';

    -- test all possible input values
    loop
        transmit(tx_data_var);

        -- wait until the UART_TX is ready to transmit the next data symbol
        wait until tx_busy = '0';

        -- increment the input data symbol before the next test
        tx_data_var  := std_logic_vector(unsigned(tx_data_var) + 1);

        -- exit the loop if all bits are zero (we have wrapped around the range of tx_data)
        if unsigned(tx_data_var) = 0 then
            exit;
        end if;
    end loop;

    -- wait until UART_RX is done
    wait_until_fifo_empty;

    -- add a pause to check that there is no more output
    wait for 1 ms;

    ---------------------------------------------------------------------------
    -- check that the stop bit error signal is working
    ---------------------------------------------------------------------------
    transmit(x"00");
    wait until tx_rx = '0';
    tx_rx <= force '0'; -- creating a stop bit error
    wait_until_fifo_empty;
    -- at this point there should be a stop bit error
    assert rx_stop_bit_error = '1'
            report "Stop bit error signal was not asserted" 
            severity failure;

    -- release the stop bit error and check that the dut recovers
    tx_rx <= release;
    wait for 1 ms;
    transmit(x"00");
    wait_until_fifo_empty;
    assert rx_stop_bit_error = '0'
            report "Stop bit error signal is still asserted" 
            severity failure;

    print_test_ok;
    finish;
      
  end process;

  ---------------------------------------------------------------------------
  -- process to match the output of the UART_RX
  -- module to the expected injected data
  ---------------------------------------------------------------------------
  PROC_CHECK_RX : process
    variable expected : integer;
  begin

    -- when the rx_valid signal is asserted, we know that the UART_RX has valid output data
    wait until rx_valid = '1';

    -- get the next transmitted word from the fifo
    expected := fifo.pop;

    -- check that this is the expected output
    assert to_integer(unsigned(rx_data)) = expected
        report "Output from UART_RX (" & integer'image(to_integer(unsigned(rx_data)))
                & ") does not match transmitted word (" & integer'image(expected) & ")"
        severity failure;

    report "Received " & integer'image(expected);
      
  end process; -- PROC_CHECK_RX

end architecture;