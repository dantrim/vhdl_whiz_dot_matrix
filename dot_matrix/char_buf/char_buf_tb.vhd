library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- library "std" is always available
use std.env.finish;
use std.textio.all;

library dot_matrix;
library dot_matrix_sim;
use dot_matrix_sim.sim_constants.all;
use dot_matrix_sim.sim_subprograms.all;

entity char_buf_tb is
-- tb do not have port declaration
end char_buf_tb; 

architecture sim of char_buf_tb is

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal wr : std_logic := '0';
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    signal dout : std_logic_vector(7 downto 0);

begin

    gen_clock(clk);

    DUT : entity dot_matrix.char_buf(rtl)
    port map(
        clk => clk,
        rst => rst,
        wr => wr,
        din => din,
        dout => dout
    );

    PROC_SEQUENCER  : process
        constant all_ones : std_logic_vector(din'range) := (others => '1');
        variable last_din : std_logic_vector(din'range);
    begin

        -- reset strobe
        wait for 10 * clock_period;
        rst <= '0';

        loop
            last_din := din;

            -- write a new input to the DUT
            wr <= '1';
            wait until rising_edge(clk);
            wr <= '0';

            -- change din before the next test to check that the DUT samples at the right time
            din <= std_logic_vector(unsigned(din) + 1);
            wait until rising_edge(clk);

            -- immediate test
            assert dout = last_din
                report "DUT output doesn't equal last input immediately after write"
                severity failure;

            wait for 10 * clock_period;

            -- long time test
            assert dout = last_din
                report "DUT output doesn't equal last input after several clock periods"
                severity failure;

            -- exit the loop when we have tested all possible input values
            if dout = all_ones then
                exit;
            end if;

        end loop;

        print_test_ok;
        finish;
        
    end process;

end architecture;