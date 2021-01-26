library ieee;
use ieee.std_logic_1164.all;

package types is

    subtype row_range is natural range 0 to 7;
    subtype col_range is natural range 7 downto 0;

    -- represents the 8x8 LED matrix
    type matrix_type is array (row_range) of std_logic_vector(col_range);

    -- the addressable ASCII range
    subtype char_range is natural range 0 to 127;

    -- ROM type
    type charmap_type is array(char_range) of matrix_type;
    
end package;