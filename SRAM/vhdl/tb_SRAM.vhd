-- fcampi@sfu.ca July 2013
-- rbg2gray Testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity E is
end E;

Architecture A of E is

  	component SRAM
	generic ( addr_size : integer := 14;
	          word_size : integer := 32 );
		    
        port (clk    :   in  std_logic;
           rdn       :   in  std_logic;
	   wrn       :   in  std_logic;
	   address   :   in  std_logic_vector(addr_size-1 downto 0) ;
	   data_in   :   in  std_logic_vector(word_size-1 downto 0) ;
	   M         :   in  std_logic_vector(word_size-1 downto 0) ;
	   data_out  :   out std_logic_vector(word_size-1 downto 0));
	end component;


	signal dataIn,dataOut,Mask : std_logic_vector(31 downto 0) ;
	signal addr                : std_logic_vector(13 downto 0) ;
	signal write_n,read_n      : std_logic ;
	signal CLK                 : std_logic ;

	-------- temp Signals

	--signal dataReg             : std_logic_vector(31 downto 0) ;

	--------------------
    begin

	UUT : SRAM   port map  (clk      =>  CLK,
				rdn      =>  read_n,
				wrn      =>  write_n,
				address  =>  addr,
				data_in  =>  dataIn,
				M        =>  Mask,
				data_out =>  dataOut);

------------------------- CLK process  -------------------------

	clock_engine : process
    		begin
      		CLK <= '0';
      		wait for 3 ns;
      		CLK <= '1';
      		wait for 3 ns;
    		end process;
------------------------ Read Enable -----------------------------
    
    	read_enable : process
    		begin
    		read_n <= '0';
		wait for 2 ns;
		read_n <= '1';
		wait for 2 ns;
		end process;  
----------------------- Write enable -----------------------
	write_enable : process
    		begin
      		write_n <= '0';
      		wait for 4 ns;
      		write_n <= '1';
      		wait for 4 ns;
    		end process;
----------------------- Mask engine -----------------------
	Mask_engine : process
                begin
	        Mask <= "11111111111111111111111111111111";
	        wait for 7 ns;
	        Mask <= "00001111111111110000000000001111";
	        wait for 7 ns;
	        Mask <= "00000000111111111111111100000000";
	        wait for 7 ns;
	        Mask <= "00000000000000000000000000000000";
	        wait for 7 ns;
	        end process;

----------------------- Address changing ----------------------------
   	address_engine : process
    		begin
      		addr <= "00000000001111";
      		wait for 7 ns;
      		addr <= "00000011110000";
      		wait for 7 ns;
      		addr <= "00011100000000";
      		wait for 7 ns;
      		addr <= "11100000000000";
      		wait for 7 ns;
    		end process;
-------------------------- Write data ---------------------------
	write_data : process
 		variable count : integer := 0;
  		begin
		dataIn <= (others=>'0');
      		while true loop
        	  count := count + 1;
		  wait for 8 ns;
		  dataIn <= conv_std_logic_vector(count,32);
      		end loop;
    	end process;      
-------------------------------------------------------------------

  end A;
