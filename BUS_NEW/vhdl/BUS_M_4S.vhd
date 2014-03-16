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
	generic( word_width 	 : integer  :=  32 ;
			 address_width   : integer  :=  32);
	Port (  	clk     	 : in std_logic; 
				reset_n		 : in std_logic;		
			-- CPU side pins
				Addr    	 : in std_logic_vector (address_width-1 downto 0);
				Rdata   	 : out std_logic_vector(word_width-1 downto 0); -- data input
				Wdata   	 : in std_logic_vector(word_width-1 downto 0); -- data output
				Write   	 : in std_logic; -- write strobe
				Read    	 : in std_logic; -- write enable
				Ready_n 	 : out std_logic; -- busy signal	
			-- COM 1  
				COM_1_rclk   : in  std_logic;
				COM_1_rdata  : out std_logic_vector(word_width-1 downto 0);
				COM_1_rempty : out std_logic;
				COM_1_rinc   : in  std_logic;
				COM_1_rrst_n : in  std_logic;				

				COM_1_wclk   : in  std_logic;
				COM_1_wdata  : in  std_logic_vector(word_width-1 downto 0);
				COM_1_wfull  : out std_logic;
				COM_1_winc   : in  std_logic;
				COM_1_wrst_n : in  std_logic;
			-- COM 2  
				COM_2_rclk   : in  std_logic;
				COM_2_rdata  : out std_logic_vector(word_width-1 downto 0);
				COM_2_rempty : out std_logic;
				COM_2_rinc   : in  std_logic;
				COM_2_rrst_n : in  std_logic;
				
				COM_2_wclk   : in  std_logic;
				COM_2_wdata  : in  std_logic_vector(word_width-1 downto 0);
				COM_2_wfull  : out std_logic;
				COM_2_winc   : in  std_logic;
				COM_2_wrst_n : in  std_logic;
			-- COM 3  
				COM_3_rclk   : in  std_logic;
				COM_3_rdata  : out std_logic_vector(word_width-1 downto 0);
				COM_3_rempty : out std_logic;
				COM_3_rinc   : in  std_logic;
				COM_3_rrst_n : in  std_logic;
				
				COM_3_wclk   : in  std_logic;
				COM_3_wdata  : in  std_logic_vector(word_width-1 downto 0);
				COM_3_wfull  : out std_logic;
				COM_3_winc   : in  std_logic;
				COM_3_wrst_n : in  std_logic;
			-- COM 4  
				COM_4_rclk   : in  std_logic;
				COM_4_rdata  : out std_logic_vector(word_width-1 downto 0);
				COM_4_rempty : out std_logic;
				COM_4_rinc   : in  std_logic;
				COM_4_rrst_n : in  std_logic;
				
				COM_4_wclk   : in  std_logic;
				COM_4_wdata  : in  std_logic_vector(word_width-1 downto 0);
				COM_4_wfull  : out std_logic;
				COM_4_winc   : in  std_logic;
				COM_4_wrst_n : in  std_logic);
end BUS_MSSSS;

architecture Behavioral of BUS_MSSSS is

