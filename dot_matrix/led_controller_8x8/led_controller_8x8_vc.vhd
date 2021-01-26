library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library dot_matrix;
use dot_matrix.types.all;

entity led_controller_8x8_vc is
  generic (
      PULSE_TIME_US : natural;
      DEADBAND_TIME_US : natural
  );
  port (
      enable : in boolean;
      led8x8_template : in matrix_type;
      led8x8_output : out matrix_type;
      test_failed : out boolean;
      rows : in std_logic_vector;
      cols : in std_logic_vector
  );
end led_controller_8x8_vc; 

architecture sim of led_controller_8x8_vc is

  -- Types used for verification of LED lighting pattern
  type verification_col_type is array (col_range) of integer;
  type matrix_verification_type is array (row_range) of verification_col_type;

  -- Get the event status of a vector member
  function get_event(
    signal vec : in std_logic_vector;
    constant index : natural
  ) return boolean is
  begin
    case index is
      when  0 => return vec(0)'event;
      when  1 => return vec(1)'event;
      when  2 => return vec(2)'event;
      when  3 => return vec(3)'event;
      when  4 => return vec(4)'event;
      when  5 => return vec(5)'event;
      when  6 => return vec(6)'event;
      when  7 => return vec(7)'event;
      when others =>
        assert false
          report "Index " & integer'image(index) & " is not handled by this function"
          severity failure;
        return false;
    end case;
  end function get_event;

  function get_last_value(
    signal vec : in std_logic_vector;
    constant index : natural
  ) return std_logic is
  begin
    case index is
      when  0 => return vec(0)'last_value;
      when  1 => return vec(1)'last_value;
      when  2 => return vec(2)'last_value;
      when  3 => return vec(3)'last_value;
      when  4 => return vec(4)'last_value;
      when  5 => return vec(5)'last_value;
      when  6 => return vec(6)'last_value;
      when  7 => return vec(7)'last_value;
      when others =>
        assert false
          report "Index " & integer'image(index) & " is not handled by this function"
          severity failure;
        return 'X';
    end case;
  end function get_last_value;

  function get_last_event(
    signal vec : in std_logic_vector;
    constant index : natural
  ) return time is
  begin
    case index is
      when  0 => return vec(0)'last_event;
      when  1 => return vec(1)'last_event;
      when  2 => return vec(2)'last_event;
      when  3 => return vec(3)'last_event;
      when  4 => return vec(4)'last_event;
      when  5 => return vec(5)'last_event;
      when  6 => return vec(6)'last_event;
      when  7 => return vec(7)'last_event;
      when others =>
        assert false
          report "Index " & integer'image(index) & " is not handled by this function"
          severity failure;
        return time'high;
    end case;
  end function get_last_event;

  -- Mark any LED indicated as active in <rows> and <cols> as touched
  -- A lit LED is marked by incrementing its number in <touched>.
  procedure touch_leds(
    signal rows : in std_logic_vector;
    signal cols : in std_logic_vector;
    signal touched : inout matrix_verification_type
  ) is
  begin
    for r in rows'range loop
      for c in cols'range loop
        if (get_event(rows, r) or get_event(cols, c)) and (rows(r) = '1' and cols(c) = '1') then
          touched(r)(c) <= touched(r)(c) + 1;
        end if;
      end loop;
    end loop;
  end procedure touch_leds;

  procedure check_leds(
    constant template : matrix_type;
    constant touched : matrix_verification_type;
    signal failed : out boolean
  ) is
    variable first_num : integer := 0;
  begin
    failed <= false;

    for r in template'range loop
      for c in template(r)'range loop

        -- check that the pattern of the lit LEDs matches the template
        if not ((template(r)(c) = '1') = (touched(r)(c) /= 0)) then
          assert false
            report "Mismatch for row: " & integer'image(r) & ", col: " & integer'image(c) &
              ", template: " & std_logic'image(template(r)(c)) & ", touched: " & integer'image(touched(r)(c))
            severity error; -- don't want to stop the testbench here
          failed <= true;
        end if;

        -- check that all active LEDs are being lit the same number of times,
        -- allowing a max difference of 1 to accomodate for random starting condition
        first_num := touched(r)(c) when first_num = 0;
        if touched(r)(c) /= 0 and abs(first_num - touched(r)(c)) > 1 then
          assert false
            report "touched(" & integer'image(r) & ")(" & integer'image(c) & ") has been lit " & integer'image(touched(r)(c)) &
            " times while the first lit LED was lit " & integer'image(first_num) & " times"
            severity error;
          failed <= true;
        end if;

      end loop;
    end loop;
  end procedure check_leds;

  function to_matrix_type(matrix_int : matrix_verification_type) return matrix_type is
    variable ret : matrix_type := (others => (others => '0'));
  begin
    for r in matrix_int'range loop
      for c in matrix_int(r)'range loop
        ret(r)(c) := '1' when matrix_int(r)(c) > 0 else '0';
      end loop;
    end loop;
    return ret;
  end function to_matrix_type;

  -- convert integer values denoting microseconds to time values
  constant led_pulse_time : time := 1 us * PULSE_TIME_US;
  constant led_deadband_time : time := 1 us * DEADBAND_TIME_US;

  -- max allowed deviation from the time values
  constant max_deviation_ratio : real := 0.1;

  constant max_pulse_time : time := led_pulse_time * (1.0 + max_deviation_ratio) - led_deadband_time;
  constant min_pulse_time : time := led_pulse_time * (1.0 - max_deviation_ratio) - led_deadband_time;

  -- don't worry about max, since we care only about min -- if deadband is too small we can experience light leakage
  constant min_deadband_time : time := led_deadband_time * (1.0 - max_deviation_ratio);

  procedure check_pulse_time(
    signal vec : in std_logic_vector;
    signal vec_delta : in std_logic_vector;
    constant vec_name : string;
    signal failed : out boolean
  ) is
    variable duration : time;
  begin
    for i in vec'range loop
      if get_event(vec, i) then

        -- if this is a transition from '1' to '0'
        if get_last_value(vec, i) = '1' and vec(i) = '0' then

          -- check the high period pulse duration
          duration := get_last_event(vec_delta, i);
          if duration < min_pulse_time or duration > max_pulse_time then
            assert false
              report "Pulse time " & time'image(duration) & " for " & vec_name & "(" & integer'image(i) & ")" &
                " is outside of min-max range: " & time'image(min_pulse_time) & " - " & time'image(max_pulse_time)
              severity error;
            failed <= true;
          end if;
        end if;

        -- if this is a transition from '0' to '1'
        if get_last_value(vec, i) = '0' and vec(i) = '1' then

          -- deadband period should be a period in which all leds are unlit
          if to_integer(unsigned(vec_delta)) /= 0 then
            assert false
              report vec_name & " was not all zeros in the deadband period"
              severity error;
            failed <= true;
          end if;

          -- check that the duration of the deadband period is sufficient
          duration := vec_delta'last_event;
          if duration < min_deadband_time then
            assert false
              report "Deadband time " & time'image(duration) & " for " & vec_name & " is less than min: " & time'image(min_deadband_time)
              severity error;
            failed <= true;
          end if;

        end if;
      end if;
    end loop;
  end procedure check_pulse_time;

  -- for keeping track of how many times each LED has been lit
  signal touched_leds : matrix_verification_type;

  -- the rows signal delayed by one delta cycle
  signal rows_delta : rows'subtype;
  signal cols_delta : cols'subtype;

  -- fail indicators from different tests
  signal pattern_test_failed : boolean := false;
  signal pulse_duration_test_failed : boolean := false;

