library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MIPS_encoding.all;

entity processor is
    port(clock : in std_logic;
         reset : in std_logic);
end processor;

architecture arch of processor is

    -- components

    component memory is
        generic(ram_size : integer := 8192);
        port(clock       : in  std_logic;
             writedata   : in  std_logic_vector(31 downto 0) := (others => '0');
             address     : in  integer range 0 to ram_size - 1;
             memwrite    : in  std_logic := '0';
             memread     : in  std_logic;
             readdata    : out std_logic_vector(31 downto 0);
             waitrequest : out std_logic);
    end component;

    component registers is
        port(clock      : in  std_logic;
             reset      : in  std_logic;
             rs_addr    : in  std_logic_vector(4 downto 0);
             rt_addr    : in  std_logic_vector(4 downto 0);
             write_en   : in  std_logic;
             write_addr : in  std_logic_vector(4 downto 0);
             writedata  : in  std_logic_vector(31 downto 0);
             rs         : out std_logic_vector(31 downto 0);
             rt         : out std_logic_vector(31 downto 0));
    end component;

    component alu is
        port(a      : in  std_logic_vector(31 downto 0);
             b      : in  std_logic_vector(31 downto 0);
             opcode : in  std_logic_vector(5 downto 0);
             shamt  : in  std_logic_vector(4 downto 0);
             funct  : in  std_logic_vector(5 downto 0);
             output : out std_logic_vector(63 downto 0));
    end component;

    component hazard_detector is
        port(if_id  : in  std_logic_vector(31 downto 0);
             id_ex  : in  std_logic_vector(31 downto 0);
             ex_mem : in  std_logic_vector(31 downto 0);
             mem_wb : in  std_logic_vector(31 downto 0);
             stall  : out std_logic);
    end component;

    -- pc
    signal pc        : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_enable : std_logic;

    -- if
    signal if_instruction : std_logic_vector(31 downto 0);
    signal if_npc         : std_logic_vector(31 downto 0);
    signal if_address     : integer := 0;
    signal if_read_en     : std_logic;
    signal if_waitrequest : std_logic;

    -- if/id
    signal if_id_reset, if_id_enable : std_logic;

    -- id
    signal id_instruction   : std_logic_vector(31 downto 0);
    signal id_opcode        : std_logic_vector(5 downto 0);
    signal id_funct         : std_logic_vector(5 downto 0);
    signal id_target        : std_logic_vector(25 downto 0);
    signal id_rs_addr       : std_logic_vector(4 downto 0);
    signal id_rt_addr       : std_logic_vector(4 downto 0);
    signal id_npc           : std_logic_vector(31 downto 0);
    signal id_rs            : std_logic_vector(31 downto 0);
    signal id_rt            : std_logic_vector(31 downto 0);
    signal id_rs_output     : std_logic_vector(31 downto 0);
    signal id_rt_output     : std_logic_vector(31 downto 0);
    signal id_immediate     : std_logic_vector(31 downto 0);
    signal id_branch_taken  : std_logic;
    signal id_branch_target : std_logic_vector(31 downto 0);

    -- id/ex
    signal id_ex_reset, id_ex_enable : std_logic;

    -- ex
    signal ex_instruction : std_logic_vector(31 downto 0);
    signal ex_opcode      : std_logic_vector(5 downto 0);
    signal ex_funct       : std_logic_vector(5 downto 0);
    signal ex_shamt       : std_logic_vector(4 downto 0);
    signal ex_rs          : std_logic_vector(31 downto 0);
    signal ex_rt          : std_logic_vector(31 downto 0);
    signal ex_immediate   : std_logic_vector(31 downto 0);
    signal ex_alu_result  : std_logic_vector(63 downto 0); -- 64 bit for mult and div results
    signal ex_a, ex_b     : std_logic_vector(31 downto 0);
    signal ex_output      : std_logic_vector(31 downto 0);

    signal hi, lo : std_logic_vector(31 downto 0);

    -- ex/mem
    signal ex_mem_reset, ex_mem_enable : std_logic;

    -- mem
    signal mem_instruction : std_logic_vector(31 downto 0);
    signal mem_opcode      : std_logic_vector(5 downto 0);
    signal mem_rt          : std_logic_vector(31 downto 0);
    signal mem_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_memory_load : std_logic_vector(31 downto 0);
    signal mem_address     : integer := 0;
    signal mem_write_en    : std_logic;
    signal mem_read_en     : std_logic;
    signal mem_waitrequest : std_logic;

    -- mem/wb
    signal mem_wb_reset, mem_wb_enable : std_logic;

    -- wb
    signal wb_instruction : std_logic_vector(31 downto 0);
    signal wb_opcode      : std_logic_vector(5 downto 0);
    signal wb_rt_addr     : std_logic_vector(4 downto 0);
    signal wb_rd_addr     : std_logic_vector(4 downto 0);
    signal wb_alu_result  : std_logic_vector(31 downto 0);
    signal wb_memory_load : std_logic_vector(31 downto 0);
    signal wb_write_en    : std_logic;
    signal wb_write_addr  : std_logic_vector(4 downto 0);
    signal wb_writedata   : std_logic_vector(31 downto 0);

    -- stalls and flushes
    signal data_hazard_stall : std_logic;

    -- performance counters
    signal memory_access_stall_count : integer := 0;
    signal data_hazard_stall_count   : integer := 0;
    signal branch_hazard_stall_count : integer := 0;

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

    instruction_cache : memory
    generic map(ram_size => 1024)
    port map(clock => clock,
             address => if_address,
             memread => if_read_en,
             readdata => if_instruction,
             waitrequest => if_waitrequest);
    if_address <= to_integer(unsigned(pc(31 downto 2)));
    if_read_en <= '1';

    with id_branch_taken select if_npc <=
        std_logic_vector(unsigned(pc) + 4) when '0', -- predict taken
        id_branch_target when others;

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

    id_opcode <= id_instruction(31 downto 26);
    id_funct <= id_instruction(5 downto 0);
    id_target <= id_instruction(25 downto 0);
    id_rs_addr <= id_instruction(25 downto 21);
    id_rt_addr <= id_instruction(20 downto 16);

    register_file : registers
    port map(clock => clock,
             reset => reset,
             rs_addr => id_rs_addr,
             rt_addr => id_rt_addr,
             write_en => wb_write_en,
             write_addr => wb_write_addr,
             writedata => wb_writedata,
             rs => id_rs,
             rt => id_rt);

    with id_opcode select id_rs_output <=
        id_npc when OP_JAL,
        id_rs when others;
    id_rt_output <= id_rt;

    id_immediate <= std_logic_vector(resize(signed(id_instruction(15 downto 0)), 32)); -- sign extend

    branch_resolution : process(id_opcode, id_funct, id_target, id_npc, id_rs, id_rt, id_immediate)
    begin
        id_branch_taken <= '0';
        id_branch_target <= (others => '0');
        case id_opcode is
            when OP_R_TYPE =>
                if (id_funct = FUNCT_JR) then
                    id_branch_taken <= '1';
                    id_branch_target <= id_rs;
                end if;
            when OP_J =>
                id_branch_taken <= '1';
                id_branch_target <= id_npc(31 downto 28) & id_target & "00";
            when OP_JAL =>
                id_branch_taken <= '1';
                id_branch_target <= id_npc(31 downto 28) & id_target & "00";
            when OP_BEQ =>
                if (id_rs = id_rt) then
                    id_branch_taken <= '1';
                    id_branch_target <= std_logic_vector(signed(id_npc) + signed(id_immediate(29 downto 0) & "00"));
                end if;
            when OP_BNE =>
                if (id_rs /= id_rt) then
                    id_branch_taken <= '1';
                    id_branch_target <= std_logic_vector(signed(id_npc) + signed(id_immediate(29 downto 0) & "00"));
                end if;
            when others =>
                null;
        end case;
    end process;

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
                    ex_rs          <= id_rs_output;
                    ex_rt          <= id_rt_output;
                    ex_immediate   <= id_immediate;
                end if;
            end if;
        end if;
    end process;

    --ex

    ex_opcode <= ex_instruction(31 downto 26);
    ex_funct  <= ex_instruction(5 downto 0);
    ex_shamt  <= ex_instruction(10 downto 6);

    alu_input_1 : process(ex_rs)
    begin
        ex_a <= ex_rs;
    end process;
    alu_input_2 : process(ex_opcode, ex_rt, ex_immediate)
    begin
    	case ex_opcode is
    		when OP_R_TYPE =>
                ex_b <= ex_rt;
    		when others =>
                ex_b <= ex_immediate;
    	end case;
    end process;

    ex_alu : alu
    port map(a => ex_a,
             b => ex_b,
             opcode => ex_opcode,
             shamt => ex_shamt,
             funct => ex_funct,
             output => ex_alu_result);

    hi_lo_registers : process(clock, reset)
    begin
        if (reset = '1') then
            hi <= (others => '0');
            lo <= (others => '0');
        elsif (rising_edge(clock)) then
            if (ex_opcode = OP_R_TYPE) then
                if ((ex_funct = FUNCT_MULT) or (ex_funct = FUNCT_DIV)) then
                    hi <= ex_alu_result(63 downto 32);
                    lo <= ex_alu_result(31 downto 0);
                end if;
            end if;
        end if;
    end process;

    ex_output_mux : process(ex_opcode, ex_funct, ex_alu_result, hi, lo)
    begin
        ex_output <= ex_alu_result(31 downto 0);
        if (ex_opcode = OP_R_TYPE) then
            if (ex_funct = FUNCT_MFHI) then
                ex_output <= hi;
            elsif (ex_funct = FUNCT_MFLO) then
                ex_output <= lo;
            end if;
        end if;
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
                    mem_alu_result  <= ex_output;
                end if;
            end if;
        end if;
    end process;

    -- mem

    mem_opcode <= mem_instruction(31 downto 26);

    data_cache : memory
    generic map(ram_size => 8192)
    port map(clock => clock,
             writedata => mem_rt,
             address => mem_address,
             memwrite => mem_write_en,
             memread => mem_read_en,
             readdata => mem_memory_load,
             waitrequest => mem_waitrequest);
    mem_address <= to_integer(unsigned(mem_alu_result(31 downto 2)));

    with mem_opcode select mem_write_en <=
        '1' when OP_SW,
        '0' when others;

    with mem_opcode select mem_read_en <=
        '1' when OP_LW,
        '0' when others;

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

    wb_opcode  <= wb_instruction(31 downto 26);
    wb_rt_addr <= wb_instruction(20 downto 16);
    wb_rd_addr <= wb_instruction(15 downto 11);

    write_en_mux : process(wb_opcode)
    begin
        case wb_opcode is
            when OP_SW | OP_BEQ | OP_BNE | OP_J =>
                wb_write_en <= '0';
            when others =>
                wb_write_en <= '1';
        end case;
    end process;

    write_addr_mux : process(wb_opcode, wb_rt_addr, wb_rd_addr)
    begin
        case wb_opcode is
            when OP_R_TYPE =>
                wb_write_addr <= wb_rd_addr;
            when OP_JAL =>
                wb_write_addr <= "11111"; -- $ra
            when others =>
                wb_write_addr <= wb_rt_addr;
        end case;
    end process;

    writedata_mux : process(wb_opcode, wb_alu_result, wb_memory_load)
    begin
        case wb_opcode is
            when OP_LW =>
                wb_writedata <= wb_memory_load;
            when others =>
                wb_writedata <= wb_alu_result;
        end case;
    end process;

    -- stalls and flushes

    data_hazard_detector : hazard_detector
    port map(if_id => id_instruction,
             id_ex => ex_instruction,
             ex_mem => mem_instruction,
             mem_wb => wb_instruction,
             stall => data_hazard_stall);

    pc_enable     <= (not if_waitrequest) and (not mem_waitrequest) and (not data_hazard_stall);
    if_id_enable  <= (not if_waitrequest) and (not mem_waitrequest) and (not data_hazard_stall);
    if_id_reset   <= id_branch_taken;
    id_ex_enable  <= not mem_waitrequest;
    id_ex_reset   <= if_waitrequest or data_hazard_stall;
    ex_mem_enable <= not mem_waitrequest;
    ex_mem_reset  <= '0';
    mem_wb_enable <= '1';
    mem_wb_reset  <= mem_waitrequest;

    -- performance counters

    stall_counter : process(clock, reset)
    begin
        if (reset = '1') then
            memory_access_stall_count <= 0;
            data_hazard_stall_count <= 0;
            branch_hazard_stall_count <= 0;
        elsif (rising_edge(clock)) then
            if (if_waitrequest = '1' or mem_waitrequest = '1') then
                memory_access_stall_count <= memory_access_stall_count + 1;
            elsif (data_hazard_stall = '1') then
                data_hazard_stall_count <= data_hazard_stall_count + 1;
            elsif (id_branch_taken = '1') then
                branch_hazard_stall_count <= branch_hazard_stall_count + 1;
            end if;
        end if;
    end process;

end architecture;
