library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_instruction_set.all;
use work.branch_prediction.all;

entity processor is
    port(clock : in std_logic;
         reset : in std_logic);
end processor;

architecture arch of processor is

    -- components

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
             result : out std_logic_vector(63 downto 0));
    end component;

    component hazard_detector is
        port(id_instruction  : in  std_logic_vector(31 downto 0);
             ex_instruction  : in  std_logic_vector(31 downto 0);
             mem_instruction : in  std_logic_vector(31 downto 0);
             wb_instruction  : in  std_logic_vector(31 downto 0);
             stall           : out std_logic);
    end component;

    component cache is
        generic(CACHE_SIZE : integer;
                RAM_SIZE   : integer := 8192);
        port(clock         : in  std_logic;
             reset         : in  std_logic;
             -- Avalon interface --
             s_addr        : in  std_logic_vector(31 downto 0);
             s_read        : in  std_logic;
             s_readdata    : out std_logic_vector(31 downto 0);
             s_write       : in  std_logic                     := '0';
             s_writedata   : in  std_logic_vector(31 downto 0) := (others => '0');
             s_waitrequest : out std_logic;
             m_addr        : out integer range 0 to RAM_SIZE - 1;
             m_read        : out std_logic;
             m_readdata    : in  std_logic_vector(31 downto 0);
             m_write       : out std_logic;
             m_writedata   : out std_logic_vector(31 downto 0);
             m_waitrequest : in  std_logic);
    end component;

    component memory is
        generic(RAM_SIZE     : integer := 8192;
                MEM_DELAY    : time    := 10 ns;
                CLOCK_PERIOD : time    := 1 ns);
        port(clock       : in  std_logic;
             writedata   : in  std_logic_vector(31 downto 0);
             address     : in  integer range 0 to RAM_SIZE - 1;
             memwrite    : in  std_logic;
             memread     : in  std_logic;
             readdata    : out std_logic_vector(31 downto 0);
             waitrequest : out std_logic);
    end component;

    component arbiter is
        generic(RAM_SIZE : integer := 8192);
        port(clock         : in  std_logic;
             reset         : in  std_logic;
             i_addr        : in  integer range 0 to RAM_SIZE - 1;
             i_read        : in  std_logic;
             i_readdata    : out std_logic_vector(31 downto 0);
             i_write       : in  std_logic;
             i_writedata   : in  std_logic_vector(31 downto 0);
             i_waitrequest : out std_logic;
             d_addr        : in  integer range 0 to RAM_SIZE - 1;
             d_read        : in  std_logic;
             d_readdata    : out std_logic_vector(31 downto 0);
             d_write       : in  std_logic;
             d_writedata   : in  std_logic_vector(31 downto 0);
             d_waitrequest : out std_logic;
             m_addr        : out integer range 0 to RAM_SIZE - 1;
             m_read        : out std_logic;
             m_readdata    : in  std_logic_vector(31 downto 0);
             m_write       : out std_logic;
             m_writedata   : out std_logic_vector(31 downto 0);
             m_waitrequest : in  std_logic);
    end component;

    constant INSTRUCTION_CACHE_SIZE : integer := 64;
    constant DATA_CACHE_SIZE        : integer := 64;

    -- pc
    signal pc        : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_enable : std_logic;

    -- if
    signal if_instruction : std_logic_vector(31 downto 0);
    signal if_opcode      : std_logic_vector(5 downto 0);
    signal if_immediate   : std_logic_vector(15 downto 0);
    signal if_target      : std_logic_vector(25 downto 0);
    signal if_npc         : std_logic_vector(31 downto 0);
    signal if_address     : std_logic_vector(31 downto 0) := (others => '0');
    signal if_read_en     : std_logic;
    signal if_waitrequest : std_logic;

    signal if_prediction    : std_logic;
    signal if_branch        : std_logic;
    signal if_jump          : std_logic;
    signal if_branch_target : std_logic_vector(31 downto 0);
    signal if_pc_plus_four  : std_logic_vector(31 downto 0);
    signal if_bp_update     : std_logic;

    -- if/id
    signal if_id_reset, if_id_enable : std_logic;

    -- id
    signal id_instruction  : std_logic_vector(31 downto 0);
    signal id_opcode       : std_logic_vector(5 downto 0);
    signal id_funct        : std_logic_vector(5 downto 0);
    signal id_rs_addr      : std_logic_vector(4 downto 0);
    signal id_rt_addr      : std_logic_vector(4 downto 0);
    signal id_pc_plus_four : std_logic_vector(31 downto 0);
    signal id_rs           : std_logic_vector(31 downto 0);
    signal id_rs_fwd       : std_logic_vector(31 downto 0);
    signal id_rt           : std_logic_vector(31 downto 0);
    signal id_rt_fwd       : std_logic_vector(31 downto 0);
    signal id_rs_output    : std_logic_vector(31 downto 0);
    signal id_rt_output    : std_logic_vector(31 downto 0);
    signal id_immediate    : std_logic_vector(31 downto 0);

    signal id_jump_reg      : std_logic;
    signal id_branch_taken  : std_logic;
    signal id_branch_target : std_logic_vector(31 downto 0);

    signal id_previous_pc            : std_logic_vector(31 downto 0);
    signal id_made_prediction        : std_logic;
    signal id_previous_prediction    : std_logic;
    signal id_previous_branch_target : std_logic_vector(31 downto 0);
    signal id_prediction_incorrect   : std_logic;

    -- id/ex
    signal id_ex_reset, id_ex_enable : std_logic;

    -- ex
    signal ex_instruction : std_logic_vector(31 downto 0);
    signal ex_opcode      : std_logic_vector(5 downto 0);
    signal ex_funct       : std_logic_vector(5 downto 0);
    signal ex_shamt       : std_logic_vector(4 downto 0);
    signal ex_rs          : std_logic_vector(31 downto 0);
    signal ex_rs_fwd      : std_logic_vector(31 downto 0);
    signal ex_rt          : std_logic_vector(31 downto 0);
    signal ex_rt_fwd      : std_logic_vector(31 downto 0);
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
    signal mem_rt_fwd      : std_logic_vector(31 downto 0);
    signal mem_alu_result  : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_memory_load : std_logic_vector(31 downto 0);
    signal mem_address     : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_write_en    : std_logic;
    signal mem_read_en     : std_logic;
    signal mem_waitrequest : std_logic;

    -- mem/wb
    signal mem_wb_reset, mem_wb_enable : std_logic;

    -- wb
    signal wb_instruction : std_logic_vector(31 downto 0);
    signal wb_opcode      : std_logic_vector(5 downto 0);
    signal wb_funct       : std_logic_vector(5 downto 0);
    signal wb_rs_addr     : std_logic_vector(4 downto 0);
    signal wb_rt_addr     : std_logic_vector(4 downto 0);
    signal wb_rd_addr     : std_logic_vector(4 downto 0);
    signal wb_immediate   : std_logic_vector(15 downto 0);
    signal wb_alu_result  : std_logic_vector(31 downto 0);
    signal wb_memory_load : std_logic_vector(31 downto 0);
    signal wb_write_en    : std_logic;
    signal wb_write_addr  : std_logic_vector(4 downto 0);
    signal wb_writedata   : std_logic_vector(31 downto 0);

    -- main memory
    signal i_addr        : integer;
    signal i_read        : std_logic;
    signal i_readdata    : std_logic_vector(31 downto 0);
    signal i_write       : std_logic;
    signal i_writedata   : std_logic_vector(31 downto 0);
    signal i_waitrequest : std_logic;
    signal d_addr        : integer;
    signal d_read        : std_logic;
    signal d_readdata    : std_logic_vector(31 downto 0);
    signal d_write       : std_logic;
    signal d_writedata   : std_logic_vector(31 downto 0);
    signal d_waitrequest : std_logic;
    signal m_addr        : integer;
    signal m_read        : std_logic;
    signal m_readdata    : std_logic_vector(31 downto 0);
    signal m_write       : std_logic;
    signal m_writedata   : std_logic_vector(31 downto 0);
    signal m_waitrequest : std_logic;

    -- stalls and flushes
    signal data_hazard_stall : std_logic;

    -- forwarding
    signal fwd_id_rs  : std_logic_vector(4 downto 0);
    signal fwd_id_rt  : std_logic_vector(4 downto 0);
    signal fwd_ex_rs  : std_logic_vector(4 downto 0);
    signal fwd_ex_rt  : std_logic_vector(4 downto 0);
    signal fwd_mem_rt : std_logic_vector(4 downto 0);

    signal fwd_ex_result  : std_logic_vector(4 downto 0);
    signal fwd_ex_ready   : std_logic;
    signal fwd_mem_result : std_logic_vector(4 downto 0);
    signal fwd_mem_ready  : std_logic;
    signal fwd_wb_result  : std_logic_vector(4 downto 0);
    signal fwd_wb_ready   : std_logic;

    -- performance counters
    signal instruction_count           : integer := 0;
    signal i_memory_access_stall_count : integer := 0;
    signal d_memory_access_stall_count : integer := 0;
    signal data_hazard_stall_count     : integer := 0;
    signal branch_hazard_stall_count   : integer := 0;

    -- bookkeeping
    signal id_done : std_logic := '0';
    signal wb_done : std_logic := '0';

    signal clear_cache_count : integer := 0;

    signal done : std_logic := '0';

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

    instruction_cache : cache
        generic map(CACHE_SIZE => INSTRUCTION_CACHE_SIZE)
        port map(clock         => clock,
                 reset         => reset,
                 s_addr        => if_address,
                 s_read        => if_read_en,
                 s_readdata    => if_instruction,
                 s_waitrequest => if_waitrequest,
                 m_addr        => i_addr,
                 m_read        => i_read,
                 m_readdata    => i_readdata,
                 m_write       => i_write,
                 m_writedata   => i_writedata,
                 m_waitrequest => i_waitrequest);
    if_address <= pc(31 downto 2) & "00";
    if_read_en <= '1';

    if_pc_plus_four <= std_logic_vector(unsigned(pc) + 4);

    branch_predictor : bp_tournament_2_2
        port map(clock                => clock,
                 reset                => reset,
                 pc                   => pc,
                 update               => if_bp_update,
                 previous_pc          => id_previous_pc,
                 previous_prediction  => id_previous_prediction,
                 prediction_incorrect => id_prediction_incorrect,
                 prediction           => if_prediction);
    if_bp_update <= id_made_prediction and if_id_enable;

    if_opcode    <= if_instruction(31 downto 26);
    if_immediate <= if_instruction(15 downto 0);
    if_target    <= if_instruction(25 downto 0);

    branch_prediction_resolution : process(if_pc_plus_four, if_opcode, if_immediate, if_target)
    begin
        if_branch        <= '0';
        if_jump          <= '0';
        if_branch_target <= (others => '0');
        case if_opcode is
            when OP_J =>
                if_jump          <= '1';
                if_branch_target <= if_pc_plus_four(31 downto 28) & if_target & "00";
            when OP_JAL =>
                if_jump          <= '1';
                if_branch_target <= if_pc_plus_four(31 downto 28) & if_target & "00";
            when OP_BEQ =>
                if_branch        <= '1';
                if_branch_target <= std_logic_vector(signed(if_pc_plus_four) + signed(if_immediate & "00"));
            when OP_BNE =>
                if_branch        <= '1';
                if_branch_target <= std_logic_vector(signed(if_pc_plus_four) + signed(if_immediate & "00"));
            when others =>
                null;
        end case;
    end process;

    if_npc <= id_branch_target when (id_prediction_incorrect = '1') else if_branch_target when (if_jump = '1' or (if_branch = '1' and if_prediction = '1')) else if_pc_plus_four;

    -- if/id

    if_id_pipeline_register : process(clock, reset)
    begin
        if (reset = '1') then
            id_instruction            <= (others => '0');
            id_pc_plus_four           <= (others => '0');
            id_previous_pc            <= (others => '0');
            id_made_prediction        <= '0';
            id_previous_prediction    <= '0';
            id_previous_branch_target <= (others => '0');
        elsif (rising_edge(clock)) then
            if (if_id_enable = '1') then
                if (if_id_reset = '1') then
                    id_instruction            <= (others => '0');
                    id_pc_plus_four           <= (others => '0');
                    id_previous_pc            <= (others => '0');
                    id_made_prediction        <= '0';
                    id_previous_prediction    <= '0';
                    id_previous_branch_target <= (others => '0');
                else
                    id_instruction            <= if_instruction;
                    id_pc_plus_four           <= if_pc_plus_four;
                    id_previous_pc            <= pc;
                    id_made_prediction        <= if_branch;
                    id_previous_prediction    <= if_prediction;
                    id_previous_branch_target <= if_branch_target;
                end if;
            end if;
        end if;
    end process;

    -- id

    id_opcode  <= id_instruction(31 downto 26);
    id_funct   <= id_instruction(5 downto 0);
    id_rs_addr <= id_instruction(25 downto 21);
    id_rt_addr <= id_instruction(20 downto 16);

    register_file : registers
        port map(clock      => clock,
                 reset      => reset,
                 rs_addr    => id_rs_addr,
                 rt_addr    => id_rt_addr,
                 write_en   => wb_write_en,
                 write_addr => wb_write_addr,
                 writedata  => wb_writedata,
                 rs         => id_rs,
                 rt         => id_rt);

    id_forwarding_rs : process(id_rs, fwd_id_rs, fwd_ex_ready, fwd_ex_result, ex_rs, fwd_mem_ready, fwd_mem_result, mem_alu_result, fwd_wb_ready, fwd_wb_result, wb_writedata)
    begin
        id_rs_fwd <= id_rs;             -- default output
        if (fwd_id_rs /= "00000") then
            if (fwd_ex_ready = '1' and fwd_id_rs = fwd_ex_result) then
                id_rs_fwd <= ex_rs;     -- special case for JAL
            elsif (fwd_mem_ready = '1' and fwd_id_rs = fwd_mem_result) then
                id_rs_fwd <= mem_alu_result;
            elsif (fwd_wb_ready = '1' and fwd_id_rs = fwd_wb_result) then
                id_rs_fwd <= wb_writedata;
            end if;
        end if;
    end process;

    id_forwarding_rt : process(id_rt, fwd_id_rt, fwd_ex_ready, fwd_ex_result, ex_rs, fwd_mem_ready, fwd_mem_result, mem_alu_result, fwd_wb_ready, fwd_wb_result, wb_writedata)
    begin
        id_rt_fwd <= id_rt;             -- default output
        if (fwd_id_rt /= "00000") then
            if (fwd_ex_ready = '1' and fwd_id_rt = fwd_ex_result) then
                id_rt_fwd <= ex_rs;     -- special case for JAL
            elsif (fwd_mem_ready = '1' and fwd_id_rt = fwd_mem_result) then
                id_rt_fwd <= mem_alu_result;
            elsif (fwd_wb_ready = '1' and fwd_id_rt = fwd_wb_result) then
                id_rt_fwd <= wb_writedata;
            end if;
        end if;
    end process;

    with id_opcode select id_rs_output <=
        id_pc_plus_four when OP_JAL,
        id_rs_fwd when others;
    id_rt_output <= id_rt_fwd;

    immediate_extend : process(id_opcode, id_instruction)
    begin
        case id_opcode is
            when OP_ORI | OP_ANDI | OP_XORI =>
                id_immediate <= x"0000" & id_instruction(15 downto 0); -- zero extend
            when others =>
                id_immediate <= std_logic_vector(resize(signed(id_instruction(15 downto 0)), 32)); -- sign extend
        end case;
    end process;

    branch_resolution : process(id_opcode, id_funct, id_pc_plus_four, id_previous_branch_target, id_rs_fwd, id_rt_fwd)
    begin
        id_jump_reg      <= '0';
        id_branch_taken  <= '0';
        id_branch_target <= id_pc_plus_four;
        case id_opcode is
            when OP_R_TYPE =>
                if (id_funct = FUNCT_JR) then
                    id_jump_reg      <= '1';
                    id_branch_taken  <= '1';
                    id_branch_target <= id_rs_fwd;
                end if;
            when OP_J | OP_JAL =>
                id_branch_taken  <= '1';
                id_branch_target <= id_previous_branch_target;
            when OP_BEQ =>
                if (id_rs_fwd = id_rt_fwd) then
                    id_branch_taken  <= '1';
                    id_branch_target <= id_previous_branch_target;
                end if;
            when OP_BNE =>
                if (id_rs_fwd /= id_rt_fwd) then
                    id_branch_taken  <= '1';
                    id_branch_target <= id_previous_branch_target;
                end if;
            when others =>
                null;
        end case;
    end process;

    id_prediction_incorrect <= id_jump_reg or (id_made_prediction and (id_branch_taken xor id_previous_prediction));

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

    -- ex

    ex_opcode <= ex_instruction(31 downto 26);
    ex_funct  <= ex_instruction(5 downto 0);
    ex_shamt  <= ex_instruction(10 downto 6);

    ex_forwarding_rs : process(ex_rs, fwd_ex_rs, fwd_mem_ready, fwd_mem_result, mem_alu_result, fwd_wb_ready, fwd_wb_result, wb_writedata)
    begin
        ex_rs_fwd <= ex_rs;             -- default output
        if (fwd_ex_rs /= "00000") then
            if (fwd_mem_ready = '1' and fwd_ex_rs = fwd_mem_result) then
                ex_rs_fwd <= mem_alu_result;
            elsif (fwd_wb_ready = '1' and fwd_ex_rs = fwd_wb_result) then
                ex_rs_fwd <= wb_writedata;
            end if;
        end if;
    end process;

    ex_forwarding_rt : process(ex_rt, fwd_ex_rt, fwd_mem_ready, fwd_mem_result, mem_alu_result, fwd_wb_ready, fwd_wb_result, wb_writedata)
    begin
        ex_rt_fwd <= ex_rt;             -- default output
        if (fwd_ex_rt /= "00000") then
            if (fwd_mem_ready = '1' and fwd_ex_rt = fwd_mem_result) then
                ex_rt_fwd <= mem_alu_result;
            elsif (fwd_wb_ready = '1' and fwd_ex_rt = fwd_wb_result) then
                ex_rt_fwd <= wb_writedata;
            end if;
        end if;
    end process;

    alu_input_1 : process(ex_rs_fwd)
    begin
        ex_a <= ex_rs_fwd;
    end process;
    alu_input_2 : process(ex_opcode, ex_rt_fwd, ex_immediate)
    begin
        case ex_opcode is
            when OP_R_TYPE =>
                ex_b <= ex_rt_fwd;
            when others =>
                ex_b <= ex_immediate;
        end case;
    end process;

    ex_alu : alu
        port map(a      => ex_a,
                 b      => ex_b,
                 opcode => ex_opcode,
                 shamt  => ex_shamt,
                 funct  => ex_funct,
                 result => ex_alu_result);

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
                    mem_rt          <= ex_rt_fwd;
                    mem_alu_result  <= ex_output;
                end if;
            end if;
        end if;
    end process;

    -- mem

    mem_opcode <= mem_instruction(31 downto 26);

    mem_forwarding_rt : process(mem_rt, fwd_mem_rt, fwd_wb_ready, fwd_wb_result, wb_writedata)
    begin
        mem_rt_fwd <= mem_rt;           -- default output
        if (fwd_mem_rt /= "00000") then
            if (fwd_wb_ready = '1' and fwd_mem_rt = fwd_wb_result) then
                mem_rt_fwd <= wb_writedata;
            end if;
        end if;
    end process;

    data_cache : cache
        generic map(CACHE_SIZE => DATA_CACHE_SIZE)
        port map(clock         => clock,
                 reset         => reset,
                 s_addr        => mem_address,
                 s_read        => mem_read_en,
                 s_readdata    => mem_memory_load,
                 s_write       => mem_write_en,
                 s_writedata   => mem_rt_fwd,
                 s_waitrequest => mem_waitrequest,
                 m_addr        => d_addr,
                 m_read        => d_read,
                 m_readdata    => d_readdata,
                 m_write       => d_write,
                 m_writedata   => d_writedata,
                 m_waitrequest => d_waitrequest);
    mem_address <= mem_alu_result(31 downto 2) & "00" when wb_done = '0' else std_logic_vector(to_unsigned(clear_cache_count, 28) & "0000");

    with mem_opcode select mem_write_en <=
        '1' when OP_SW,
        '0' when others;

    with mem_opcode select mem_read_en <=
        '1' when OP_LW,
        wb_done when others;

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

    wb_opcode    <= wb_instruction(31 downto 26);
    wb_funct     <= wb_instruction(5 downto 0);
    wb_rs_addr   <= wb_instruction(25 downto 21);
    wb_rt_addr   <= wb_instruction(20 downto 16);
    wb_rd_addr   <= wb_instruction(15 downto 11);
    wb_immediate <= wb_instruction(15 downto 0);

    write_en_mux : process(wb_opcode, wb_funct)
    begin
        wb_write_en <= '1';             -- default value
        case wb_opcode is
            when OP_R_TYPE =>
                case wb_funct is
                    when FUNCT_MULT | FUNCT_DIV | FUNCT_JR =>
                        wb_write_en <= '0';
                    when others =>
                        null;
                end case;
            when OP_SW | OP_BEQ | OP_BNE | OP_J =>
                wb_write_en <= '0';
            when others =>
                null;
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

    -- main memory

    mem : memory
        port map(clock       => clock,
                 writedata   => m_writedata,
                 address     => m_addr,
                 memwrite    => m_write,
                 memread     => m_read,
                 readdata    => m_readdata,
                 waitrequest => m_waitrequest);

    mem_arbiter : arbiter
        port map(clock         => clock,
                 reset         => reset,
                 i_addr        => i_addr,
                 i_read        => i_read,
                 i_readdata    => i_readdata,
                 i_write       => i_write,
                 i_writedata   => i_writedata,
                 i_waitrequest => i_waitrequest,
                 d_addr        => d_addr,
                 d_read        => d_read,
                 d_readdata    => d_readdata,
                 d_write       => d_write,
                 d_writedata   => d_writedata,
                 d_waitrequest => d_waitrequest,
                 m_addr        => m_addr,
                 m_read        => m_read,
                 m_readdata    => m_readdata,
                 m_write       => m_write,
                 m_writedata   => m_writedata,
                 m_waitrequest => m_waitrequest);

    -- stalls and flushes

    data_hazard_detector : hazard_detector
        port map(id_instruction  => id_instruction,
                 ex_instruction  => ex_instruction,
                 mem_instruction => mem_instruction,
                 wb_instruction  => wb_instruction,
                 stall           => data_hazard_stall);

    pc_enable     <= (not if_waitrequest) and (not mem_waitrequest) and (not data_hazard_stall);
    if_id_enable  <= (not if_waitrequest) and (not mem_waitrequest) and (not data_hazard_stall);
    if_id_reset   <= id_prediction_incorrect;
    id_ex_enable  <= not mem_waitrequest;
    id_ex_reset   <= if_waitrequest or data_hazard_stall;
    ex_mem_enable <= not mem_waitrequest;
    ex_mem_reset  <= '0';
    mem_wb_enable <= '1';
    mem_wb_reset  <= mem_waitrequest;

    -- forwarding

    instruction_input_decoding : process(id_instruction, ex_instruction, mem_instruction)
        variable reg_in_1, reg_in_2     : std_logic_vector(4 downto 0);
        variable stage_in_1, stage_in_2 : integer;
    begin
        decode_instruction_input(id_instruction, reg_in_1, reg_in_2, stage_in_1, stage_in_2);
        fwd_id_rs <= reg_in_1;
        fwd_id_rt <= reg_in_2;

        decode_instruction_input(ex_instruction, reg_in_1, reg_in_2, stage_in_1, stage_in_2);
        fwd_ex_rs <= reg_in_1;
        fwd_ex_rt <= reg_in_2;

        decode_instruction_input(mem_instruction, reg_in_1, reg_in_2, stage_in_1, stage_in_2);
        fwd_mem_rt <= reg_in_2;
    end process;

    instruction_output_decoding : process(ex_instruction, mem_instruction, wb_instruction)
        variable reg_out   : std_logic_vector(4 downto 0);
        variable stage_out : integer;
    begin
        -- default outputs
        fwd_ex_ready  <= '0';
        fwd_mem_ready <= '0';
        fwd_wb_ready  <= '0';

        decode_instruction_output(ex_instruction, reg_out, stage_out);
        fwd_ex_result <= reg_out;
        if (stage_out <= STAGE_EX) then
            fwd_ex_ready <= '1';
        end if;

        decode_instruction_output(mem_instruction, reg_out, stage_out);
        fwd_mem_result <= reg_out;
        if (stage_out <= STAGE_MEM) then
            fwd_mem_ready <= '1';
        end if;

        decode_instruction_output(wb_instruction, reg_out, stage_out);
        fwd_wb_result <= reg_out;
        if (stage_out <= STAGE_WB) then
            fwd_wb_ready <= '1';
        end if;
    end process;

    -- performance counters

    stall_counter : process(clock, reset)
    begin
        if (reset = '1') then
            instruction_count           <= 0;
            i_memory_access_stall_count <= 0;
            d_memory_access_stall_count <= 0;
            data_hazard_stall_count     <= 0;
            branch_hazard_stall_count   <= 0;
        elsif (rising_edge(clock)) then
            if (wb_done = '0' and mem_waitrequest = '1') then
                d_memory_access_stall_count <= d_memory_access_stall_count + 1;
            elsif (id_done = '0' and if_waitrequest = '1') then
                i_memory_access_stall_count <= i_memory_access_stall_count + 1;
            elsif (id_done = '0' and data_hazard_stall = '1') then
                data_hazard_stall_count <= data_hazard_stall_count + 1;
            elsif (id_done = '0' and id_prediction_incorrect = '1') then
                branch_hazard_stall_count <= branch_hazard_stall_count + 1;
            elsif (id_done = '0') then
                instruction_count <= instruction_count + 1;
            end if;
        end if;
    end process;

    -- bookkeeping

    branch_termination_latch : process(reset, id_opcode, id_rs_addr, id_rt_addr, id_immediate)
    begin
        if (reset = '1') then
            id_done <= '0';
        elsif (id_opcode = OP_BEQ and id_rs_addr = id_rt_addr and id_immediate = x"FFFFFFFF") then
            -- No more branch hazards can occur if an infinite loop using BEQ reaches ID
            id_done <= '1';
        end if;
    end process;

    program_termination_latch : process(reset, wb_opcode, wb_rs_addr, wb_rt_addr, wb_immediate)
    begin
        if (reset = '1') then
            wb_done <= '0';
        elsif (wb_opcode = OP_BEQ and wb_rs_addr = wb_rt_addr and wb_immediate = x"FFFF") then
            -- The program is done if an infinite loop using BEQ reaches WB
            wb_done <= '1';
        end if;
    end process;

    -- Flushes D$ after the program is completed by reading instructions into D$
    clear_cache_counter : process(clock, reset)
    begin
        if (reset = '1') then
            done              <= '0';
            clear_cache_count <= 0;
        elsif (rising_edge(clock)) then
            if (wb_done = '1' and mem_waitrequest = '0') then
                if (clear_cache_count /= DATA_CACHE_SIZE / 4) then
                    clear_cache_count <= clear_cache_count + 1;
                else
                    done <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;
