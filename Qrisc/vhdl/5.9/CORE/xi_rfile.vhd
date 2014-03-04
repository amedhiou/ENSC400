
---------------------------------------------------------------------------
--                          XI_RFILE.VHD                                 --
--                                                                       --
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
-- This license is a modification of the Cadence Design Systems Source Code Public 
-- License Version 1.0 which is similar to the Netscape public license.  
-- We believe this license conforms to requirements adopted by OpenSource.org.  
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- The register file is a read/write memory, composed by 32 32-bit general
-- purpose registers.
-- It can be addressed by different resources in a concurrent enviroment.
-- This model is a 2-read and 1-writes port


library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;  
  use work.components.all;

entity Rfile is
  generic( Word_Width              : positive := 32;
           rf_registers_addr_width : positive := 3 );
  port(  clk    : in  Std_logic;
         reset  : in  Std_logic;
         enable : in  Std_logic;
         ra     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
         a_out  : out Std_logic_vector(Word_width-1 downto 0);
         rb     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
         b_out  : out Std_logic_vector(Word_width-1 downto 0);
         
         rd1    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
         d1_in  : in  Std_logic_vector(Word_width-1 downto 0) ); 
end Rfile;


architecture behavioral of Rfile is 

  -- Used for the Register file data structure
  type rf_bus_array is array (2**rf_registers_addr_width-1 downto 0) of Std_logic_vector(Word_width-1 downto 0);

  signal reg_in,reg_out : rf_bus_array;
  
begin

  -- Register 0 is grounded
  reg_out(0) <= (others => '0');

  
  Registers:for i in 1 to (2**rf_registers_addr_width-1) generate   
     rx : data_reg generic map ( reg_width=> word_width )
                   port map (clk,reset,enable,reg_in(i),reg_out(i));                            
  end generate Registers;
  
    -- Reg_file Reads
    --
    READ_A_MUX: process(reg_out,ra)
    begin
      if Conv_Integer(unsigned(ra)) = 0 then
        a_out <= ( others => '0' );
      else
        a_out <= reg_out(Conv_Integer(unsigned(ra)));
      end if;
    end process;

    READ_B_MUX: process(reg_out,rb)
    begin
      if Conv_Integer(unsigned(rb)) = 0 then
        b_out <= ( others => '0' );
      else
        b_out <= reg_out(Conv_Integer(unsigned(rb)));
      end if;
    end process;
       
    -- Reg_file writes. Being clock-dependent, this process separates
    -- the memory access from the Writeback stage: Consequently, there is
    -- no need for an esplicit writeback register for Data or Control
    -- signals.
  
  WRITE_D_MUX:process(rd1,d1_in,reg_out)            
  begin      
      for i in 1 to (2**rf_registers_addr_width-1) loop
          if i = Conv_Integer(unsigned(rd1)) then
            reg_in(i) <= d1_in;            
          else
            reg_in(i) <= reg_out(i);
          end if;
      end loop;
  end process;




end behavioral;