component Top_BUS is
	generic( word_width : integer  := 32;
			 address_width : integer :=  32);

	Port (  clk             : in std_logic; 
			reset_n         : in std_logic;			
			-- CPU side pins
            cpuAddr         : in  std_logic_vector (address_width-1 downto 0);
			cpuRdata        : out std_logic_vector (word_width-1 downto 0); -- data input
			cpuWdata        : in  std_logic_vector (word_width-1 downto 0); -- data output
			cpuWrite        : in  std_logic; -- write strobe
			cpuRead         : in  std_logic; -- write enable
			cpuReady_n      : out std_logic; -- busy signal
		
			-- Slave 1 side pins
			slave_1_addr    : out std_logic_vector (address_width-3 downto 0);
            slave_1_rdata   : in  std_logic_vector (word_width-1 downto 0); -- data input
	        slave_1_wdata   : out std_logic_vector (word_width-1 downto 0); -- data output
			slave_1_write   : out std_logic; -- write strobe
			slave_1_read    : out std_logic; -- write enable
			-- Slave 2 side pins
			counter_addr    : out std_logic_vector (address_width-3 downto 0); -- counter add input
			
			counter_data_in : out std_logic_vector (word_width-1 downto 0); -- data to counter
			counter_rdn     : out std_logic; -- rdn output to counter
			
			counter_data_out: in  std_logic_vector (word_width-1 downto 0); -- data from counter
			counter_wrn     : out  std_logic; -- wrn output to counter

			-- Comunication Channel 1
			channel_1_addr  : out std_logic_vector (address_width-3 downto 0);
			
			channel_1_wdata : out std_logic_vector (word_width-1 downto 0);
			channel_1_wfull : in  std_logic;
			channel_1_winc  : out std_logic;
			
			channel_1_rdata : in  std_logic_vector (word_width-1 downto 0);
			channel_1_rempty: in  std_logic;
			channel_1_rinc  : out std_logic;
			

			-- Communication Channel 2
			channel_2_addr  : out std_logic_vector (address_width-3 downto 0);

			channel_2_wdata : out std_logic_vector (word_width-1 downto 0);
			channel_2_wfull : in  std_logic;
			channel_2_winc  : out std_logic;

			channel_2_rdata : in std_logic_vector (word_width-1 downto 0);
			channel_2_rempty: in std_logic;
			channel_2_rinc  : out std_logic;
			
			-- communication channel 3
			channel_3_addr  : out std_logic_vector (address_width-3 downto 0);

			channel_3_wdata : out std_logic_vector (word_width-1 downto 0);
			channel_3_wfull : in  std_logic;
			channel_3_winc  : out std_logic;

			channel_3_rdata : in  std_logic_vector (word_width-1 downto 0);
			channel_3_rempty: in  std_logic;
			channel_3_rinc  : out std_logic;

			-- communication channel 4
			channel_4_addr  : out std_logic_vector (address_width-3 downto 0);

			channel_4_wdata : out std_logic_vector (word_width-1 downto 0);
			channel_4_wfull : in  std_logic;
			channel_4_winc  : out std_logic;

			channel_4_rdata : in  std_logic_vector (word_width-1 downto 0);
			channel_4_rempty: in  std_logic;
			channel_4_rinc  : out std_logic);

end component;

component SRAM is
generic ( addr_size : integer := 8;
			word_size : integer := 32 );
		port (  clk       :   in  std_logic;
				-- CPU PINS
				rdn       :   in  std_logic;
				wrn       :   in  std_logic;
				address   :   in  std_logic_vector(addr_size-1 downto 0);
				bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
				data_in   :   in  std_logic_vector(word_size-1 downto 0);
				data_out  :   out std_logic_vector(word_size-1 downto 0)
				 );
	
end component;

component fifo2 is
    generic (DSIZE : integer:=32; ASIZE : integer:=4);
    port ( rdata              : out std_logic_vector(DSIZE-1 downto 0);
           wfull              : out std_logic;
           rempty             : out std_logic;         
		   wdata              : in  std_logic_vector(DSIZE-1 downto 0);
           winc, wclk, wrst_n : in  std_logic;
           rinc, rclk, rrst_n : in  std_logic);
end component;


component counter is 
  generic ( addr_size    : integer := 30;
            word_size    : integer := 32;
            num_counters : integer := 4);
  port (    clk        :   in  std_logic; 
		  	resetn 	   :   in  std_logic; 
          	rdn        :   in  std_logic;
          	wrn        :   in  std_logic;
          	address    :   in  std_logic_vector(addr_size-1 downto 0);
          	data_in    :   in  std_logic_vector(word_size-1 downto 0);
          	data_out   :   out std_logic_vector(word_size-1 downto 0) );
end component;


-- Mask is all 1 for now
signal 			Mask : std_logic_vector(word_width-1 downto 0);

signal			slave1_addr    :  std_logic_vector (address_width-3 downto 0);
signal          slave1_rdata   :  std_logic_vector (word_width-1 downto 0); -- datsignala input
signal	        slave1_wdata   :  std_logic_vector (word_width-1 downto 0); -- data output
signal			slave1_write   :  std_logic; -- write strobe
signal			slave1_read    :  std_logic; -- write enable
			-- Slave 2 side pins
signal			counteraddr    :  std_logic_vector (address_width-3 downto 0); -- counter add input
			
signal			counterdata_in :  std_logic_vector (word_width-1 downto 0); -- data to counter
signal			counterrdn     :  std_logic; -- rdn output to counter
			
signal			counterdata_out:  std_logic_vector (word_width-1 downto 0); -- data from counter
signal			counterwrn     :  std_logic; -- wrn output to counter

			-- Comunication Channel 1
signal			channel1_addr  :  std_logic_vector (address_width-3 downto 0);
			
