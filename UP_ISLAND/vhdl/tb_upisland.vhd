-------------------------------------------------------------------------------
-- tb_upisland
-- by fcampi@sfu.ca Jan 2014
--
-- Simple Testbench that makes a barebone basic use of the qrisc microprocessor
-- See file tb_qrisc for more sophisticated use
-------------------------------------------------------------------------------

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;
  use work.menu.all;
  
entity E is
end E; 
Architecture A of E is

component up_island
	Port (   -- System Control Signals
           CLK               : in   Std_logic;
           reset             : in   Std_logic;

           -- Data Bus Request
           BUS_NREADY          : in   Std_logic;
           BUS_MR, BUS_MW      : out  Std_logic;
           BUS_ADDR_OUTBUS     : out  Std_logic_vector(Daddr_width-1 downto 0);
           BUS_DATA_INBUS      : in   Std_logic_vector(Word_width-1 downto 0);
           BUS_DATA_OUTBUS     : out  Std_logic_vector(Word_width-1 downto 0) );
end component;

component BUS_MSSSS 
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
end component;
  
signal CLK,reset : Std_logic;
signal BUS_NREADY,BUS_MR,BUS_MW       : std_logic;
signal BUS_ADDR_OUTBUS                : Std_logic_vector(daddr_width-1 downto 0);
signal BUS_DATA_INBUS,BUS_DATA_OUTBUS : Std_logic_vector(word_width-1 downto 0);
signal clock_out : std_logic;
  
begin 

  UUT : up_island 
  port map ( CLK,reset,
             BUS_NREADY,
	    	 BUS_MR,
	    	 BUS_MW,
             BUS_ADDR_OUTBUS,
	    	 BUS_DATA_INBUS,
	    	 BUS_DATA_OUTBUS );

  BUS_NREADY <= '1';

  BigBUS :  BUS_MSSSS                        -- Bus with 4 Memory blocks -
    generic map (word_width => 32 , address_width => 32)
    port map (  clk   => clk,
				Read  => BUS_MR,
				Write => BUS_MW,
				Addr  => BUS_ADDR_OUTBUS,
              	Wdata => BUS_DATA_OUTBUS,
				Ready_n => BUS_NREADY,
				Rdata => BUS_DATA_INBUS);

  reset_engine : process
  begin
    reset <='0';
    wait for 30 ns;
    reset <= '1';
    wait;
  end process;
  
  clock_engine : process
    begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
      if clock_out='0' then
        wait;
      end if;
    end process;
  
end A; 
  

