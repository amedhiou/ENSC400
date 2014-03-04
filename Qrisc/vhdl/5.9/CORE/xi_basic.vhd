---------------------------------------------------------------------------
--                        XI_BASIC.VHD                                   --
--                                                                       --
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it                      --
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
--
-- Definition of basic parameters,
-- defined to ease the Risc Model code readability.
--
-- all the code here defined must mantain synthesizability !!
--
 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;                                         
use work.menu.all;  

   
 

package basic is

  -- Definition of Custom Data TYPES                                  
  subtype Risc_word  is std_logic_vector(Word_Width-1 downto 0);      
  subtype Risc_instr is std_logic_vector(Instr_width-1 downto 0);     
  subtype Risc_daddr is std_logic_vector(DAddr_width-1 downto 0);     
  subtype Risc_iaddr is std_logic_vector(IAddr_width-1 downto 0);
 
  subtype Risc_alucode is std_logic_vector(5 downto 0);
  subtype Risc_shiftcode is std_logic_vector(2 downto 0);
  subtype Risc_exccode is std_logic_vector(5 downto 0);
  subtype Risc_regaddr is std_logic_vector(4 downto 0);

  subtype Risc_exeout is std_logic_vector(2 downto 0);
  subtype Risc_eop is std_logic_vector(2 downto 0);
  subtype Risc_jop is std_logic_vector(5 downto 0);
  subtype Risc_mulop is std_logic_vector(5 downto 0);
  subtype Risc_bypcontrol is std_logic_vector(2 downto 0);  
 
-------------------------------------------------------------------
-- Exception Codes:                                            --
--                                                               --
-- They describe the currently raised exception, and will be   --
-- copied in case of exceptions to the CAUSE special register  --
-- last 6 bits                                                 --
--                                                               --
-- All these exccodes points to Interrupt Table in the Data    --
-- Memory, where are stored the word_width address of the      --
-- reserved portion of the instruction memory                  --
-- where exception servicing procedures are stored.            --
-- ----------------------------------------------------------------

  constant no_problem  : Risc_exccode := "111111";  
  constant interrupt_0 : Risc_exccode := "000000";
  constant interrupt_1 : Risc_exccode := "000001";
  constant interrupt_2 : Risc_exccode := "000010";
  constant interrupt_3 : Risc_exccode := "000011";
  constant interrupt_4 : Risc_exccode := "000100";
  constant interrupt_5 : Risc_exccode := "000101";
  constant interrupt_6 : Risc_exccode := "000110";
  constant interrupt_7 : Risc_exccode := "000111";
  constant interrupt_8 : Risc_exccode := "001000";
  constant interrupt_9 : Risc_exccode := "001001";

  constant hardware_reset         : Risc_exccode := "001100";
  constant imem_invalid_address   : Risc_exccode := "001101";
  constant imem_misaligned_access : Risc_exccode := "001110";
  constant imem_protection_fault  : Risc_exccode := "001111";
  constant illegal_opcode1        : Risc_exccode := "010000";
  constant illegal_opcode2        : Risc_exccode := "010001";
  constant dmem_invalid_address   : Risc_exccode := "010010";
  constant dmem_misaligned_access : Risc_exccode := "010011";
  constant dmem_protection_fault  : Risc_exccode := "010100";
  constant alu_overflow1          : Risc_exccode := "010101";
  constant alu_overflow2          : Risc_exccode := "010110";
  constant mad_overflow           : Risc_exccode := "010111";

  constant trap_0 : Risc_exccode := "100000";
  constant trap_1 : Risc_exccode := "100001";
  constant trap_2 : Risc_exccode := "100010";
  constant trap_3 : Risc_exccode := "100011";
  constant trap_4 : Risc_exccode := "100100";
  constant trap_5 : Risc_exccode := "100101";
  constant trap_6 : Risc_exccode := "100110";

  
  -- ......

  -- Special Registers Codes
  constant sr_aluout : Std_logic_vector(2 downto 0) := "000";
  constant sr_cause  : Std_logic_vector(2 downto 0) := "001";
  constant sr_eps    : Std_logic_vector(2 downto 0) := "010";
  constant sr_epc    : Std_logic_vector(2 downto 0) := "011";
  constant sr_status : Std_logic_vector(2 downto 0) := "100";
  constant sr_sticky : Std_logic_vector(2 downto 0) := "101";

  -- Coprocessor Codes
  constant cop_scc : Std_logic_vector(1 downto 0) := "00";
  constant cop_fpu : Std_logic_vector(1 downto 0) := "01";
  constant cop_dbg : Std_logic_vector(1 downto 0) := "10";
  
  -- Bypass Configurations
  constant no_bypass    : Risc_bypcontrol := "000";
  constant main_exe     : Risc_bypcontrol := "100";
  constant main_mem     : Risc_bypcontrol := "101";
  constant aux_exe      : Risc_bypcontrol := "110";
  constant aux_mem      : Risc_bypcontrol := "111";

  
  -- Record Type definitions useful to enhance code readability
  
  type Mem_control is
    record
      mb : std_logic;
      mh : std_logic;
      mr : std_logic;
      mw : std_logic;
      sign : std_logic;
    end record;

  type Alu_control is
    record
      op       : std_logic_vector(5 downto 0);
      hrdwit   : std_logic;
      isel     : Std_logic;
    end record;

  type Cop_control is
    record
      index   : Std_logic_vector(1 downto 0);
      op      : Std_logic_vector(5 downto 0);     
    end record;         

  type Exc_list is
    record
      illop1          : Std_logic;
      illop2          : Std_logic;
      alu_oflow1      : Std_logic;
      alu_oflow2      : Std_logic;
      mad_oflow       : Std_logic;
      imem_misalign   : Std_logic;
      imem_prot_warn  : Std_logic;
      imem_inv_addr   : Std_logic;
      dmem_misalign   : Std_logic;
      dmem_prot_warn  : Std_logic;
      dmem_inv_addr   : Std_logic;
      fpu             : Std_logic; 
    end record;

end basic;


--
-- basic_body
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package body basic is
end basic;


