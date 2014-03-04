---------------------------------------------------------------------------
--                      XI_double_components.VHD                         --
---------------------------------------------------------------------------
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


-- This Vhdl package contains a collection of simple logic devices such as 
-- Registers and Multiplexers, that rather than being implicitly described in
-- the VHDL code or defined through general vhdl definition models, are
-- described in detail in a more or less DEDICATED entity block.


-------------------------------------------------------------------------------
--
--          PIPELINE FLOW SYNCHRONIZATION DEVICES
--
-- In this section are contained ALL the ( behavioral ) logic blocks in the
-- whole model that are actually not combinatorial:
-- All the synchronization device here described are simple arrays of F/Fs,
-- that sample input data on the raising edge of the CLK signal if the
-- ENABLE input is '1', and that can be resetted to a user-defined value
-- asynchronously by the RESET signal whose logic is defined in file
-- basic.vhd ( the reset signal is synchronized as it enters the
-- processor, see file top.vhd ).

-- As introduced before, There should be no need to define all these registers as
-- separate entities, this option has only been chosen to describe with the 
-- appropriate names and data_types all the entity ports, and ease code
-- readability, even though all data_types are subtypes of Std_logic_vectors.


--        CONTROL BLOCK REGISTERS

----------------------------------------------------------------------------
-- EXECUTE REGISTER
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.menu.all;
use work.basic.all;
use work.isa_32.all;

entity Double_Ireg_Execute is
  generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  
  port( clk, reset, enable : in std_logic;

        in_alu_command1              : in Alu_control;
        in_alu_command2              : in Alu_control;
        in_alu_immed1                : in Std_logic_vector(word_width-1 downto 0);
        in_alu_immed2                : in Std_logic_vector(word_width-1 downto 0);
        in_shift_op1                 : in Risc_shiftcode;
        in_shift_op2                 : in Risc_shiftcode;
        in_exe_outsel1               : in Risc_exeout;
        in_exe_outsel2               : in Risc_exeout;
        in_mul_command               : in Risc_mulop;
        in_mem_command               : in Mem_control;
        in_rd1,in_rd2                : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;

        out_alu_command1             : out Alu_control;
        out_alu_command2             : out Alu_control;
        out_alu_immed1               : out Std_logic_vector(word_width-1 downto 0);
        out_alu_immed2               : out Std_logic_vector(word_width-1 downto 0);        
        out_shift_op1                : out Risc_shiftcode;
        out_shift_op2                : out Risc_shiftcode;
        out_exe_outsel1              : out Risc_exeout;
        out_exe_outsel2              : out Risc_exeout;
        out_mul_command              : out Risc_mulop;
        out_mem_command              : out Mem_control;
        out_rd1,out_rd2              : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic );
end Double_Ireg_Execute;

architecture behavioral of Double_Ireg_Execute is
begin
  process(CLK, reset)
  begin

    if reset = reset_active then
      out_alu_command1 <= ( isel=>'1',op=>xi_alu_add,hrdwit=>'1' );
      out_alu_command2 <= ( isel=>'1',op=>xi_alu_add,hrdwit=>'1' );
      out_alu_immed1   <= ( others=>'0' );
      out_alu_immed2   <= ( others=>'0' );
      out_shift_op1    <= xi_shift_sll(2 downto 0);
      out_exe_outsel1  <= "000";
      out_mul_command  <= xi_mul_nop;
      out_mem_command  <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
      out_rd1   <= (others => '0');
      out_rd2   <= (others => '0');
      out_rf_we <= '1';

    elsif CLK'event and CLK = '1' then
      if Enable = '0' then
        out_alu_command1 <= in_alu_command1;
        out_alu_command2 <= in_alu_command2;
        out_alu_immed1   <= in_alu_immed1;
        out_alu_immed2   <= in_alu_immed2;
        out_shift_op1   <= in_shift_op1;
        out_shift_op2   <= in_shift_op2;
        out_exe_outsel1 <= in_exe_outsel1;
        out_exe_outsel2 <= in_exe_outsel2;        
        out_mul_command <= in_mul_command;
        out_mem_command <= in_mem_command;
        out_rd1   <= in_rd1;
        out_rd2   <= in_rd2;
        out_rf_we <= in_rf_we;
      end if;
    end if;

  end process;
end behavioral;


----------------------------------------------------------------------------
-- MEMORY ACCESS REGISTER
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.menu.all;
use work.basic.all;
use work.isa_32.all;

entity Double_Ireg_Memory is
  generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  port( clk, reset, enable : in std_logic;

        in_alu_command1              : in Alu_control;
        in_alu_command2              : in Alu_control;        
        in_alu_immed1                : in Std_logic_vector(word_width-1 downto 0);
        in_alu_immed2                : in Std_logic_vector(word_width-1 downto 0);
        in_mem_command               : in Mem_control;
        in_rd1,in_rd2                : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;
        in_serve_exception           : in std_logic;

        out_alu_command1             : out Alu_control;
        out_alu_command2             : out Alu_control;
        out_alu_immed1               : out Std_logic_vector(word_width-1 downto 0);
        out_alu_immed2               : out Std_logic_vector(word_width-1 downto 0);
        out_mem_command              : out Mem_control;
        out_rd1,out_rd2              : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic;
        out_serve_exception          : out std_logic );
end Double_Ireg_Memory;

