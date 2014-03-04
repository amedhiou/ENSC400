---------------------------------------------------------------------------
--                       XI_CONTROL.VHD                                  --
--                                                                       --
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
-- 
-- This logic block contains the Elaboration Control logic for the single
-- datapath version of the XiRisc processor model.
-- This control logic is composed of the two main decode logic blocks
-- (instruction decode and next pc decode) and controls and synchronizes
-- the Main Datapath (see xi_mainchannel.vhd).


---------------------------------------------------------------------------
--                ENTITY DEFINITION                                         
---------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;
  use work.components.all;
  use work.definitions.all;  
   
entity Main_control is
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
end Main_control;


----------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
----------------------------------------------------------------------------

architecture structural of Main_control is

  --synopsys synthesis_off 
  type spy_control is (pipe_run,pipe_stalldecode,pipe_imiss,pipe_dmiss,pipe_freeze);
  signal spy : spy_control;
 --synopsys synthesis_on 
  
--    Formal conventions for signal declaration:
-- f_xxx :-> Segnals belonging to Fetch stage 
-- d_xxx :->   "         "     "  Decode stage
-- x_xxx :->   "         "     "  Execute stage
-- m_xxx :->   "         "     "  Writeback stage
-- 
-- p_xxx :-> Overall pipeline control signals

  constant r0               : Std_logic_vector(rf_registers_addr_width-1 downto 0) := (others=>'0');
  signal ck_reset,int_reset : std_logic;
  
-- Signals describing the path of the fetched instruction word
-- until the stage where it is decoded into control signals    
  signal f_currpc,d_currpc,d_nextpc       : Std_logic_vector(Iaddr_width-1 downto 0);
  signal f_instr,d_sampled_finstr,d_instr : Std_logic_vector(Instr_width-1 downto 0);

  
-- Signals generated by operation decoding
  signal d_cop_command               : Cop_control;
  signal d_jump_type                 : Risc_jop;
  signal d_rs1,d_rs2,d_rcop           : Std_logic_vector(rf_registers_addr_width-1 downto 0);
    
  -- Signals propagating the destination register address
  -- to the Writeback stage
  signal d_rd,x_rd,m_sampled_xrd,m_rd : Risc_regaddr;
    
  -- Alu and Immediate operand generator control signals
  signal d_alu_command,x_alu_command,m_alu_command : alu_control;
  signal d_alu_immed,x_alu_immed,m_alu_immed       : Std_logic_vector(word_width-1 downto 0);
  signal d_shift_op,x_shift_op                     : Risc_shiftcode;
  signal d_exe_outsel,x_exe_outsel                 : Risc_exeout;
    
  -- Multiplication & Accumulation logic control signals    
  signal d_mul_command,x_mul_command  : Risc_mulop;
         
  -- Data memory control signals
  signal d_mem_command,x_sampled_dmem_command,x_mem_command,m_mem_command  : Mem_control;
       
  -- Bypass_multiplexers_handling Signals, sent to the datapaths to activate
  -- the bypass channels
  signal p_bypcontrolA,p_bypcontrolB       : Risc_bypcontrol;
    
  -- Write_Enable Signals:
  -- If during its flow through the pipeline an instruction or a couple of
  -- them in double processing mode causes stalls, or raises an
  -- exception, its (their) completion must be "deactivated" 
  -- before it (they) might perform any no-return unconsistent operation.
  -- The write_enable flag, associated to each instruction (couple),
  -- set to '0',
  -- prevents any memory write or regfile writeback operation.
  signal f_we,d_sampled_fwe,d_we,x_sampled_dwe,x_we,m_we  : Std_logic;

  -- Write enable story:
  -- The write enable signals represent the fundamental evolution of the
  -- pipeline and its fundamental mean for handling hazards and stall configuration.
  -- Each time for some reason a stall have to be issued in the pipeline (the
  -- pipeline flow must suffer a discontinuity) we has to be turned off in
  -- order to avoid unwanted or parasitic effects on no-return operations such
  -- as JUMPS(d), BYPASSES(x,m), MEMORY WRITES(x), WCOPS(x), MULT/MAD writes(m)
  -- WRITEBACKS(m).
  -- This is the evolution of the we signal all through the pipeline:
  -- FETCH: When an instruction is fetched a f_we is associated to it.
  --        a) in case X or M present an exception f_we is deactivated because the
  --           instruction will have to be flushed away.
  --        b) In case of ifetch stall (I_NREADY='0') the F stage is stalled 
  --           while the rest may proceed.
  -- DECODE: The signal f_we is sampled into d_sampled_fwe, that is used to
  --         erase possible Jumps in case they are deactivated.        
  --        a) In case X present and exception d_we is deactivated  because the
  --           instruction will have to be flushed away. (If M presents an
  --           exception it would have deactivated the instr at the previous cycle).
  --        b) In case a pipeline stall is issued (stall_decode) a bubble will
  --           have to be inserted in the pipeline
  -- EXECUTE: The signal d_we is sampled into x_sampled_dwe.
  --          x_we turns off Memory Writes and Wcops. 
  --        a) In case of exception x_we is obviously deactivated as it was the
  --           interrupting instruction.Bypasses are tolerated, as
  --           anyway they would bypass data to instruction already deactivated.
  --           This way, a long path is avoided going from the alu through
  --           overflow to the bypass channel all the way to instruction decode.
  -- MEMORY: The signal x_we is sampled on m_we, that is used to redirect
  --         unwanted writebacks on r0. Additional r0 causes may be the very
  --         subtle case of a branch-decrement instruction whose BDS generates
  --         an exception. In this case the branchdec would be repeated so its
  --         current writeback must be disabled. 
  --        
    
