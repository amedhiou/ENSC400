-----------------------------------------------------------------------
--                   XI_DECODEPC.VHD                         --
--               Next_PC Address Calculation                 --
-----------------------------------------------------------------------
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it          --
-- DEIS, Department of Electronics Informatics and Systems,  --
-- University of Bologna, BOLOGNA , ITALY                    -- 
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
--I
-- This license is a modification of the Ricoh Source Code Public
-- License Version 1.0 which is similar to the Netscape public license.
-- We believe this license conforms to requirements adopted by OpenSource.org.
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- Decode pc logic for the Risc processor model.
-- This logic is controlled by the jump_type signal produced by the
-- Decodeop main Instruction Decode Logic (IDL)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.basic.all;
use work.isa_32.all;
use work.components.all;

entity Decode_PC is
  generic( include_scc : integer:= 1;
           Word_Width      : positive := 32;
           Instr_width     : positive := 32;
           Iaddr_width     : positive := 24 );
  
  port(   serve_exception : in std_logic;
          jump_type       : in Risc_jop;
          curr_pc         : in Std_logic_vector(iaddr_width-1 downto 0);
          Reg_A,Reg_B     : in Std_logic_vector(word_width-1 downto 0);
          Immediate       : in Std_logic_vector(word_width-1 downto 0);
          serve_proc_addr : in Std_logic_vector(iaddr_width-1 downto 0);
          epc             : in Std_logic_vector(iaddr_width-1 downto 0);

          out_next_pc : out Std_logic_vector(iaddr_width-1 downto 0); 
          pc_plus_4   : out Std_logic_vector(iaddr_width-1 downto 0) );
end Decode_PC;


architecture behavioral of Decode_PC is

  --synopsys synthesis_off 
  type branch_spy is (blez,bgtz,bltz,bgez,beq,bne,bgt1,j,jr,rfe,carryon,exception);
  signal spy : branch_spy;
  --synopsys synthesis_on
  
  signal Bta, pcplus4, target, next_pc, increment : Std_logic_vector(iaddr_width-1 downto 0);
  signal condition                                : Std_logic;
  signal zero_data,uno_data                       : Std_logic_vector(word_width-1 downto 0);

-- This signals collect the overflow values of the adders used in this entity,
-- but their values are never used so I expect the Synthesis logic to
-- destroy them
  signal of1, of2 : std_logic;


begin

  --synopsys synthesis_off
  process(jump_type)
  begin
    if jump_type = xi_branch_beq then
       spy <= beq;
    elsif jump_type = xi_branch_bne then
       spy <= bne;
    elsif jump_type = xi_branch_blez then
       spy <= blez;
    elsif jump_type = xi_branch_bgtz then
       spy <= bgtz;
    elsif jump_type = xi_branch_bltz then
       spy <= bltz;
    elsif jump_type = xi_branch_bgez then
       spy <= bgez;
    elsif jump_type = xi_branch_bgt1 then
       spy <= bgt1;
    elsif (serve_exception = '0' and include_scc=1) then
       spy <= exception;
    elsif jump_type = xi_branch_rfe and include_scc=1 then
       spy <= rfe;
    elsif jump_type = xi_branch_jr then
       spy <= jr;
    elsif jump_type = xi_branch_j then
       spy <= j;
    else
       spy <= carryon;
    end if;
  end process;
      
  --synopsys synthesis_on
  
  zero_data <= (others => '0');
  uno_data <=Conv_std_logic_vector(1,Word_width); 

  BRANCH_CONDITION_RESOLVING :
  process(Reg_A, Reg_B, Jump_type, zero_data, uno_data)
  begin
    if jump_type = xi_branch_beq then      
       if Reg_A = Reg_B then
               condition <= '0';
       else
               condition <= '1';
       end if;
    elsif jump_type = xi_branch_bne then     
       if Reg_A /= Reg_B then
               condition <= '0';
       else
               condition <= '1';
       end if;
    elsif jump_type = xi_branch_blez then      
       if Reg_A(word_width-1) = '1' or Reg_A = zero_data then
               condition <= '0';
       else
               condition <= '1';
       end if;
    elsif jump_type = xi_branch_bgtz then
       if Reg_A(word_width-1) = '0' and Reg_A /= zero_data then
               condition <= '0';
      else
               condition <= '1';
       end if;
    elsif jump_type = xi_branch_bltz then
       if Reg_A(word_width-1) = '1' then
               condition <= '0';
       else
               condition <= '1';
       end if;
    elsif jump_type = xi_branch_bgez then
       if Reg_A(word_width-1) = '0' then
               condition <= '0';
       else
               condition <= '1';
       end if;      
    elsif jump_type = xi_branch_bgt1 then
       if Reg_A(word_width-1) = '0' and Reg_A /= uno_data then
               condition <= '0';
       else
               condition <= '1';
       end if;
    else   
       condition <= '1';
    end if;
    
  end process;


