library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity cache is
    generic(CACHE_SIZE : integer;
            RAM_SIZE   : integer);
    port(clock         : in  std_logic;
         reset         : in  std_logic;
         -- Avalon interface --
         s_addr        : in  std_logic_vector(31 downto 0);
         s_read        : in  std_logic;
         s_readdata    : out std_logic_vector(31 downto 0);
         s_write       : in  std_logic;
         s_writedata   : in  std_logic_vector(31 downto 0);
         s_waitrequest : out std_logic;
         m_addr        : out integer range 0 to RAM_SIZE - 1;
         m_read        : out std_logic;
         m_readdata    : in  std_logic_vector(31 downto 0);
         m_write       : out std_logic;
         m_writedata   : out std_logic_vector(31 downto 0);
         m_waitrequest : in  std_logic);
end cache;

architecture arch of cache is
    constant TAG_WIDTH   : integer := integer(ceil(log2(real(RAM_SIZE / CACHE_SIZE))));
    constant INDEX_WIDTH : integer := integer(ceil(log2(real(CACHE_SIZE / 4))));

    signal input_reg_en    : std_logic;
    signal s_addr_reg      : std_logic_vector(31 downto 0);
    signal s_writedata_reg : std_logic_vector(31 downto 0);
    signal s_write_reg     : std_logic;
    signal s_addr_sel      : std_logic                     := '0';
    signal s_addr_internal : std_logic_vector(31 downto 0) := (others => '0');

    signal tag_hit      : std_logic;
    signal word_done    : std_logic;
    signal tag_sel      : std_logic;
    signal word_sel     : std_logic;
    signal word_en      : std_logic;
    signal tag_out      : std_logic_vector(TAG_WIDTH - 1 downto 0);
    signal tag          : std_logic_vector(TAG_WIDTH - 1 downto 0)   := (others => '0');
    signal block_index  : std_logic_vector(INDEX_WIDTH - 1 downto 0) := (others => '0');
    signal word_cnt     : std_logic_vector(1 downto 0)               := (others => '0');
    signal block_offset : std_logic_vector(1 downto 0)               := (others => '0');

    signal c_read      : std_logic;
    signal c_write     : std_logic;
    signal c_dirty_clr : std_logic;
    signal c_write_sel : std_logic;
    signal data_in     : std_logic_vector(31 downto 0);

    signal data_out          : std_logic_vector(131 downto 0);
    signal dirty             : std_logic;
    signal dirty_data        : std_logic;
    signal valid             : std_logic;
    signal readdata_internal : std_logic_vector(31 downto 0);

    component cache_controller is
        port(clock         : in  std_logic;
             reset         : in  std_logic;
             -- Avalon interface
             s_read        : in  std_logic;
             s_write       : in  std_logic;
             m_waitrequest : in  std_logic;
             -- Cache logic interface 
             tag_hit       : in  std_logic;
             word_done     : in  std_logic;
             -- Cache storage interface
             valid         : in  std_logic;
             dirty         : in  std_logic;
             dirty_data    : in  std_logic;
             -- Avalon interface
             m_read        : out std_logic;
             m_write       : out std_logic;
             s_waitrequest : out std_logic;
             -- Cache storage interface
             c_read        : out std_logic;
             c_write       : out std_logic;
             c_write_sel   : out std_logic;
             c_dirty_clr   : out std_logic;
             -- Cache Logic interface
             tag_sel       : out std_logic;
             word_sel      : out std_logic;
             word_en       : out std_logic;
             -- Input registers
             s_write_reg   : in  std_logic;
             input_reg_en  : out std_logic;
             s_addr_sel    : out std_logic);
    end component;

    component cache_block is
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
    end component;

begin
    controller : cache_controller
        port map(clock         => clock,
                 reset         => reset,
                 s_read        => s_read,
                 s_write       => s_write,
                 m_waitrequest => m_waitrequest,
                 tag_hit       => tag_hit,
                 word_done     => word_done,
                 valid         => valid,
                 dirty         => dirty,
                 dirty_data    => dirty_data,
                 m_read        => m_read,
                 m_write       => m_write,
                 s_waitrequest => s_waitrequest,
                 c_read        => c_read,
                 c_write       => c_write,
                 c_write_sel   => c_write_sel,
                 c_dirty_clr   => c_dirty_clr,
                 tag_sel       => tag_sel,
                 word_sel      => word_sel,
                 word_en       => word_en,
                 s_write_reg   => s_write_reg,
                 input_reg_en  => input_reg_en,
                 s_addr_sel    => s_addr_sel);

    cache_memory : cache_block
        generic map(TAG_WIDTH   => TAG_WIDTH,
                    INDEX_WIDTH => INDEX_WIDTH)
        port map(clock           => clock,
                 reset           => reset,
                 read_en         => c_read,
                 write_en        => c_write,
                 data_in         => data_in,
                 tag_in          => tag,
                 block_index_in  => block_index,
                 block_offset_in => block_offset,
                 dirty_clr       => c_dirty_clr,
                 data_out        => data_out,
                 tag_out         => tag_out,
                 valid_out       => valid);

    input_regs : process(clock, reset)
    begin
        if (reset = '1') then
            s_addr_reg      <= (others => '0');
            s_writedata_reg <= (others => '0');
            s_write_reg     <= '0';
        elsif (falling_edge(clock)) then
            if (input_reg_en = '1') then
                s_addr_reg      <= s_addr;
                s_writedata_reg <= s_writedata;
                s_write_reg     <= s_write;
            end if;
        end if;
    end process;

    with s_addr_sel select s_addr_internal <=
        s_addr_reg when '1',
        s_addr when others;

    tag_hit <= '1' when (s_addr_internal(TAG_WIDTH + INDEX_WIDTH + 3 downto INDEX_WIDTH + 4) = tag_out) else '0';

    with tag_sel select tag <=
        tag_out when '1',
        s_addr_internal(TAG_WIDTH + INDEX_WIDTH + 3 downto INDEX_WIDTH + 4) when others;

    block_index <= s_addr_internal(INDEX_WIDTH + 3 downto 4);

    with word_sel select block_offset <=
        word_cnt when '1',
        s_addr_internal(3 downto 2) when others;

    word_done <= (word_cnt(1) and word_cnt(0));

    word_counter : process(clock, reset)
    begin
        if (reset = '1') then
            word_cnt <= (others => '0');
        elsif (rising_edge(clock)) then
            if (word_en = '1') then
                word_cnt <= std_logic_vector(unsigned(word_cnt) + 1);
            end if;
        end if;
    end process;

    m_addr <= to_integer(unsigned(tag & block_index & block_offset));

    with c_write_sel select data_in <=
        s_writedata_reg when '1',
        m_readdata when others;

    dirty <= (data_out(0) or data_out(33) or data_out(66) or data_out(99));

    with block_offset select dirty_data <=
        data_out(0) when "00",
        data_out(33) when "01",
        data_out(66) when "10",
        data_out(99) when others;

    with block_offset select readdata_internal <=
        data_out(32 downto 1) when "00",
        data_out(65 downto 34) when "01",
        data_out(98 downto 67) when "10",
        data_out(131 downto 100) when others;

    s_readdata  <= readdata_internal;
    m_writedata <= readdata_internal;

end arch;
