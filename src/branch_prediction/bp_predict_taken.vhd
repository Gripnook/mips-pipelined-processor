library ieee;
use ieee.std_logic_1164.all;

entity bp_predict_taken is
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
end bp_predict_taken;

architecture arch of bp_predict_taken is
begin
    prediction <= '1';

end architecture;
