library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_block is
    port(
        reset           : in  std_logic;
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
    TYPE MEM IS ARRAY (31 downto 0) OF STD_LOGIC_VECTOR(138 DOWNTO 0);
    --128 for 4 words + 4 dirty bit + tag + 1 valid bit
    -- format follows(0 dirty 1-32 data, 33 dirty 34-65 data dirty, 66 dirty 67-98 data, 99 dirty 100-131 data, 
    -- 132-137 tag, 138 valid
    SIGNAL ram_block : MEM := (others => (others => '0'));

begin
    process(reset)
    begin
    end process;

    process(clock)                      -- component in data_path
    begin
        if (clock'event and clock = '1') then
            if (reset = '1') then
                ram_block <= (others => (others => '0'));
            end if;

            if (read = '1') then
                valid_out <= ram_block((to_integer(unsigned(block_index_in))))(138);
                tag_out   <= ram_block((to_integer(unsigned(block_index_in))))(137 downto 132);
                data_out  <= ram_block((to_integer(unsigned(block_index_in))))(131 downto 0);
            end if;

            if (write = '1') then
                ram_block((to_integer(unsigned(block_index_in))))(138) <= '1';
                if (block_offset_in = "00") then
                    if (dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(0) <= '0';
                    elsif (dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(0) <= '1';
                    end if;
                    ram_block((to_integer(unsigned(block_index_in))))(32 downto 1) <= data_in;
                elsif (block_offset_in = "01") then
                    if (dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(33) <= '0';
                    elsif (dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(33) <= '1';
                    end if;
                    ram_block((to_integer(unsigned(block_index_in))))(65 downto 34) <= data_in;
                elsif (block_offset_in = "10") then
                    if (dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(66) <= '0';
                    elsif (dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(66) <= '1';
                    end if;
                    ram_block((to_integer(unsigned(block_index_in))))(98 downto 67) <= data_in;
                elsif (block_offset_in = "11") then
                    if (dirty_clr = '1') then
                        ram_block((to_integer(unsigned(block_index_in))))(99) <= '0';
                    elsif (dirty_clr = '0') then
                        ram_block((to_integer(unsigned(block_index_in))))(99) <= '1';
                    end if;
                    ram_block((to_integer(unsigned(block_index_in))))(131 downto 100) <= data_in;
                end if;
            end if;

            if (dirty_clr = '1') then
                if (block_offset_in = "00") then
                    ram_block((to_integer(unsigned(block_index_in))))(0) <= '0';
                elsif (block_offset_in = "01") then
                    ram_block((to_integer(unsigned(block_index_in))))(33) <= '0';
                elsif (block_offset_in = "10") then
                    ram_block((to_integer(unsigned(block_index_in))))(66) <= '0';
                elsif (block_offset_in = "11") then
                    ram_block((to_integer(unsigned(block_index_in))))(99) <= '0';
                end if;
            end if;
        end if;
    end process;
end a1;