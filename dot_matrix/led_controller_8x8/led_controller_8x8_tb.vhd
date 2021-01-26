library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

library dot_matrix;
use dot_matrix.types.all;
use dot_matrix.charmap.all;

library dot_matrix_sim;
use dot_matrix_sim.sim_subprograms.all;
use dot_matrix_sim.sim_constants.all;

entity led_controller_8x8_tb is
end led_controller_8x8_tb; 

architecture sim of led_controller_8x8_tb is

    -- DUT signals
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal led8x8 : matrix_type := (others => (others => '0'));
    signal rows : std_logic_vector(7 downto 0);
    signal cols : std_logic_vector(7 downto 0);

    -- verification component signals
    signal enable_checking : boolean := false;
    signal led8x8_output : matrix_type := (others => (others => '0'));
    signal test_failed : boolean := false;

begin

    gen_clock(clk);

    DUT : entity dot_matrix.led_controller_8x8(rtl)
    generic map (
        PULSE_TIME_US => sim_led_pulse_time_us,
        DEADBAND_TIME_US => sim_led_deadband_time_us
    )
    port map (
        clk => clk,
        rst => rst, 
        led8x8 => led8x8,
        rows => rows,
        cols => cols
    );

    VC : entity dot_matrix_sim.led_controller_8x8_vc(sim)
    generic map (
        PULSE_TIME_US => sim_led_pulse_time_us,
        DEADBAND_TIME_US => sim_led_deadband_time_us
    )
    port map (
        enable => enable_checking,
        led8x8_template => led8x8,
        led8x8_output => led8x8_output,
        test_failed => test_failed,
        rows => rows,
        cols => cols
    );

    PROC_SEQUENCER : process
        variable str : line;
    begin
        -- reset strobe
        wait for 10 * clock_period;
        rst <= '0';

        for i in 0 to charmap'length - 1 loop

            -- print the DUT input
            report "Char: '" & character'val(i) & "'";
            write(str, string'("---------------------"));
            writeline(output, str);
            write(str, string'("Input:"));
            writeline(output, str);
            print_char(charmap(i));

            led8x8 <= charmap(i);

            -- give DUT some time to react
            wait for 10 * clock_period;

            -- check a few full cycles for each of the cahracters
            enable_checking <= true;
            wait for 10 * full_cycle_time;
            enable_checking <= false;

            -- wait past all delta cycle delays
            wait for 1 ns;

            -- print the DUT output
            write(str, string'("Output:"));
            writeline(output, str);
            print_char(led8x8_output);
            assert not test_failed severity failure;
        end loop;

        print_test_ok;
        finish;
    end process;

end architecture;