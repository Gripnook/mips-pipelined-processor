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

    procedure decode_instruction_input(instr : in  std_logic_vector(31 downto 0);
                                       ri1   : out std_logic_vector(4 downto 0);
                                       ri2   : out std_logic_vector(4 downto 0);
                                       t1    : out integer;
                                       t2    : out integer);

    procedure decode_instruction_output(instr : in  std_logic_vector(31 downto 0);
                                        ro    : out std_logic_vector(4 downto 0);
                                        t     : out integer);

end package;

package body mips_instruction_set is

    procedure decode_instruction_input(instr : in  std_logic_vector(31 downto 0);
                                       ri1   : out std_logic_vector(4 downto 0);
                                       ri2   : out std_logic_vector(4 downto 0);
                                       t1    : out integer;
                                       t2    : out integer) is
        variable op     : std_logic_vector(5 downto 0);
        variable rs, rt : std_logic_vector(4 downto 0);
        variable funct  : std_logic_vector(5 downto 0);
    begin
        op    := instr(31 downto 26);
        rs    := instr(25 downto 21);
        rt    := instr(20 downto 16);
        funct := instr(5 downto 0);

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_JR) then
                t1 := STAGE_ID;
                t2 := STAGE_NONE;
            else
                t1 := STAGE_EX;
                t2 := STAGE_EX;
            end if;
        elsif (op = OP_BEQ or op = OP_BNE) then
            t1 := STAGE_ID;
            t2 := STAGE_ID;
        elsif (op = OP_SW) then
            t1 := STAGE_EX;
            t2 := STAGE_MEM;
        else
            t1 := STAGE_EX;
            t2 := STAGE_EX;
        end if;

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_MFHI or funct = FUNCT_MFLO) then
                ri1 := "00000";
                ri2 := "00000";
            elsif (funct = FUNCT_SLL or funct = FUNCT_SRL or funct = FUNCT_SRA) then
                ri1 := "00000";
                ri2 := rt;
            elsif (funct = FUNCT_JR) then
                ri1 := rs;
                ri2 := "00000";
            else
                ri1 := rs;
                ri2 := rt;
            end if;
        elsif (op = OP_J or op = OP_JAL or op = OP_LUI) then
            ri1 := "00000";
            ri2 := "00000";
        elsif (op = OP_BEQ or op = OP_BNE or op = OP_SW) then
            ri1 := rs;
            ri2 := rt;
        else
            ri1 := rs;
            ri2 := "00000";
        end if;
    end procedure decode_instruction_input;

    procedure decode_instruction_output(instr : in  std_logic_vector(31 downto 0);
                                        ro    : out std_logic_vector(4 downto 0);
                                        t     : out integer) is
        variable op     : std_logic_vector(5 downto 0);
        variable rt, rd : std_logic_vector(4 downto 0);
        variable funct  : std_logic_vector(5 downto 0);
    begin
        op    := instr(31 downto 26);
        rt    := instr(20 downto 16);
        rd    := instr(15 downto 11);
        funct := instr(5 downto 0);

        if (op = OP_JAL) then
            t := STAGE_EX;
        elsif (op = OP_LW) then
            t := STAGE_WB;
        else
            t := STAGE_MEM;
        end if;

        if (op = OP_R_TYPE) then
            if (funct = FUNCT_MULT or funct = FUNCT_DIV or funct = FUNCT_JR) then
                ro := "00000";
            else
                ro := rd;
            end if;
        elsif (op = OP_J or op = OP_BEQ or op = OP_BNE or op = OP_SW) then
            ro := "00000";
        elsif (op = OP_JAL) then
            ro := "11111"; -- $ra
        else
            ro := rt;
        end if;
    end procedure decode_instruction_output;

end mips_instruction_set;
