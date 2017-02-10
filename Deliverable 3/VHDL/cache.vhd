library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
    generic(
        ram_size : INTEGER := 32768
    );
    port(
        clock         : in  std_logic;
        reset         : in  std_logic;
        -- Avalon interface --
        s_addr        : in  std_logic_vector(31 downto 0);
        s_read        : in  std_logic;
        s_readdata    : out std_logic_vector(31 downto 0);
        s_write       : in  std_logic;
        s_writedata   : in  std_logic_vector(31 downto 0);
        s_waitrequest : out std_logic;
        m_addr        : out integer range 0 to ram_size - 1;
        m_read        : out std_logic;
        m_readdata    : in  std_logic_vector(7 downto 0);
        m_write       : out std_logic;
        m_writedata   : out std_logic_vector(7 downto 0);
        m_waitrequest : in  std_logic
    );
end cache;

architecture arch of cache is
    signal tag_hit, byte_done, word_done        : std_logic;
    signal tag_sel, word_sel                    : std_logic;
    signal word_en, word_clr, byte_en, byte_clr : std_logic;
    signal tag_out, tag                         : std_logic_vector(5 downto 0) := (others => '0');
    signal block_index                          : std_logic_vector(4 downto 0) := (others => '0');
    signal word_cnt                             : std_logic_vector(1 downto 0) := (others => '0');
    signal block_offset                         : std_logic_vector(1 downto 0) := (others => '0');
    signal byte_cnt                             : std_logic_vector(1 downto 0) := (others => '0');
    signal byte_offset                          : std_logic_vector(1 downto 0) := (others => '0');

    signal en1, en2, en3, en4     : std_logic;
    signal reg1, reg2, reg3, reg4 : std_logic_vector(7 downto 0);

    signal c_read, c_write, c_dirty_clr : std_logic;
    signal c_write_sel, c_write_reg_en  : std_logic;
    signal data_in                      : std_logic_vector(31 downto 0);

    signal data_out                 : std_logic_vector(131 downto 0);
    signal dirty, dirty_data, valid : std_logic;
    signal s_readdata_internal      : std_logic_vector(31 downto 0);

    component cache_controller is
        port(
            clock          : in  std_logic;
            reset          : in  std_logic;
            -- Avalon interface
            s_read         : in  std_logic;
            s_write        : in  std_logic;
            m_waitrequest  : in  std_logic;
            -- Cache logic interface 
            tag_hit        : in  std_logic;
            byte_done      : in  std_logic;
            word_done      : in  std_logic;
            -- Cache storage interface
            valid          : in  std_logic;
            dirty          : in  std_logic;
            dirty_data     : in  std_logic;
            -- Avalon interface
            m_read         : out std_logic;
            m_write        : out std_logic;
            s_waitrequest  : out std_logic;
            -- Cache storage interface
            c_read         : out std_logic;
            c_write        : out std_logic;
            c_write_sel    : out std_logic;
            c_write_reg_en : out std_logic;
            c_dirty_clr    : out std_logic;
            -- Cache Logic interface
            tag_sel        : out std_logic;
            word_sel       : out std_logic;
            word_en        : out std_logic;
            word_clr       : out std_logic;
            byte_en        : out std_logic;
            byte_clr       : out std_logic);
    end component;

    component cache_block is
        port(
            clock           : in  std_logic;
            reset           : in  std_logic;
            read_en         : in  std_logic;
            write_en        : in  std_logic;
            data_in         : in  std_logic_vector(31 downto 0);
            tag_in          : in  std_logic_vector(5 downto 0);
            block_index_in  : in  std_logic_vector(4 downto 0);
            block_offset_in : in  std_logic_vector(1 downto 0);
            dirty_clr       : in  std_logic;
            data_out        : out std_logic_vector(131 downto 0);
            tag_out         : out std_logic_vector(5 downto 0);
            valid_out       : out std_logic);
    end component;

