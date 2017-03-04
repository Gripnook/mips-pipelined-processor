library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end entity alu_tb;

architecture arch of alu_tb is
    -- test signals

    signal a          : std_logic_vector(31 downto 0);
    signal b          : std_logic_vector(31 downto 0);
    signal opcode     : std_logic_vector(5 downto 0);
    signal shamt      : std_logic_vector(4 downto 0);
    signal funct      : std_logic_vector(5 downto 0);
    signal alu_output : std_logic_vector(63 downto 0);

    component alu
        port(
            a          : in  std_logic_vector(31 downto 0);
            b          : in  std_logic_vector(31 downto 0);
            instr      : in  std_logic_vector(31 downto 0);
            output     : out std_logic_vector(63 downto 0));
    end component alu;

    procedure assert_equal(actual, expected : in std_logic_vector(63 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & to_string(expected) & " but was " & to_string(actual) severity error;
    end assert_equal;

begin
    dut : alu
        port map(
            a          => a,
            b          => b,
            instr(31 downto 26) => opcode,
            instr(10 downto 6 ) => shamt,
            instr(5  downto 0 ) => funct,
            instr(25 downto 11) => "000000000000000", --not used in test
            output => alu_output
        );

    test_process : process
        variable error_count : integer := 0;
    begin
        -------------- Arithmetic instructions---------------
        report "Testing arithmetic instructions";

        -----------------------------------------------------
        ---------------------Test#1: add---------------------
        --This test performs the add operation on the alu
        report "Test#1: add";
        a      <= (others => '0');
        b      <= (others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"20";

        wait for 1 ns;

        assert_equal(alu_output, 64x"0000000000000000", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#2: sub---------------------
        --This test performs the sub operation on the alu
        report "Test#2: sub";
        a      <= (others => '1');
        b      <= (others => '1');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"22";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000000", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#3: addi---------------------
        --This test performs the addi operation on the alu
        report "Test#3: addi";
        a      <= (others => '1');
        b      <= (others => '0');
        opcode <= 6x"8";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#4: mult---------------------
        --This test performs the mult operation on the alu
        report "Test#4: mult";
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"18";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#5: div---------------------
        --This test performs the div operation on the alu
        report "Test#5: div";
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"1a";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#6: slt---------------------
        --This test performs the slt operation on the alu
        report "Test#6: slt";
        a      <= (others => '0');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"2a";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000001", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#7: slti---------------------
        --This test performs the slti operation on the alu
        report "Test#7: slti";
        a      <= (others => '0');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"a";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000001", error_count);
        -----------------------------------------------------

        ----------------- Logical instructions---------------
        report "Testing logical instructions";

        -----------------------------------------------------
        ---------------------Test#8: and---------------------
        --This test performs the and operation on the alu
        report "Test#8: and";
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"24";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000001", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#9: or---------------------
        --This test performs the or operation on the alu
        report "Test#9: or";
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"25";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#10: nor---------------------
        --This test performs the nor operation on the alu
        report "Test#10: nor";
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"27";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000000", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#11: xor---------------------
        --This test performs the xor operation on the alu
        report "Test#11: xor";
        a      <= (others => '1');
        b      <= (others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"26";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#12: andi---------------------
        --This test performs the andi operation on the alu
        report "Test#12: andi";
        a      <= (others => '1');
        b      <= (others => '0');
        opcode <= 6x"c";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000000", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#13: ori---------------------
        --This test performs the ori operation on the alu
        report "Test#13: ori";
        a      <= (others => '1');
        b      <= (others => '0');
        opcode <= 6x"d";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#14: xori---------------------
        --This test performs the xori operation on the alu
        report "Test#14: xori";
        a      <= (others => '1');
        b      <= (others => '0');
        opcode <= 6x"e";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        ----------------- Transfer instructions--------------
        report "Testing transfer instructions";

        -----------------------------------------------------
        ---------------------Test#15: mfhi---------------------
        --This test performs the mfhi operation on the alu
        report "Test#15: mfhi";

        -- Do a mul
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"18";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);

        -- Do a mfhi
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"10";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000000", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#16: mflo---------------------
        --This test performs the mflo operation on the alu
        report "Test#16: mflo";

        -- Do a mul
        a      <= (others => '1');
        b      <= (0 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"18";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);

        -- Do a mflo
        opcode <= 6x"0";
        shamt  <= 5x"0";
        funct  <= 6x"12";

        wait for 1 ns;

        assert_equal(alu_output, x"00000000FFFFFFFF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#17: lui---------------------
        --This test performs the lui operation on the alu
        report "Test#17: lui";
        b      <= (0 => '1', others => '0');
        opcode <= 6x"f";
        shamt  <= 5x"0";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000010000", error_count);
        -----------------------------------------------------

        ----------------- Shift instructions-----------------
        report "Testing shift instructions";

        -----------------------------------------------------
        ---------------------Test#18: sll---------------------
        --This test performs the sll operation on the alu
        report "Test#18: sll";
        b      <= (2 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"1";
        funct  <= 6x"0";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000008", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#19: srl---------------------
        --This test performs the srl operation on the alu
        report "Test#19: srl";
        b      <= (2 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"1";
        funct  <= 6x"2";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000002", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        ---------------------Test#20: sra---------------------
        --This test performs the sra operation on the alu
        report "Test#20: sra";
        b      <= (2 => '1', others => '0');
        opcode <= 6x"0";
        shamt  <= 5x"1";
        funct  <= 6x"3";

        wait for 1 ns;

        assert_equal(alu_output, x"0000000000000002", error_count);
        -----------------------------------------------------

        ----------------- Memory instructions----------------
        report "Testing memory instructions";

        ----------------- Control-flow instructions----------------
        report "Testing control-flow instructions";

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
