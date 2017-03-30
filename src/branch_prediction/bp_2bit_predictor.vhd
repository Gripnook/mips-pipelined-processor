library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bp_2bit_predictor is
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
end entity bp_2bit_predictor;

architecture arch of bp_2bit_predictor is
    type bht_element_type is array (0 to 2 ** BHT_BITS) of std_logic;
    type state_type is (Taken0, Taken1, NotTaken0, NotTaken1);

    signal bht_table           : bht_element_type;
    signal prediction_internal : std_logic  := '0';
    signal state               : state_type := NotTaken1;

begin
    prediction <= prediction_internal;

    state_update : process(clock, reset) is
    begin
        if reset = '1' then
            state <= NotTaken1;
            for i in 0 to 2 ** BHT_BITS loop
                bht_table(i) <= '0';
            end loop;
        elsif rising_edge(clock) then
            if update = '1' then
                case state is
                    when NotTaken0 =>
                        if prediction_incorrect = '1' then
                            state                                                               <= Taken1;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '1';
                        else
                            state                                                               <= NotTaken1;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '0';
                        end if;
                    when NotTaken1 =>
                        if prediction_incorrect = '1' then
                            state                                                               <= NotTaken0;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '0';
                        end if;
                    when Taken0 =>
                        if prediction_incorrect = '1' then
                            state                                                               <= NotTaken1;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '0';
                        else
                            state                                                               <= Taken1;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '1';
                        end if;
                    when Taken1 =>
                        if prediction_incorrect = '1' then
                            state                                                               <= Taken0;
                            bht_table(to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)))) <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;

    output : process(clock, reset) is
    begin
        if reset = '1' then
            prediction_internal <= '0';
        elsif falling_edge(clock) then
            prediction_internal <= bht_table(to_integer(unsigned(pc(BHT_BITS + 1 downto 2))));
        end if;
    end process;
end architecture arch;