begin

  -- concurrent assignment
  test_failed <= pattern_test_failed or pulse_duration_test_failed;

  -- delay by 1 delta cycle
  -- rows_delta gets delayed by 1 delta cycle
  rows_delta <= rows;
  cols_delta <= cols;

  PROC_CHECK_PATTERN : process
  begin

    -- Reset the counters before each test
    touched_leds <= (others => (others => 0));

    -- this event triggers verification of the output
    wait until enable;

    pattern_test_failed <= false;

    while enable loop

      -- mark any lit LEDs as touched
      touch_leds(rows, cols, touched_leds);

      -- wait until the DUT output changes, or until the test is over
      -- wait on any of these signals changing
      wait on rows, cols, enable;
    end loop;

    -- check that the touched LEDs match the template character
    check_leds(led8x8_template, touched_leds, pattern_test_failed);

    -- output the rendered character at the end of the test
    led8x8_output <= to_matrix_type(touched_leds);
    
  end process; -- PROC_CHECK_PATTERN


  PROC_CHECK_PULSE_TIME : process
  begin

    -- test start trigger
    wait until enable;
    pulse_duration_test_failed <= false;

    while enable loop

      check_pulse_time(
        rows,
        rows_delta,
        string'(rows'simple_name),
        pulse_duration_test_failed
      );

      check_pulse_time(
        cols,
        cols_delta,
        string'(rows'simple_name),
        pulse_duration_test_failed
      );

      wait on rows, cols, enable;
    end loop;
    
  end process; -- PROC_CHECK_PULSE_TIME

end architecture;