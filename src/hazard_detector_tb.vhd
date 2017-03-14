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
    constant BEQR1R0L0   : std_logic_vector(31 downto 0) := 6x"4" & 5x"1" & 5x"0" & 16x"0"; -- I-Type
    constant JL0         : std_logic_vector(31 downto 0) := 6x"2" & 26x"0"; -- J-Type
    constant JAL0        : std_logic_vector(31 downto 0) := 6x"3" & 26x"0"; -- J-Type
    constant LWR1        : std_logic_vector(31 downto 0) := 6x"23" & 5x"0" & 5x"1" & 16x"4";
    constant SWR1        : std_logic_vector(31 downto 0) := 6x"2B" & 5x"0" & 5x"1" & 16x"4";

    component hazard_detector
        port(
            id_instruction  : in  std_logic_vector(31 downto 0);
            ex_instruction  : in  std_logic_vector(31 downto 0);
            mem_instruction : in  std_logic_vector(31 downto 0);
            wb_instruction : in  std_logic_vector(31 downto 0);
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
            id_instruction  => if_id,
            ex_instruction  => id_ex,
            mem_instruction => ex_mem,
            wb_instruction => mem_wb,
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
        ---------------------Test#2-1: ADD1---------------------
        --This test performs ADD1
        report "Test#2-1: ADD1";
        if_id  <= ADDR0R1R1;
        id_ex  <= ADDR1R0R0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#2-2: ADD2---------------------
        --This test performs ADD2
        report "Test#2-2: ADD2";
        if_id  <= ADDR0R1R1;
        id_ex  <= NOP;
        ex_mem <= ADDR1R0R0;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#2-3: ADD3---------------------
        --This test performs ADD3
        report "Test#2-3: ADD3";
        if_id  <= ADDR0R1R1;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= ADDR1R0R0;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -------------- Control hazards ---------------
        report "Testing control hazards";

        -----------------------------------------------------
        ---------------------Test#3-1: BEQ---------------------
        --This test performs BEQ
        report "Test#3-1: BEQ";
        if_id  <= BEQR1R0L0;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3-2: BEQ---------------------
        --This test performs BEQ
        report "Test#3-2: BEQ";
        if_id  <= ADDR1R0R0;
        id_ex  <= BEQR1R0L0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3-3: BEQ---------------------
        --This test performs BEQ
        report "Test#3-3: BEQ";
        if_id  <= ADDR0R1R1;
        id_ex  <= BEQR1R0L0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3-4: BEQ---------------------
        --This test performs BEQ
        report "Test#3-4: BEQ";
        if_id  <= BEQR1R0L0;
        id_ex  <= ADDR1R0R0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3-5: BEQ---------------------
        --This test performs BEQ
        report "Test#3-5: BEQ";
        if_id  <= BEQR1R0L0;
        id_ex  <= NOP;
        ex_mem <= ADDR1R0R0;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3-6: BEQ---------------------
        --This test performs BEQ
        report "Test#3-6: BEQ";
        if_id  <= BEQR1R0L0;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= ADDR1R0R0;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#4-1: JAL1---------------------
        --This test performs JAL1
        report "Test#4-1: JAL1";
        if_id  <= ADDR0R31R31;
        id_ex  <= JAL0;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#4-2: JAL2---------------------
        --This test performs JAL2
        report "Test#4-2: JAL2";
        if_id  <= ADDR0R31R31;
        id_ex  <= NOP;
        ex_mem <= JAL0;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#4-3: JAL3---------------------
        --This test performs JAL3
        report "Test#4-3: JAL3";
        if_id  <= ADDR0R31R31;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= JAL0;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-1: LW/ALU---------------------
        --This test performs LW then ALU
        report "Test#5-1: LW";
        if_id  <= ADDR1R0R0;
        id_ex  <= LWR1;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-2: LW/ALU---------------------
        --This test performs LW then ALU
        report "Test#5-2: LW";
        if_id  <= ADDR1R0R0;
        id_ex  <= NOP;
        ex_mem <= LWR1;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-3: LW/ALU---------------------
        --This test performs LW then ALU
        report "Test#5-3: LW";
        if_id  <= ADDR1R0R0;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= LWR1;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-4: LW---------------------
        --This test performs LW
        report "Test#5-4: LW";
        if_id  <= LWR1;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-5: LW/SW---------------------
        --This test performs LW/SW
        report "Test#5-5: LW";
        if_id  <= LWR1;
        id_ex  <= SWR1;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-6: LW/SW---------------------
        --This test performs LW/SW
        report "Test#5-6: LW";
        if_id  <= LWR1;
        id_ex  <= NOP;
        ex_mem <= SWR1;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5-7: LW/SW---------------------
        --This test performs LW/SW
        report "Test#5-7: LW";
        if_id  <= LWR1;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= SWR1;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ------------------Test#5-8: LW/BEQ-------------------
        --This test performs LW then Branch
        report "Test#5-8: LW";
        if_id  <= BEQR1R0L0;
        id_ex  <= LWR1;
        ex_mem <= NOP;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '1', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ----------------Test#5-9: LW/BEQ---------------------
        --This test performs LW then Branch
        report "Test#5-9: LW";
        if_id  <= BEQR1R0L0;
        id_ex  <= NOP;
        ex_mem <= LWR1;
        mem_wb <= NOP;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ----------------Test#5-10: LW/BEQ--------------------
        --This test performs LW then Branch
        report "Test#5-10: LW";
        if_id  <= BEQR1R0L0;
        id_ex  <= NOP;
        ex_mem <= NOP;
        mem_wb <= LWR1;

        wait for 1 ns;

        assert_equal_bit(stall, '0', error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
