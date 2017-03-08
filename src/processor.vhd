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
        generic(
            ram_size     : integer := 32768
        );
        port(
            clock       : in  std_logic;
            writedata   : in  std_logic_vector(31 downto 0) := (others => '0');
            address     : in  integer range 0 to ram_size - 1;
            memwrite    : in  std_logic := '0';
            memread     : in  std_logic;
            readdata    : out std_logic_vector(31 downto 0);
            waitrequest : out std_logic
        );
    end component;

    component registers
      port (clock         : in  std_logic;
            regWrite      : in  std_logic;
            rs_adr        : in  std_logic_vector(4 downto 0);
            rt_adr        : in  std_logic_vector(4 downto 0);
            instruction   : in  std_logic_vector(31 downto 0);
            wb_data       : in  std_logic_vector(31 downto 0);
            id_rs         : out std_logic_vector(31 downto 0);
            id_rt         : out std_logic_vector(31 downto 0)
            );
    end component registers;

    component alu
        port(
            a      : in  std_logic_vector(31 downto 0);
            b      : in  std_logic_vector(31 downto 0);
            opcode : in  std_logic_vector(5 downto 0);
            shamt  : in  std_logic_vector(4 downto 0);
            funct  : in  std_logic_vector(5 downto 0);
            output : out std_logic_vector(63 downto 0));
    end component alu;

    -- pc
    signal pc        : std_logic_vector(31 downto 0);
    signal pc_enable : std_logic;

    -- if
    signal if_instruction : std_logic_vector(31 downto 0);
    signal if_npc         : std_logic_vector(31 downto 0);
    signal if_address     : integer;
    signal if_read_en     : std_logic;
    signal if_waitrequest : std_logic;

    -- if/id
    signal if_id_reset, if_id_enable : std_logic;

    -- id
    signal id_instruction   : std_logic_vector(31 downto 0);
    signal id_npc           : std_logic_vector(31 downto 0);
    signal id_rs            : std_logic_vector(31 downto 0);
    signal id_rt            : std_logic_vector(31 downto 0);
    signal id_immediate     : std_logic_vector(31 downto 0);
    signal id_branch_taken  : std_logic;
    signal id_branch_target : std_logic_vector(31 downto 0);

    -- id/ex
    signal id_ex_reset, id_ex_enable : std_logic;

    -- ex
    signal ex_instruction : std_logic_vector(31 downto 0);
    signal ex_rs          : std_logic_vector(31 downto 0);
    signal ex_rt          : std_logic_vector(31 downto 0);
    signal ex_immediate   : std_logic_vector(31 downto 0);
    signal ex_alu_result  : std_logic_vector(63 downto 0); -- 64 bit for mult and div results
    signal a, b           : std_logic_vector(31 downto 0);
    signal mflo, mfhi     : std_logic_vector(31 downto 0);
    signal ex_mf_result   : std_logic_vector(31 downto 0);
    signal ex_output      : std_logic_vector(31 downto 0); 
    signal mf_write_en    : std_logic;
    signal mf_read        : std_logic_vector(1  downto 0);

    -- ex/mem
    signal ex_mem_reset, ex_mem_enable : std_logic;

    -- mem
    signal mem_instruction : std_logic_vector(31 downto 0);
    signal mem_rt          : std_logic_vector(31 downto 0);
    signal mem_alu_result  : std_logic_vector(31 downto 0);
    signal mem_memory_load : std_logic_vector(31 downto 0);

    -- mem/wb
    signal mem_wb_reset, mem_wb_enable : std_logic;

    -- wb
    signal wb_instruction : std_logic_vector(31 downto 0);
    signal wb_alu_result  : std_logic_vector(31 downto 0);
    signal wb_memory_load : std_logic_vector(31 downto 0);
    signal wb_data        : std_logic_vector(31 downto 0);
    signal wb_regWrite    : std_logic;

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
    if_address <= to_integer(unsigned(pc));

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

    registers1 : registers port map(  clock => clock,
                                      regWrite => wb_regWrite,
                                      rs_adr => id_instruction(25 downto 21),
                                      rt_adr => id_instruction(20 downto 16),
                                      instruction => wb_instruction,
                                      wb_data => wb_data,
                                      id_rs => id_rs,
                                      id_rt => id_rt);

    id_immediate <= std_logic_vector(resize(signed(id_instruction(15 downto 0)), 32)); --sign extend

    branch_resolution : process(id_instruction, id_npc, id_rs, id_rt, id_immediate)
        variable opcode : std_logic_vector(5 downto 0);
        variable funct  : std_logic_vector(5 downto 0);
        variable target : std_logic_vector(25 downto 0);
    begin
        opcode := id_instruction(31 downto 26);
        funct  := id_instruction(5 downto 0);
        target := id_instruction(25 downto 0);

        id_branch_taken <= '0';
        id_branch_target <= (others => '0');
        case opcode is
            when OP_R_TYPE =>
                if (funct = FUNCT_JR) then
                    id_branch_taken <= '1';
                    id_branch_target <= id_rs;
                end if;
            when OP_J =>
                id_branch_taken <= '1';
                id_branch_target <= (id_npc and x"f0000000") or (x"0" & target & "00");
            when OP_JAL =>
                id_branch_taken <= '1';
                id_branch_target <= (id_npc and x"f0000000") or (x"0" & target & "00");
            when OP_BEQ =>
                if (id_rs = id_rt) then
                    id_branch_taken <= '1';
                    id_branch_target <= std_logic_vector(signed(id_npc) + signed(id_immediate));
                end if;
            when OP_BNE =>
                if (id_rs /= id_rt) then
                    id_branch_taken <= '1';
                    id_branch_target <= std_logic_vector(signed(id_npc) + signed(id_immediate));
                end if;
            when others => null;
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
                    ex_rs          <= id_rs;
                    ex_rt          <= id_rt;
                    ex_immediate   <= id_immediate;
                end if;
            end if;
        end if;
    end process;
    
    --ex

    alu1 : alu port map(a => a, b => b, opcode => ex_instruction(31 downto 26), shamt => ex_instruction(10 downto 6), funct => ex_instruction(5 downto 0), output => ex_alu_result);
    
    a <= ex_rs;
    alu_input : process(ex_instruction, ex_rt, ex_immediate)
    begin
    	op_input : case ex_instruction(31 downto 26) is
    		when "000000" => b <= ex_rt;
    			fn_mf_write_en : case ex_instruction(5 downto 0) is
    				when "011000" => mf_write_en <= '1'; --mult
    				when "011010" => mf_write_en <= '1'; --div
    				when others   => mf_write_en <= '0';
    			end case fn_mf_write_en;
    			fn_mf_read : case ex_instruction(5 downto 0) is
    				when "010010" => mf_read <= "01"; --mflo
    				when "010000" => mf_read <= "10"; --mfhi
    				when others   => mf_read <= "00"; --default
    			end case fn_mf_read;
    		when others => b <= ex_immediate; -- default values
    			mf_write_en <= '0';
    			mf_read     <= "00";
    	end case op_input;
    end process;

    mf_fns : process(clock, reset)
    begin
    	if (reset = '1') then
    		mflo      <= (others => '0');
    		mfhi      <= (others => '0');
    		ex_output <= (others => '0');
    	elsif (rising_edge(clock)) then
    		if (mf_write_en = '1') then
    			mflo <= ex_alu_result(31 downto 0);
    			mfhi <= ex_alu_result(63 downto 32);
    		else
    			mflo <= mflo;
    			mfhi <= mfhi;
    		end if;
    	elsif (falling_edge(clock)) then
    		if (mf_read = "01") then
    			ex_mf_result <= mflo;
    		elsif (mf_read = "10") then
    			ex_mf_result <= mfhi;
    		end if;
    	end if;
    end process;

    with mf_read select ex_output <=
    	ex_mf_result               when "01",
    	ex_mf_result               when "10",
    	ex_alu_result(31 downto 0) when others;

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

    -- stalls

    pc_enable <= not if_waitrequest;
    if_id_enable <= not if_waitrequest;
    if_id_reset <= id_branch_taken;
    id_ex_enable <= '1';
    id_ex_reset <= if_waitrequest;
    ex_mem_enable <= '1';
    ex_mem_reset <= '0';
    mem_wb_enable <= '1';
    mem_wb_reset <= '0';

end architecture;
