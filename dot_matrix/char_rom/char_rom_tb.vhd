library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- library "std" is always available
use std.env.finish;
use std.textio.all;

library dot_matrix;
use dot_matrix.types.all;
use dot_matrix.charmap.all;

library dot_matrix_sim;
use dot_matrix_sim.sim_subprograms.all;

entity char_rom_tb is
end char_rom_tb; 

architecture sim of char_rom_tb is

    -- DUT signals
    signal clk : std_logic := '1'; -- start off the clock at a known value
    signal addr : char_range;
    signal dout : matrix_type;

begin

    -- usually keep the concurrent/boilerplate statements at the top
    gen_clock(clk);

    DUT : entity dot_matrix.char_rom(rtl)
    port map (
        clk => clk,
        addr => addr,
        dout => dout
    );

    -- we don't use sensitivity lists in testbenches, we use wait statements
    PROC_SEQUENCE : process
        variable str : line;
    begin

        -- wait for known time, to let the other entities settle
        for i in  1 to 10 loop
            wait until rising_edge(clk);
        end loop;

        -- loop over the full range of characters
        for i in char_range loop

            -- set the DUT input
            addr <= i;

            -- the ROM shifts in the address after the next rising edge
            wait until rising_edge(clk);
            -- the output is available one clock cycle after loading in the address
            wait until rising_edge(clk);

            if dout /= charmap(i) then
                write(str, string'("dout:"));
                writeline(output, str);
                print_char(dout);
                write(str, string'("expected:"));
                writeline(output, str);
                print_char(charmap(i));
                assert false
                    report "DUT dout != TB charmap_val: " &
                        " for i=" & integer'image(i) &
                        " (ASCII: " & character'val(i) & ")"
                    severity failure;
            end if;


        end loop;

        print_test_ok;
        finish;
        
    end process;

end architecture;