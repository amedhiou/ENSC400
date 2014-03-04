--------------------------------------------------------------------------
-- Author      : Ahmed Medhioub                                         --
-- CopyRights  : SFU | ENSC 400 | Spring 2014                           --
-- File        : BUS_M_4S.vhd 											--
-- Description : 														--
--	* This is the Top level HDL for the bus                             --
--	* Connects the Bus master to the 4 slaves 							--
--	* In order to change slaves, address multiplexing has to be modified--
--	  in Top_BUS then change the slaves connection here                 --
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity BUS_MSSSS is
	generic( word_width : integer  := 32;
			 address_width : integer :=  32);
	Port (  clk   : in std_logic; 
			-- CPU side pins
			Addr    : in std_logic_vector (address_width-1 downto 0);
			Rdata   : out std_logic_vector(word_width-1 downto 0); -- data input
			Wdata   : in std_logic_vector(word_width-1 downto 0); -- data output
			Write   : in std_logic; -- write strobe
			Read    : in std_logic; -- write enable
			Ready_n : out std_logic); -- busy signal
end BUS_MSSSS;

architecture Behavioral of BUS_MSSSS is

component SRAM is
generic ( addr_size : integer := 8;
			word_size : integer := 32 );
		port (  clk       :   in  std_logic;
		rdn       :   in  std_logic;
		wrn       :   in  std_logic;
		address   :   in  std_logic_vector(addr_size-1 downto 0);
		bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
		data_in   :   in  std_logic_vector(word_size-1 downto 0);
		data_out  :   out std_logic_vector(word_size-1 downto 0) );
	
end component;

component Top_BUS is
	generic( word_width : integer  := 32;
			 address_width : integer :=  32);
	Port (  clk   : in std_logic; 
			-- CPU side pins
			cpuAddr       : in std_logic_vector (address_width-1 downto 0);
			cpuRdata      : out std_logic_vector(word_width-1 downto 0); -- data input
			cpuWdata      : in std_logic_vector(word_width-1 downto 0); -- data output
			cpuWrite      : in std_logic; -- write strobe
			cpuRead       : in std_logic; -- write enable
			cpuReady_n    : out std_logic; -- busy signal
			-- Slave 1 side pins
			slave_1_addr  : out std_logic_vector (address_width-3 downto 0);
            slave_1_rdata : in std_logic_vector(word_width-1 downto 0); -- data input
	        slave_1_wdata : out std_logic_vector(word_width-1 downto 0); -- data output
			slave_1_write : out std_logic; -- write strobe
			slave_1_read  : out std_logic; -- write enable
			-- Slave 2 side pins
			slave_2_addr  : out std_logic_vector (address_width-3 downto 0);
            slave_2_rdata : in std_logic_vector(word_width-1 downto 0); -- data input
	        slave_2_wdata : out std_logic_vector(word_width-1 downto 0); -- data output
			slave_2_write : out std_logic; -- write strobe
			slave_2_read  : out std_logic; -- write enable
			-- Slave 3 side pins
			slave_3_addr  : out std_logic_vector (address_width-3 downto 0);
            slave_3_rdata : in std_logic_vector(word_width-1 downto 0); -- data input
	        slave_3_wdata : out std_logic_vector(word_width-1 downto 0); -- data output
			slave_3_write : out std_logic; -- write strobe
			slave_3_read  : out std_logic; -- write enable
			-- Slave 4 side pins 
			slave_4_addr  : out std_logic_vector (address_width-3 downto 0);
            slave_4_rdata : in std_logic_vector(word_width-1 downto 0); -- data input
	        slave_4_wdata : out std_logic_vector(word_width-1 downto 0); -- data output
			slave_4_write : out std_logic; -- write strobe
			slave_4_read  : out std_logic); -- write enable

end component;

-- Mask is all 1 for now
signal Mask : std_logic_vector(word_width-1 downto 0);


signal slave1_read    : std_logic ;
signal slave1_write   : std_logic ;
signal slave1_addr    : std_logic_vector(address_width-3 downto 0);
signal slave1_wdataIn : std_logic_vector(word_width-1 downto 0);
signal slave1_rdataout: std_logic_vector(word_width-1 downto 0);

