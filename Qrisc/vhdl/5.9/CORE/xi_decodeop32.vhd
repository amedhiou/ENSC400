----------------------------------------------------------------------------
--                         XI_DECODEOP32.VHD                              --
--                                                                        --
--                                                                        --
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it                       --
-- DEIS, Department of Electronics Informatics and Systems,               --
-- University of Bologna, BOLOGNA , ITALY                                 --
----------------------------------------------------------------------------
--                                                                        --
--   Instruction Decoding combinatorial logic, built to support           --
--   XiRisc-32 ISA instruction set described in file xi_isa.vhd           --
--                                                                        --
----------------------------------------------------------------------------

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

--
-- The Decodeop architecture is strictly combinatorial: it performs all the 
-- decodification of the data elaboration required by the instruction in the
-- decode stage: This block generates all the control signals that,
-- transmitted to the datapath, will rule all the following stages of the
-- instruction execution.
-- 
-- Functions performed:
-- (A) Selection of the Writeback destination register address RD.
-- (B) Determination of  the ALU operation code, and extension to 32 bits of
--     the Immediate operand. Selection of the execute stage output.
-- (C) Determination of Memory access operations control signals that will be
--       sent to the off-chip main data memory.
-- (D) Raise of the "Illegal Opcode" exception in case the input opcode is
--       not recognized.
--

-- NOTE: All Std_logic control sognals are defined as ACTIVE LOW SIGNALS!!!!!

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;

entity Decode_Op32 is
    generic( word_width : positive := 32;
             rf_registers_addr_width : positive := 5 );
    port( instr                        : in   Std_logic_vector(31 downto 0);
          r1_reg,r2_reg,r3_reg         : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          writeback_reg                : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          jump_type                    : out  Risc_jop;
          alu_command                  : out  Alu_control;
          alu_immed                    : out  Std_logic_vector(word_width-1 downto 0);
          shift_op                     : out  Risc_shiftcode;
          cop_command                  : out  Cop_control;
          mul_command                  : out  Risc_mulop;
          exe_outsel                   : out  Risc_exeout;
          mem_command                  : out  Mem_control;
          illegal_opcode               : out  Std_logic );
end Decode_Op32;

architecture behavioral of Decode_Op32 is 

type instr_spy is (alu,alui,mul,shift,lui,load,store,jump,branch,cop,ill_op);  
  
