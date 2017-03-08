--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memory IS
    GENERIC(
        ram_size     : INTEGER := 32768;
        mem_delay    : time    := 0 ns;
        clock_period : time    := 1 ns
    );
    PORT(
        clock       : IN  STD_LOGIC;
        writedata   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        address     : IN  INTEGER RANGE 0 TO ram_size - 1;
        memwrite    : IN  STD_LOGIC;
        memread     : IN  STD_LOGIC;
        readdata    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        waitrequest : OUT STD_LOGIC
    );
END memory;

ARCHITECTURE rtl OF memory IS
    TYPE MEM IS ARRAY (ram_size - 1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ram_block         : MEM;
    SIGNAL read_address_reg  : INTEGER RANGE 0 to ram_size - 1;
    SIGNAL write_waitreq_reg : STD_LOGIC := '1';
    SIGNAL read_waitreq_reg  : STD_LOGIC := '1';
BEGIN
    --This is the main section of the SRAM model
    mem_process : PROCESS(clock)
    BEGIN
        --This is a cheap trick to initialize the SRAM in simulation
        IF (now < 1 ps) THEN
            For i in 0 to ram_size - 1 LOOP
                ram_block(i) <= std_logic_vector(to_unsigned(0, 32));
            END LOOP;
        end if;

        --This is the actual synthesizable SRAM block
        IF (rising_edge(clock)) THEN
            IF (memwrite = '1') THEN
                ram_block(address) <= writedata;
            END IF;
            read_address_reg <= address;
        END IF;

        IF (falling_edge(clock)) THEN
         readdata <= ram_block(read_address_reg);
        END IF;

    END PROCESS;

    --The waitrequest signal is used to vary response time in simulation
    --Read and write should never happen at the same time.
    waitreq_w_proc : PROCESS(memwrite)
    BEGIN
        IF (rising_edge(memwrite)) THEN
            write_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
        END IF;
    END PROCESS;

    waitreq_r_proc : PROCESS(memread)
    BEGIN
        IF (rising_edge(memread)) THEN
            read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
        END IF;
    END PROCESS;
    waitrequest <= write_waitreq_reg and read_waitreq_reg;

END rtl;
