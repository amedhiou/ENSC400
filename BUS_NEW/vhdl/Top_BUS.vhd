--------------------------------------------------------------------------
-- Author      : Ahmed Medhioub                                         --
-- CopyRight   : SFU | ENSC 400 | Spring 2014                           --
-- File        : Top_BUS.vhd                                            --
-- Description :                                                        --
--      * here is where address multiplexing is handled                 --
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity Top_BUS is
	generic(word_width      : integer :=  32;
			address_width   : integer :=  32);
	Port (  clk             : in std_logic; 
			reset_n			: in std_logic;
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

end Top_BUS;

architecture Behavioral of Top_BUS is

component BUS_master is

	generic( word_width : integer  := 32;
			 address_width : integer :=  30);
	Port (  clk   : in std_logic; 
			-- CPU side pins
			cpu_addr    : in std_logic_vector (address_width-1 downto 0);
			cpu_rdata   : out std_logic_vector(word_width-1 downto 0); -- data input
			cpu_wdata   : in std_logic_vector(word_width-1 downto 0); -- data output
			cpu_write   : in std_logic; -- write strobe
			cpu_read    : in std_logic; -- write enable
			cpu_ready_n : out std_logic; -- busy signal
			-- Slave side pins
			slave_addr  : out std_logic_vector (address_width-1 downto 0);
            slave_rdata : in std_logic_vector(word_width-1 downto 0); -- data input
	        slave_wdata : out std_logic_vector(word_width-1 downto 0); -- data output
			slave_write : out std_logic; -- write strobe
			slave_read  : out std_logic); -- write enable
	
end component;

signal address_from_Master : std_logic_vector (31 downto 0);
signal slaveRdata          : std_logic_vector (word_width-1 downto 0);
signal slavewdata          : std_logic_vector (word_width-1 downto 0);
signal slaveRead           : std_logic ;
signal slaveWrite          : std_logic ;
signal Master_cpuReady_n   : std_logic ;
signal channel_1_cpuReady    : std_logic ;
signal channel_2_cpuReady    : std_logic ;
signal channel_3_cpuReady    : std_logic ;
signal channel_4_cpuReady    : std_logic ;
begin

BUS_M: BUS_Master 
			generic map ( word_width    =>  32,
			 			  address_width =>  32)
			port map( 
					clk 		 => clk,
					cpu_addr     => cpuAddr,
					cpu_rdata    => cpuRdata,
					cpu_wdata    => cpuWdata, -- data output
					cpu_write    => cpuWrite,-- write strobe
					cpu_read     => cpuRead , -- write enable
					cpu_ready_n  => Master_cpuReady_n, -- busy signal
					-- Slave side pins
					slave_addr   => address_from_Master ,
            		slave_rdata  => slaveRdata, -- data input
      				slave_wdata  => slavewdata, -- data output
					slave_write  => slaveWrite, -- write strobe
					slave_read   => slaveRead  -- write enable
					);


Process(address_from_Master)

---------------------------------------------------------------------------
-- Slave addresses:
--		* Channel 4 : 0xFFFFFFFC
--		* Channel 3 : 0xFFFFFFF8
--		* Channel 2 : 0xFFFFFFF4
--		* Channel 1 : 0xFFFFFFF0
--		* Counter range : 0xFFFFFF40 to 0xFFFFFF7F
--		* SRAM range : 0x50000000 to 0xFFFFFF3F 
-- 			since our SRAM is mapped as 10 bit address from (11 down to 2)
--			the effective address is : 
--				* 0x50000000 to 0xXXXXEFFF
---------------------------------------------------------------------------


begin 
	case address_from_Master is
		when "11111111111111111111111111111100" => 		-- channel 2 address =  0xFFFFFFFC
			channel_4_addr   <= address_from_Master;
			channel_4_wdata  <= slavewdata 	    ;
			channel_4_winc   <= slaveWrite 	    ;
		 	slaveRdata	     <= channel_4_rdata ;
			channel_4_rinc   <= slaveRead	    ;
			
			if ((slaveRead = '0') and (slaveWrite = '1')) then -- read 
				channel_4_cpuReady <= channel_4_rempty;
			else 
				channel_4_cpuReady <= channel_4_wfull;
			end if;
		
		when "11111111111111111111111111111000" => 		-- channel 2 address =  0xFFFFFFF4
			channel_3_addr   <= address_from_Master;
			channel_3_wdata  <= slavewdata 	;
			channel_3_winc   <= slaveWrite 	;
			slaveRdata	     <= channel_3_rdata;
			channel_3_rinc   <= slaveRead	;
			
			if ((slaveRead = '0') and (slaveWrite = '1')) then -- read 
				channel_3_cpuReady <= channel_3_rempty;
			else 
				channel_3_cpuReady <= channel_3_wfull;
			end if;

		when "11111111111111111111111111110100" => 		-- channel 2 address =  0xFFFFFFF8
			channel_2_addr   <= address_from_Master;
			channel_2_wdata  <= slavewdata 	;
			channel_2_winc   <= slaveWrite 	;
			slaveRdata       <= channel_2_rdata 	;
			channel_2_rinc   <= slaveRead	;
			
			if ((slaveRead = '0') and (slaveWrite = '1')) then -- read 
				channel_2_cpuReady <= channel_2_rempty;
			else 
				channel_2_cpuReady <= channel_2_wfull;
			end if;

		when "11111111111111111111111111110000" =>        -- channel one address =  0xFFFFFFF0
			channel_1_addr   <= address_from_Master;
			channel_1_wdata  <= slavewdata 	;
			channel_1_winc   <= slaveWrite 	;
			slaveRdata	     <= channel_1_rdata ;
			channel_1_rinc   <= slaveRead	;
			
			if ((slaveRead = '0') and (slaveWrite = '1')) then -- read 
				channel_1_cpuReady  <= channel_1_rempty;
			else 
				channel_1_cpuReady  <= channel_1_wfull;
			end if;
		
		when others  =>										-- either Counter or SRAM	
			if (address_from_Master(31 downto 6) = "11111111111111111111111110" ) then -- counter range
				counter_addr     <= address_from_Master;
	        	counter_data_in  <= slavewdata;
	        	counter_rdn      <= slaveRead ;
	        	slaveRdata       <= counter_data_out;
	        	counter_wrn      <= slaveWrite;
		
			else											-- SRAM ports				
				slave_1_addr     <= address_from_Master ;
				slaveRdata       <= slave_1_rdata;
				slave_1_wdata    <= slavewdata;
				slave_1_write    <= slaveWrite;
				slave_1_read     <= slaveRead ;
			end if;
	end case;
	
end process;

with address_from_Master select 
	cpuReady_n  <= (channel_1_cpuReady or Master_cpuReady_n) when "11111111111111111111111111110000", -- Channel 1 is either full or empty
	               (channel_2_cpuReady or Master_cpuReady_n) when "11111111111111111111111111110100", -- Channel 2 is either full or empty
	               (channel_3_cpuReady or Master_cpuReady_n) when "11111111111111111111111111111000", -- Channel 3 is either full or empty
	               (channel_4_cpuReady or Master_cpuReady_n) when "11111111111111111111111111111100", -- Channel 4 is either full or empty
					Master_cpuReady_n						 when others;

end Behavioral;


