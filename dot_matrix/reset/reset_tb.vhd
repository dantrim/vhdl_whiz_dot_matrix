library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

library dot_matrix;

library dot_matrix_sim;
use dot_matrix_sim.sim_constants.all;
use dot_matrix_sim.sim_subprograms.all;


entity reset_tb is
end reset_tb; 

architecture sim of reset_tb is

    -- min and max duration of the reset strobe
    constant min_duration : time := 20 * clock_period;
    constant max_duration : time := 100 us;

    -- time to wait before assuming that the device under test is not resetting
    constant quiet_duration : time := max_duration * 5;

    -- DUT signals
    signal clk : std_logic := '1';
    signal rst_in : std_logic := '1'; -- pull-up resistor assumed
    signal rst_out : std_logic;

begin

    gen_clock(clk);

    DUT : entity dot_matrix.reset(rtl)
    port map (
        clk => clk,
        rst_in => rst_in,
        rst_out => rst_out
    );

    PROC_SEQUENCER : process

        -- check that the duration of the reset procedure is within min/max
        procedure check_duration is
        begin
            assert rst_out = '1'
                report "rst_out should be '1' before calling check_duration" 
                severity failure;
            
            wait on rst_out for min_duration;
            assert rst_out'stable(min_duration)
                report "Strobe on rst_out was shorter than min_duration: "
                    & time'image(min_duration)
                severity failure;
            
            wait for max_duration - min_duration;
            assert rst_out = '0'
                report "rst_out didn't change from '1' to '0' within " 
                    & time'image(max_duration)
                severity failure;
        end procedure;

        -- perform one test of the reset cycle
        procedure button_test is
        begin
            assert rst_out = '0'
                report "rst_out should be '0' when button_test is called" 
                severity failure;
            
            wait for quiet_duration;
            assert rst_out = '0' and rst_out'stable(quiet_duration)
                report "rst_out asserted without any activity on rst_in" 
                severity failure;
            
            report "Triggering a reset";
            wait until rising_edge(clk);
            rst_in <= '0';
            wait until rising_edge(clk);
            rst_in <= '1';
            wait until rising_edge(clk);

            assert rst_out = '1'
                report "rst_out was not asserted after a pulse on rst_in" 
                severity failure;
            
            check_duration;

            
        end procedure;
    begin

        -- wait for 1 delta cycle to allow DUT to set to initial value
        wait for 0 ns;

        -- at power-up, the rst_out signal should be asserted for 127 clock cycles
        assert rst_out = '1'
            report "rst_out was not asserted on power-up"
            severity failure;

        -- check the duration of the power-on reset strobe
        check_duration;

        -- test two reset cycles triggered by button input
        button_test;
        button_test;

        print_test_ok;
        finish;
    end process;

end architecture;