architecture behavioral of Double_Ireg_Memory is
begin
  process(CLK, reset)
  begin

    if reset = reset_active then

      out_alu_command1    <=  (isel=>'1',op=>xi_alu_add,hrdwit=>'1');
      out_alu_command2    <=  (isel=>'1',op=>xi_alu_add,hrdwit=>'1');      
      out_alu_immed1      <=  ( others => '0' );
      out_alu_immed2      <=  ( others => '0' );
      out_mem_command     <=  (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
      out_rd1             <= (others => '0');
      out_rd2             <= (others => '0');
      out_rf_we           <= '1';
      out_serve_exception <= '1';


    elsif CLK'event and CLK = '1' then
      if Enable = '0' then
        out_alu_command1    <= in_alu_command1;
        out_alu_command2    <= in_alu_command2;
        out_alu_immed1      <= in_alu_immed1;
        out_alu_immed2      <= in_alu_immed2;
        out_mem_command     <= in_mem_command;
        out_rd1             <= in_rd1;
        out_rd2             <= in_rd2;        
        out_rf_we           <= in_rf_we;
        out_serve_exception <= in_serve_exception;
      end if;
    end if;

  end process;
end behavioral;


-------------------------------------------------------------------------------
-- Bypass multiplexing logic used in the Double datapath architecture,
-- to perform inter and intra-datapath Multiplexing !
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use work.menu.all;
use work.basic.all;


entity DOUBLE_BYPASS_MUX is
  generic( Word_Width      : positive := 32 );
  port ( byp_control :   in  Risc_bypcontrol;
         rfile_out   :   in  Std_logic_vector(word_width-1 downto 0);
         Mainexe_out :   in  Std_logic_vector(word_width-1 downto 0);
         Mainmem_out :   in  Std_logic_vector(word_width-1 downto 0);
         Auxexe_out  :   in  Std_logic_vector(word_width-1 downto 0);
         Auxmem_out  :   in  Std_logic_vector(word_width-1 downto 0);
         byp_channel :   out Std_logic_vector(word_width-1 downto 0) );
end DOUBLE_BYPASS_MUX;


architecture BEHAVIORAL of DOUBLE_BYPASS_MUX is

begin  -- BEHAVIORAL

  process(byp_control,rfile_out,Mainexe_out,Mainmem_out,
          Auxexe_out,Auxmem_out)
  begin
    case byp_control is
       when Main_exe => byp_channel <= Mainexe_out;
       when Main_mem => byp_channel <= Mainmem_out;
       when Aux_exe  => byp_channel <= Auxexe_out;
       when Aux_mem  => byp_channel <= Auxmem_out;
       when others   => byp_channel <= rfile_out;
     end case;
  end process;

end BEHAVIORAL;


-- Components package definition ----------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use work.basic.all;

package double_components is

component Double_Ireg_Execute
 generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  
  port( clk, reset, enable : in std_logic;

        in_alu_command1              : in Alu_control;
        in_alu_command2              : in Alu_control;
        in_alu_immed1                : in Std_logic_vector(word_width-1 downto 0);
        in_alu_immed2                : in Std_logic_vector(word_width-1 downto 0);
        in_shift_op1                 : in Risc_shiftcode;
        in_shift_op2                 : in Risc_shiftcode;
        in_exe_outsel1               : in Risc_exeout;
        in_exe_outsel2               : in Risc_exeout;
        in_mul_command               : in Risc_mulop;
        in_mem_command               : in Mem_control;
        in_rd1,in_rd2                : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;

        out_alu_command1             : out Alu_control;
        out_alu_command2             : out Alu_control;
        out_alu_immed1               : out Std_logic_vector(word_width-1 downto 0);
        out_alu_immed2               : out Std_logic_vector(word_width-1 downto 0);        
        out_shift_op1                : out Risc_shiftcode;
        out_shift_op2                : out Risc_shiftcode;
        out_exe_outsel1              : out Risc_exeout;
        out_exe_outsel2              : out Risc_exeout;
        out_mul_command              : out Risc_mulop;
        out_mem_command              : out Mem_control;
        out_rd1,out_rd2              : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic );  
end component;

component Double_Ireg_Memory 
   generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  port( clk, reset, enable : in std_logic;

        in_alu_command1              : in Alu_control;
        in_alu_command2              : in Alu_control;        
        in_alu_immed1                : in Std_logic_vector(word_width-1 downto 0);
        in_alu_immed2                : in Std_logic_vector(word_width-1 downto 0);
        in_mem_command               : in Mem_control;
        in_rd1,in_rd2                : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;
        in_serve_exception           : in std_logic;

        out_alu_command1             : out Alu_control;
        out_alu_command2             : out Alu_control;
        out_alu_immed1               : out Std_logic_vector(word_width-1 downto 0);
        out_alu_immed2               : out Std_logic_vector(word_width-1 downto 0);
        out_mem_command              : out Mem_control;
        out_rd1,out_rd2              : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic;
        out_serve_exception          : out std_logic ); 
end component;

component double_bypass_mux
  generic( Word_Width      : positive := 32);
  port ( byp_control :   in  Risc_bypcontrol;
         rfile_out   :   in  Std_logic_vector(word_width-1 downto 0);
         Mainexe_out :   in  Std_logic_vector(word_width-1 downto 0);
         Mainmem_out :   in  Std_logic_vector(word_width-1 downto 0);
         Auxexe_out  :   in  Std_logic_vector(word_width-1 downto 0);
         Auxmem_out  :   in  Std_logic_vector(word_width-1 downto 0);
         byp_channel :   out Std_logic_vector(word_width-1 downto 0) );
end component;

end double_components;

package body double_components is
end double_components;
  
