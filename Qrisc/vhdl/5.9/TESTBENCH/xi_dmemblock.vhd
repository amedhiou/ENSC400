---------------------------------------------------------------------------
--                       Xi_dmemblock.vhd                                --
--                                                                       --
---------------------------------------------------------------------------
-- Created 2001 by F.M.Campi , fcampi@deis.unibo.it                      --
-- DEIS, Department of Electronics Informatics and Systems,              --
-- University of Bologna, BOLOGNA , ITALY                                -- 
---------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- "The contents of this file are subject to the Source Code Public License 
-- Version 1.0 (the "License"); you may not use this file except in compliance 
-- with the License. 
-- You may obtain a copy of the License at http://xirisc.deis.unibo.it/license.txt
--
-- Software distributed under the License is distributed on an "AS IS" basis, 
-- WITHOUT WARRANTY OF ANY KIND, either express or implied. 
-- See the License for the specific language governing rights and limitations
-- under the License.
--
-- This code was initially developed at "Department of electronics, computer 
-- science and Systems", (D.E.I.S.), University of Bologna, Bologna, Italy.
--
-- This license is a modification of the Ricoh Source Code Public 
-- License Version 1.0 which is similar to the Netscape public license.  
-- We believe this license conforms to requirements adopted by OpenSource.org. 
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- Glue logic for the organization of the Memory banks that implement
-- the on-chip data memory.

-- This decoding logic has a very peculiar feature: as 
-- the memory sample is executed ON the same clock cycle that will
-- change the memory inputs, there is actually no choice but latching on a
-- dedicated sequential logic the inputs before the clock to correctly decode
-- the memory output after the clock: this allows to read, if so needed, the
-- latched address synchronizing it with the corrispondent data.


library IEEE;
  use IEEE.std_logic_1164.all;

-- INPUT DATA CONTROL ---------------------------------------------------------
  
  entity Dmem_input_sel is    
    port( mw,mb,mh                            : in  std_logic;
          daddr_in                            : in  Std_logic_vector(1 downto 0);
          ddataout_micro                      : in  Std_logic_vector(31 downto 0);
          We                                  : out Std_logic_vector(3 downto 0);
          ddatain_mem                         : out Std_logic_vector(31 downto 0) );
  end Dmem_input_sel;
  
  architecture BEHAVIORAL of Dmem_input_sel is  
    
  begin  -- BEHAVIORAL
    process( mw,mb,mh,daddr_in,ddataout_micro )
    begin
      if mw = '0' then
         
         if mb = '0'  then
            -- Store Byte Instruction
	    case daddr_in(1 downto 0) is
		  when "00" => We(3) <= '0';We(2) <= '1';
			       We(1) <= '1';We(0) <= '1';
		  when "01" => We(3) <= '1';We(2) <= '0';
			       We(1) <= '1';We(0) <= '1';
		  when "10" => We(3) <= '1';We(2) <= '1';
			       We(1) <= '0';We(0) <= '1';
		  when "11" => We(3) <= '1';We(2) <= '1';
			       We(1) <= '1';We(0) <= '0';
		  when others => We(0) <= '1';We(1) <= '1';
				 We(2) <= '1';We(3) <= '1';
            end case;
	  
            ddatain_mem(7 downto 0)   <= ddataout_micro(7 downto 0);
            ddatain_mem(15 downto 8)  <= ddataout_micro(7 downto 0);
	    ddatain_mem(23 downto 16) <= ddataout_micro(7 downto 0);
	    ddatain_mem(31 downto 24) <= ddataout_micro(7 downto 0);

         elsif mh = '0' then

            -- Store half word instruction
	    case daddr_in(1) is	      
		  when '0' =>  We(3) <= '0';We(2) <= '0';
			       We(1) <= '1';We(0) <= '1';			  
		  when '1' =>  We(3) <= '1';We(2) <= '1';
			       We(1) <= '0';We(0) <= '0';
		  when others => We(0) <= '1';We(1) <= '1';
				 We(2) <= '1';We(3) <= '1';
	    end case;
	  
	    ddatain_mem(7 downto 0)   <= ddataout_micro(7 downto 0);
	    ddatain_mem(15 downto 8)  <= ddataout_micro(15 downto 8);
	    ddatain_mem(23 downto 16) <= ddataout_micro(7 downto 0);
	    ddatain_mem(31 downto 24) <= ddataout_micro(15 downto 8);

         else
           
            -- Store Word Instruction
	    We(3) <= '0';We(2) <= '0';
	    We(1) <= '0';We(0) <= '0';
	 
            ddatain_mem(7 downto 0)   <= ddataout_micro(7 downto 0);
	    ddatain_mem(15 downto 8)  <= ddataout_micro(15 downto 8);
	    ddatain_mem(23 downto 16) <= ddataout_micro(23 downto 16);
	    ddatain_mem(31 downto 24) <= ddataout_micro(31 downto 24);
	    
         end if;
         
      else
        
        -- Write operation not enabled
        We(3) <= '1';We(2) <= '1';
	We(1) <= '1';We(0) <= '1';
        
        ddatain_mem(7 downto 0)   <= ddataout_micro(7 downto 0);
        ddatain_mem(15 downto 8)  <= ddataout_micro(15 downto 8);
	ddatain_mem(23 downto 16) <= ddataout_micro(23 downto 16);
	ddatain_mem(31 downto 24) <= ddataout_micro(31 downto 24);

      end if;
   end process;    
