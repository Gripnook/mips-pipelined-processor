library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detector_tb is
end entity hazard_detector_tb;

architecture arch of hazard_detector_tb is
    -- test signals

    signal if_id  : std_logic_vector(31 downto 0);
    signal id_ex  : std_logic_vector(31 downto 0);
    signal ex_mem : std_logic_vector(31 downto 0);
    signal mem_wb : std_logic_vector(31 downto 0);
    signal stall  : std_logic;

    component hazard_detector
        port(
            if_id  : in  std_logic_vector(31 downto 0);
            id_ex  : in  std_logic_vector(31 downto 0);
            ex_mem : in  std_logic_vector(31 downto 0);
            mem_wb : in  std_logic_vector(31 downto 0);
            stall  : out std_logic);
    end component hazard_detector;

    procedure assert_equal(actual, expected : in std_logic_vector(63 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & to_string(expected) & " but was " & to_string(actual) severity error;
    end assert_equal;

    procedure assert_equal_bit(actual, expected : in std_logic; error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & to_string(expected) & " but was " & to_string(actual) severity error;
    end assert_equal_bit;

begin
    dut : hazard_detector
        port map(
            if_id  => if_id,
            id_ex  => id_ex,
            ex_mem => ex_mem,
            mem_wb => mem_wb,
            stall  => stall
        );

    test_process : process
        variable error_count : integer := 0;
    begin
        -------------- Data hazards ---------------
        report "Testing data hazards";

        -----------------------------------------------------
        ---------------------Test#1: X---------------------
        --This test performs X
        report "Test#1: X";
        if_id  <= (others => '0');
        id_ex  <= (others => '0');
        ex_mem <= (others => '0');
        mem_wb <= (others => '0');

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -------------- Control hazards ---------------
        report "Testing control hazards";

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
