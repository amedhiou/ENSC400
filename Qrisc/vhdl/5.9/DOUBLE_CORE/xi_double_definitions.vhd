---------------------------------------------------------------------------
--                        XI_DOUBLE_DEFINITIONS.VHD                      --
---------------------------------------------------------------------------
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

-- Component descriptions for some structural blocks used in the double datapath
-- model design
-- 

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;
  
package double_definitions is

component Double_Bypass_Logic  
      generic( rf_registers_addr_width : positive := 5);
      port( source_reg         : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
            main_erd, main_mrd : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
            aux_erd, aux_mrd   : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
            x_we, m_we         : in std_logic;

            byp_control : out Risc_bypcontrol ); 
end component;
             
component Double_Stall_Logic
   port( byp_controlA, byp_controlB,
        byp_controlC, byp_controlD      : in  Risc_bypcontrol;
        jump_type                       : in  Risc_jop;
        x_mul_command                   : in  Risc_mulop;
        x_mem_isread, m_mem_isread      : in  std_logic;
        x_mulpath, x_mempath, m_mempath : in  std_logic;
        serve_exception                 : in  std_logic;
        stall_decode                    : out std_logic );
end component;

component Double_control
         generic(
              -- System Control Coprocessor is the coprocessor handling interrupts
              -- and exceptions
              include_scc : integer:= 1;
              -- Hardware iterations: allows for the utilization of Branch Decrement
              -- instructions
              include_hrdwit  : integer := 1;
              -- Number of bits to address GP register in the processor Rfile
              -- The number of registers will be 2**rf_registers_addr_width
              rf_registers_addr_width : positive := 5;
              -- BUS WIDTH DEFINITION
              -- Processor Data Width
              Word_Width      : positive := 32;
              -- Processor Instruction Width
              Instr_Width     : positive := 32;
              -- Processor Instruction addressing space Width
              Iaddr_width     : positive := 24;
              -- Instruction Address imposed at reset and reboot
              reboot_value_upper  : integer := 0;
              reboot_value_lower  : integer := 0;
              reset_value_upper   : integer := 0;
              reset_value_lower   : integer := 16#1000# );

         
       port( clk                         : in   Std_logic;

              -- PIPELINE CONTROL SIGNALS
              reset,reboot                : in   Std_logic;
              freeze                      : in   Std_logic;
              I_NREADY,D_NREADY           : in   std_logic;
              
           -- SIGNALS CONTROLLING OUTSIDE IMEMORY
              imem_address                : out  Std_logic_vector(Iaddr_width-1 downto 0);
              imem_out                    : in   Std_logic_vector(Instr_width-1 downto 0);
              
           -- REGISTER FILE READS
              -- Source registers A and B are read from the register file, to perform
              -- jump register operation or to check branch conditions.
              branch_rega,branch_regb,
              branch_regc,branch_regd    : in    Std_logic_vector(Word_width-1 downto 0);
               
           -- INTERRUPT SERVICE CONTROL SIGNALS
              -- The value produced from data memory access, that is a
              -- pointer to the appropriate Exception servicing procedure,
              -- is forced on the next_pc register in case an exception has
              -- been acknowledged.
              serve_exception             : in   Std_logic;
              incoming_servproc_addr      : in   Std_logic_vector(Iaddr_width-1 downto 0);
 
           -- DATAPATH CONTROL SIGNALS
              -- Register file Control 
              rs1_1,rs2_1,rd_1            : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
              rs1_2,rs2_2,rd_2            : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
              rcop                        : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
              
              -- Bypass Control
              byp_controlA,byp_controlB   : out  Risc_bypcontrol;
              byp_controlC,byp_controlD   : out  Risc_bypcontrol;
              
              -- AluExecution control
              alu_command1,alu_command2   : out  alu_control;
              alu_immed1,alu_immed2       : out  Std_logic_vector(Word_width-1 downto 0);
              shift_op1,shift_op2         : out  Risc_shiftcode;
              exe_outsel1,exe_outsel2     : out  Risc_exeout;
              
           -- Multiplication & Accumulation Logic Control
              dmul_command                : out  Risc_mulop;
              d_writeenable,x_writeenable,
              m_writeenable               : out  Std_logic;
              
           -- Memory access control
              smdr_enable                 : out  Std_logic;
              xmem_command,mmem_command   : out  Mem_control;
      
              -- The effective Curr_pc signal is transmitted to the System control
              -- coprocessor to update EPC register in case of exceptions,
              -- while the next PC+4 value is saved on the JAR register as a
              -- path to be stored on $31.
              -- On the contrary, EPC is used to restore the current address in
              -- case of RFE instruction and represents the PC_basevalue saved
              -- at the beginning of the service procedure
              d_bds                        : out  Std_logic;
              PC_basevalue,pc_plus_4       : out  Std_logic_vector(Iaddr_width-1 downto 0);
              epc                          : in   Std_logic_vector(Iaddr_width-1 downto 0);

             -- Specification of the chosen channel for exclusive operations
              d_coppath,d_mulpath,d_mempath,
              x_mempath,m_mempath          : out  Std_logic;
              
          -- EXCEPTION LOGIC CONTROL SIGNALS
              -- Ports carrying exception occurances to exc_handling logic.
              exc_illegal_opcode1,exc_illegal_opcode2  : out  Std_logic;

              -- Pipeline synchronization signals
              en_f,en_fd,en_dx,en_xm,en_mw : out  Std_logic;
              -- Icache interface control signal
              I_busy,D_busy                : out  Std_logic;
              
              -- COPROCESSOR CONTROL SIGNALS
              cop_command                  : out Cop_control );  
end component;

component Double_channel
   generic ( 
          -- ARCHITECTURE DEFINITION 
           -- System Control Coprocessor is the coprocessor handling interrupts
           -- and exceptions
           include_scc : integer:= 1;           
           -- Floating point Unit
           include_fpu     : integer := 1;
           -- On-chip Unit interfacing XiRisc with an external GDB suite
           include_dbg     : integer := 0;           
           -- Hardware shift logic
           include_shift   : integer := 1;           
           -- Rotate logic
           include_rotate  : integer := 1;
           -- Hardware iterations: allows for the utilization of Branch Decrement
           -- instructions
           include_hrdwit  : integer := 1;
           -- Multiply-Accumulation logic
           include_mul     : integer := 1;
           include_mult    : integer := 1;
           include_mad     : integer := 1;
           -- Hardware check on Imem access
           include_iaddr_check : integer :=1;
           -- Hardware check on Imem access
           include_daddr_check : integer :=1;
           -- Depth of the on-chip shifter: Max shift is 2**shift_count_width
           shift_count_width   : integer := 5;
           -- BUS WIDTH DEFINITION
           -- Processor Data Width
           Word_Width      : positive := 32;
            -- Processor Instruction Width
           Instr_Width     : positive := 32;
           -- Processor Data addressing space Width (XiRisc has Harvard memory
           -- organization
           Daddr_width     : positive := 32;
           -- Processor Instruction addressing space Width (XiRisc has Harvard
           -- memory organization
           Iaddr_width     : positive := 24 );
           
     port(  clk                             : in    Std_logic;            
            reset                           : in    Std_logic;
            freeze                          : in    Std_logic;
            -- DATAPATH CONTROL SIGNALS, produced by control_logic
            -- Pipeline control
            en_dx,en_xm,en_mw               : in   Std_logic;
            d_we,x_we,m_we                  : in   Std_logic;         
            -- Values Read from Register File 
            rs1_data,rs2_data,rs3_data,rs4_data : in Std_logic_vector(word_width-1 downto 0);
            -- Alu Execution control
            alu_command1,alu_command2       : in   alu_control;
            alu_immed1,alu_immed2           : in   Std_logic_vector(word_width-1 downto 0);
            shift_op1,shift_op2             : in   Risc_shiftcode;
            exe_outsel1,exe_outsel2         : in   Risc_exeout;              
            -- Multiplication logic control
            mul_command                     : in   Risc_mulop;
            -- Memory access control
            smdr_enable                     : in   Std_logic;
            m_mem_command                   : in   Mem_control;            
            jar_in                          : in   Std_logic_vector(iaddr_width-1 downto 0);
            -- COPROCESSOR OUTPUT (For selecting it as a possible Wback value)
            cop_output                      : in   Std_logic_vector(word_width-1 downto 0);
            -- Specification of the chosen channel for exclusive operations
            d_mulpath,d_mempath,
            x_mempath,m_mempath             : in   Std_logic;    
         
            -- RESULTS PRODUCED BY DATAPATH ELABORATION
            Byp1_x_op,Byp1_x_branch,
            Byp1_m_op,Byp1_m_branch         : out  Std_logic_vector(word_width-1 downto 0);
            Byp2_x_op,Byp2_x_branch,
            Byp2_m_op,Byp2_m_branch         : out  Std_logic_vector(word_width-1 downto 0);

            alu_oflow1,alu_oflow2           : out   Std_logic;          
            mad_oflow                       : out   Std_logic;
            
             -- System Bus
            ADDRESS_BUS                     : out   Std_logic_vector(daddr_width-1 downto 0);
            DATA_IN                         : in    Std_logic_vector(word_width-1 downto 0);
            DATA_OUT                        : out   Std_logic_vector(word_width-1 downto 0)  );
end component;

end double_definitions;

package body double_definitions is
end double_definitions;  
