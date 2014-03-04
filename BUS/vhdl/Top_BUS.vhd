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
	generic( word_width : integer  := 32;
			 address_width : integer :=  32);
	Port (  clk   : in std_logic; 
			-- CPU side pins
                        cpuAddr    : in std_logic_vector (address_width-1 downto 0);
			cpuRdata   : out std_logic_vector(word_width-1 downto 0); -- data input
			cpuWdata   : in std_logic_vector(word_width-1 downto 0); -- data output
			cpuWrite   : in std_logic; -- write strobe
			cpuRead    : in std_logic; -- write enable
			cpuReady_n : out std_logic; -- busy signal
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

signal Addrs_Mux_cntr : std_logic_vector(1 downto 0) ;
signal address_from_Master : std_logic_vector(address_width-1 downto 0);
signal address_to_slaves : std_logic_vector(address_width-3 downto 0);

signal data_Mux_cntr  : std_logic_vector(1 downto 0) ;
signal slavewdata    : std_logic_vector(word_width-1 downto 0) ;
signal slaveRdata    : std_logic_vector(word_width-1 downto 0) ;

signal slaveWrite    : std_logic;
signal slaveRead     : Std_logic;

begin

 
-- Address multiplexing
Addrs_Mux_cntr <= address_from_Master(address_width-1 downto address_width-2);
address_to_slaves <= address_from_Master(address_width-3 downto 0);

Process(Addrs_Mux_cntr,address_to_slaves)
begin
	case Addrs_Mux_cntr is 
		when "00"   => slave_1_addr  <= address_to_slaves; slave_2_addr <= (others => '0')  ; slave_3_addr <= (others => '0')  ; slave_4_addr <= (others => '0') ;
		when "01"   => slave_1_addr  <= (others => '0')  ; slave_2_addr <= address_to_slaves; slave_3_addr <= (others => '0')  ; slave_4_addr <= (others => '0') ;
		when "10"   => slave_1_addr  <= (others => '0')  ; slave_2_addr <= (others => '0')  ; slave_3_addr <= address_to_slaves; slave_4_addr <= (others => '0') ;
		when others => slave_1_addr  <= (others => '0')  ; slave_2_addr <= (others => '0')  ; slave_3_addr <= (others => '0')  ; slave_4_addr <= address_to_slaves;
	end case;
end process;

-- Data multiplexing
--data_Mux_cntr <= cpuAddr(address_width-1 downto address_with-2);
Process(Addrs_Mux_cntr, slavewdata)
begin
	case Addrs_Mux_cntr  is 
		when "00"   => slave_1_wdata <= slavewdata      ; slave_2_wdata <= (others => '0')  ; slave_3_wdata <= (others => '0')  ; slave_4_wdata <= (others => '0') ;
		when "01"   => slave_1_wdata <= (others => '0')  ; slave_2_wdata <= slavewdata      ; slave_3_wdata <= (others => '0')  ; slave_4_wdata <= (others => '0') ;
		when "10"   => slave_1_wdata <= (others => '0')  ; slave_2_wdata <= (others => '0')  ; slave_3_wdata <= slavewdata      ; slave_4_wdata <= (others => '0') ;
		when others => slave_1_wdata <= (others => '0')  ; slave_2_wdata <= (others => '0')  ; slave_3_wdata <= (others => '0')  ; slave_4_wdata <= slavewdata     ;
	end case;
end Process;

with Addrs_Mux_cntr  select slaveRdata <= 
	slave_1_rdata  when "00" ,
	slave_2_rdata  when "01" ,
	slave_3_rdata  when "10" ,
	slave_4_rdata  when others ;


-- Write sig Muxing
Process (Addrs_Mux_cntr,slaveWrite)
begin
	case Addrs_Mux_cntr  is
		when "00"   => slave_1_write <= slaveWrite ;  slave_2_write <= '1' ; slave_3_write <= '1' ;slave_4_write <= '1' ;
		when "01"   => slave_2_write <= slaveWrite ;  slave_1_write <= '1' ; slave_3_write <= '1' ;slave_4_write <= '1' ;
		when "10"   => slave_3_write <= slaveWrite ;  slave_2_write <= '1' ; slave_1_write <= '1' ;slave_4_write <= '1' ;
		when others => slave_4_write <= slaveWrite ;  slave_2_write <= '1' ; slave_3_write <= '1' ;slave_1_write <= '1' ;
	end case;
end process;
-- Read sig Muxing
Process (Addrs_Mux_cntr,slaveRead)
begin
	case Addrs_Mux_cntr  is
		when "00"   => slave_1_read <= slaveRead ;  slave_2_read <= '1' ; slave_3_read <= '1' ;slave_4_read <= '1' ;
		when "01"   => slave_2_read <= slaveRead ;  slave_1_read <= '1' ; slave_3_read <= '1' ;slave_4_read <= '1' ;
		when "10"   => slave_3_read <= slaveRead ;  slave_2_read <= '1' ; slave_1_read <= '1' ;slave_4_read <= '1' ;
		when others => slave_4_read <= slaveRead ;  slave_2_read <= '1' ; slave_3_read <= '1' ;slave_1_read <= '1' ;
	end case;
end Process;

BUS_M: BUS_Master generic map ( word_width   => 32,
			 address_width =>  32)
			port map( 
					clk 		 => clk,
					cpu_addr     => cpuAddr,
					cpu_rdata    => cpuRdata,
					cpu_wdata    => cpuWdata, -- data output
					cpu_write    => cpuWrite,-- write strobe
					cpu_read     => cpuRead , -- write enable
					cpu_ready_n  => cpuReady_n, -- busy signal
					-- Slave side pins
					slave_addr   => address_from_Master ,
		            		slave_rdata  => slaveRdata, -- data input
	       				slave_wdata  => slavewdata, -- data output
					slave_write  => slaveWrite, -- write strobe
					slave_read   => slaveRead  -- write enable
					);


end Behavioral;
