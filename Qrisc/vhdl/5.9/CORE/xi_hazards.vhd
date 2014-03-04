---------------------------------------------------------------------------
--                         XI_HAZARDS.VHD                                --
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
-- This license is a modification of the Cadence Design Systems Source Code Public 
-- License Version 1.0 which is similar to the Netscape public license.  
-- We believe this license conforms to requirements adopted by OpenSource.org.  
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- This file contains the description of the combinatorial blocks included in
-- the control block to handle pipeline hazard configuration.
-- The package here defined contains element for both a single-datapath and
-- a double-datapath processor model.



-------------------------------------------------------------------------------
--              1)      BYPASS LOGIC                                         --
-------------------------------------------------------------------------------

-- This small combinatorial block is associated to each Rfile output, and is
-- used to detect if the operand being read on the rfile need to be bypassed
-- from the following pipeline stages (see Hennessy/Patterson "Computer
-- Architecture,a quantitative Approach", ch. 6 par. 4 ).

-- The block does not execute bypass: it is only a control logic, that 
-- determines the necessary bypass configuration chosen between:

-- No_Bypass -> The Rfile output is passed to the alu
-- Main_exe  -> The datapath Alu result is bypassed to next cycle's alu input
-- Main_mem  -> The datapath Memory stage result is bypassed to next cycle's alu input 

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.basic.all;
  
entity Bypass_Logic is
    generic( rf_registers_addr_width : positive := 5);
    port( source_reg             : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          main_erd,main_mrd      : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          x_we ,m_we             : in  Std_logic;

          byp_control            : out Risc_bypcontrol    );
end Bypass_Logic;


architecture behavioral of Bypass_Logic is

constant r0       : Std_logic_vector(rf_registers_addr_width-1 downto 0) := (others=>'0');
  
begin

   process( source_reg,main_erd,main_mrd,x_we,m_we )    
   variable exec_main , memory_main : Boolean;
    
    begin
       -- The Alu_out to Alu_in Bypass condition is verified:
       -- Decoded_instr( Source Register ) = Executing_instr( Destination
       -- Register)
       -- In case the value to be bypassed is the result of a deactivated
       -- instruction (write enable signal we='0'), it is not significant
       -- and the bypass channel must not be activated.
      
       exec_main  := (source_reg = main_erd) and (main_erd /= r0 ) and (x_we = '0');
       

       -- The Mem_out to Alu_in Bypass condition is verified:
       -- Decoded_instr( Source Register ) = Memory_instr( Destination Reg)
        
       memory_main:= (source_reg = main_mrd) and (main_mrd /= r0 ) and (m_we = '0');
       
       if exec_main then
          byp_control <= Main_exe;
       elsif memory_main then
          byp_control <= Main_mem;
       else
          byp_control <= no_bypass;
       end if;                        

    end process;

end behavioral;


-------------------------------------------------------------------------------
--         2)    STALL LOGIC                                                 --
-------------------------------------------------------------------------------

-- The STALL logic is a strictly combinatorial control logic that can 
-- deactivate write operations and/or hold the 
-- pipeline flow to resolve potential hazard configurations: 
--
-- In practice, this logic issues a load stall in case a load instruction
-- (that can be executed only on the Main Datapath) has a target register
-- used as source in one of the two following parallel instructions.

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.basic.all;
  use work.isa_32.all;
    
entity Stall_Logic is
    port( byp_controlA,byp_controlB  : in  Risc_bypcontrol;          
          jump_type                  : in  Risc_jop;
          x_mul_command              : in  Risc_mulop;
	  x_mem_isread,m_mem_isread  : in  Std_logic; 
          serve_exception            : in  Std_logic;
          stall_decode               : out Std_logic	);    
end Stall_logic;


architecture behavioral of Stall_logic is

signal branch_uses_rega,branch_uses_regb                       : Std_logic;
signal branch_uses_main_mem_result,branch_uses_main_exe_result : Std_logic;
signal load_stall,branchlw_stall,branchmul_stall               : Std_logic;

begin
           
    -- LOAD_STALL CONFIGURATION DETECTION
    --
    -- Detection of load_stall configuration:
    -- the first two stages of the pipeline 
    -- must be stalled if a memory load is followed by some instruction
    -- using the load target register as source operand.
    -- 
    process(byp_controlA,byp_controlB,x_mem_isread)    
    begin      

      if x_mem_isread = '0' and ( byp_controlA = Main_exe or byp_controlB = Main_exe ) then
      -- Load stall scheduled at next cycle
         load_stall <= '0' ;
      else
      -- No load stall configuration detected
         load_stall <= '1' ;
      end if;
      
    end process;
    

    -- BRANCH/LW Stall configuration detection
    -- This stall configuration is used to break a critical path in the processor:
    -- In case the output of a Memory Load operation is to be used as argument
    -- of a conditional branch, this operation is stalled to accomplish the
    -- clocking of the Load result and thus break the critical path.    

    branch_uses_rega <= '0' when ( jump_type=xi_branch_beq  or jump_type=xi_branch_bne or
                                   jump_type=xi_branch_blez or jump_type=xi_branch_bgez or
                                   jump_type=xi_branch_bgt1 or jump_type=xi_branch_jr )
                            else '1';
    
    branch_uses_regb <= '0' when ( jump_type=xi_branch_beq  or jump_type=xi_branch_bne )
                            else '1';
    
    branch_uses_main_mem_result <= '0' when ( byp_controlB=Main_mem and branch_uses_regb='0' ) or
                                            ( byp_controlA=Main_mem and branch_uses_rega='0' )
                                   else '1';

    
    process(m_mem_isread,branch_uses_main_mem_result)
    begin    
       if ( m_mem_isread='0' and branch_uses_main_mem_result='0') then 
                  branchlw_stall <= '0';
       else
                  branchlw_stall <= '1';
       end if;
    end process;

    -- BRANCH/Mul Stall configuration detection
    -- This stall configuration is used to break a critical path in the processor:
    -- In case the output of a single-cycle Mul operation is to be used as argument
    -- of a conditional branch, this operation is stalled to accomplish the
    -- clocking of the Mul result and thus break the critical path.
    branch_uses_main_exe_result <= '0' when ( byp_controlB=main_exe and branch_uses_regb='0' ) or
                                            ( byp_controlA=main_exe and branch_uses_rega='0' )
                                   else '1';
    
    process(x_mul_command,branch_uses_main_exe_result)
    begin                              
       if ( x_mul_command=xi_mul_mul or x_mul_command=xi_mul_mulu ) and
          ( branch_uses_main_exe_result='0' )  then
         
                  branchmul_stall <= '0';
       else
                  branchmul_stall <= '1';        
       end if;
    end process;
    

    -- OUTPUT CONTROL ---------------------------------------------------------

        -- Stall control signals generation:
    -- In case an exception or interrupt is being acknowledged (that is, a
    -- servicing procedure is about to be started) the current elaboration
    -- will be aborted, so the pipeline stall must not be activated.
    process(serve_exception,branchlw_stall,branchmul_stall,load_stall)
    begin

    if serve_exception = '1' then
    
    -- NO EXCEPTION SERVICING SCHEDULED FOR NEXT CYCLE               
       if (load_stall = '0') or (branchlw_stall = '0') or (branchmul_stall='0') then  
          -- Load Stall handling:
          stall_decode <= '0';          
       else
          --    No hazard configuration detected    --
          stall_decode <= '1';
       end if;

    else
      -- An exception is being served, the current elaboration is aborted.      
       stall_decode <= '1';       
    end if;
      
    end process;
         
end behavioral;

