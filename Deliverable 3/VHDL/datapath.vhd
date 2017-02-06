library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lpm;
use lpm.lpm_components.all;

entity datapath is
    port(
        clk            : in  std_logic; -- TODO: check to make sure port I/O is correct
        -- Avalon interface
        s_read         : out  std_logic;
        s_write        : out  std_logic;
        m_waitrequest  : out  std_logic;
        -- Cache logic interface 
        tag_hit        : out  std_logic;
        byte_done      : out  std_logic;
        word_done      : out  std_logic;
        -- Cache storage interface
        valid          : out  std_logic;
        dirty          : out  std_logic;
        dirty_data     : out  std_logic;
        -- Avalon interface
        m_read         : in std_logic;
        m_write        : in std_logic;
        s_waitrequest  : in std_logic;
        -- Cache storage interface
        c_read         : in std_logic;
        c_write        : in std_logic;
        c_write_sel    : in std_logic;
        c_write_reg_en : in std_logic;
        c_dirty_clr    : in std_logic;
        -- Cache Logic interface
        tag_sel        : in std_logic;
        word_sel       : in std_logic;
        word_en        : in std_logic;
        word_clr       : in std_logic;
        byte_en        : in std_logic;
        byte_clr       : in std_logic;
		  
		  s_adr			  : in std_logic_vector(31 downto 0));
		  --s_read 		  : in std_logic;
end datapath;

architecture a1 of datapath is
-- data_in related
	signal en1, en2, en3, en4: std_logic;
	signal reg1, reg2, reg3, reg4: std_logic_vector(7 downto 0);
	signal m_readdata: std_logic_vector(7 downto 0);
	signal regdata, s_writedata, data_in: std_logic_vector(31 downto 0); --data_in in component
	signal byte_offset: std_logic_vector(1 downto 0);
-- block related
	signal word_cnt, byte_cnt, block_offset: std_logic_vector(1 downto 0);
	signal m_adr: std_logic_vector(31 downto 0);
	signal tag_out, tag: std_logic_vector(5 downto 0); --tag_out also used in data_out
	signal block_index: std_logic_vector(4 downto 0);
-- data_out related
	signal data_out: std_logic_vector(131 downto 0);
	signal m_writedata: std_logic_vector(7 downto 0);
	signal s_readdata: std_logic_vector(31 downto 0);
-- component related
	signal read, write, dirty_clr: std_logic;
	signal tag_in: std_logic_vector(5 downto 0);
	signal block_index_in: std_logic_vector(4 downto 0);
	signal block_offset_in: std_logic_vector(1 downto 0);
	signal data_in_comp: std_logic_vector(31 downto 0);

	signal data_out_comp: std_logic_vector(131 downto 0);
	signal tag_out_comp: std_logic_vector(5 downto 0);
	signal valid_out: std_logic;
	
-- to be organized later
begin
-----------------------------------------------------------
--	Matching equivalent signals
-----------------------------------------------------------
	byte_offset <= byte_cnt;
	block_index <= s_adr(8 downto 4);

