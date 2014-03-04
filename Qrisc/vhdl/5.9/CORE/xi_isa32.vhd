--------------------------------------------------------------------------
--                                                                      --
--                         XI_ISA32                                     --
--                                                                      --
--  Package specification for XIRISC-32 instruction set                 --
--                                                                      --
--  Created 2000 by F.M.Campi , fcampi@deis.unibo.it                    --
--  DEIS, Department of Electronics Informatics and Systems,            --
--  University of Bologna, BOLOGNA , ITALY                              --
--------------------------------------------------------------------------

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


library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.all;
    use work.basic.all;
    
package isa_32 is

-- A XI-ISA instruction is 32 bits wide.

-----------------------------------------------------------------------------
-- Instruction codes for XiRisc operations, described by 6-bits               -
-- Std_logic_vectors     ( XiRisc instruction word, bits 31..26)              -
-----------------------------------------------------------------------------
  
-- R-type format: 
--
--  31       26 25     21 20     16 15     11 10      6 5          0
-- +----------------------------------------------------------------+
-- |  opcode   |   rs    |   rt    |   rd    |         |   sp_func  |
-- +----------------------------------------------------------------+
--                                        
--                                          
-- Encodes: - register-register ALU operations (rd <- rs1 func rs2)
--            func encodes the datapath operation (add, sub, ...)
--         
--
--
-- I-type format: 
--
-- 31        26 25     21 20     16 15                             0
-- +----------------------------------------------------------------+
-- |  opcode   |   rs    |   rt    |           immed16              |
-- +----------------------------------------------------------------+
--
-- Encodes: - loads and stores of bytes, words, half-words
--            with immediate displacement
--          - all immediate arithmetical operations (rd <- rs1 op immediate)
--          - conditional branch instructions (rd unused)
--          - jump register, jump and link register
--            (rd = 0; rs = destination; immediate = 0)