signal			channel1_wdata :  std_logic_vector (word_width-1 downto 0);
signal			channel1_wfull :  std_logic;
signal			channel1_winc  :  std_logic;
			
signal			channel1_rdata :  std_logic_vector (word_width-1 downto 0);
signal			channel1_rempty:  std_logic;
signal			channel1_rinc  :  std_logic;
			

			-- Communication Channel 2
signal			channel2_addr  :  std_logic_vector (address_width-3 downto 0);

signal			channel2_wdata :  std_logic_vector (word_width-1 downto 0);
signal			channel2_wfull :  std_logic;
signal			channel2_winc  :  std_logic;

signal			channel2_rdata :  std_logic_vector (word_width-1 downto 0);
signal			channel2_rempty:  std_logic;
signal			channel2_rinc  :  std_logic;
			
			-- communication channel 3
signal			channel3_addr  :  std_logic_vector (address_width-3 downto 0);

signal			channel3_wdata :  std_logic_vector (word_width-1 downto 0);
signal			channel3_wfull :  std_logic;
signal			channel3_winc  :  std_logic;

signal			channel3_rdata :  std_logic_vector (word_width-1 downto 0);
signal			channel3_rempty:  std_logic;
signal			channel3_rinc  :  std_logic;

			-- communication channel 4
signal			channel4_addr  :  std_logic_vector (address_width-3 downto 0);

signal			channel4_wdata :  std_logic_vector (word_width-1 downto 0);
signal			channel4_wfull :  std_logic;
signal			channel4_winc  :  std_logic;

signal			channel4_rdata :  std_logic_vector (word_width-1 downto 0);
signal			channel4_rempty:  std_logic;
signal			channel4_rinc  :  std_logic;

begin

Mask <= (others => '0') ;

Master : Top_BUS Port map(  
			clk             =>  clk,
			reset_n         =>	reset_n,		
			-- CPU side pins
            cpuAddr         =>  Addr,
			cpuRdata        =>  Rdata,
			cpuWdata        =>  Wdata,
			cpuWrite        =>  Write,
			cpuRead         =>  Read,
			cpuReady_n      =>  Ready_n,
			-- Slave 1 side pins
			slave_1_addr    =>  slave1_addr, 
            slave_1_rdata   =>  slave1_rdata,
	        slave_1_wdata   =>  slave1_wdata,
			slave_1_write   =>  slave1_write,
			slave_1_read    =>  slave1_read,
			-- Slave 2 side pins
			counter_addr    =>  counteraddr,
			counter_data_in =>  counterdata_in,
			counter_rdn     =>  counterrdn,
			counter_data_out=>  counterdata_out, 
			counter_wrn     =>  counterwrn,
			-- Comunication Channel 1
			channel_1_addr  =>  channel1_addr,
			
			channel_1_wdata =>  channel1_wdata,
			channel_1_wfull =>  channel1_wfull,
			channel_1_winc  =>  channel1_winc,
			
			channel_1_rdata =>  channel1_rdata,
			channel_1_rempty=>  channel1_rempty,
			channel_1_rinc  =>  channel1_rinc,
			-- Communication Channel 2
			channel_2_addr  =>  channel2_addr, 

			channel_2_wdata =>  channel2_wdata,
			channel_2_wfull =>  channel2_wfull,
			channel_2_winc  =>  channel2_winc,

			channel_2_rdata =>  channel2_rdata,
			channel_2_rempty=>  channel2_rempty,
			channel_2_rinc  =>  channel2_rinc,
			-- communication channel 3
			channel_3_addr  =>  channel3_addr, 

			channel_3_wdata =>  channel3_wdata,
			channel_3_wfull =>  channel3_wfull,
			channel_3_winc  =>  channel3_winc,

			channel_3_rdata =>  channel3_rdata,
			channel_3_rempty=>  channel3_rempty,
			channel_3_rinc  =>  channel3_rinc,
			-- communication channel 4
			channel_4_addr  =>  channel4_addr,

			channel_4_wdata =>  channel4_wdata,
			channel_4_wfull =>  channel4_wfull, 
			channel_4_winc  =>  channel4_winc,

			channel_4_rdata =>  channel4_rdata ,
			channel_4_rempty=>  channel4_rempty,
			channel_4_rinc  =>  channel4_rinc
			);


