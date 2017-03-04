library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

entity alu is
  port (a, b, immediate : in  std_logic_vector(31 downto 0);
        instr           : in  std_logic_vector(31 downto 0);
        output          : out std_logic_vector(63 downto 0));
end alu;


architecture a1 of alu is
alias opcode : std_logic_vector(5  downto 0) is instr(31 downto 26);
alias rs     : std_logic_vector(4  downto 0) is instr(25 downto 21);
alias rt     : std_logic_vector(4  downto 0) is instr(20 downto 16);
alias rd     : std_logic_vector(4  downto 0) is instr(15 downto 11);
alias shift  : std_logic_vector(4  downto 0) is instr(10 downto 6);
alias funct  : std_logic_vector(5  downto 0) is instr(5  downto 0);
alias imm    : std_logic_vector(15 downto 0) is instr(15 downto 0);

begin

alu: process(a,b,instr)
begin
    OP: case opcode is
      when "000000" => 
        FN: case funct is
      	  when "100000" => output(31 downto 0 )  <= std_logic_vector(signed(a) + signed(b));                            -- ADD
          when "100010" => output(31 downto 0 )  <= std_logic_vector(signed(a) - signed(b));                            -- SUB
          when "011000" => output                <= std_logic_vector(signed(a) * signed(b));                            -- MULT
          when "011010" => output(63 downto 32)  <= std_logic_vector(signed(a) mod signed(b));                          -- DIV
                           output(31 downto 0 )  <= std_logic_vector(signed(a) / signed(b));              
          when "101010" =>                                                                                              -- SLT
            if signed(a) < signed(b) then output <= std_logic_vector(to_signed(1, 64));
            else                          output <= std_logic_vector(to_signed(0, 64));
            end if;
          when "100100" => output(31 downto 0 )  <= a and b;                                                            -- AND
          when "100101" => output(31 downto 0 )  <= a or  b;                                                            -- OR
          when "100111" => output(31 downto 0 )  <= a nor b;                                                            -- NOR
          when "100110" => output(31 downto 0 )  <= a xor b;     
          when "010000" => NULL;                                                                                        -- MFHI
          when "010010" => NULL;                                                                                        -- MFLO                                                       -- XOR
          when "000000" => output(31 downto 0 )  <= std_logic_vector(unsigned(a) sll to_integer(unsigned(shift)));      -- SLL
          when "000010" => output(31 downto 0 )  <= std_logic_vector(unsigned(a) srl to_integer(unsigned(shift)));      -- SRL
          when "000011" => output(31 downto 0 )  <= to_stdlogicvector(to_bitvector(a) sra to_integer(unsigned(shift))); -- SRA
          when "001000" => NULL;                                                                                        -- JR
          when others   => NULL;
      	end case FN;
      when "000010" => NULL;                                                                                            -- J
      when "000011" => NULL;                                                                                            -- JAL
      when "000100" =>                                                                                                  -- BEQ
        if a  = b then output                    <= std_logic_vector(to_unsigned(1,64)); 
        else           output                    <= std_logic_vector(to_unsigned(0,64));
        end if;
	  when "000101" =>                                                                                                  -- BNE
        if a /= b then output                    <= std_logic_vector(to_unsigned(1,64));
        else           output                    <= std_logic_vector(to_unsigned(1,64));
        end if;
      when "001000" => output(31 downto 0 )      <= std_logic_vector(signed(a) + signed(b));                            -- ADDI
      when "001010" =>                                                                                                  -- SLTI
        if signed(a) < signed(imm) then output   <= std_logic_vector(to_unsigned(1,64));
        else                            output   <= std_logic_vector(to_unsigned(0,64));
        end if;
      when "001100" => output(31 downto 0 )      <= a and b;                                                            -- ANDI
      when "001101" => output(31 downto 0 )      <= a or  b;                                                            -- ORI
      when "001110" => output(31 downto 0 )      <= a xor b;                                                            -- XORI
      when "001111" => output(31 downto 0 )      <= std_logic_vector(unsigned(a) sll 16);                               -- LUI 
      when "100011" => NULL;                                                                                            -- LW
      when "101011" => NULL;                                                                                            -- SW
      when others   => NULL;
    end case OP;
end process;
end a1;