------------------------------------------------------------
--	data_in related
------------------------------------------------------------
	
	with c_write_sel select data_in <= --c_write_sel MUX
		regdata when '0',
		s_writedata when '1';
		
	regdata(31 downto 24) <= reg4; --readdata placed
	regdata(23 downto 16) <= reg3;	
	regdata(15 downto 8)  <= reg2;	
	regdata(7 downto 0)	 <= reg1;
	
	Register_en_decoder: process(byte_offset, c_write_reg_en) --Register enable to take read decoder
	begin
		if(c_write_reg_en = '1') then
			if(byte_offset(1) = '0') then
				en3 <= '0';
				en4 <= '0';
				if(byte_offset(0) = '0') then
					en1 <= '1';
					en2 <= '0';
				elsif(byte_offset(0) = '1') then
					en1 <= '0';
					en2 <= '1';
				end if;
			elsif(byte_offset(1) = '1') then
				en1 <= '0';
				en2 <= '0';
				if(byte_offset(0) = '0') then
					en3 <= '1';
					en4 <= '0';
				elsif(byte_offset(0) = '1') then
					en3 <= '0';
					en4 <= '1';
				end if;
			end if;
		elsif(c_write_reg_en = '0') then
			en1 <= '0';
			en2 <= '0';
			en3 <= '0';
			en4 <= '0';
		end if;
	end process;
	
	m_readdata_to_reg: process(clk) --enabled registers to take in m_readdata
	begin
		if(clk'event and clk = '1') then
			if(en1 = '1') then
				reg1 <= m_readdata;
			elsif(en2 = '1') then
				reg2 <= m_readdata;
			elsif(en3 = '1') then
				reg3 <= m_readdata;
			elsif(en4 <= '1') then
				reg4 <= m_readdata;
			end if;
		end if;
	end process;
	
-------------------------------------------------------
--	Block Related
-------------------------------------------------------
	
	word_counter: lpm_counter -- word counter
		generic map(LPM_WIDTH => 2)
		port map (clock => clk, aclr => word_clr, q => word_cnt, cnt_en => word_en);
	
	byte_counter: lpm_counter -- byte counter
		generic map(LPM_WIDTH => 2)
		port map (clock => clk, aclr => byte_clr, q => byte_cnt, cnt_en => byte_en);
	
	word_done <= (word_cnt(1) and word_cnt(0)); --outputs relating to block
	byte_done <= (byte_cnt(1) and byte_cnt(0));
	tag_hit <= '1' when (s_adr(8 downto 4) = tag_out); -- tag_hit
	
	with word_sel select block_offset <= -- block_offset selector
		s_adr(3 downto 2) when '0',
		word_cnt          when '1';
		
	with tag_sel select tag <= -- tag selector
		s_adr(14 downto 9) when '0',
		tag_out				when '1';
		
	--m_adr(31 downto 15) <= '; -- m_adr TODO:
	m_adr(14 downto 9) <= tag;
	m_adr(8 downto 4)  <= block_index;
	m_adr(3 downto 2)  <= block_offset;
	m_adr(1 downto 0)  <= byte_offset;
	
-----------------------------------------------------------------------------
--	Data-out Related
-----------------------------------------------------------------------------
	dirty <= (data_out(0) or data_out(33) or data_out(66) or data_out(99)); -- dirty bit is at end of data group
	
	with block_offset select dirty_data <= --dirty_data
		data_out(0)  when "00",
		data_out(33) when "01",
		data_out(66) when "10",
		data_out(99) when "11";
		
	with block_offset select s_readdata <= --s_readdata
		data_out(32 downto 1)    when "00",
		data_out(65 downto 34)   when "01",
		data_out(98 downto 67)   when "10",
		data_out(131 downto 100) when "11";
		
	with byte_offset select m_writedata <= -- m_writedata
		s_readdata(7 downto 0)   when "00",
		s_readdata(15 downto 8)  when "01",
		s_readdata(23 downto 16) when "10",
		s_readdata(31 downto 24) when "11";
	
	------------------------------------------------------------------------
	--	Component Related
	------------------------------------------------------------------------
	
	component_datapath: process(clk) -- 'component' in data_path
	begin
		if(clk'event and clk = '1') then
			read <= c_read; -- taking in inputs on clk cycle
			write <= c_write;
			data_in_comp <= data_in;
			tag_in <= tag;
			block_index_in <= block_index;
			block_offset_in <= block_offset;
			dirty_clr <= c_dirty_clr;
			
			if(block_offset_in = "00") then --block offset to determine data_out data postition
				data_out_comp(32 downto 1) <= data_in_comp;
			elsif(block_offset_in = "01") then
				data_out_comp(65 downto 34) <= data_in_comp;
			elsif(block_offset_in = "10") then
				data_out_comp(98 downto 67) <= data_in_comp;
			elsif(block_offset_in = "11") then
				data_out_comp(131 downto 100) <= data_in_comp;
			end if;
			
			if(dirty_clr = '1') then --dirty bit clear 1 -> 0 dirty, controlled by controller
				if(block_offset_in = "00") then 
					data_out_comp(0) <= '0';
				elsif(block_offset_in = "01") then
					data_out_comp(33) <= '0';
				elsif(block_offset_in = "10") then
					data_out_comp(66) <= '0';
				elsif(block_offset_in = "11") then
					data_out_comp(99) <= '0';
				end if;
			elsif(dirty_clr = '0')then -- 0 -> 1 dirty, 
				if(block_offset_in = "00") then 
					data_out_comp(0) <= '1';
				elsif(block_offset_in = "01") then
					data_out_comp(33) <= '1';
				elsif(block_offset_in = "10") then
					data_out_comp(66) <= '1';
				elsif(block_offset_in = "11") then
					data_out_comp(99) <= '1';
				end if;
			end if;
			
			if(tag_in = data_in_comp(14 downto 9)) then --if tags match - valid
				valid_out <= '1';
			elsif(tag_in /= data_in_comp(14 downto 9)) then
				valid_out <= '0';
			end if;
			
			if(read = '1' or write = '1') then -- 'release' data upon read or write signal
				data_out <= data_out_comp;
				tag_out <= tag_in;
				valid <= valid_out;
				
				
			end if;
		end if;
	end process;
	
end a1;