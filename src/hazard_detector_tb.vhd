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

    constant NOP         : std_logic_vector(31 downto 0) := 6x"0" & 5x"0" & 5x"0" & 5x"0" & 5x"0" & 6x"22"; --R-Type
    constant ADDR1R0R0   : std_logic_vector(31 downto 0) := 6x"0" & 5x"0" & 5x"0" & 5x"1" & 5x"0" & 6x"22"; --R-Type
    constant ADDR0R1R1   : std_logic_vector(31 downto 0) := 6x"0" & 5x"1" & 5x"1" & 5x"0" & 5x"0" & 6x"22"; --R-Type
    constant ADDR0R31R31 : std_logic_vector(31 downto 0) := 6x"0" & 5x"1f" & 5x"1f" & 5x"0" & 5x"0" & 6x"22"; --R-Type
    constant BEQR0R0L0   : std_logic_vector(31 downto 0) := 6x"4" & 5x"0" & 5x"0" & 16x"0"; -- I-Type
    constant JL0         : std_logic_vector(31 downto 0) := 6x"2" & 26x"0"; -- J-Type
    constant JAL0        : std_logic_vector(31 downto 0) := 6x"3" & 26x"0"; -- J-Type

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
        ---------------------Test#1: NOP---------------------
        --This test performs NOP
        report "Test#1: NOP";
        if_id  <= NOP;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#2: ADD1---------------------
        --This test performs ADD1
        report "Test#2: ADD1";
        if_id  <= ADDR0R1R1;
        id_ex  <= ADDR1R0R0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3: ADD2---------------------
        --This test performs ADD2
        report "Test#3: ADD2";
        if_id  <= ADDR0R1R1;
        id_ex  <= NOP;
        ex_mem <= ADDR1R0R0;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3: ADD3---------------------
        --This test performs ADD3
        report "Test#3: ADD3";
        if_id  <= ADDR0R1R1;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= ADDR1R0R0;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -------------- Control hazards ---------------
        report "Testing control hazards";

        -----------------------------------------------------
        ---------------------Test#4: BEQ---------------------
        --This test performs BEQ
        report "Test#4: BEQ";
        if_id  <= BEQR0R0L0;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5: JAL1---------------------
        --This test performs JAL1
        report "Test#5: JAL1";
        if_id  <= ADDR0R31R31;
        id_ex  <= JAL0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------


        -----------------------------------------------------
        ---------------------Test#6: JAL2---------------------
        --This test performs JAL2
        report "Test#6: JAL2";
        if_id  <= ADDR0R31R31;
        id_ex  <= NOP;
        ex_mem <= JAL0;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#7: JAL3---------------------
        --This test performs JAL3
        report "Test#7: JAL3";
        if_id  <= ADDR0R31R31;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= JAL0;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