end BEHAVIORAL;

-------------------------------------------------------------------------------

-- OUTPUT DATA CONTROL --------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;         
  entity Dmem_out_sel is
    port ( ck_mb,ck_mh        : in  Std_logic;
           ck_daddr           : in  Std_logic_vector(1 downto 0);
           ddataout_mem       : in  Std_logic_vector(31 downto 0);
           ddatain_micro      : out Std_logic_vector(31 downto 0) );
  end Dmem_out_sel;
        
 architecture BEHAVIORAL of Dmem_out_sel is

 begin  -- BEHAVIORAL
   process( ck_mb,ck_mh,ck_daddr,
	    ddataout_mem )
   begin
      if ck_mb = '0' then
	  
	 case ck_daddr(1 downto 0) is
	     when "00" => ddatain_micro <= EXT(ddataout_mem(31 downto 24),32);
	     when "01" => ddatain_micro <= EXT(ddataout_mem(23 downto 16),32);
	     when "10" => ddatain_micro <= EXT(ddataout_mem(15 downto 8),32);
	     when "11" => ddatain_micro <= EXT(ddataout_mem(7 downto 0),32); 
	     when others => ddatain_micro <= ( others => '0');
	 end case;
	 
      elsif ck_mh = '0' then
	  
	 case ck_daddr(1) is
	     when '0' => ddatain_micro <= EXT(ddataout_mem(31 downto 16),32);
	     when '1' => ddatain_micro <= EXT(ddataout_mem(15 downto 0),32);
	     when others => ddatain_micro <= ( others => '0');
         end case;

      else
	 ddatain_micro <= ddataout_mem;
      end if;
      
   end process;
 end BEHAVIORAL;  


 
------------------------------------------------------------------------------
--                                                                          --
--                   DMEM BLOCK      MAIN ENTITY                            --
--                                                                          --
------------------------------------------------------------------------------

-- Dmem block four banks memory model.
-- Note: This memory is configurable only in terms of addressing space while
-- all other parameters are fixed: it comprises four banks of 8 bits each.

 
library IEEE;
  use IEEE.std_logic_1164.all;
  use work.components.all;
  use work.menu.all;
 
  entity Dmem_block is
  generic( daddress_width : integer;
           load_file     : string );
    
  port( load,clk,reset        : in  Std_logic;
        
        control_in            : in  Std_logic_vector(3 downto 0);
        clocked_control       : out Std_logic_vector(3 downto 0);

        daddr_in              : in  Std_logic_vector(daddress_width-1 downto 0);
        clocked_daddr         : out Std_logic_vector(daddress_width-1 downto 0);
        
        ddata_in              : in  Std_logic_vector(31 downto 0);
        ddata_out             : out Std_logic_vector(31 downto 0)
      );
  end Dmem_block;
  