-- J-type format: 
--
--  31       26 25                                                 0
-- +----------------------------------------------------------------+
-- |  opcode   |                  Target                            |
-- +----------------------------------------------------------------+
--
-- Encodes: - jump and jump-and-link
-- 

   -- TYPE DEFINITIONS        
   subtype XI_sp_branch is Std_logic_vector(4 downto 0);
   subtype XI_scc_op    is Std_logic_vector(4 downto 0);

   -- Constant definitions
   
  constant xi_add      : Std_logic_vector(5 downto 0) := "000000";
  constant xi_addi     : Std_logic_vector(5 downto 0) := "000001";
  constant xi_addiu    : Std_logic_vector(5 downto 0) := "000010";
  constant xi_slti     : Std_logic_vector(5 downto 0) := "000011";

  constant xi_sltiu    : Std_logic_vector(5 downto 0) := "000100";
  constant xi_andi     : Std_logic_vector(5 downto 0) := "000101";
  constant xi_ori      : Std_logic_vector(5 downto 0) := "000110";
  constant xi_xori     : Std_logic_vector(5 downto 0) := "000111";

  constant xi_mul      : Std_logic_vector(5 downto 0) := "001000";
  constant XI_undefined_09 : Std_logic_vector(5 downto 0) := "001001";
  constant XI_undefined_0a : Std_logic_vector(5 downto 0) := "001010";
  constant XI_undefined_0b : Std_logic_vector(5 downto 0) := "001011";

  constant XI_undefined_oc : Std_logic_vector(5 downto 0) := "001100";
  constant XI_undefined_od : Std_logic_vector(5 downto 0) := "001101";
  constant XI_undefined_oe : Std_logic_vector(5 downto 0) := "001110";
  constant XI_undefined_of : Std_logic_vector(5 downto 0) := "001111";

  constant xi_shift    : Std_logic_vector(5 downto 0) := "010000";
  constant xi_shift_v  : Std_logic_vector(5 downto 0) := "010001";
  constant xi_lui      : Std_logic_vector(5 downto 0) := "010010";
  constant XI_undef_13 : Std_logic_vector(5 downto 0) := "010011";

  constant xi_lb        : Std_logic_vector(5 downto 0) := "010100";
  constant xi_lh        : Std_logic_vector(5 downto 0) := "010101";
  constant xi_lw        : Std_logic_vector(5 downto 0) := "010110";
  constant xi_lbu       : Std_logic_vector(5 downto 0) := "010111";

  constant xi_sb        : Std_logic_vector(5 downto 0) := "011000";
  constant xi_sh        : Std_logic_vector(5 downto 0) := "011001";
  constant xi_sw        : Std_logic_vector(5 downto 0) := "011010";
  constant xi_lhu       : Std_logic_vector(5 downto 0) := "011011";

  constant XI_undef_1c  : Std_logic_vector(5 downto 0) := "011100";
  constant XI_undef_1d  : Std_logic_vector(5 downto 0) := "011101";
  constant XI_undef_1e  : Std_logic_vector(5 downto 0) := "011110";
  constant XI_undef_1f  : Std_logic_vector(5 downto 0) := "011111";
    
  constant xi_branch    : Std_logic_vector(5 downto 0) := "100000";
  constant xi_bequ      : Std_logic_vector(5 downto 0) := "100001";
  constant xi_bne       : Std_logic_vector(5 downto 0) := "100010";
  constant xi_brdec     : Std_logic_vector(5 downto 0) := "100011";

  constant XI_undef_24  : Std_logic_vector(5 downto 0) := "100100";
  constant XI_undef_25  : Std_logic_vector(5 downto 0) := "100101";
  constant XI_undef_26  : Std_logic_vector(5 downto 0) := "100110";
  constant XI_undef_27  : Std_logic_vector(5 downto 0) := "100111";

  constant xi_read_cop  : Std_logic_vector(5 downto 0) := "101000";
  constant xi_write_cop : Std_logic_vector(5 downto 0) := "101001";
  constant XI_undef_2a  : Std_logic_vector(5 downto 0) := "101010";
  constant XI_undef_2b  : Std_logic_vector(5 downto 0) := "101011";

  constant XI_undef_2c  : Std_logic_vector(5 downto 0) := "101100";
  constant XI_undef_2d  : Std_logic_vector(5 downto 0) := "101101";
  constant XI_undef_2e  : Std_logic_vector(5 downto 0) := "101110";
  constant XI_undef_2f  : Std_logic_vector(5 downto 0) := "101111";
 
  constant xi_j         : Std_logic_vector(5 downto 0) := "101000";
  constant xi_jal       : Std_logic_vector(5 downto 0) := "101001";
  constant xi_jr        : Std_logic_vector(5 downto 0) := "101010";
  constant xi_jalr      : Std_logic_vector(5 downto 0) := "101011";

  constant xi_cop       : Std_logic_vector(5 downto 0) := "111000";
  constant XI_undef_35  : Std_logic_vector(5 downto 0) := "110101";
  constant XI_fmfpga    : Std_logic_vector(5 downto 0) := "110110";
  constant XI_tofpga    : Std_logic_vector(5 downto 0) := "110111";

  constant XI_undef_38  : Std_logic_vector(5 downto 0) := "111000";
  constant XI_undef_39  : Std_logic_vector(5 downto 0) := "111001";
  constant XI_undef_3a  : Std_logic_vector(5 downto 0) := "111010";
  constant XI_undef_3b  : Std_logic_vector(5 downto 0) := "111011";
    
  constant XI_pgaload   : Std_logic_vector(5 downto 0) := "111100";
  constant XI_pgaop32   : Std_logic_vector(5 downto 0) := "111101";
  constant XI_pgaop64   : Std_logic_vector(5 downto 0) := "111110";
  constant XI_undef_3f  : Std_logic_vector(5 downto 0) := "111111";

  
