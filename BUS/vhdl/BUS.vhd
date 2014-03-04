--------------------------------------------------------------------------
-- Author      : Ahmed Medhioub                                         --
-- CopyRight   : SFU | ENSC 400 | Spring 2014                           --
-- File        : BUS.vhd						--
-- Description :                                                        --
--	* FSM that impliments comunication protocol between CPU/SLAVE   --
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity BUS_master is
	generic( word_width : integer  := 32;
			 address_width : integer :=  32);
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

end BUS_master;

architecture Behavioral of BUS_master is

component REG is
	generic( word_width : integer := 32);
	Port (clk  : in std_logic; -- clock input
	      din  : in std_logic_vector(word_width-1 downto 0); -- input data
	      dout : out std_logic_vector(word_width-1 downto 0); -- data output
	      wen  : in std_logic; -- write enab
	      ren  : in std_logic); 
end component;

type state_type is (s0,s1,s2);
signal current_s,next_s: state_type;
signal Swreg_write,Swreg_read,Srreg_write,Srreg_read: std_logic;
signal addreg_w, addreg_r  : std_logic;
signal addr_dataOut : std_logic_vector(address_width-1 downto 0);
begin

S_Wreg: REG generic map ( word_width => word_width)
			port map( clk  => clk,
					din  => cpu_wdata,
					dout => slave_wdata,
					wen  => Swreg_write,  -- cntrl
					ren  => Swreg_read    -- cntrl
					);

S_Rreg: REG generic map ( word_width => word_width)
			port map( clk  => clk,
                    din  => slave_rdata,
                    dout => cpu_rdata,
                    wen  => Srreg_write,  -- cntrl
                    ren  => Srreg_read    -- cntrl
                    );

addreg: REG generic map ( word_width => address_width)
		    port map( clk  => clk,
                    din  => cpu_addr,
                    dout => addr_dataOut,
                    wen  => addreg_w,     -- cntrl
                    ren  => addreg_r	  -- cntrl
                    );

slave_addr <= addr_dataOut when (cpu_read = '1') else cpu_addr ; -- when read dont save the addr

state_proc: process (clk)
	begin
 	if (clk'event and clk = '1') then
    	current_s <= next_s;   --state change.
	end if;
	end process;

	 --state machine process.
output_proc: process (current_s,cpu_write,cpu_read)
	 
begin
	 case current_s is
	 	when s0 =>        --when current state is "s0"
	 		if ((cpu_write ='0')and(cpu_read='1')) then  -- write
                addreg_w    <= '1';  -- save addree from cpu 
				addreg_r    <= '0';
				Srreg_read  <= '0';
				Srreg_write <= '0';
				Swreg_read  <= '0';		
				Swreg_write <= '1';  -- save data in register
				-- Output to cpu
				cpu_ready_n <= '0';	 -- Bussy
				-- output to salve
				slave_write <= '1';	 
				slave_read  <= '1';
				-- next state
				next_s <= s2;

	   		elsif ((cpu_write ='1')and(cpu_read='0')) then  -- read
                addreg_w    <= '0';
				addreg_r    <= '0';
				Srreg_read  <= '0';
				Srreg_write <= '1';
				Swreg_read  <= '0';
				Swreg_write <= '0';
				-- Output to cpu
				cpu_ready_n <= '0';
				-- output to salve
				slave_write <= '1';
				slave_read  <= '0';
				-- next state
				next_s      <= s1 ;

			else					    -- idle
				-- Data path controle sig
				addreg_w    <= '0';
				addreg_r    <= '0';
				Srreg_read  <= '0';
				Srreg_write <= '0';
				Swreg_read  <= '0';
				Swreg_write <= '0';
				-- Output to cpu
				cpu_ready_n <= '1';
				-- output to salve
				slave_write <= '1';
				slave_read  <= '1';
				-- next state
				next_s      <= s0 ;

	   		end if;   

	   	when s1 =>        --when current state is "s1" => read
			if ((cpu_write ='0')and(cpu_read='1')) then  -- write while read
				addreg_w    <= '1'; -- save addr in reg
				addreg_r    <= '0';
				Srreg_read  <= '1'; -- read data from register 
				Srreg_write <= '0';
				Swreg_read  <= '0';
				Swreg_write <= '1'; -- save data from cpu in wreg
				-- Output to cpu
				cpu_ready_n <= '0'; -- bussy
				-- output to salve
				slave_write <= '1';  -- no write
				slave_read  <= '1';  --  no read
				-- next state
				next_s <= s2;

			else
				addreg_w	<= '0';
				addreg_r    <= '0';
				Srreg_read  <= '1'; -- read data from reg
				Srreg_write <= '1';
				Swreg_read  <= '0';
				Swreg_write <= '0';
				-- Output to cpu
				cpu_ready_n <= '1';  -- not bussy 
				-- output to salve
				slave_write <= '1'; -- no read
				slave_read  <= '1'; -- no write
				-- next state
				next_s      <= s0 ;
	   		end if;	
	   	when s2 =>       --when current state is "s2" => write
	   		if ((cpu_write ='1')and(cpu_read='0')) then  -- read while write
				addreg_w    <= '0';
				addreg_r    <= '1';  -- read address from register 
				Srreg_read  <= '0';  
				Srreg_write <= '1';  -- read data from memory
				Swreg_read  <= '1';  -- read read data from data register 
				Swreg_write <= '0';
				-- Output to cpu
				cpu_ready_n <= '0';  -- bussy
				-- output to salve
				slave_write <= '0';  -- write to mem
				slave_read  <= '0';  -- read from mem
				-- next state
				next_s      <= s1 ;  -- go to read
			else			
				addreg_w    <= '0';
				addreg_r    <= '1';  -- read address from register 
				Srreg_read  <= '0';
				Srreg_write <= '0';
				Swreg_read  <= '1';  -- read read data from data register 
				Swreg_write <= '0';
				-- Output to cpu
				cpu_ready_n <= '1';  -- not bussy
				-- output to salve
				slave_write <= '0';  -- write to mem
				slave_read  <= '1';
				-- next state
				next_s      <= s0 ;  -- back to idle 
			end if;
     end case;
	   
end process;

end Behavioral;
