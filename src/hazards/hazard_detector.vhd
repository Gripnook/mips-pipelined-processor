library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_instruction_set.all;

entity hazard_detector is
    port(id_instruction  : in  std_logic_vector(31 downto 0);
         ex_instruction  : in  std_logic_vector(31 downto 0);
         mem_instruction : in  std_logic_vector(31 downto 0);
         wb_instruction  : in  std_logic_vector(31 downto 0);
         stall           : out std_logic);
end hazard_detector;

architecture arch of hazard_detector is
    constant FORWARDING : std_logic := '1'; -- Enables data forwarding

begin
    hazard_detection : process(id_instruction, ex_instruction, mem_instruction, wb_instruction)

        -- Input registers and consumption stages for each decoded instruction
        variable id_reg_in_1, id_reg_in_2     : std_logic_vector(4 downto 0);
        variable id_stage_in_1, id_stage_in_2 : integer;

        -- Output registers and production stages for each decoded instruction
        variable ex_reg_out, mem_reg_out, wb_reg_out       : std_logic_vector(4 downto 0);
        variable ex_stage_out, mem_stage_out, wb_stage_out : integer;

        -- Number of stages left until production of outputs or consumption of inputs
        variable prod_stages_left                       : integer;
        variable cons_stages_left_1, cons_stages_left_2 : integer;

    begin
        decode_instruction_input(id_instruction, id_reg_in_1, id_reg_in_2, id_stage_in_1, id_stage_in_2);
        decode_instruction_output(ex_instruction, ex_reg_out, ex_stage_out);
        decode_instruction_output(mem_instruction, mem_reg_out, mem_stage_out);
        decode_instruction_output(wb_instruction, wb_reg_out, wb_stage_out);

        cons_stages_left_1 := id_stage_in_1 - STAGE_ID;
        cons_stages_left_2 := id_stage_in_2 - STAGE_ID;

        stall <= '0';                   -- default output

        if (ex_reg_out /= "00000") then
            prod_stages_left := ex_stage_out - STAGE_EX;
            if (ex_reg_out = id_reg_in_1 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_1)) then
                stall <= '1';
            end if;
            if (ex_reg_out = id_reg_in_2 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_2)) then
                stall <= '1';
            end if;
        end if;

        if (mem_reg_out /= "00000") then
            prod_stages_left := mem_stage_out - STAGE_MEM;
            if (mem_reg_out = id_reg_in_1 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_1)) then
                stall <= '1';
            end if;
            if (mem_reg_out = id_reg_in_2 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_2)) then
                stall <= '1';
            end if;
        end if;

        if (wb_reg_out /= "00000") then
            prod_stages_left := wb_stage_out - STAGE_WB;
            if (wb_reg_out = id_reg_in_1 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_1)) then
                stall <= '1';
            end if;
            if (wb_reg_out = id_reg_in_2 and (FORWARDING = '0' or prod_stages_left > cons_stages_left_2)) then
                stall <= '1';
            end if;
        end if;

    end process;

end arch;