-- Pipeline Control Signals: This signals will Enable/Disable the flow
  -- of the instruction through the five pipeline stages.
  signal enable_f,enable_fd,enable_dx,enable_xm,enable_mw   : Std_logic;
    
-- Exceptions handling signals
  signal x_serve_exception,m_serve_exception       : Std_logic;
    
-- Stall handling signals
  signal stall_decode,pipeline_stall               : Std_logic; 
    
  -- Dummy signals to ease the model readability!!    
  signal Hi,Lo           : Std_logic;
  
begin

  --synopsys synthesis_off
  PIPESPY: process(I_NREADY,D_NREADY,stall_decode,freeze)
  begin
    if (freeze='0') then
       spy <= pipe_freeze;
    elsif (D_NREADY='0') then
       spy <= pipe_dmiss;
    elsif (I_NREADY='0') then
       spy <= pipe_imiss;
    elsif (stall_decode='0') then
       spy <= pipe_stalldecode;
    else
       spy <= pipe_run;
    end if;
  end process;
  --synopsys synthesis_on

  
    -- Constant to be defined as signal to be transmitted on subcircuits input
    -- ports
    Hi   <= '1';Lo <= '0';
    
    int_reset <= reset and reboot;

    ---------------------------------------------------------------------------
    -- PIPELINE CONTROL
    -- Pipeline Control Signals: This signals will Enable/Disable the flow
  -- of the instruction through the five pipeline stages.
  -- Possible causes of discontinuities in the pipeline flow are:
   -- a) External Freeze (All Computation Frozen, i.e. for debugging purposes)
         -- All stages are frozen synchronously
   -- b) Miss on Instruction memory (Waitstates insertion to allow instruction Fetch)
         -- Fetch, decode are frozen
   -- c) Miss on Data memory (Waitstates insertion to allow data access)
         -- All stages are frozen as writeback can not be performed
   -- d) Stalls in the pipeline flow
         -- Fetch, decode are frozen
    enable_f      <= (not ( stall_decode and freeze and I_NREADY and D_NREADY ));
    enable_fd     <= (not ( stall_decode and freeze and I_NREADY and D_NREADY ));    
    enable_dx     <= not  ( freeze and D_NREADY );
    enable_xm     <= not  ( freeze and D_NREADY );
    enable_mw     <= not  ( freeze and D_NREADY );

    I_busy        <= ( stall_decode and freeze and D_NREADY );
    D_busy        <= ( freeze );
    
    ----------------------------------------------------------
    -- FETCH STAGE
    ----------------------------------------------------------       
        

    -- INSTRUCTION FETCH: ---------------------------------------------------
    -- Note: f_currpc is in fact the bypassed d_nexpc value determined from the
    -- nexpc logic in the decode stage
    imem_address <= d_nextpc;    
  
  ---------------------------------------------------------------------------


    -- EXCEPTION HANDLING: ----------------------------------------------------
    --
    PC_BVGEN: if include_scc=1 generate
      
      -- 1) PC BASEVALUE GENERATION 
      -- PC_basevalue is the consistent value of the program counter, the PC in
      -- all cases but Branch Delay slots, when it becomes the jumping instruction value.
      -- This value is used only in case of RFE instructions, that is when handling
      -- interrupts so this logic is only included when exceptions are handled
        
      bvgen : PCbvgen generic map ( iaddr_width )
                      port map ( clk,reset,enable_fd,enable_dx,
                                 d_jump_type,f_currpc,PC_basevalue,d_bds );
      
      -- 2) INSTRUCTION DISABLE   
      -- If an exception is acknowledged the following fetches (prior to
      -- exception servicing) will be write-disabled, so that the fetched
      -- instruction will flush harmlessy through the pipeline.  They will be
      -- resumed later.
      -- Also if this is the first instruction after a reset it must be turned
      -- off
      process( x_serve_exception,m_serve_exception,I_NREADY )
      begin
        if (x_serve_exception='0') or (m_serve_exception='0') or
           (I_NREADY='0') then
          f_we    <= '1';
        else
          f_we    <= '0';
        end if;
      end process;

    end generate PC_BVGEN;
    
    NO_PC_BVGEN:if include_scc=0 generate
      pc_basevalue <= ( others => '0');
      f_we <= '0';      
    end generate NO_PC_BVGEN;  


    -- The PC value may be reset to the RESET or REBOOT value
    -- Note the External imem and the Proogram counter actually belong to a
    -- different stage with respect to the fd register that follows.
    -- But the control signal that enable their activity in in fact the same,
    -- so it is possible to use the same control signal for both.
    Program_counter: Ireg_Fetch
      generic map ( iaddr_width,
                    reset_value_lower-(instr_width/8),reset_value_upper,
                    reboot_value_lower-(instr_width/8),reboot_value_upper)
      port map ( clk,reset,reboot,enable_f,
                 d_nextpc,f_currpc );

    -- As Part of the pipeline structure, the instruction read from the Imem is
    -- in the DECODE stage
    f_instr <= imem_out;       
    
  --------------------------------------------------------------------------
  -- FETCH to DECODE REGISTER:                                            --
  --------------------------------------------------------------------------        

    ir_fd : Data_Reg
      generic map( 0,Instr_width )
      port map ( clk,int_reset,enable_fd,f_instr,d_sampled_finstr );
    
    irfd : FlipFlop
      port map ( clk,int_reset,enable_fd,f_we,d_sampled_fwe );
    
  -------------------------------------------------------------------------
  -- DECODE STAGE
  -------------------------------------------------------------------------    

   -- if the current instruction is not valid because an interrupt was issued
   -- in the previous clock (d_we = '1') then current instruction is nop-ized to avoid
   -- undesired jumps
   INSTRUCTION_VALID_MUX: process(d_sampled_fwe,d_sampled_finstr,d_instr)
   begin
     if d_sampled_fwe='0' then
        d_instr <= d_sampled_finstr;
     else
        d_instr <= ( others=>'0');
     end if;
   end process;
    
 -- CONTROL SIGNALS GENERATION ------------------------------------------------
   -- Generation of Datapath resources control signals:

    Operation_decoding32:      
      Decode_op32 generic map ( word_width,rf_registers_addr_width )
                  port map ( d_instr,
                             d_rs1,d_rs2,d_rcop,d_rd,
                             d_jump_type,d_alu_command,d_alu_immed,
                             d_shift_op,d_cop_command,
                             d_mul_command,
                             d_exe_outsel,d_mem_command,
                             exc_illegal_opcode ); 
  
  -- Program flow control logic: Jumps & Branches handling --------------------
       
   Nextpc_decoding: 
     Decode_PC generic map ( include_scc,Word_Width,Instr_width,Iaddr_width )
               port map ( m_serve_exception,d_jump_type,f_currpc,
                          branch_rega,branch_regb, 
                          d_alu_immed,incoming_servproc_addr,epc,
                          d_nextpc,pc_plus_4 );
       
   -- PIPELINE HAZARDS HANDLE -------------------------------------------------
  
   bp_logicA: Bypass_Logic port map ( d_rs1,
                                      x_rd,m_sampled_xrd,x_sampled_dwe,m_we,
                                      p_bypcontrolA );
   
   bp_logicB: Bypass_Logic port map ( d_rs2,
                                      x_rd,m_sampled_xrd,x_sampled_dwe,m_we,
                                      p_bypcontrolB );

   st_logic: Stall_logic  port map ( p_bypcontrolA,p_bypcontrolB,
                                     d_jump_type,x_mul_command,
                                     x_mem_command.mr,m_mem_command.mr,
                                     x_serve_exception,
                                     pipeline_stall );

  stall_decode <= '0' when (pipeline_stall='0' or cop_stall='0') else '1';
    
 -- OUTPUT PORTS FEED:
    -- Generation of Register_file inputs.
    -- These signals selects the alu operands between the 32 Risc general 
    -- purpose registers. Rb can be substituted by an immediate
    -- operand, in case of Register/Immediate operations.
      rs1 <= d_rs1;
      rs2 <= d_rs2;
      rcop <= d_rcop;
    
      alu_immed  <= d_alu_immed;
      alu_command.hrdwit <= d_alu_command.hrdwit;
      alu_command.isel   <= d_alu_command.isel;
    
      dmul_command       <= d_mul_command;
      d_writeenable      <= d_we;
      x_writeenable      <= x_we;
      m_writeenable      <= m_we;
    
      byp_controlA <= p_bypcontrolA;
      byp_controlB <= p_bypcontrolB;
    
    -- Coprocessor Control Command, comprising Cop_op, Cop_index 
      cop_command   <= d_cop_command;


    -- INSTRUCTION DISABLE (BUBBLE ISSUING)
    -- The instruction currently in the decode stage will be disabled if
    -- (a) The decoded stage is going to be stalled, so the current 
    --     instruction will stay, and a dummy will be passed on to execute stage.
    -- (b) The decoded instruction witness a ICACHE Miss. In this case the first two
    --     stages of the pipeline are stalled. This instruction must then be deactivated 
    --     because it will be run again at the end of the miss cycle.

    -- (c) An exception was raised in the execute stage, so the pipeline must
    --     be flushed
    -- (d) The operation was disabled in the previous stage

    process(I_NREADY,d_sampled_fwe,x_serve_exception,stall_decode)
    begin
      if (I_NREADY='0') or (d_sampled_fwe = '1') or 
         (x_serve_exception = '0') or (stall_decode = '0') then         

           d_we <= '1';
      else
           d_we <= '0';
      end if;
    end process;

   --------------------------------------------------------------------------
   -- DECODE to EXECUTE REGISTER:                                          --
   --------------------------------------------------------------------------       
    
    ir_dx: Ireg_Execute
            generic map ( Word_Width,rf_registers_addr_width )
            port map ( clk,int_reset,enable_dx,
                    
                       d_alu_command,d_alu_immed,
                       d_shift_op,d_exe_outsel,
                       d_mul_command,
                       d_mem_command,d_rd,d_we,

                       x_alu_command,x_alu_immed,
                       x_shift_op,
                       x_exe_outsel,x_mul_command,
                       x_sampled_dmem_command,x_rd,x_sampled_dwe );

    
   ---------------------------------------------------------------------
   --       EXECUTE  STAGE                                            --
   ---------------------------------------------------------------------         
    

   ------------------------------------------------------------------------------    
   -- OUTPUT PORTS FEED
    -- Transmission of the Alu control signals to datapath logic block
    -- Note: of the 3 fields of alu_command, only immediate is transmitted from
    -- the decode stage, the other two refer to the execution stage    
    
    alu_command.op     <= x_alu_command.op;

    shift_op           <= x_shift_op;
    exe_outsel         <= x_exe_outsel;
       
    -- MEMORY ACCESS ADDRESS GENERATION: 
    -- In case the current instruction is a memory access, the target
    -- address must be transmitted to the outgoing address bus sampling
    -- the alu_output.   
    -- The SMDR latches hold the word to be stored in case of STORE
    -- operations, Sampled from the in_regB signal, that is the second
    -- register file output.   
    smdr_enable <= d_mem_command.mw or enable_dx;
    
    x_serve_exception <= serve_exception;
    
    -- Memory access control:    
    --  If the current instruction is for some reasons write-disabled the
    --  scheduled memory access is cancelled.
    --  Note that the x_we value is not used in this case because it comes from
    --  the memory address verification logic and this would cause a
    --  combinatorial loop !!
    process(x_sampled_dwe,x_sampled_dmem_command )
    begin
       if x_sampled_dwe = '0' then
             -- Regular instruction, if a memory access is scheduled then it is
             -- performed normally
             x_mem_command <= x_sampled_dmem_command;
       else
             -- The current instruction is write-disabled (bubble) so any
             -- scheduled memory access must be cancelled
             x_mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
       end if;     
    end process;
    
    -- INSTRUCTION DISABLE
    -- The instruction currently in the execution stage will be disabled if
    -- (a) An exception was raised by (or over) this very instruction execute stage,
    --     so the pipeline must be flushed
    -- (b) The operation was disabled in the previous stage    
    x_we   <= x_sampled_dwe or (not x_serve_exception);
    
   --------------------------------------------------------------------------
   -- EXECUTE to MEMORY REGISTER:                                       --
   --------------------------------------------------------------------------         

    ir_xm : Ireg_Memory generic map ( Word_Width,rf_registers_addr_width )
                        port map ( clk,int_reset,enable_xm,
                                   x_alu_command,x_alu_immed,
                                   x_mem_command,x_rd,x_we,
                                   x_serve_exception,
                                   m_alu_command,m_alu_immed,
                                   m_mem_command,m_sampled_xrd,m_we,
                                   m_serve_exception );
    
  -------------------------------------------------------------------------
  --        MEMORY ACCESS STAGE                                          
  -------------------------------------------------------------------------
    
  -- At the beginning of the writeback stage all possible exception cause have
  -- been verified, and the interrupt vector has been sampled.
  -- During this stage two alternative patterns of execution are
  -- possible:
  --
  -- (A) If in the last exception stage an Exception or Interrupt has
  --     been acknowledged, the alu-generated data memory address was overwritten
  --     by the interrupt Table pointer produced using the appropriate Exception
  --     code (see file basic.vhd for Risc exception codes).
  --     Processor mode is switched to kernel, cause register is updated,
  --     and the current program counter is saved on EPC register.
  --     Consequently the data memory, that was addressed by the interrupt
  --     table pointer, will generate the specified
  --     exception procedure address, that is bypassed to the fetch stage and redirected over the
  --     PC register. Of course, in the current stage Rd is set to r0 to disable unwanted
  --     writebacks. 
  --
  -- (B) If No exceptions or interrupts have been detected, the instruction is
  --     committed, that is the normal memory access cycle scheduled by the
  --     instruction decoding logic has been performed and the result is now normally
  --     carried to the regfile ports
  --     

    
    -- MEMORY CONTROL SIGNALS -----------------------------------------
    xmem_command <= x_mem_command;
    mmem_command <= m_mem_command;

    ------------------------------------------------------------------
    
    -- INSTRUCTION DISABLE
    -- The instruction currently in the writeback stage will be disabled if
    -- (a) An exception was raised by the following instruction,
    --     residing in the execution stage, that is the Branch Delay Slot of a
    --     hardware iteration (that is the only writebacking instruction that
    --     may generate a BDS)
    -- (b) The operation was disabled in a previous stages    

    -- The fact is, we don't want the hrdwit instruction to perform unwanted writebacks
    -- when an exception is issued.
    -- Nevertheless, a huge false path builds up because an exception will
    -- influence the bypass logic that influences the nexpc calculation.
    -- To avoid this the following choice is made:
    -- a) On the register file this occurrance is handled, and in case we are
    --    running a hrdwit instruction in M and an exception raises in X the
    --    writeback is cancelled
    -- b) The bypass is not disabled. It would build a stupidly high critical path.
    --    But in fact this is not necessary, as the bypass will be performed to
    --    the instruction in the decode stage, that being AFTER the interrupted
    --    one, would anyway be flushed through the pipeline to be resumed at
    --    the end of the interrupting procedure.        
    
    process(m_we,m_sampled_xrd,x_serve_exception,m_alu_command)
    begin
       if ( include_hrdwit=1 and x_serve_exception='0' and m_alu_command.hrdwit='0' ) then
            m_rd <= r0;
        elsif (m_we='1') then 
            m_rd <= r0;
        else
            m_rd <= m_sampled_xrd;
       end if;

    end process;
    
   
  -- OUTPUT PORT FEED
    rd         <= m_rd;
    
    -- Pipeline Synchronization signals
    en_f   <= enable_f;
    en_fd  <= enable_fd;
    en_dx  <= enable_dx;
    en_xm  <= enable_xm;
    en_mw  <= enable_mw;

    -- END of PIPELINE DESCRIPTION
    
end STRUCTURAL;


