-------------------------------------------------------------------------------
-- Memory.vhd
-------------------------------------------------------------------------------
--
-- Simple non-synthesizable SRAM memory template
-- fcampi@sfu.ca Oct 2013

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;


entity SRAM is

  generic ( addr_size : integer :=11;
            word_size : integer := 32 );
  port (  clk	    : 	in  std_logic;
          rdn	    :	in  std_logic;
          wrn	    :	in  std_logic;
          address   :	in  std_logic_vector(addr_size-1 downto 0);
	  bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
          data_in   :	in  std_logic_vector(word_size-1 downto 0);
          data_out  :	out std_logic_vector(word_size-1 downto 0) );

end SRAM;

architecture behv of SRAM is			
  
  signal addr_reg       : std_logic_vector(7 downto 0);
  signal data_reg,M_reg : std_logic_vector(15 downto 0);
  
  begin
    
    process(clk)
    begin 
      if clk'event and clk='1' then 
        --Mask
	M_reg <= bit_wen; 
	-- Data out
	if rdn='0' then 
          addr_reg <= address;	
	end if; 
        -- Data Write 
        if wrn='0' then 
	  data_reg <= data_in;
        end if;
      end if;
    end process;

	data_out <= data_reg AND M_reg when ((addr_reg(0) OR addr_reg(1) or addr_reg(2) OR addr_reg(3) or addr_reg(4) or addr_reg(5) or addr_reg(6) or addr_reg(7) or addr_reg(8) or addr_reg(9) or addr_reg(10)) = '1' ) else data_reg XOR M_reg;





end behv;
