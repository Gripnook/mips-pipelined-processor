library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_block is
    generic(TAG_WIDTH   : integer;
            INDEX_WIDTH : integer);
    port(clock           : in  std_logic;
         reset           : in  std_logic;
         read_en         : in  std_logic;
         write_en        : in  std_logic;
         data_in         : in  std_logic_vector(31 downto 0);
         tag_in          : in  std_logic_vector(TAG_WIDTH - 1 downto 0);
         block_index_in  : in  std_logic_vector(INDEX_WIDTH - 1 downto 0);
         block_offset_in : in  std_logic_vector(1 downto 0);
         dirty_clr       : in  std_logic;
         data_out        : out std_logic_vector(131 downto 0);
         tag_out         : out std_logic_vector(TAG_WIDTH - 1 downto 0);
         valid_out       : out std_logic);
end cache_block;

architecture a1 of cache_block is
    type data_mem_type is array (0 to 2 ** (INDEX_WIDTH + 2) - 1) of std_logic_vector(31 downto 0);
    type dirty_mem_type is array (0 to 2 ** (INDEX_WIDTH + 2) - 1) of std_logic;
    type tag_mem_type is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic_vector(TAG_WIDTH - 1 downto 0);
    type valid_mem_type is array (0 to 2 ** INDEX_WIDTH - 1) of std_logic;

    signal data_mem  : data_mem_type;
    signal dirty_mem : dirty_mem_type;
    signal tag_mem   : tag_mem_type;
    signal valid_mem : valid_mem_type := (others => '0');

begin
    process(clock, reset)
        variable block_addr, read_word_addr, write_word_addr : integer;
    begin
        if (reset = '1') then
            valid_mem <= (others => '0');
        elsif (falling_edge(clock)) then
            block_addr     := to_integer(unsigned(block_index_in));
            read_word_addr := to_integer(unsigned(std_logic_vector'(block_index_in & "00")));

            if (read_en = '1') then
                data_out  <= data_mem(read_word_addr + 3) & dirty_mem(read_word_addr + 3) & data_mem(read_word_addr + 2) & dirty_mem(read_word_addr + 2) & data_mem(read_word_addr + 1) & dirty_mem(read_word_addr + 1) & data_mem(read_word_addr) & dirty_mem(read_word_addr);
                tag_out   <= tag_mem(block_addr);
                valid_out <= valid_mem(block_addr);
            end if;
        elsif (rising_edge(clock)) then
            block_addr      := to_integer(unsigned(block_index_in));
            write_word_addr := to_integer(unsigned(std_logic_vector'(block_index_in & block_offset_in)));

            if (write_en = '1') then
                valid_mem(block_addr)     <= '1';
                tag_mem(block_addr)       <= tag_in;
                data_mem(write_word_addr) <= data_in;
                if (dirty_clr = '1') then
                    dirty_mem(write_word_addr) <= '0';
                else
                    dirty_mem(write_word_addr) <= '1';
                end if;
            end if;

            if (dirty_clr = '1') then
                dirty_mem(write_word_addr) <= '0';
            end if;
        end if;
    end process;

end a1;