-----------------------------------------------------------------------------
-- Special (Function-specific) Operations Code: (Instr. word, bits 5..0)    - 
-----------------------------------------------------------------------------

  constant xi_alu_add      : Std_logic_vector(5 downto 0) := "000000";
  constant xi_alu_addu     : Std_logic_vector(5 downto 0) := "000001";
  constant xi_alu_add4     : Std_logic_vector(5 downto 0) := "000010";
  constant xi_alu_add4u    : Std_logic_vector(5 downto 0) := "000011";

  constant xi_alu_add2     : Std_logic_vector(5 downto 0) := "000100";
  constant xi_alu_add2u    : Std_logic_vector(5 downto 0) := "000101";
  constant xi_alu_addsat   : Std_logic_vector(5 downto 0) := "000110";
  constant xi_alu_addsatu  : Std_logic_vector(5 downto 0) := "000111";

  constant xi_alu_addsat4  : Std_logic_vector(5 downto 0) := "001000";
  constant xi_alu_addsat4u : Std_logic_vector(5 downto 0) := "001001";
  constant xi_alu_addsat2  : Std_logic_vector(5 downto 0) := "001010";
  constant xi_alu_addsat2u : Std_logic_vector(5 downto 0) := "001011";

  constant xi_alu_sub      : Std_logic_vector(5 downto 0) := "010000";
  constant xi_alu_subu     : Std_logic_vector(5 downto 0) := "010001";
  constant xi_alu_sub4     : Std_logic_vector(5 downto 0) := "010010";
  constant xi_alu_sub4u    : Std_logic_vector(5 downto 0) := "010011";

  constant xi_alu_sub2     : Std_logic_vector(5 downto 0) := "010100";
  constant xi_alu_sub2u    : Std_logic_vector(5 downto 0) := "010101";
  constant xi_alu_subsat   : Std_logic_vector(5 downto 0) := "010110";
  constant xi_alu_subsatu  : Std_logic_vector(5 downto 0) := "010111";

  constant xi_alu_subsat4  : Std_logic_vector(5 downto 0) := "011000";
  constant xi_alu_subsat4u : Std_logic_vector(5 downto 0) := "011001";
  constant xi_alu_subsat2  : Std_logic_vector(5 downto 0) := "011010";
  constant xi_alu_subsat2u : Std_logic_vector(5 downto 0) := "011011";

  constant xi_alu_slt      : Std_logic_vector(5 downto 0) := "100000";
  constant xi_alu_sltu     : Std_logic_vector(5 downto 0) := "100001";
     
  constant xi_alu_and      : Std_logic_vector(5 downto 0) := "110000";
  constant xi_alu_or       : Std_logic_vector(5 downto 0) := "110001";
  constant xi_alu_xor      : Std_logic_vector(5 downto 0) := "110010";
  constant xi_alu_nor      : Std_logic_vector(5 downto 0) := "110011";
  constant xi_alu_nop      : Std_logic_vector(5 downto 0) := "111111";

  -- Multiplier Operation Codes
  constant xi_mul_mult     : Std_logic_vector(5 downto 0) := "000000";
  constant xi_mul_multu    : Std_logic_vector(5 downto 0) := "000001";
  constant xi_mul_div      : Std_logic_vector(5 downto 0) := "000010";
  constant xi_mul_divu     : Std_logic_vector(5 downto 0) := "000011";
  constant xi_mul_mad      : Std_logic_vector(5 downto 0) := "000100";
  constant xi_mul_madu     : Std_logic_vector(5 downto 0) := "000101";
  constant xi_mul_mul      : Std_logic_vector(5 downto 0) := "000110";
  constant xi_mul_mulu     : Std_logic_vector(5 downto 0) := "000111";
  constant xi_mul_mfhi     : Std_logic_vector(5 downto 0) := "001000";
  constant xi_mul_mflo     : Std_logic_vector(5 downto 0) := "001001";
  constant xi_mul_mthi     : Std_logic_vector(5 downto 0) := "001010";
  constant xi_mul_mtlo     : Std_logic_vector(5 downto 0) := "001011";
  constant xi_mul_nop      : Std_logic_vector(5 downto 0) := "001111";

  -- Shift operation Codes
  constant xi_shift_sll    : Std_logic_vector(5 downto 0) := "000000";
  constant xi_shift_srl    : Std_logic_vector(5 downto 0) := "000001";
  constant xi_shift_sra    : Std_logic_vector(5 downto 0) := "000010";
  constant xi_shift_ror    : Std_logic_vector(5 downto 0) := "000100";
  constant xi_shift_rol    : Std_logic_vector(5 downto 0) := "000101";
  
  -- Program flow handle operation Codes
  constant xi_branch_blez     : Std_logic_vector(5 downto 0) := "000000";
  constant xi_branch_bgtz     : Std_logic_vector(5 downto 0) := "000001";
  constant xi_branch_bltz     : Std_logic_vector(5 downto 0) := "000010";
  constant xi_branch_bgez     : Std_logic_vector(5 downto 0) := "000011";
  constant xi_branch_beq      : Std_logic_vector(5 downto 0) := "000100";
  constant xi_branch_bne      : Std_logic_vector(5 downto 0) := "000101";   
  constant xi_branch_bgt1     : Std_logic_vector(5 downto 0) := "000110";
  constant xi_branch_j        : Std_logic_vector(5 downto 0) := "001000";
  constant xi_branch_jr       : Std_logic_vector(5 downto 0) := "001001";   
  constant xi_branch_rfe      : Std_logic_vector(5 downto 0) := "001010";
  constant xi_branch_carryon  : Std_logic_vector(5 downto 0) := "001111";   

  -- Scc & System Operation codes
    -- Scc & System Operation codes
  constant xi_system_rfe      : Std_logic_vector(5 downto 0) := "000000";  
  constant xi_system_suspend  : Std_logic_vector(5 downto 0) := "000010";
  constant xi_system_wcop     : Std_logic_vector(5 downto 0) := "010000";
  constant xi_system_rcop     : Std_logic_vector(5 downto 0) := "010001";
  constant xi_system_null     : Std_logic_vector(5 downto 0) := "001000";
  constant xi_system_break    : Std_logic_vector(5 downto 0) := "111111";
                                              
end isa_32;
  
package body isa_32 is
end isa_32;
