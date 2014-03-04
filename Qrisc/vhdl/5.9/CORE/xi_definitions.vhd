---------------------------------------------------------------------------
--                        XI_DEFINITIONS.VHD                 --
---------------------------------------------------------------------------
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it          --
-- DEIS, Department of Electronics Informatics and Systems,  --
-- University of Bologna, BOLOGNA , ITALY                    -- 
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

-- Component descriptions for all the structural blocks reused in the design
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.basic.all;

package definitions is

  -----------------------------------------------------------------------------
  -- BLOCKS INCLUDED IN THE PROCESSOR DATA-PATH
  -- (Function units and computational blocks)
  -----------------------------------------------------------------------------
  
   component Main_Alu
     generic( Word_Width      : positive := 32 );
     port(  in_a         : in  Std_logic_vector(Word_Width-1 downto 0);
            in_b         : in  Std_logic_vector(Word_Width-1 downto 0);
            op           : in  Risc_Alucode;
            result       : out Std_logic_vector(word_width-1 downto 0);
            overflow     : out Std_logic ); 
   end component;

   component Shifter
     generic ( Word_Width          : positive := 32;
               shift_count_width   : positive := 5;
               include_rotate      : integer := 1 );     
     port( a        : in  Std_logic_vector(word_width-1 downto 0);
           op       : in  Risc_shiftcode;
           shamt    : in  Std_logic_vector(shift_count_width-1 downto 0);
           sh       : out Std_logic_vector(word_width-1 downto 0)  );
   end component;

  component mult_block
   generic(  Word_Width      : positive := 32;
            include_mul     : integer  := 1;
            include_mult    : integer  := 1;
            include_mad     : integer  := 1 );
  
   port ( clk,reset                : in    Std_logic;
          en_dx,en_xm,en_mw,m_we   : in    Std_logic;
          d_mul_command            : in    Risc_mulop;
          operand1                 : in    Std_logic_vector(word_width-1 downto 0);
          operand2                 : in    Std_logic_vector(word_width-1 downto 0);

          Multout    : out   Std_logic_vector(word_width-1 downto 0);
          mad_oflow  : out Std_logic );
  end component;

  component mem_handle
  generic ( Word_Width      : positive := 32 );
  port ( clk,reset     : in  Std_logic;
         smdr_enable   : in  Std_logic;
	 mem_baddr : in std_logic_vector(1 downto 0);
         -- The data to be stored => datapath in_regB signal
         stored_data   : in  std_logic_vector(word_width-1 downto 0);
         -- The data read from memory
         read_data     : out std_logic_vector(word_width-1 downto 0);
         -- Memory access control signals
         x_mem_command,m_mem_command   : in  mem_control;
         -- ddata_in bus
         DATA_IN       : in  std_logic_vector(word_width-1 downto 0);
         -- ddata_out bus 
         DATA_OUT      : out std_logic_vector(word_width-1 downto 0)  );
  end component;

   ----------------------------------------------------------------------------
   -- BLOCKS INCLUDED IN THE CONTROL LOGIC
   -- (Instruction decode and pipeline handle)
   ----------------------------------------------------------------------------

  component Decode_op32
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
  end component;
   
  component Decode_PC
    generic( include_scc : integer:= 1;
             Word_Width      : positive := 32;
             Instr_Width     : positive := 32;
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
  end component;

  component Addrchk
    generic ( w  : integer := 32;
              ckmn : integer := 1;        -- enable check on the lower limit
              ckmx : integer := 1;        -- enable check on the upper limit
              mxl : integer := 16#ffff#;  -- lower 16 bits of the upper limit of the space address
              mxh : integer := 16#0000#;  -- upper 16 bits of the upper limit of the space address
              mnl : integer := 16#0010#;  -- lower 16 bits of the lower limit of the space address
              mnh : integer := 16#0000# ); -- upper 16 bits of the lower limit of the space address
    port ( ADDRESS : in std_logic_vector(w-1 downto 0);           
           invalid_addr : out std_logic;
           misalign     : out std_logic;
           prot_warn    : out std_logic;
           enable : in std_logic;
           isbyte : in std_logic;
           ishalf : in std_logic );
  end component; 

  component PCbvgen
    generic( Iaddr_width     : positive := 24 );
    port(   clk,reset          : in  Std_logic;
            en_fd,en_dx        : in  Std_logic;
            jump_type          : in  Risc_jop;
	    curr_pc            : in  Std_logic_vector(iaddr_width-1 downto 0);

            PC_basevalue       : out Std_logic_vector(iaddr_width-1 downto 0);
            d_bds              : out Std_logic );
  end component;

 
  component Bypass_Logic 
    generic( rf_registers_addr_width : positive := 5);
    port( source_reg             : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          main_erd,main_mrd      : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
          x_we ,m_we             : in  Std_logic;
          byp_control            : out Risc_bypcontrol    );
  end component;        

  component Stall_Logic 
    port( byp_controlA,byp_controlB    : in  Risc_bypcontrol;          
          jump_type                    : in  Risc_jop;
          x_mul_command                : in  Risc_mulop;
	  x_mem_isread,m_mem_isread    : in  Std_logic;
          serve_exception              : in  Std_logic;
          stall_decode                 : out Std_logic	);        
  end component;
   
  -----------------------------------------------------------------------------
  --                    MAIN PROCESSOR DATAPATH                             --
  -----------------------------------------------------------------------------
   
  component Main_channel
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
     
    port(   clk                             : in    Std_logic;            
            reset                           : in    Std_logic;
            freeze                          : in    Std_logic;
           -- DATAPATH CONTROL SIGNALS, produced by control_logic
            -- Pipeline control
            en_dx,en_xm,en_mw               : in   Std_logic;
            d_we,x_we,m_we                  : in   Std_logic;
            -- Values Read from Register File 
            rs1_data,rs2_data               : in   Std_logic_vector(Word_width-1 downto 0);              
            -- Alu Execution control
            alu_command                     : in   alu_control;
             alu_immed                       : in   Std_logic_vector(word_width-1 downto 0);
            shift_op                        : in   Risc_shiftcode;
            exe_outsel                      : in   Risc_exeout;            
	    -- Multiplication logic control
            mul_command                     : in   Risc_mulop;                          
            -- Memory access control
            smdr_enable                     : in   Std_logic;
            x_mem_command,m_mem_command     : in   Mem_control;             
            jar_in                          : in   Std_logic_vector(iaddr_width-1 downto 0);
           -- COPROCESSOR OUTPUT (For Writeback over the RegFile)
            cop_output                      : in   Std_logic_vector(word_width-1 downto 0);              
           -- RESULTS PRODUCED BY DATAPATH ELABORATION
            Bypa_x_op,Bypa_x_branch,
            Bypa_m_op,Bypa_m_branch         : out  Std_logic_vector(word_width-1 downto 0);
            
            alu_oflow,mad_oflow             : out   Std_logic;            
           -- System Bus
            ADDRESS_BUS                     : out   Std_logic_vector(daddr_width-1 downto 0);
            DATA_IN                         : in    Std_logic_vector(word_width-1 downto 0);
            DATA_OUT                        : out   Std_logic_vector(word_width-1 downto 0)
            );   
  end component;

   ----------------------------------------------------------------------------
   --                   PROCESSOR CONTROL LOGIC                              --
   ----------------------------------------------------------------------------
   
  component Main_control
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
              reset_value_lower   : integer := 16#100# );
              
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
              branch_rega,branch_regb    : in    Std_logic_vector(Word_width-1 downto 0);
               
           -- INTERRUPT SERVICE CONTROL SIGNALS
              -- The value produced from data memory access, that is a
              -- pointer to the appropriate Exception servicing procedure,
              -- is forced on the next_pc register in case an exception has
              -- been acknowledged.
              serve_exception             : in   Std_logic;
              incoming_servproc_addr      : in   Std_logic_vector(Iaddr_width-1 downto 0);
 
           -- DATAPATH CONTROL SIGNALS
              -- Register file Control 
              rs1,rs2,rcop,rd              : out  Std_logic_vector(rf_registers_addr_width-1 downto 0);
              -- Bypass Control
              byp_controlA,byp_controlB   : out  Risc_bypcontrol;
              -- AluExecution control
              alu_command                 : out  alu_control;
              alu_immed                   : out  Std_logic_vector(Word_width-1 downto 0);
              shift_op                    : out  Risc_shiftcode;
              exe_outsel                  : out  Risc_exeout;
              
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
              d_bds                       : out  Std_logic;
              PC_basevalue,pc_plus_4      : out  Std_logic_vector(Iaddr_width-1 downto 0);
              epc                         : in   Std_logic_vector(Iaddr_width-1 downto 0);
              
          -- EXCEPTION LOGIC CONTROL SIGNALS
              -- Ports carrying exception occurances to exc_handling logic.
              exc_illegal_opcode         : out  Std_logic;

              -- Pipeline synchronization signals
              en_f,en_fd,en_dx,en_xm,en_mw    : out  Std_logic;
              -- Icache interface control signal
              I_busy,D_busy              : out  Std_logic;
              
              -- COPROCESSOR CONTROL SIGNALS
              cop_stall                  : in  Std_logic;
              cop_command                : out Cop_control ); 
  end component;

  component Rfile
    generic( Word_Width              : positive := 32;
             rf_registers_addr_width : positive := 5 );
    port(  clk    : in  Std_logic;
           reset  : in  Std_logic;
           enable : in  Std_logic;
           ra     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
           a_out  : out Std_logic_vector(Word_width-1 downto 0);
           rb     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
           b_out  : out Std_logic_vector(Word_width-1 downto 0);
                 
           rd1    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
           d1_in  : in  Std_logic_vector(Word_width-1 downto 0) ); 
  end component;

  component xi_verify
   generic( Word_Width              : positive := 32;
            Iaddr_width             : positive := 24;
            rf_registers_addr_width : positive := 5;
            include_wbtrace     : integer :=1;
            include_selfprofile : integer :=1;
            include_putchar     : integer :=1 );
  
  port( clk,reset,enable_dx,enable_mw,d_we : in Std_logic;
        argument        : in Std_logic_vector(Word_width-1 downto 0);            
        rd1             : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
        d1_in           : in  Std_logic_vector(Word_width-1 downto 0);
        break_code      : in  Std_logic_vector(Word_width-1 downto 0);        
        Cop_command_in  : in  Cop_control;               
        Cop_command_out : out Cop_control
        );
  end component;
   
end definitions;

package body definitions is
end definitions;