constant r0       : Std_logic_vector(rf_registers_addr_width-1 downto 0) := (others=>'0');
constant link_reg : Std_logic_vector(rf_registers_addr_width-1 downto 0) := (others=>'1');
signal   spy      : instr_spy;

 begin   

    process(instr)
    -- Operation codes
    variable op           : Std_logic_vector(5 downto 0);
    variable opx          : Std_logic_vector(5 downto 0);
    variable op_scc       : XI_scc_op;
    variable op_branch  : Std_logic_vector(4 downto 0);
    
    -- Addressed Registers:
    variable rs  : Std_logic_vector(rf_registers_addr_width-1 downto 0);
    variable rt  : Std_logic_vector(rf_registers_addr_width-1 downto 0);
    variable rd  : Std_logic_vector(rf_registers_addr_width-1 downto 0);

    -- Shift Amount Field:
    variable shamt   : Std_logic_vector(4 downto 0);
    
    -- 16-bit immediate operand:(Used for Register/Immediate Alu operations)
    variable immed16 : Std_logic_vector(15 downto 0);
    
    begin

      -- Operation codes
      op           := instr(31 downto 26);
      opx          := instr( 5 downto  0);
      op_branch    := instr(20 downto 16);
      
      -- Addressed Registers:
      rs  := instr(25 downto 21);
      rt  := instr(20 downto 16);
      rd  := instr(15 downto 11);

      -- Shift Amount Field:
      shamt   := instr(10 downto 6);
    
      -- 16-bit immediate operand:
      --   (Used for Register/Immediate Alu operations)
      immed16 := instr(15 downto 0);

      if op = xi_add then    

            --synopsys synthesis_off
            spy <= alu;
            --synopsys synthesis_on
         
            writeback_reg <= rd;
			 
	  --  alu_command <= (op=>opx,isel=>'1',immed=>(others => '0'),hrdwit=>'1' );
            alu_command.op     <= opx;
            alu_command.isel   <= '1';
            alu_immed  <= (others => '0');
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

           -- mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';

            
            illegal_opcode <= '1'; 
	    jump_type   <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_addi then

            writeback_reg <= rt;
			 
	    --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;
            
            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_addiu then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on

            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_addu,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_addu;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

          --  mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

       elsif op = xi_slti then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on
         
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_slt,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op <= xi_alu_slt;
            alu_command.isel <= '0';
            alu_immed <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_sltiu then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on

            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_sltu,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op <= xi_alu_sltu;
            alu_command.isel <= '0';
            alu_immed <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_andi then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on

            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_and,isel=>'0',immed=>EXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op <= xi_alu_and;
            alu_command.isel <= '0';
            alu_immed <= EXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_ori then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on

            writeback_reg <= rt;

           -- alu_command <= (op=>xi_alu_or,isel=>'0',immed=>EXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op <= xi_alu_or;
            alu_command.isel <= '0';
            alu_immed <= EXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1';   
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_xori then

            --synopsys synthesis_off
            spy <= alui;
            --synopsys synthesis_on
        
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_xor,isel=>'0',immed=>EXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op <= xi_alu_xor;
            alu_command.isel <= '0';
            alu_immed <= EXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      elsif op = xi_mul then

            --synopsys synthesis_off
            spy <= mul;
            --synopsys synthesis_on
            
            writeback_reg <= rd;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>(others=>'0'),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= (others=>'0');
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';

            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= opx;

      elsif op = xi_shift then

            --synopsys synthesis_off
            spy <= shift;
            --synopsys synthesis_on
            
            writeback_reg <= rd;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>EXT(shamt,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '0';
            alu_immed  <= EXT(shamt,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= opx(2 downto 0);
            exe_outsel <= op(5 downto 3);

           -- mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <=  xi_mul_nop;

      elsif op = xi_shift_v then

            --synopsys synthesis_off
            spy <= shift;
            --synopsys synthesis_on
        
            writeback_reg <= rd;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>(others => '0'),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= (others => '0');
            alu_command.hrdwit <= '1';
            
            shift_op   <= opx(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <=  xi_mul_nop;
            
      elsif op = xi_lui then

            --synopsys synthesis_off
            spy <= lui;
            --synopsys synthesis_on
            
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>immed16(word_width-17 downto 0)&Conv_std_logic_vector(0,16),hrdwit=>'1' );
            alu_command.op     <= xi_alu_addu;
            alu_command.isel   <= '0';
            alu_immed  <= immed16(word_width-17 downto 0)&Conv_std_logic_vector(0,16);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= xi_add(5 downto 3);
 
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1';
 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

      -------------------------------------------------------------------------
      -- MEMORY ACCESS Operations ---------------------------------------------
      -------------------------------------------------------------------------

      elsif op = xi_lw then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
            
            -- LOAD BYTE (The byte loaded from memory is sign-extended)
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op         <= xi_alu_addu;
            alu_command.isel       <= '0';
            alu_immed      <= SXT(immed16,word_width);
            alu_command.hrdwit     <= '1' ;
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'0',mw=>'1',mb=>'1',mh=>'1',sign=>'0');
            mem_command.mr   <= '0';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '0';
            
	    illegal_opcode <= '1'; 
            
            jump_type   <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;                            
	 
      elsif op = xi_lh then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
            

            -- LOAD HALFWORD (The halfword loaded from memory is sign-extended) 
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'0',mw=>'1',mb=>'1',mh=>'0',sign=>'0');
            mem_command.mr   <= '0';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '0';
            mem_command.sign <= '0';
            
	    illegal_opcode <= '1'; 
            
            jump_type   <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <= "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;            
         
      elsif op = xi_lb  then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
            
             -- LOAD byte
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'0',mw=>'1',mb=>'0',mh=>'1',sign=>'0');
            mem_command.mr   <= '0';
            mem_command.mw   <= '1';
            mem_command.mb   <= '0';
            mem_command.mh   <= '1';
            mem_command.sign <= '0';
            
	    illegal_opcode   <= '1'; 
            
            jump_type  <= xi_branch_carryon;
	    --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;            
            
            mul_command <= xi_mul_nop;                              
        
      elsif op = xi_lhu then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
            
            -- LOAD HALFWORD UNSIGNED (The halfword is zero-extended)
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'0',mw=>'1',mb=>'1',mh=>'0',sign=>'1');
            mem_command.mr   <= '0';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '0';
            mem_command.sign <= '1';

	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

       elsif op = xi_lbu then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
         
            -- LOAD BYTE UNSIGNED (The byte loaded from memory is zero-extended)
            writeback_reg <= rt;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'0',mw=>'1',mb=>'0',mh=>'1',sign=>'1');
            mem_command.mr   <= '0';
            mem_command.mw   <= '1';
            mem_command.mb   <= '0';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';

	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;
                             
            -- STORE operations: the immediate operand is the target address offset.
            -- this operation has no writeback stage, WRITEBACK_REG is conventionally
            -- set to R0.
          
        elsif  op = xi_sb then

            --synopsys synthesis_off
            spy <= store; 
            --synopsys synthesis_on

            -- STORE BYTE
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'0',mb=>'0',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '0';
            mem_command.mb   <= '0';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;      
                             
        elsif op = xi_sh then

            --synopsys synthesis_off
            spy <= store;
            --synopsys synthesis_on
           
            -- STORE HALF WORD
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'0',mb=>'1',mh=>'0',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '0';
            mem_command.mb   <= '1';
            mem_command.mh   <= '0';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;                                                  
                            
	elsif op = xi_sw  then

            --synopsys synthesis_off
            spy <= load;
            --synopsys synthesis_on
          
            -- STORE WORD 
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width),hrdwit=>'1' );
            alu_command.op     <= xi_alu_add;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width);
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

            --mem_command <= (mr=>'1',mw=>'0',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '0';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_carryon;

            --cop_command <= ( "00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;      

        ---------------------------------------------------------------
        -- CONTROL FLOW OPERATIONS                                   --
        -- Part a: Unconditional Jumps                               --
        ----------------------------------------------------------------
                        
        elsif op = xi_j  then

            --synopsys synthesis_off
            spy <= jump;
            --synopsys synthesis_on

            -- JUMP
                -- Type J instructions, featuring a 26-bit immediate
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>SXT(instr(25 downto 0),word_width-2)&("00"),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= SXT(instr(25 downto 0),word_width-2)&("00");
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1';
            jump_type   <= xi_branch_j;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;
                           

	elsif op = xi_jal then

            --synopsys synthesis_off
            spy <= jump;
            --synopsys synthesis_on         
            
            -- JUMP and LINK
            writeback_reg <= link_reg;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>SXT(instr(25 downto 0),word_width-2)&("00"),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= SXT(instr(25 downto 0),word_width-2)&("00");
            alu_command.hrdwit <= '1';   
            
            shift_op    <= xi_shift_sll(2 downto 0);
            exe_outsel  <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1'; 
            jump_type   <= xi_branch_j;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;      

        -- JUMP REGISTER
        elsif op = xi_jr then

            --synopsys synthesis_off
            spy <= jump;
            --synopsys synthesis_on
          
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>( others => '0' ),hrdwit=>'1' );
            alu_command.op      <= xi_alu_nop;
            alu_command.isel    <= '1';
            alu_immed   <= ( others => '0' );
            alu_command.hrdwit  <= '1';   
            
            shift_op <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

	    --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';

            illegal_opcode <= '1'; 
	    jump_type  <= xi_branch_jr;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;             
                 
          -- JUMP and LINK REGISTER 
	  elsif op = xi_jalr then

            --synopsys synthesis_off
            spy <= jump;
            --synopsys synthesis_on

            writeback_reg <= link_reg;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>( others => '0' ),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= ( others => '0' );
            alu_command.hrdwit <= '1';  
            
	    shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
	    illegal_opcode <= '1'; 
            jump_type  <= xi_branch_jr;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;             

        ---------------------------------------------------------------
        -- CONTROL FLOW OPERATIONS                                   --
        -- Part b: Conditional Branches                              --
        ---------------------------------------------------------------

          -- Branch Operation
          elsif op = xi_branch then

            --synopsys synthesis_off
            spy <= branch;
            --synopsys synthesis_on
             
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width-2)&("00"),hrdwit=>'1' );
            alu_command.op      <= xi_alu_nop;
            alu_command.isel    <= '0';
            alu_immed   <= SXT(immed16,word_width-2)&("00");
            alu_command.hrdwit  <= '1';
             
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
            jump_type      <= EXT(op_branch,6);

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;

          -- Branch Equal Operation
          elsif op = xi_bequ then

            --synopsys synthesis_off
            spy <= branch;
            --synopsys synthesis_on
            
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width-2)&("00"),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width-2)&("00");
            alu_command.hrdwit <= '1';

            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
            jump_type      <= xi_branch_beq;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
             
            mul_command <= xi_mul_nop;

         -- Branch Not Equal Operation
          elsif op = xi_bne then

            --synopsys synthesis_off
            spy <= branch;
            --synopsys synthesis_on
            
            writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>SXT(immed16,word_width-2)&("00"),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '0';
            alu_immed  <= SXT(immed16,word_width-2)&("00");
            alu_command.hrdwit <= '1';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
            jump_type      <= xi_branch_bne;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop; 
        
         elsif (op = xi_brdec and include_hrdwit=1) then

            --synopsys synthesis_off
            spy <= branch;
            --synopsys synthesis_on
           
            writeback_reg <= rs;

            --alu_command <= (op=>xi_alu_sub,isel=>'1',immed=>SXT(immed16,word_width-2)&("00"),hrdwit=>'0' );
            alu_command.op     <= xi_alu_sub;
            alu_command.isel   <= '1';
            alu_immed  <= SXT(immed16,word_width-2)&("00");
            alu_command.hrdwit <= '0';
            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1'; 
            jump_type  <= EXT(op_branch,6);

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;      
                              
           
          -- COPROCESSOR CALL
          -- (Break,Trap,rfe,suspend Instructions are utilized as Calls to
          -- coprocessor 0)            
          elsif (op=xi_cop) then            

            --synopsys synthesis_off
            spy <= cop;
            --synopsys synthesis_on
            
            --alu_command <= (op=>xi_alu_add,isel=>'0',immed=>(others=>'0'),hrdwit=>'1' );
            alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= EXT(instr(25 downto 6),word_width);  -- Code for break operations
            alu_command.hrdwit <= '1';            
            shift_op   <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3); 
			  
            -- mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '1';

            mul_command <= xi_mul_nop;    

            
               -- rfe instructions
               if (opx=xi_system_rfe) and (instr(7 downto 6)=cop_scc) then
                  jump_type <= xi_branch_rfe;
               else
                  jump_type <= xi_branch_carryon;
               end if;
            
               cop_command.index <= (shamt(1 downto 0));
               cop_command.op    <= opx;
               
               -- Rcop instruction
               -- The only coprocessor instruction that has an impact over the
               -- processor functioning is the rcop, that will cause a
               -- writeback over the processor Regfile. This must be the same
               -- for all coprocessors, or malfunctions may occurr!
               -- In the case of all other cop instructions, the instruction is
               -- simply handed over to the coprocessor that will handle it
               -- iself without particular interest on behalf of the core to
               -- control what is going on.
               if (opx=xi_system_rcop) then
                   writeback_reg    <= rt;               
               else                 
                   writeback_reg    <= r0;
               end if;
                        
        else

            --synopsys synthesis_off
            spy <= ill_op;
            --synopsys synthesis_on

            -- ILLEGAL OPCODE
	    writeback_reg <= r0;

            --alu_command <= (op=>xi_alu_add,isel=>'1',immed=>( others => '0' ),hrdwit=>'1' );        
	    alu_command.op     <= xi_alu_nop;
            alu_command.isel   <= '1';
            alu_immed  <= ( others => '0' );
            alu_command.hrdwit <= '1';
            
	    shift_op <= xi_shift_sll(2 downto 0);
            exe_outsel <= op(5 downto 3);

	    --mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
            mem_command.mr   <= '1';
            mem_command.mw   <= '1';
            mem_command.mb   <= '1';
            mem_command.mh   <= '1';
            mem_command.sign <= '1';
            
            illegal_opcode <= '0';
	    jump_type   <= xi_branch_carryon;

            --cop_command <= ("00",xi_system_null,rd);
            cop_command.index <=  "00";
            cop_command.op    <= xi_system_null;
            
            mul_command <= xi_mul_nop;      
            
        end if;
     
    end process;    
    
    r1_reg  <= instr(25 downto 21)
                 when (instr(31 downto 26)/=xi_cop or instr(5 downto 0)/=xi_system_break)
                 else Conv_std_logic_vector(4,rf_registers_addr_width);
    r2_reg  <= instr(20 downto 16)
                 when (instr(31 downto 26)/=xi_cop or instr(5 downto 0)/=xi_system_break)
                 else Conv_std_logic_vector(5,rf_registers_addr_width);
    
    r3_reg  <= instr(15 downto 11);
    
 end behavioral;  