Slave1 : SRAM   generic map (addr_size => 10 )
				port map(
					clk        => clk ,	
					rdn	       => slave1_read ,
			        wrn	       => slave1_write ,
		   			address    => slave1_addr(11 DOWNTO 2),
          			data_in    => slave1_wdata,
          			bit_wen    => Mask,
          			data_out   => slave1_rdata
				); 

Count : counter	port map(
					clk			=> clk,
					resetn		=> reset_n,
					rdn			=> counterrdn,
					wrn			=> counterwrn,
					address		=> counteraddr,
					data_in		=> counterdata_in,
					data_out	=> counterdata_out
				); 
---------------------------------------------------------------------------
COM_1_FIFOread : fifo2 port map(
					rdata		=> channel1_rdata,
					rempty		=> channel1_rempty,
					rinc		=> channel1_rinc,
					rclk		=> clk,
					rrst_n   	=> reset_n,

					wdata		=> COM_1_wdata,
					wfull		=> COM_1_wfull,
					wclk		=> COM_1_wclk,
					winc		=> COM_1_winc,
					wrst_n		=> COM_1_wrst_n
				);

COM_1_FIFOwrite : fifo2 port map(
					rdata		=> COM_1_rdata,
					rempty		=> COM_1_rempty,
					rinc		=> COM_1_rinc,
					rclk		=> COM_1_rclk,
					rrst_n   	=> COM_1_rrst_n,

					wdata		=> channel1_wdata,
					wfull		=> channel1_wfull,
					wclk		=> clk,
					winc		=> channel1_winc,
					wrst_n		=> reset_n
				);
-------------------------------------------------------------------------
COM_2_FIFOread : fifo2 port map(
					rdata		=> channel2_rdata,
					rempty		=> channel2_rempty,
					rinc		=> channel2_rinc,
					rclk		=> clk,
					rrst_n   	=> reset_n,

					wdata		=> COM_2_wdata,
					wfull		=> COM_2_wfull,
					wclk		=> COM_2_wclk,
					winc		=> COM_2_winc,
					wrst_n		=> COM_2_wrst_n
				);

COM_2_FIFOwrite : fifo2 port map(
					rdata		=> COM_2_rdata,
					rempty		=> COM_2_rempty,
					rinc		=> COM_2_rinc,
					rclk		=> COM_2_rclk,
					rrst_n   	=> COM_2_rrst_n,

					wdata		=> channel2_wdata,
					wfull		=> channel2_wfull,
					wclk		=> clk,
					winc		=> channel2_winc,
					wrst_n		=> reset_n
				);
------------------------------------------------------------------------
COM_3_FIFOread : fifo2 port map(
					rdata		=> channel3_rdata,
					rempty		=> channel3_rempty,
					rinc		=> channel3_rinc,
					rclk		=> clk,
					rrst_n   	=> reset_n,

					wdata		=> COM_3_wdata,
					wfull		=> COM_3_wfull,
					wclk		=> COM_3_wclk,
					winc		=> COM_3_winc,
					wrst_n		=> COM_3_wrst_n
				);

COM_3_FIFOwrite : fifo2 port map(
					rdata		=> COM_3_rdata,
					rempty		=> COM_3_rempty,
					rinc		=> COM_3_rinc,
					rclk		=> COM_3_rclk,
					rrst_n   	=> COM_3_rrst_n,

					wdata		=> channel3_wdata,
					wfull		=> channel3_wfull,
					wclk		=> clk,
					winc		=> channel3_winc,
					wrst_n		=> reset_n
				);
----------------------------------------------------------------------
COM_4_FIFOread : fifo2 port map(
					rdata		=> channel4_rdata,
					rempty		=> channel4_rempty,
					rinc		=> channel4_rinc,
					rclk		=> clk,
					rrst_n   	=> reset_n,

					wdata		=> COM_4_wdata,
					wfull		=> COM_4_wfull,
					wclk		=> COM_4_wclk,
					winc		=> COM_4_winc,
					wrst_n		=> COM_4_wrst_n
				);

COM_4_FIFOwrite : fifo2 port map(
					rdata		=> COM_4_rdata,
					rempty		=> COM_4_rempty,
					rinc		=> COM_4_rinc,
					rclk		=> COM_4_rclk,
					rrst_n   	=> COM_4_rrst_n,

					wdata		=> channel4_wdata,
					wfull		=> channel4_wfull,
					wclk		=> clk,
					winc		=> channel4_winc,
					wrst_n		=> reset_n
				);
-----------------------------------------------------------------------

end Behavioral;
