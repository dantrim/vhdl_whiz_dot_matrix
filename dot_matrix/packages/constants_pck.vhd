package constants is
    -- lattice icestick has 12 MHz oscillator
    constant clock_frequency : real := 12.0e6; -- 12 MHz from Lattice

    -- UART baud rate
    constant baud_rate : natural := 115200;

    -- how long each led shall be lit in microseconds
    constant led_pulse_time_us : natural := 1000; -- 1 / (1000e-6 * 8) = 125 Hz

    -- deadband in microseconds subtracted from led_pulse_time_us
    constant led_deadband_time_us : natural := 10;
end package;