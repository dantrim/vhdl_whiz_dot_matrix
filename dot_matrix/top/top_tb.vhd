library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all; -- line
use std.env.finish;
use std.env.stop;

library dot_matrix;
use dot_matrix.constants.all;
use dot_matrix.types.all;
use dot_matrix.charmap.all;

library dot_matrix_sim;
use dot_matrix_sim.sim_subprograms.all;
use dot_matrix_sim.sim_constants.all;

entity top_tb is
end top_tb; 

architecture sim of top_tb is

    -- DUT signals
    signal clk : std_logic := '1';
    signal rst_button : std_logic := '1'; -- pull-up
    signal uart_to_dut : std_logic := '1'; -- uart interface is held at logical high during IDLE
    signal uart_from_dut : std_logic;
    signal led_1 : std_logic;
    signal led_2 : std_logic;
    signal led_3 : std_logic;
    signal led_4 : std_logic;
    signal led_5 : std_logic;
    signal rows : std_logic_vector(7 downto 0);
    signal cols : std_logic_vector(7 downto 0);

    -- TB UART_TX signals
    signal uart_tx_start : std_logic := '0';
    signal uart_tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal uart_tx_busy : std_logic; -- this is an output, so do not need to provide an initial value

    -- LED_CONTROLLER_8X8_VC signals
    signal vc_enable_checking : boolean := false;
    signal vc_led8x8_template : matrix_type := (others => (others => '0'));
    signal vc_led8x8_output : matrix_type := (others => (others => '0'));
    signal vc_test_failed : boolean;

    -- set to true from TCL to enable interactive mode
    signal interactive : boolean := false;

    -- time to wait before checking the DUT output
    constant dut_reaction_time : time := 10 * clock_period;

    -- how long to keep checking the DUT output for each character
    constant check_cycle_time : time := 10 * full_cycle_time;

    -- total time the TCL program should wait for each test to complete
    constant character_test_time : time := dut_reaction_time + check_cycle_time;

begin

    gen_clock(clk);

    -----------------------------------------------------------------
    -- DUT instantiation
    -----------------------------------------------------------------
    DUT : entity dot_matrix.top(str)
    generic map (
        PULSE_TIME_US => sim_led_pulse_time_us,
        DEADBAND_TIME_US => sim_led_deadband_time_us
    )
    port map (
          clk => clk,
          rst_button => rst_button,
          uart_rx => uart_to_dut,
          uart_tx => uart_from_dut,
          led_1 => led_1, 
          led_2 => led_2, 
          led_3 => led_3, 
          led_4 => led_4, 
          led_5 => led_5, 
          rows => rows, 
          cols => cols 
    );

    -----------------------------------------------------------------
    -- Computer input
    -----------------------------------------------------------------
    UART_TX : entity dot_matrix.uart_tx(rtl)
    port map (
        clk => clk,
        rst => << signal DUT.rst : std_logic >>, -- hierarchical signal reference 
        start => uart_tx_start,
        data => uart_tx_data,
        busy => uart_tx_busy,
        tx => uart_to_dut
  );

    -----------------------------------------------------------------
    -- LED 8x8 verification component
    -----------------------------------------------------------------
    VC : entity dot_matrix_sim.led_controller_8x8_vc(sim)
    generic map (
        PULSE_TIME_US => sim_led_pulse_time_us,
        DEADBAND_TIME_US => sim_led_deadband_time_us
    )
    port map (
        enable => vc_enable_checking,
        led8x8_template => vc_led8x8_template,
        led8x8_output => vc_led8x8_output,
        test_failed => vc_test_failed,
        rows => rows,
        cols => cols
    );

    -----------------------------------------------------------------
    -- PROC_SEQUENCER
    -----------------------------------------------------------------
    PROC_SEQUENCER : process
        variable str : line;
        variable char : char_range;

        procedure check_output(constant expected_char : char_range) is
        begin
            vc_led8x8_template <= charmap(expected_char);

            -- give the DUT some time to react
            wait until uart_tx_busy = '0';
            wait for dut_reaction_time;

            -- check a few full render cycles for this character
            vc_enable_checking <= true;
            wait for check_cycle_time;
            vc_enable_checking <= false;
            wait for 1 ns; -- wait for any delta cycle delay to ensure VC outputs are set

            write(str, string'("Output:"));
            writeline(output, str);
            print_char(vc_led8x8_output);

        end procedure check_output;

    begin


        -- Wait until the DUT is out of reset
        wait until << signal DUT.rst : std_logic >> = '0';

        if interactive then
            write(str, string'("Interactive mode enabled"));
            writeline(output, str);

            -- infinite loop
            while true loop

                -- hand over control to TCL when uart_tx is ready
                if uart_tx_busy /= '0' then
                    wait until uart_tx_busy = '0';
                    stop; -- VHDL 2008 keyword to stop the testbench
                end if;

                -- print the transmitted character
                if uart_tx_start /= '1' then
                    wait until uart_tx_start = '1';
                end if;

                char := to_integer(unsigned(uart_tx_data));
                report "TX: " & character'val(char);

                check_output(char);

            end loop;
        end if;

        -- if the interactive flag was not set (self-checking mode)
        for c in char_range loop
            -- write character to the DUT
            report "TX: " & character'val(c);
            uart_tx_data <= std_logic_vector(to_unsigned(c, uart_tx_data'length));
            uart_tx_start <= '1';
            wait until rising_edge(clk);
            uart_tx_start <= '0';
            wait until rising_edge(clk);

            check_output(c);

            assert not vc_test_failed severity failure;

        end loop;

        print_test_ok;
        finish;
    end process; -- PROC_SEQUENCER

end architecture;