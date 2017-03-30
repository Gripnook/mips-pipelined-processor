library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bp_1bit_predictor is
    generic(BHT_BITS : integer);
    port(
        clock                : in  std_logic;
        reset                : in  std_logic;
        pc                   : in  std_logic_vector(31 downto 0);
        update               : in  std_logic; -- '1' if a prediction should be updated, '0' otherwise
        previous_pc          : in  std_logic_vector(31 downto 0);
        previous_prediction  : in  std_logic;
        prediction_incorrect : in  std_logic; -- '1' if prediction was incorrect, '0' otherwise
        prediction           : out std_logic -- '1' = predict taken, '0' = predict not taken
    );
end bp_1bit_predictor;

architecture arch of bp_1bit_predictor is
    type bht_type is array (0 to 2 ** BHT_BITS - 1) of std_logic;

    constant Taken    : std_logic := '1';
    constant NotTaken : std_logic := '0';

    signal bht                 : bht_type;
    signal prediction_internal : std_logic := '0';

begin
    prediction <= prediction_internal;

    state_update : process(clock, reset)
        variable idx : integer;
    begin
        if reset = '1' then
            for i in 0 to 2 ** BHT_BITS - 1 loop
                bht(i) <= NotTaken;
            end loop;
        elsif rising_edge(clock) then
            if update = '1' then
                -- We ignore the lower two bits since the PC is word aligned
                idx := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                case bht(idx) is
                    when NotTaken =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= Taken;
                        end if;
                    when Taken =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= NotTaken;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    output : process(clock, reset)
        variable state : std_logic;
    begin
        if reset = '1' then
            prediction_internal <= '0';
        elsif falling_edge(clock) then
            -- We ignore the lower two bits since the PC is word aligned
            state := bht(to_integer(unsigned(pc(BHT_BITS + 1 downto 2))));
            if state = Taken then
                prediction_internal <= '1';
            else
                prediction_internal <= '0';
            end if;
        end if;
    end process;
end architecture;
