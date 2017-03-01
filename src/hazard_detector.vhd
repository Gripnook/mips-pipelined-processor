library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detector is
    port(
        if_id  : in  std_logic_vector(31 downto 0);
        id_ex  : in  std_logic_vector(31 downto 0);
        ex_mem : in  std_logic_vector(31 downto 0);
        mem_wb : in  std_logic_vector(31 downto 0);
        stall  : out std_logic);
end entity hazard_detector;

architecture arch of hazard_detector is
    procedure decode_instruction(instr : in    std_logic_vector(31 downto 0);
                                 ro    : inout std_logic_vector(4 downto 0);
                                 ri1   : inout std_logic_vector(4 downto 0);
                                 ri2   : inout std_logic_vector(4 downto 0);
                                 b     : inout std_logic) is
        variable op         : std_logic_vector(5 downto 0);
        variable rs, rt, rd : std_logic_vector(4 downto 0);
        variable funct      : std_logic_vector(5 downto 0);
    begin
        op    := instr(31 downto 26);
        rs    := instr(25 downto 21);
        rt    := instr(20 downto 16);
        rd    := instr(15 downto 11);
        funct := instr(5 downto 0);
        b     := '0';

        if (op = 6x"0") then            -- R-Types
            if (funct = 6x"18" or funct = 6x"1a") then -- rs, rt format
                ro  := 5x"0";
                ri1 := rs;
                ri2 := rt;
            elsif (funct = 6x"10" or funct = 6x"12") then -- rd format
                ro  := rd;
                ri1 := 5x"0";
                ri2 := 5x"0";
            elsif (funct = 6x"0" or funct = 6x"2" or funct = 6x"3") then -- rd, rt format
                ro  := rd;
                ri1 := rt;
                ri2 := rt;
            elsif (funct = 6x"8") then  -- rs format
                ro  := 5x"0";
                ri1 := rs;
                ri2 := rs;
            else                        -- rd, rs, rt format
                ro  := rd;
                ri1 := rs;
                ri2 := rt;
            end if;
        elsif (op = 6x"2" or op = 6x"3") then -- J-Types
            ro  := 5x"0";
            ri1 := 5x"0";
            ri2 := 5x"0";
        else                            -- I-Types
            if (op = 6x"f") then        -- rt format
                ro  := rt;
                ri1 := 5x"0";
                ri2 := 5x"0";
            elsif (op = 6x"4" or op = 6x"5") then -- beq, bne
                ro  := 5x"0";
                ri1 := rs;
                ri2 := rt;
                b   := '1';
            elsif (op = 6x"2b") then    -- store
                ro  := 5x"0";
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

        -- Tell whether an instruction is a branch or not
        variable b1, b2, b3, b4 : std_logic;
    begin
        decode_instruction(if_id, o1, i11, i12, b1);
        decode_instruction(id_ex, o2, i21, i22, b2);
        decode_instruction(ex_mem, o3, i31, i32, b3);
        decode_instruction(mem_wb, o4, i41, i42, b4);

        stall <= '0';                   -- Do not stall

        if (b1 = '1') then              -- Branch detected, 1 stall cycle
            stall <= '1';
        elsif (o2 /= 5x"0") then        -- Read-After-Write hazards detection (True Dependence)
            if (o2 = i11 or o2 = i12) then -- 3 stall cycles
                stall <= '1';
            end if;
        elsif (o3 /= 5x"0") then
            if (o3 = i11 or o3 = i12) then -- 2 stall cycles
                stall <= '1';
            end if;
        elsif (o4 /= 5x"0") then
            if (o4 = i11 or o4 = i12) then -- 1 stall cycle
                stall <= '1';
            end if;
        end if;
    end process;

end architecture arch;
