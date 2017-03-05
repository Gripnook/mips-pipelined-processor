library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processor is
    port(clock : in std_logic;
         reset : in std_logic);
end processor;

architecture arch of processor is

    -- pc
    signal pc        : std_logic_vector(31 downto 0);
    signal pc_enable : std_logic;

    -- if
    signal if_instruction : std_logic_vector(31 downto 0);
    signal if_npc         : std_logic_vector(31 downto 0);

    -- if/id
    signal if_id_reset, if_id_enable : std_logic;

    -- id
    signal id_instruction : std_logic_vector(31 downto 0);
    signal id_npc         : std_logic_vector(31 downto 0);
    signal id_rs          : std_logic_vector(31 downto 0);
    signal id_rt          : std_logic_vector(31 downto 0);
    signal id_immediate   : std_logic_vector(31 downto 0);

    -- id/ex
    signal id_ex_reset, id_ex_enable : std_logic;

    -- ex
    signal ex_instruction : std_logic_vector(31 downto 0);
    signal ex_rs          : std_logic_vector(31 downto 0);
    signal ex_rt          : std_logic_vector(31 downto 0);
    signal ex_immediate   : std_logic_vector(31 downto 0);
    signal ex_alu_result  : std_logic_vector(63 downto 0); -- 64 bit for mult and div results
    signal a, b           : std_logic_vector(31 downto 0);

    -- ex/mem
    signal ex_mem_reset, ex_mem_enable : std_logic;

    -- mem
    signal mem_instruction : std_logic_vector(31 downto 0);
    signal mem_rt          : std_logic_vector(31 downto 0);
    signal mem_alu_result  : std_logic_vector(63 downto 0);
    signal mem_memory_load : std_logic_vector(31 downto 0);

    -- mem/wb
    signal mem_wb_reset, mem_wb_enable : std_logic;

    -- wb
    signal wb_instruction : std_logic_vector(31 downto 0);
    signal wb_alu_result  : std_logic_vector(63 downto 0);
    signal wb_memory_load : std_logic_vector(31 downto 0);

    component alu
        port(
            a      : in  std_logic_vector(31 downto 0);
            b      : in  std_logic_vector(31 downto 0);
            opcode : in  std_logic_vector(5 downto 0);
            shamt  : in  std_logic_vector(4 downto 0);
            funct  : in  std_logic_vector(5 downto 0);
            output : out std_logic_vector(63 downto 0));
    end component alu;

begin

    -- pc

    pc_register : process(clock, reset)
    begin
        if (reset = '1') then
            pc <= (others => '0');
        elsif (rising_edge(clock)) then
            if (pc_enable = '1') then
                pc <= if_npc;
            end if;
        end if;
    end process;

    -- if


    -- if/id

    if_id_pipeline_register : process(clock, reset)
    begin
        if (reset = '1') then
            id_instruction <= (others => '0');
            id_npc         <= (others => '0');
        elsif (rising_edge(clock)) then
            if (if_id_enable = '1') then
                if (if_id_reset = '1') then
                    id_instruction <= (others => '0');
                    id_npc         <= (others => '0');
                else
                    id_instruction <= if_instruction;
                    id_npc         <= if_npc;
                end if;
            end if;
        end if;
    end process;

    -- id


    -- id/ex

    id_ex_pipeline_register : process(clock, reset)
    begin
        if (reset = '1') then
            ex_instruction <= (others => '0');
            ex_rs          <= (others => '0');
            ex_rt          <= (others => '0');
            ex_immediate   <= (others => '0');
        elsif (rising_edge(clock)) then
            if (id_ex_enable = '1') then
                if (id_ex_reset = '1') then
                    ex_instruction <= (others => '0');
                    ex_rs          <= (others => '0');
                    ex_rt          <= (others => '0');
                    ex_immediate   <= (others => '0');
                else
                    ex_instruction <= id_instruction;
                    ex_rs          <= id_rs;
                    ex_rt          <= id_rt;
                    ex_immediate   <= id_immediate;
                end if;
            end if;
        end if;
    end process;

    -- ex
    alu1 : alu port map(a => a, b => b, opcode => ex_instruction(31 downto 26), shamt => ex_instruction(10 downto 6), funct => ex_instruction(5 downto 0), output => ex_alu_result);

    a <= ex_rs;
    process(ex_instruction, ex_rt, ex_immediate)
    begin
        OP : case ex_instruction(31 downto 26) is
            when "000000" => b <= ex_rt;
            when others   => b <= ex_immediate;
        end case OP;
    end process;

    -- ex/mem

    ex_mem_pipeline_register : process(clock, reset)
    begin
        if (reset = '1') then
            mem_instruction <= (others => '0');
            mem_rt          <= (others => '0');
            mem_alu_result  <= (others => '0');
        elsif (rising_edge(clock)) then
            if (ex_mem_enable = '1') then
                if (ex_mem_reset = '1') then
                    mem_instruction <= (others => '0');
                    mem_rt          <= (others => '0');
                    mem_alu_result  <= (others => '0');
                else
                    mem_instruction <= ex_instruction;
                    mem_rt          <= ex_rt;
                    mem_alu_result  <= ex_alu_result;
                end if;
            end if;
        end if;
    end process;

    -- mem


    -- mem/wb

    mem_wb_pipeline_register : process(clock, reset)
    begin
        if (reset = '1') then
            wb_instruction <= (others => '0');
            wb_alu_result  <= (others => '0');
            wb_memory_load <= (others => '0');
        elsif (rising_edge(clock)) then
            if (mem_wb_enable = '1') then
                if (mem_wb_reset = '1') then
                    wb_instruction <= (others => '0');
                    wb_alu_result  <= (others => '0');
                    wb_memory_load <= (others => '0');
                else
                    wb_instruction <= mem_instruction;
                    wb_alu_result  <= mem_alu_result;
                    wb_memory_load <= mem_memory_load;
                end if;
            end if;
        end if;
    end process;

-- wb


end architecture;
