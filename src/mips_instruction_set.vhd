library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mips_instruction_set is
    constant OP_R_TYPE : std_logic_vector(5 downto 0) := "000000";
    constant OP_ADDI   : std_logic_vector(5 downto 0) := "001000";
    constant OP_SLTI   : std_logic_vector(5 downto 0) := "001010";
    constant OP_ANDI   : std_logic_vector(5 downto 0) := "001100";
    constant OP_ORI    : std_logic_vector(5 downto 0) := "001101";
    constant OP_XORI   : std_logic_vector(5 downto 0) := "001110";
    constant OP_LUI    : std_logic_vector(5 downto 0) := "001111";
    constant OP_LW     : std_logic_vector(5 downto 0) := "100011";
    constant OP_SW     : std_logic_vector(5 downto 0) := "101011";
    constant OP_BEQ    : std_logic_vector(5 downto 0) := "000100";
    constant OP_BNE    : std_logic_vector(5 downto 0) := "000101";
    constant OP_J      : std_logic_vector(5 downto 0) := "000010";
    constant OP_JAL    : std_logic_vector(5 downto 0) := "000011";

    constant FUNCT_ADD  : std_logic_vector(5 downto 0) := "100000";
    constant FUNCT_SUB  : std_logic_vector(5 downto 0) := "100010";
    constant FUNCT_MULT : std_logic_vector(5 downto 0) := "011000";
    constant FUNCT_DIV  : std_logic_vector(5 downto 0) := "011010";
    constant FUNCT_SLT  : std_logic_vector(5 downto 0) := "101010";
    constant FUNCT_AND  : std_logic_vector(5 downto 0) := "100100";
    constant FUNCT_OR   : std_logic_vector(5 downto 0) := "100101";
    constant FUNCT_NOR  : std_logic_vector(5 downto 0) := "100111";
    constant FUNCT_XOR  : std_logic_vector(5 downto 0) := "100110";
    constant FUNCT_MFHI : std_logic_vector(5 downto 0) := "010000";
    constant FUNCT_MFLO : std_logic_vector(5 downto 0) := "010010";
    constant FUNCT_SLL  : std_logic_vector(5 downto 0) := "000000";
    constant FUNCT_SRL  : std_logic_vector(5 downto 0) := "000010";
    constant FUNCT_SRA  : std_logic_vector(5 downto 0) := "000011";
    constant FUNCT_JR   : std_logic_vector(5 downto 0) := "001000";

end package;
