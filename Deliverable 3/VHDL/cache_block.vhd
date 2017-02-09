library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_block is
    port(
        reset           : in std_logic;
        clock           : in  std_logic;
        read            : in  std_logic;
        write           : in  std_logic;
        data_in         : in  std_logic_vector(31 downto 0);
        tag_in          : in  std_logic_vector(5 downto 0);
        block_index_in  : in  std_logic_vector(4 downto 0);
        block_offset_in : in  std_logic_vector(1 downto 0);
        dirty_clr       : in  std_logic;
        data_out        : out std_logic_vector(131 downto 0);
        tag_out         : out std_logic_vector(5 downto 0);
        valid_out       : out std_logic);
    
end cache_block;

architecture a1 of cache_block is
    TYPE MEM IS ARRAY (31 downto 0) OF STD_LOGIC_VECTOR(138 DOWNTO 0); --128 for 4 words + 4 dirty bit + tag + 1 valid bit
        -- format follows
        --138 valid | 137-132 tag 
        
        --131-100 data offset 11, dirty 99
        --98-67 data offset 10, dirty 66 
        --65-34 data offset 01, dirty 33
        --32-1 data offset 00, dirty 0
    SIGNAL ram_block              : MEM := (others => (others => '0'));
     
         -- debug signals for ease of visibility
     TYPE valid is array(31 downto 0) of std_logic;
     signal debug_valid_array      : valid := (others => '0'); -- for ease of debugging
     type dirty is array(31 downto 0) of std_logic_vector(3 downto 0);
     signal debug_dirty              : dirty := (others => (others => '0'));
     type tag is array(31 downto 0) of std_logic_vector(5 downto 0);
     signal debug_tag              : tag   := (others => (others => '0'));
     
     begin
     -- debug signals
     debug_valid_array(to_integer(unsigned(block_index_in))) <= ram_block((to_integer(unsigned(block_index_in))))(138);
     debug_dirty(to_integer(unsigned(block_index_in)))(0)    <= ram_block((to_integer(unsigned(block_index_in))))(0);
     debug_dirty(to_integer(unsigned(block_index_in)))(1)    <= ram_block((to_integer(unsigned(block_index_in))))(33);
     debug_dirty(to_integer(unsigned(block_index_in)))(2)    <= ram_block((to_integer(unsigned(block_index_in))))(66);
     debug_dirty(to_integer(unsigned(block_index_in)))(3)    <= ram_block((to_integer(unsigned(block_index_in))))(99);
     debug_tag(to_integer(unsigned(block_index_in)))         <= ram_block((to_integer(unsigned(block_index_in))))(137 downto 132);
     
    process(clock) -- component in data_path
    begin
        if(clock'event and clock = '1') then
            if(reset = '1') then
                ram_block <= (others => (others => '0'));
            end if;
        
            if(read = '1') then
                valid_out <= ram_block((to_integer(unsigned(block_index_in))))(138); --valid bit
                tag_out <= ram_block((to_integer(unsigned(block_index_in))))(137 downto 132); -- tag
                data_out <= ram_block((to_integer(unsigned(block_index_in))))(131 downto 0); -- data
            end if;
                    

            
            if(write = '1') then 
                ram_block((to_integer(unsigned(block_index_in))))(138) <= '1'; --valid
                if(block_offset_in = "00") then
                    if(dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(0) <= '0'; -- dirty bit offset 00
                    elsif(dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(0) <= '1'; --dirty bit offset 00
                    end if;
                        ram_block((to_integer(unsigned(block_index_in))))(32 downto 1) <= data_in; -- data offset 00
                elsif(block_offset_in = "01") then
                    if(dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(33) <= '0'; -- dirty bit offset 01
                    elsif(dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(33) <= '1'; -- dirty bit offset 01
                    end if;
                        ram_block((to_integer(unsigned(block_index_in))))(65 downto 34) <= data_in; -- data offset 01
                elsif(block_offset_in = "10") then
                    if(dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(66) <= '0'; -- dirty bit offset 10
                    elsif(dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(66) <= '1'; -- dirty bit offset 10
                    end if;
                        ram_block((to_integer(unsigned(block_index_in))))(98 downto 67) <= data_in; -- data offset 10
                elsif(block_offset_in = "11") then
                    if(dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(99) <= '0'; -- dirty bit offset 11
                    elsif(dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(99) <= '1'; -- -- dirty bit offset 0
                    end if;
                        ram_block((to_integer(unsigned(block_index_in))))(131 downto 100) <= data_in; -- data offset 11
                end if;
            end if;
            
            if(dirty_clr = '1') then
                if(block_offset_in = "00") then
                    ram_block((to_integer(unsigned(block_index_in))))(0) <= '0'; -- dirty bit offset 00
                elsif(block_offset_in = "01") then
                    ram_block((to_integer(unsigned(block_index_in))))(33) <= '0'; -- dirty bit offset 01
                elsif(block_offset_in = "10") then
                    ram_block((to_integer(unsigned(block_index_in))))(66) <= '0'; -- dirty bit offset 10
                elsif(block_offset_in = "11") then
                    ram_block((to_integer(unsigned(block_index_in))))(99) <= '0'; -- dirty bit offset 11
                end if;
            end if;
        end if;
     
     
    end process;

end a1;