signal slave2_read    : std_logic ;
signal slave2_write   : std_logic ;
signal slave2_addr    : std_logic_vector(address_width-3 downto 0);
signal slave2_wdataIn : std_logic_vector(word_width-1 downto 0);
signal slave2_rdataout: std_logic_vector(word_width-1 downto 0);

signal slave3_read    : std_logic ;
signal slave3_write   : std_logic ;
signal slave3_addr    : std_logic_vector(address_width-3 downto 0);
signal slave3_wdataIn : std_logic_vector(word_width-1 downto 0);
signal slave3_rdataout: std_logic_vector(word_width-1 downto 0);

signal slave4_read    : std_logic ;
signal slave4_write   : std_logic ;
signal slave4_addr    : std_logic_vector(address_width-3 downto 0);
signal slave4_wdataIn : std_logic_vector(word_width-1 downto 0);
signal slave4_rdataout: std_logic_vector(word_width-1 downto 0);

begin

Mask <= (others => '0') ;

Slave1 : SRAM   generic map (addr_size => 10 )
				port map(
					clk        => clk ,	
					rdn	       => slave1_read ,
			        wrn	       => slave1_write ,
		   			address    => slave1_addr(11 DOWNTO 2),
          			data_in    => slave1_wdataIn,
          			bit_wen    => Mask,
          			data_out   => slave1_rdataout
				); 

Slave2 : SRAM    generic map (addr_size => 10 )
				port map(
					clk        => clk ,	
					rdn	       => slave2_read ,
			        wrn	       => slave2_write ,
		   			address    => slave2_addr(11 DOWNTO 2),
          			data_in    => slave2_wdataIn,
          			bit_wen         => Mask,
          			data_out   => slave2_rdataout
				); 

Slave3 : SRAM   generic map (addr_size => 10 )
				port map(
					clk        => clk ,	
					rdn	       => slave3_read ,
			        wrn	       => slave3_write ,
		   			address    => slave3_addr(11 DOWNTO 2),
          			data_in    => slave3_wdataIn,
          			bit_wen          => Mask,
          			data_out   => slave3_rdataout
				); 

Slave4 : SRAM   generic map (addr_size => 10 )
				port map(
					clk        => clk ,	
					rdn	       => slave4_read ,
			        wrn	       => slave4_write ,
		   			address    => slave4_addr(11 DOWNTO 2),
          			data_in    => slave4_wdataIn,
          			bit_wen          => Mask,
          			data_out   => slave4_rdataout
				); 

Master : Top_BUS Port map(  
			clk           => clk, 
			-- CPU side pins
			cpuAddr       => Addr,
			cpuRdata      => Rdata,
			cpuWdata      => Wdata,
			cpuWrite      => Write,
			cpuRead       => Read,
			cpuReady_n    => Ready_n,
			-- Slave 1 side pins
			slave_1_addr  => slave1_addr,
            slave_1_rdata => slave1_rdataout,
	        slave_1_wdata => slave1_wdataIn,
			slave_1_write => slave1_write,
			slave_1_read  => slave1_read ,
			-- Slave 2 side pins
			slave_2_addr  => slave2_addr,
            slave_2_rdata => slave2_rdataout,
	        slave_2_wdata => slave2_wdataIn,
			slave_2_write => slave2_write,
			slave_2_read  => slave2_read ,
			-- Slave 3 side pins
			slave_3_addr  => slave3_addr,
            slave_3_rdata => slave3_rdataout,
	        slave_3_wdata => slave3_wdataIn,
			slave_3_write => slave3_write,
			slave_3_read  => slave3_read ,
			-- Slave 4 side pins 
			slave_4_addr  => slave4_addr,
            slave_4_rdata => slave4_rdataout,
	        slave_4_wdata => slave4_wdataIn,
			slave_4_write => slave4_write,
			slave_4_read  => slave4_read 
			); 

end Behavioral;
