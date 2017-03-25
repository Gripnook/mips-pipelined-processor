library ieee;
use ieee.std_logic_1164.all;

entity arbiter is
    port(
        clock         : in  std_logic;
        reset         : in  std_logic;
        i_addr        : in  std_logic_vector(7 downto 0);
        i_read        : in  std_logic;
        i_readdata    : out std_logic_vector(7 downto 0);
        i_write       : in  std_logic;
        i_writedata   : in  std_logic_vector(7 downto 0);
        i_waitrequest : out std_logic;
        d_addr        : in  std_logic_vector(7 downto 0);
        d_read        : in  std_logic;
        d_readdata    : out std_logic_vector(7 downto 0);
        d_write       : in  std_logic;
        d_writedata   : in  std_logic_vector(7 downto 0);
        d_waitrequest : out std_logic;
        m_addr        : out std_logic_vector(7 downto 0);
        m_read        : out std_logic;
        m_readdata    : in  std_logic_vector(7 downto 0);
        m_write       : out std_logic;
        m_writedata   : out std_logic_vector(7 downto 0);
        m_waitrequest : in  std_logic
    );
end arbiter;

architecture arch of arbiter is
begin

    controller : process(clock, reset)
    begin
        if reset = '1' then
            i_waitrequest <= '0';
            d_waitrequest <= '0';
            m_read        <= '0';
            m_write       <= '0';
        elsif rising_edge(clock) then
            if m_waitrequest = '1' then
                i_waitrequest <= '1';
                d_waitrequest <= '1';
                m_read        <= '0';
                m_write       <= '0';
            elsif d_read = '1' or d_write = '1' then
                i_waitrequest <= '1';
                d_waitrequest <= m_waitrequest;
                m_read        <= d_read;
                m_write       <= d_write;
            elsif i_read = '1' or i_write = '1' then
                i_waitrequest <= m_waitrequest;
                d_waitrequest <= '1';
                m_read        <= i_read;
                m_write       <= i_write;
            end if;
        end if;
    end process;

    datapath : process(d_read, d_write, i_read, i_write)
    begin
        i_readdata  <= (others => '0');
        d_readdata  <= (others => '0');
        m_writedata <= (others => '0');
        m_addr      <= (others => '0');
        if d_read = '1' or d_write = '1' then
            d_readdata  <= m_readdata;
            m_writedata <= d_writedata;
            m_addr      <= d_addr;
        elsif i_read = '1' or i_write = '1' then
            i_readdata  <= m_readdata;
            m_writedata <= i_writedata;
            m_addr      <= i_addr;
        end if;
    end process;

end architecture arch;
