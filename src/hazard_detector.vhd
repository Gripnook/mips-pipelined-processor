library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS_instruction_set.all;

entity hazard_detector is
    port(
        if_id  : in  std_logic_vector(31 downto 0);
        id_ex  : in  std_logic_vector(31 downto 0);
        ex_mem : in  std_logic_vector(31 downto 0);
        mem_wb : in  std_logic_vector(31 downto 0);
        stall  : out std_logic);
end entity hazard_detector;

architecture arch of hazard_detector is
    procedure decode_instruction(instr : in  std_logic_vector(31 downto 0);
                                 ro    : out std_logic_vector(4 downto 0);
                                 ri1   : out std_logic_vector(4 downto 0);
                                 ri2   : out std_logic_vector(4 downto 0)) is
        variable op         : std_logic_vector(5 downto 0);
        variable rs, rt, rd : std_logic_vector(4 downto 0);
        variable funct      : std_logic_vector(5 downto 0);
    begin
        op    := instr(31 downto 26);
        rs    := instr(25 downto 21);
        rt    := instr(20 downto 16);
        rd    := instr(15 downto 11);
        funct := instr(5 downto 0);

        if (op = OP_R_TYPE) then        -- R-Types
            if (funct = FUNCT_MULT or funct = FUNCT_DIV) then -- rs, rt format
                ro  := "00000";
                ri1 := rs;
                ri2 := rt;
            elsif (funct = FUNCT_MFHI or funct = FUNCT_MFLO) then -- rd format
                ro  := rd;
                ri1 := "00000";
                ri2 := "00000";
            elsif (funct = FUNCT_SLL or funct = FUNCT_SRL or funct = FUNCT_SRA) then -- rd, rt format
                ro  := rd;
                ri1 := rt;
                ri2 := rt;
            elsif (funct = FUNCT_JR) then -- rs format
                ro  := "00000";
                ri1 := rs;
                ri2 := rs;
            else                        -- rd, rs, rt format
                ro  := rd;
                ri1 := rs;
                ri2 := rt;
            end if;
        elsif (op = OP_J) then          -- J-Types
            ro  := "00000";
            ri1 := "00000";
            ri2 := "00000";
        elsif (op = OP_JAL) then
            ro  := "11111";
            ri1 := "00000";
            ri2 := "00000";
        else                            -- I-Types
            if (op = OP_LUI) then       -- rt format
                ro  := rt;
                ri1 := "00000";
                ri2 := "00000";
            elsif (op = OP_BEQ or op = OP_BNE) then
                ro  := "00000";
                ri1 := rs;
                ri2 := rt;
            elsif (op = OP_SW) then
                ro  := "00000";
                ri1 := rt;
                ri2 := rs;
            else                        -- rt, rs format
                ro  := rt;
                ri1 := rs;
                ri2 := rs;
            end if;
        end if;
    end procedure decode_instruction;

begin
    hazard_detection : process(if_id, id_ex, ex_mem, mem_wb)
        -- Pipe-line registers
        -- 1 = if_id
        -- 2 = id_ex
        -- 3 = ex_mem
        -- 4 = mem_wb

        -- Output registers for each decoded instruction
        variable o1, o2, o3, o4 : std_logic_vector(4 downto 0);

        -- Input registers for each decoded instruction
        variable i11, i12, i21, i22 : std_logic_vector(4 downto 0);
        variable i31, i32, i41, i42 : std_logic_vector(4 downto 0);

    begin
        decode_instruction(if_id, o1, i11, i12);
        decode_instruction(id_ex, o2, i21, i22);
        decode_instruction(ex_mem, o3, i31, i32);
        decode_instruction(mem_wb, o4, i41, i42);

        stall <= '0';                   -- Do not stall

        if (o2 /= "00000") then         -- Read-After-Write hazards detection (True Dependence)
            if (o2 = i11 or o2 = i12) then -- 3 stall cycles
                stall <= '1';
            end if;
        end if;
        if (o3 /= "00000") then
            if (o3 = i11 or o3 = i12) then -- 2 stall cycles
                stall <= '1';
            end if;
        end if;
        if (o4 /= "00000") then
            if (o4 = i11 or o4 = i12) then -- 1 stall cycle
                stall <= '1';
            end if;
        end if;
    end process;

end architecture arch;
