library ieee;
use ieee.std_logic_1164.all;

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

    constant STAGE_NONE : integer := 0;
    constant STAGE_IF   : integer := 1;
    constant STAGE_ID   : integer := 2;
    constant STAGE_EX   : integer := 3;
    constant STAGE_MEM  : integer := 4;
    constant STAGE_WB   : integer := 5;

    -- Decodes the input registers required by the instruction and the stages at which these inputs are consumed.
    -- If an input is unneeded, the corresponding register is set to $0.
    procedure decode_instruction_input(instruction : in  std_logic_vector(31 downto 0);
                                       reg_in_1    : out std_logic_vector(4 downto 0);
                                       reg_in_2    : out std_logic_vector(4 downto 0);
                                       stage_in_1  : out integer;
                                       stage_in_2  : out integer);

    -- Decodes the output register used to store the result of the instruction and the stage at which this result is produced.
    -- If no output result is produced, the output register is set to $0.
    procedure decode_instruction_output(instruction : in  std_logic_vector(31 downto 0);
                                        reg_out     : out std_logic_vector(4 downto 0);
                                        stage_out   : out integer);

end package;

package body mips_instruction_set is
    procedure decode_instruction_input(instruction : in  std_logic_vector(31 downto 0);
                                       reg_in_1    : out std_logic_vector(4 downto 0);
                                       reg_in_2    : out std_logic_vector(4 downto 0);
                                       stage_in_1  : out integer;
                                       stage_in_2  : out integer) is
        variable op     : std_logic_vector(5 downto 0);
        variable rs, rt : std_logic_vector(4 downto 0);
        variable funct  : std_logic_vector(5 downto 0);
    begin
        op    := instruction(31 downto 26);
        rs    := instruction(25 downto 21);
        rt    := instruction(20 downto 16);
        funct := instruction(5 downto 0);

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_JR) then
                stage_in_1 := STAGE_ID;
                stage_in_2 := STAGE_NONE;
            else
                stage_in_1 := STAGE_EX;
                stage_in_2 := STAGE_EX;
            end if;
        elsif (op = OP_BEQ or op = OP_BNE) then
            stage_in_1 := STAGE_ID;
            stage_in_2 := STAGE_ID;
        elsif (op = OP_SW) then
            stage_in_1 := STAGE_EX;
            stage_in_2 := STAGE_MEM;
        else
            stage_in_1 := STAGE_EX;
            stage_in_2 := STAGE_EX;
        end if;

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_MFHI or funct = FUNCT_MFLO) then
                reg_in_1 := "00000";
                reg_in_2 := "00000";
            elsif (funct = FUNCT_SLL or funct = FUNCT_SRL or funct = FUNCT_SRA) then
                reg_in_1 := "00000";
                reg_in_2 := rt;
            elsif (funct = FUNCT_JR) then
                reg_in_1 := rs;
                reg_in_2 := "00000";
            else
                reg_in_1 := rs;
                reg_in_2 := rt;
            end if;
        elsif (op = OP_J or op = OP_JAL or op = OP_LUI) then
            reg_in_1 := "00000";
            reg_in_2 := "00000";
        elsif (op = OP_BEQ or op = OP_BNE or op = OP_SW) then
            reg_in_1 := rs;
            reg_in_2 := rt;
        else
            reg_in_1 := rs;
            reg_in_2 := "00000";
        end if;
    end procedure decode_instruction_input;

    procedure decode_instruction_output(instruction : in  std_logic_vector(31 downto 0);
                                        reg_out     : out std_logic_vector(4 downto 0);
                                        stage_out   : out integer) is
        variable op     : std_logic_vector(5 downto 0);
        variable rt, rd : std_logic_vector(4 downto 0);
        variable funct  : std_logic_vector(5 downto 0);
    begin
        op    := instruction(31 downto 26);
        rt    := instruction(20 downto 16);
        rd    := instruction(15 downto 11);
        funct := instruction(5 downto 0);

        if (op = OP_JAL) then
            stage_out := STAGE_EX;
        elsif (op = OP_LW) then
            stage_out := STAGE_WB;
        else
            stage_out := STAGE_MEM;
        end if;

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_MULT or funct = FUNCT_DIV or funct = FUNCT_JR) then
                reg_out := "00000";
            else
                reg_out := rd;
            end if;
        elsif (op = OP_J or op = OP_BEQ or op = OP_BNE or op = OP_SW) then
            reg_out := "00000";
        elsif (op = OP_JAL) then
            reg_out := "11111";         -- $ra
        else
            reg_out := rt;
        end if;
    end procedure decode_instruction_output;

end mips_instruction_set;
