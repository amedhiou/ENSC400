--------------------------------------------------------------------------
-- Ahmed Medhioub                                                       --
-- SFU | ENSC 400 | Spring 2014                                         --
--                                                                      --
-- Description:                                                         --
--	*FlipFlop based Register with write enable and read enable      --  
--	*the default word size is 32                                    --
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity REG is
	generic( word_width : integer := 32);
	Port (  clk  : in std_logic; -- clock input
			din  : in std_logic_vector(word_width-1 downto 0); -- input data
			dout : out std_logic_vector(word_width-1 downto 0); -- data output
			wen  : in std_logic; -- write enable
			ren  : in std_logic); -- read enable for dout output
end REG;

architecture Behavioral of REG is

	signal idata: std_logic_vector(word_width-1 downto 0);

begin

	-- write data process
	write_to_reg: process(clk)
	begin

	if clk'event and clk = '1' then
		if wen = '1' then
			idata <= din;
		end if;
	end if;

	end process;

	-- Read Data 
	drive_output: process(idata, ren)
	begin

	if ren = '1' then
		dout <= idata;
	else
		dout <= (others => 'Z');
	end if;
	end process;

end Behavioral;