-- PCPLUS4_CALCULATION:                 -------------------------------------------------------

  
    increment <= Conv_std_logic_vector(Instr_width/8,Iaddr_width);
  
    incr : gp_adder generic map (width => Iaddr_width)
    port map (curr_pc, increment, pcplus4, of1);

  -- Adder calculating jump target address for jump offset or branches
    bta_calc : gp_adder generic map (width => Iaddr_width)
    port map (curr_pc, Immediate(iaddr_width-1 downto 0),Bta, of2);

  -- Immediate target extension: 
  target <= Immediate(iaddr_width-1 downto 0);

  

  NEXT_PC_CALCULATION :
    -- Multiplexing logic that selects, according to the currently decoded
    -- instruction, the appropriate next_pc value.            
  process(serve_exception,serve_proc_addr,jump_type,condition,Reg_A,pcplus4,Bta,epc,target)
  begin

    -- Exception handling: issuing and RFE
    if serve_exception = '0' and include_scc=1 then                         
                           -- Exception issue: The nextpc is forced to the
                           -- Interrupt table value just read from Dmem
                           next_pc <= serve_proc_addr;
                           
    elsif jump_type = xi_branch_rfe and include_scc=1 then
                         
                           -- Rfe ( Return from exception ) Instruction:
                           -- The PC is ripristinated to the next_pc that had been
                           -- calculated but redirected to EPC when the servicing
                           -- procedure was called.
                           next_pc <= epc;
     
    -- Jumps, branches
    elsif jump_type = xi_branch_jr then                           
                           
                           -- Jump register instructions: (jr,jalr)
                           -- Next_pc <= [RA]
                           -- ( The last bit represents the instruction decode mode
                           --   and in this context is meaningless )
                           -- next_pc <= Reg_A(iaddr_width-1 downto 1)&"0";
                           next_pc <= Reg_A(iaddr_width-1 downto 1)&"0";
                          
    elsif jump_type = xi_branch_j then

                           -- Jump Immediate instructions: (j,jal)                            
                            if (iaddr_width=29) then
                                next_pc <= curr_pc(29) & target;
                            elsif (iaddr_width>28) then
                                next_pc <= curr_pc(iaddr_width-1 downto 28) & target;
                            else
                                next_pc <= target;
                            end if;
                                                     
                                                      
    elsif (jump_type(3) = '0')  then
                         
                          -- Branch instructions: (bne,beq,blez,bgtz,bltz,bgez,bgt1)
                          -- The branch condition previously determined is checked:
                          -- Condition='0' : Taken   Branches: Next_PC = PC + Immediate
                          -- Condition='1' : Untaken Branches: Next_PC = PC + 4
                           if condition = '0' then
                             next_pc <= Bta;
                           else
                             next_pc <= pcplus4;
                           end if;
    else                                      
                           -- All others instructions do not alter the program flow,
                           -- elaboration simply continues to the next scheduled instruction:
                           -- Next_PC <= PC + 4      
                           next_pc <= pcplus4;                           
    end if;
  end process;

  out_next_pc <= next_pc;
  pc_plus_4   <= pcplus4;

  
end behavioral;

 