begin
    controller : cache_controller
        port map(
            clock          => clock,
            reset          => reset,
            s_read         => s_read,
            s_write        => s_write,
            m_waitrequest  => m_waitrequest,
            tag_hit        => tag_hit,
            byte_done      => byte_done,
            word_done      => word_done,
            valid          => valid,
            dirty          => dirty,
            dirty_data     => dirty_data,
            m_read         => m_read,
            m_write        => m_write,
            s_waitrequest  => s_waitrequest,
            c_read         => c_read,
            c_write        => c_write,
            c_write_sel    => c_write_sel,
            c_write_reg_en => c_write_reg_en,
            c_dirty_clr    => c_dirty_clr,
            tag_sel        => tag_sel,
            word_sel       => word_sel,
            word_en        => word_en,
            word_clr       => word_clr,
            byte_en        => byte_en,
            byte_clr       => byte_clr
        );

    cache_memory : cache_block
        port map(
            clock           => clock,
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
            valid_out       => valid
        );

    tag_hit <= '1' when (s_addr(14 downto 9) = tag_out) else '0';

    with tag_sel select tag <=
        tag_out when '1',
        s_addr(14 downto 9) when others;
    block_index                       <= s_addr(8 downto 4);
    with word_sel select block_offset <=
        word_cnt when '1',
        s_addr(3 downto 2) when others;
    byte_offset <= byte_cnt;

    word_done <= (word_cnt(1) and word_cnt(0));
    byte_done <= (byte_cnt(1) and byte_cnt(0));

    word_counter : process(clock, reset)
    begin
        if (reset = '1') then
            word_cnt <= (others => '0');
        elsif (rising_edge(clock)) then
            if (word_en = '1') then
                word_cnt <= std_logic_vector(unsigned(word_cnt) + 1);
            end if;

            if (word_clr = '1') then
                word_cnt <= (others => '0');
            end if;
        end if;
    end process;

    byte_counter : process(clock, reset)
    begin
        if (reset = '1') then
            byte_cnt <= (others => '0');
        elsif (rising_edge(clock)) then
            if (byte_en = '1') then
                byte_cnt <= std_logic_vector(unsigned(byte_cnt) + 1);
            end if;

            if (byte_clr = '1') then
                byte_cnt <= (others => '0');
            end if;
        end if;
    end process;

    m_addr <= to_integer(unsigned(tag & block_index & block_offset & byte_offset));

    register_en_decoder : process(byte_offset, c_write_reg_en)
    begin
        -- default outputs
        en1 <= '0';
        en2 <= '0';
        en3 <= '0';
        en4 <= '0';

        if (c_write_reg_en = '1') then
            case byte_offset is
                when "00" =>
                    en1 <= '1';
                when "01" =>
                    en2 <= '1';
                when "10" =>
                    en3 <= '1';
                when "11" =>
                    en4 <= '1';
                when others =>
                    null;
            end case;
        end if;
    end process;

    m_readdata_reg : process(clock, reset)
    begin
        if (reset = '1') then
            reg1 <= (others => '0');
            reg2 <= (others => '0');
            reg3 <= (others => '0');
            reg4 <= (others => '0');
        elsif (rising_edge(clock)) then
            if (en1 = '1') then
                reg1 <= m_readdata;
            end if;
            if (en2 = '1') then
                reg2 <= m_readdata;
            end if;
            if (en3 = '1') then
                reg3 <= m_readdata;
            end if;
            if (en4 = '1') then
                reg4 <= m_readdata;
            end if;
        end if;
    end process;

    with c_write_sel select data_in <=
        s_writedata when '1',
        reg4 & reg3 & reg2 & reg1 when others;

    dirty <= (data_out(0) or data_out(33) or data_out(66) or data_out(99));

    with block_offset select dirty_data <=
        data_out(0) when "00",
        data_out(33) when "01",
        data_out(66) when "10",
        data_out(99) when others;

    with block_offset select s_readdata_internal <=
        data_out(32 downto 1) when "00",
        data_out(65 downto 34) when "01",
        data_out(98 downto 67) when "10",
        data_out(131 downto 100) when others;

    s_readdata <= s_readdata_internal;

    with byte_offset select m_writedata <=
        s_readdata_internal(7 downto 0) when "00",
        s_readdata_internal(15 downto 8) when "01",
        s_readdata_internal(23 downto 16) when "10",
        s_readdata_internal(31 downto 24) when others;

end arch;
