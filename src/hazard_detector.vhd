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
        decode_instruction_input(if_id, i11, i12);
        decode_instruction_input(id_ex, i21, i22);
        decode_instruction_input(ex_mem, i31, i32);
        decode_instruction_input(mem_wb, i41, i42);
        decode_instruction_output(if_id, o1);
        decode_instruction_output(id_ex, o2);
        decode_instruction_output(ex_mem, o3);
        decode_instruction_output(mem_wb, o4);

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
