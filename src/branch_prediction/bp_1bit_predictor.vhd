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
end entity bp_1bit_predictor;

architecture arch of bp_1bit_predictor is
    type bht_element_type is array (0 to 2 ** BHT_BITS) of std_logic;

    constant Taken    : std_logic := '0';
    constant NotTaken : std_logic := '1';

    signal bht_table           : bht_element_type;
    signal prediction_internal : std_logic := '0';
    signal state               : std_logic := NotTaken;

begin
    prediction <= prediction_internal;

    state_update : process(clock, reset) is
        variable idx : integer;
    begin
        if reset = '1' then
            state <= NotTaken;
            for i in 0 to 2 ** BHT_BITS loop
                bht_table(i) <= '0';
            end loop;
        elsif rising_edge(clock) then
            if update = '1' then
                idx := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                case state is
                    when NotTaken =>
                        if prediction_incorrect = '1' then
                            state          <= Taken;
                            bht_table(idx) <= NotTaken;
                        end if;
                    when Taken =>
                        if prediction_incorrect = '1' then
                            state          <= NotTaken;
                            bht_table(idx) <= Taken;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    output : process(clock, reset) is
        variable s : std_logic;
    begin
        if reset = '1' then
            prediction_internal <= '0';
        elsif falling_edge(clock) then
            s := bht_table(to_integer(unsigned(pc(BHT_BITS + 1 downto 2))));
            if s = Taken then
                prediction_internal <= '1';
            elsif s = NotTaken then
                prediction_internal <= '0';
            end if;
        end if;
    end process;
end architecture arch;