architecture STRUCTURAL of Dmem_block is  

  component xi_memory_banks
    generic( banks         : integer; 
             cell_width    : integer;
             address_width : integer;
             load_file     : string;
             min_address_upper   : integer;
             min_address_lower   : integer;
             max_address_upper   : integer;
             max_address_lower   : integer );
 
    port(  load                 : in  std_logic;
           CLK                  : in  std_logic;
           OEN                  : in  std_logic;
           WEN                  : in  std_logic_vector(banks-1 downto 0);
           CSN                  : in  std_logic;
           A                    : in  std_logic_vector(address_width-1 downto 0);
           D                    : in  std_logic_vector(banks*cell_width-1 downto 0);
           Q                    : out std_logic_vector(banks*cell_width-1 downto 0) );         
  end component;

  component Dmem_out_sel
     port ( ck_mb,ck_mh        : in  Std_logic;
            ck_daddr           : in  Std_logic_vector(1 downto 0);
            ddataout_mem       : in  Std_logic_vector(31 downto 0);
            ddatain_micro      : out Std_logic_vector(31 downto 0) );  
  end component;

  component Dmem_input_sel
    port( mw,mb,mh                            : in  std_logic;
          daddr_in                            : in  Std_logic_vector(1 downto 0);
          ddataout_micro                      : in  Std_logic_vector(31 downto 0);
          We                                  : out Std_logic_vector(3 downto 0);
          ddatain_mem                         : out Std_logic_vector(31 downto 0) );
  end component;

  
  signal We                                     : std_logic_vector(3 downto 0);  
  signal ddatain_mem,ddataout_mem               : Std_logic_vector(31 downto 0);

  signal mem_access                             : Std_logic;
  signal ck_daddr                               : Std_logic_vector(daddress_width-1 downto 0);
  signal ck_control                             : Std_logic_vector(3 downto 0);
  signal mr,mw,mb,mh                            : Std_logic;
  signal ck_mr,ck_mw,ck_mb,ck_mh                : Std_logic;
  signal DCSN,DOEN                              : Std_logic;
  signal DWEN                                   : Std_logic_vector(3 downto 0);
  
  signal Hi,Lo                                  : Std_logic;
  
  
begin  -- STRUCTURAL

  Hi              <= '1';
  Lo              <= '0';
  clocked_daddr   <= ck_daddr;
  clocked_control <= ck_control;

  -- CONTROL SIGNALS AND ADDRESS SYNCHRONIZATION ------------------------------
  
  -- The elaboration of the dmemory inputs ( Daddress,mr,mw,mb,mh )
  -- must be performed both BEFORE the clock cycle (input resolution)
  -- and AFTER (outputs handling, to decode the output bitwidth -> byte,
  -- halfword, word <- )
  -- Consequently, those 32+4 std logic bits will be stored in the dedicated
  -- register described below
       
   Clockdaddr_Reg: Data_Reg
       generic map ( init_value=>0,reg_width => daddress_width )
       port map ( CLK,reset,mem_access,daddr_in,ck_daddr );
   
   ClockControl_Register: Data_Reg
       generic map ( init_value=>0,reg_width => 4 )
       port map (CLK,reset,Lo,control_in,ck_control );
  
  -- To ease readability of the following structure, the control vectors
  -- are then decoded into single-bit mnemonic signals: 

  mr <= control_in(3);mw <= control_in(2);
  mb <= control_in(1);mh <= control_in(0);

  ck_mb <= ck_control(1);ck_mh <= ck_control(0);

                
---- MEMORY STORE OPERATIONS -----------------------------------------

  INPUT_SEL: Dmem_input_sel port map ( mw,mb,mh,daddr_in(1 downto 0),ddata_in,
                                       We,ddatain_mem );
    
-----------------------------------------------------------------------------
          

---- MEMORY LOAD OPERATIONS:  OUTPUT SELECTION -----------------------------
   
-- The elaboration of the dmemory inputs ( Daddress,mr,mw,mb,mh )
-- must be performed both BEFORE the clock cycle (input resolution)
-- and AFTER (outputs handling, to decode the output bitwidth -> byte,
-- halfword, word <- )
-- Consequently, those 32+4 std logic bits will be stored in the dedicated
-- register described below

   mem_access <= mr and mw;
  
   DOEN <= '0';
   DCSN <= mem_access;

   -- This is an array of 4 elements, one per each bank
   DWEN <= We;
  
          
   OUTPUT_SEL: Dmem_out_sel port map ( ck_mb,ck_mh,ck_daddr(1 downto 0),
                                       ddataout_mem,ddata_out );
   	  
   DMEM: xi_memory_banks generic map ( banks=>4, cell_width=>8,
                                       address_width=>daddress_width-2,
                                       load_file => load_file,
                                       min_address_upper => data_mem_init_value_upper,
                                       min_address_lower => data_mem_init_value_lower,
                                       max_address_upper => data_mem_end_value_upper,
                                       max_address_lower => data_mem_end_value_lower )
                          port map ( load,clk,DOEN,DWEN,DCSN,
                                     daddr_in(daddress_width-1 downto 2),
                                     ddatain_mem,ddataout_mem );

end STRUCTURAL; 
  
