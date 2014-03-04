-----------------------------------------------------------------------
--                   XI_PCBVGEN.VHD                                  --
--               PC_basevalue Address Calculation                    --
-----------------------------------------------------------------------
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it                  --
-- DEIS, Department of Electronics Informatics and Systems,          --
-- University of Bologna, BOLOGNA , ITALY                            -- 
-----------------------------------------------------------------------

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

   -----------------------------------------------------------------------------
   -- PC_BASEVALUE_GENERATION
   -----------------------------------------------------------------------------

    -- In practice, PC_basevalue is the consistent value of the program counter,
    -- that is the PC in all cases but in the Branch Delay slots, when it becomes
    -- the jumping instruction value.
    -- This value is used only in case of RFE instructions, that is when handling interrupts

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;
  use work.components.all;

entity PCbvgen is
    generic( Iaddr_width     : positive := 24 );
    port(   clk,reset          : in  Std_logic;
            en_fd,en_dx        : in  Std_logic;
            jump_type          : in  Risc_jop;
	    curr_pc            : in  Std_logic_vector(iaddr_width-1 downto 0);

            PC_basevalue       : out Std_logic_vector(iaddr_width-1 downto 0);
            d_bds              : out Std_logic );
end PCbvgen;

architecture behavioral of PCbvgen is

signal d_curr_pc,x_curr_pc     : Std_logic_vector(iaddr_width-1 downto 0);
signal x_jump_type             : Risc_jop;
  
begin

  pcbv_reg1  : Data_Reg generic map (reg_width => iaddr_width,init_value => reset_value_lower)
                        port map (clk,reset,en_fd,Curr_PC,d_curr_pc);
  pcbv_reg2  : Data_Reg generic map (reg_width => iaddr_width,init_value => reset_value_lower)
                        port map (clk,reset,en_dx,d_Curr_PC,x_curr_pc);  
  jtype_reg1 : Data_Reg generic map (reg_width => 6)
                        port map (clk,reset,en_dx,jump_type,x_jump_type);
   
  process(x_jump_type,d_curr_pc,x_curr_pc)
  begin
   if (x_jump_type /= xi_branch_carryon) then

          -- The current instruction is a branch delay slot, the curr_PC is the
          -- address of the previous instruction (the jump that is being performed)
          PC_basevalue <= x_curr_pc;
          d_bds        <= '0';
    else
          -- Normal nojump active instruction. 
          PC_basevalue <= d_curr_pc;
          d_bds        <= '1';
    end if;
  end process;
     
end behavioral;

