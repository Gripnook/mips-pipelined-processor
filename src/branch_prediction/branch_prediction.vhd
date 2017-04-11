library ieee;
use ieee.std_logic_1164.all;

package branch_prediction is
    constant DEFAULT_BHT_BITS : integer := 4;

    component bp_predict_not_taken is
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
    end component;

    component bp_predict_taken is
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
    end component;

    component bp_1bit_predictor is
        generic(BHT_BITS : integer := DEFAULT_BHT_BITS);
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
    end component;

    component bp_2bit_predictor is
        generic(BHT_BITS : integer := DEFAULT_BHT_BITS);
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
    end component;

    component bp_correlating_2_2 is
        generic(BHT_BITS : integer := DEFAULT_BHT_BITS);
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
    end component;

    component bp_tournament_2_2 is
        generic(BHT_BITS : integer := DEFAULT_BHT_BITS);
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
    end component;

end branch_prediction;
