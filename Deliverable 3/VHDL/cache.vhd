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
    ---------------------------------------------------------
    --	Signals
    ---------------------------------------------------------
    -- data_in related
    signal en1, en2, en3, en4                                        : std_logic;
    signal reg1, reg2, reg3, reg4                                    : std_logic_vector(7 downto 0);
    signal regdata, data_in                                          : std_logic_vector(31 downto 0); --data_in in component
    signal byte_offset                                               : std_logic_vector(1 downto 0);
    -- block related
    signal word_cnt, byte_cnt, block_offset                          : std_logic_vector(1 downto 0);
    signal tag_out, tag                                              : std_logic_vector(5 downto 0); --tag_out also used in data_out
    signal block_index                                               : std_logic_vector(4 downto 0);
    signal tag_hit, byte_done, word_done                             : std_logic;
    signal tag_sel, word_sel, word_en, word_clr, byte_en, byte_clr   : std_logic;
    signal m_adr                                                     : std_logic_vector(31 downto 0);
    -- data_out related
    signal data_out                                                  : std_logic_vector(131 downto 0);
    signal s_readdataline                                            : std_logic_vector(31 downto 0);
    signal dirty, dirty_data, valid                                  : std_logic;
    -- component related
    signal read, write, dirty_clr                                    : std_logic;
    signal tag_in                                                    : std_logic_vector(5 downto 0);
    signal block_index_in                                            : std_logic_vector(4 downto 0);
    signal block_offset_in                                           : std_logic_vector(1 downto 0);
    signal data_in_comp                                              : std_logic_vector(31 downto 0);
    signal c_read, c_write, c_write_sel, c_write_reg_en, c_dirty_clr : std_logic;

    signal data_out_comp : std_logic_vector(131 downto 0);
    signal tag_out_comp  : std_logic_vector(5 downto 0);
    signal valid_out     : std_logic;
    -- Miscellanious connecting signals
    signal clk           : std_logic;

    -------------------------------------------------------------
    --	Components
    ------------------------------------------------------------
    component cache_controller
        port(clk            : in  std_logic;
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

begin                                   -- BEGIN
    -----------------------------------------------------------
    -- Matching signals and Components
    -----------------------------------------------------------
    m_addr      <= to_integer(unsigned(m_adr));
    clk         <= clock;
    byte_offset <= byte_cnt;
    block_index <= s_addr(8 downto 4);
    s_readdata  <= s_readdataline;

    controller : cache_controller
        port map(
            clk            => clk,
            -- Avalon interface
            s_read         => s_read,
            s_write        => s_write,
            m_waitrequest  => m_waitrequest,
            -- Cache logic interface 
            tag_hit        => tag_hit,
            byte_done      => byte_done,
            word_done      => word_done,
            -- Cache storage interface
            valid          => valid,
            dirty          => dirty,
            dirty_data     => dirty_data,
            -- Avalon interface
            m_read         => m_read,
            m_write        => m_write,
            s_waitrequest  => s_waitrequest,
            -- Cache storage interface
            c_read         => c_read,
            c_write        => c_write,
            c_write_sel    => c_write_sel,
            c_write_reg_en => c_write_reg_en,
            c_dirty_clr    => c_dirty_clr,
            -- Cache Logic interface
            tag_sel        => tag_sel,
            word_sel       => word_sel,
            word_en        => word_en,
            word_clr       => word_clr,
            byte_en        => byte_en,
            byte_clr       => byte_clr
        );

    ------------------------------------------------------------
    -- data_in related
    ------------------------------------------------------------

    with c_write_sel select data_in <=  --c_write_sel MUX
        regdata when '0',
        s_writedata when '1';

    regdata(31 downto 24) <= reg4;      --readdata placed
    regdata(23 downto 16) <= reg3;
    regdata(15 downto 8)  <= reg2;
    regdata(7 downto 0)   <= reg1;

    Register_en_decoder : process(byte_offset, c_write_reg_en) --Register enable to take read decoder
    begin
        if (c_write_reg_en = '1') then
            if (byte_offset(1) = '0') then
                en3 <= '0';
                en4 <= '0';
                if (byte_offset(0) = '0') then
                    en1 <= '1';
                    en2 <= '0';
                elsif (byte_offset(0) = '1') then
                    en1 <= '0';
                    en2 <= '1';
                end if;
            elsif (byte_offset(1) = '1') then
                en1 <= '0';
                en2 <= '0';
                if (byte_offset(0) = '0') then
                    en3 <= '1';
                    en4 <= '0';
                elsif (byte_offset(0) = '1') then
                    en3 <= '0';
                    en4 <= '1';
                end if;
            end if;
        elsif (c_write_reg_en = '0') then
            en1 <= '0';
            en2 <= '0';
            en3 <= '0';
            en4 <= '0';
        end if;
    end process;

    m_readdata_to_reg : process(clock)  --enabled registers to take in m_readdata
    begin
        if (clock'event and clock = '1') then
            if (en1 = '1') then
                reg1 <= m_readdata;
            elsif (en2 = '1') then
                reg2 <= m_readdata;
            elsif (en3 = '1') then
                reg3 <= m_readdata;
            elsif (en4 <= '1') then
                reg4 <= m_readdata;
            end if;
        end if;
    end process;

    -------------------------------------------------------
    -- Block Related
    -------------------------------------------------------

    word_counter : process(clock)
    begin
        if (clock'event and clock = '1' and word_en = '1') then
            if (word_cnt = "00") then
                word_cnt <= "01";
            elsif (word_cnt = "01") then
                word_cnt <= "10";
            elsif (word_cnt = "10") then
                word_cnt <= "11";
            elsif (word_cnt = "11") then
                word_cnt <= "00";
            end if;
        end if;
    end process;

    byte_counter : process(clock)
    begin
        if (clock'event and clock = '1' and byte_en = '1') then
            if (byte_cnt = "00") then
                byte_cnt <= "01";
            elsif (byte_cnt = "01") then
                byte_cnt <= "10";
            elsif (byte_cnt = "10") then
                byte_cnt <= "11";
            elsif (byte_cnt = "11") then
                byte_cnt <= "00";
            end if;
        end if;
    end process;

    word_done <= (word_cnt(1) and word_cnt(0)); --outputs relating to block
    byte_done <= (byte_cnt(1) and byte_cnt(0));
    tag_hit   <= '1' when (s_addr(8 downto 4) = tag_out); -- tag_hit

    with word_sel select block_offset <= -- block_offset selector
        s_addr(3 downto 2) when '0',
        word_cnt when '1';

    with tag_sel select tag <=          -- tag selector
        s_addr(14 downto 9) when '0',
        tag_out when '1';

    --m_adr(31 downto 15) <= '; -- m_adr TODO:
    m_adr(14 downto 9) <= tag;
    m_adr(8 downto 4)  <= block_index;
    m_adr(3 downto 2)  <= block_offset;
    m_adr(1 downto 0)  <= byte_offset;

    -----------------------------------------------------------------------------
    -- Data-out Related
    -----------------------------------------------------------------------------
    dirty <= (data_out(0) or data_out(33) or data_out(66) or data_out(99)); -- dirty bit is at end of data group

    with block_offset select dirty_data <= --dirty_data
        data_out(0) when "00",
        data_out(33) when "01",
        data_out(66) when "10",
        data_out(99) when "11";

    with block_offset select s_readdataline <= --s_readdata
        data_out(32 downto 1) when "00",
        data_out(65 downto 34) when "01",
        data_out(98 downto 67) when "10",
        data_out(131 downto 100) when "11";

    with byte_offset select m_writedata <= -- 
        s_readdataline(7 downto 0) when "00",
        s_readdataline(15 downto 8) when "01",
        s_readdataline(23 downto 16) when "10",
        s_readdataline(31 downto 24) when "11";

    ------------------------------------------------------------------------
    -- Component Related
    ------------------------------------------------------------------------

    component_datapath : process(clock) -- 'component' in data_path
    begin
        if (clock'event and clock = '1') then
            read            <= c_read;  -- taking in inputs on clk cycle
            write           <= c_write;
            data_in_comp    <= data_in;
            tag_in          <= tag;
            block_index_in  <= block_index;
            block_offset_in <= block_offset;
            dirty_clr       <= c_dirty_clr;

            if (block_offset_in = "00") then --block offset to determine data_out data postition
                data_out_comp(32 downto 1) <= data_in_comp;
            elsif (block_offset_in = "01") then
                data_out_comp(65 downto 34) <= data_in_comp;
            elsif (block_offset_in = "10") then
                data_out_comp(98 downto 67) <= data_in_comp;
            elsif (block_offset_in = "11") then
                data_out_comp(131 downto 100) <= data_in_comp;
            end if;

            if (dirty_clr = '1') then   --dirty bit clear 1 -> 0 dirty, controlled by controller
                if (block_offset_in = "00") then
                    data_out_comp(0) <= '0';
                elsif (block_offset_in = "01") then
                    data_out_comp(33) <= '0';
                elsif (block_offset_in = "10") then
                    data_out_comp(66) <= '0';
                elsif (block_offset_in = "11") then
                    data_out_comp(99) <= '0';
                end if;
            elsif (dirty_clr = '0') then -- 0 -> 1 dirty, 
                if (block_offset_in = "00") then
                    data_out_comp(0) <= '1';
                elsif (block_offset_in = "01") then
                    data_out_comp(33) <= '1';
                elsif (block_offset_in = "10") then
                    data_out_comp(66) <= '1';
                elsif (block_offset_in = "11") then
                    data_out_comp(99) <= '1';
                end if;
            end if;

            if (tag_in = data_in_comp(14 downto 9)) then --if tags match - valid
                valid_out <= '1';
            elsif (tag_in /= data_in_comp(14 downto 9)) then
                valid_out <= '0';
            end if;

            if (read = '1' or write = '1') then -- 'release' data upon read or write signal
                data_out <= data_out_comp;
                tag_out  <= tag_in;
                valid    <= valid_out;
            end if;
        end if;
    end process;
end arch;