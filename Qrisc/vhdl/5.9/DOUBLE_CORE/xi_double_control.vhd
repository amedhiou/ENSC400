---------------------------------------------------------------------------
--                       XI_DOUBLE_CONTROL.VHD                           --
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
  use work.isa_32.all;
  use work.components.all;
  use work.double_components.all;
  use work.definitions.all;
  use work.double_definitions.all; 
   
entity Double_control is
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
end Double_control;


----------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
----------------------------------------------------------------------------

architecture structural of Double_control is

  --synopsys synthesis_off 
  type spy_control is (pipe_run,pipe_stalldecode,pipe_imiss,pipe_dmiss,pipe_freeze);
  signal spy : spy_control;
  --synopsys synthesis_on
 
--    Formal conventions for signal declaration:
-- f_xxx :-> Segnals belonging to Fetch stage 
-- d_xxx :->   "         "     "  Decode stage
-- e_xxx :->   "         "     "  Execute stage
-- m_xxx :->   "         "     "  Memory access stage
-- w_xxx :->   "         "     "  Writeback stage 
-- p_xxx :-> Overall pipeline control signals


  constant r0       : Std_logic_vector(rf_registers_addr_width-1 downto 0) := (others=>'0');  
  signal int_reset : std_logic;


-- Signals describing the path of the fetched instruction word
-- until the stage where it is decoded into control signals    
  signal f_currpc,d_currpc,d_nextpc       : Std_logic_vector(Iaddr_width-1 downto 0);
  signal f_instr,d_sampled_finstr,d_instr : Std_logic_vector(Instr_width-1 downto 0);
    
-- Signals generated by operation decoding
  signal d_cop_command,d_cop_command1,d_cop_command2  : Cop_control;
  signal d_jump_type,d_jump_type1,d_jump_type2        : Risc_jop;
  signal d_rs1_1,d_rs2_1,d_rcop1     : Std_logic_vector(rf_registers_addr_width-1 downto 0);
  signal d_rs1_2,d_rs2_2,d_rcop2     : Std_logic_vector(rf_registers_addr_width-1 downto 0);  
  signal d_rcop                      : Std_logic_vector(rf_registers_addr_width-1 downto 0);

   -- Signals propagating the destination register address
  -- to the Writeback stage
  signal d_rd1,x_rd1,m_sampled_xrd1,m_rd1 : Risc_regaddr;
  signal d_rd2,x_rd2,m_sampled_xrd2,m_rd2 : Risc_regaddr;

  -- Alu and Immediate operand generator control signals
  signal d_alu_command1,x_alu_command1,m_alu_command1 : alu_control;
  signal d_alu_command2,x_alu_command2,m_alu_command2 : alu_control;
  
  signal d_alu_immed1,x_alu_immed1,m_alu_immed1    : Std_logic_vector(word_width-1 downto 0);
  signal d_alu_immed2,x_alu_immed2,m_alu_immed2    : Std_logic_vector(word_width-1 downto 0);

  signal d_jump_immed,d_jump_rega,d_jump_regb  : Std_logic_vector(word_width-1 downto 0);        

  signal d_shift_op1,x_shift_op1                   : Risc_shiftcode;
  signal d_shift_op2,x_shift_op2                   : Risc_shiftcode;
    
  signal d_exe_outsel1,x_exe_outsel1               : Risc_exeout;
  signal d_exe_outsel2,x_exe_outsel2               : Risc_exeout;

  -- Multiplication & Accumulation logic control signals    
  signal d_mul_command,x_mul_command    : Risc_mulop;
  signal d_mul_command1,x_mul_command1  : Risc_mulop;
  signal d_mul_command2,x_mul_command2  : Risc_mulop;  

    -- Data memory control signals
  signal d_mem_command,d_mem_command1,d_mem_command2         : Mem_control;
  signal x_sampled_dmem_command,x_mem_command,m_mem_command  : Mem_control;

   -- Bypass_multiplexers_handling Signals, sent to the datapaths to activate
  -- the bypass channels
  signal p_bypcontrolA,p_bypcontrolB,
         p_bypcontrolC,p_bypcontrolD  : Risc_bypcontrol; 

  -- Path selection signals used to describe the selected path for shared resources
    signal d_jump_path                             : Std_logic;
    signal d_mul_path,d_mem_path,d_cop_path        : std_logic;
    signal x_mul_path,x_mem_path,x_cop_path        : std_logic;
    signal m_mem_path                              : std_logic;
      
  -- Write_Enable Signals:
  -- If during its flow through the pipeline an instruction or a couple of
  -- them in double processing mode causes stalls, or raises an
  -- exception, its (their) completion must be "deactivated" 
  -- before it (they) might perform any no-return unconsistent operation.
  -- The write_enable flag, associated to each instruction (couple),
  -- set to '0',
  -- prevents any memory write or regfile writeback operation.
  signal f_we,d_sampled_fwe,d_we,x_sampled_dwe,x_we,m_we : Std_logic;

  -- Pipeline Control Signals: This signals will Enable/Disable the flow
  -- of the instruction through the five pipeline stages.
  signal enable_f,enable_fd,enable_dx,enable_xm,enable_mw : Std_logic;

  -- Exceptions handling signals
  signal x_serve_exception,m_serve_exception       : Std_logic;

-- Stall handling signals
  signal stall_decode    : Std_logic; 
    
  -- Dummy signals to ease the model readability!!    
  signal Hi,Lo  : Std_logic;

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
  --    All stages are frozen synchronously
  -- b) Miss on Instruction memory (Waitstates insertion to allow instruction Fetch)
  --    Fetch, decode are frozen
  -- c) Miss on Data memory (Waitstates insertion to allow data access)
  --    All stages are frozen as writeback can not be performed
  -- d) Stalls in the pipeline flow
  -- Fetch, decode are frozen
  
    enable_f      <= (not ( stall_decode and freeze and I_NREADY and D_NREADY ));
    enable_fd     <= (not ( stall_decode and freeze and I_NREADY and D_NREADY ));
    I_busy        <= ( stall_decode and freeze and D_NREADY );
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
  

    -- EXCEPTION HANDLING: ----------------------------------------------------   
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
      -- resumed later  
      process( x_serve_exception,m_serve_exception,I_NREADY )
      begin
        if (x_serve_exception = '0') or (m_serve_exception = '0') or
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
                    reboot_value_lower-(instr_width/8),reboot_value_upper )
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

    Operation_decoding32_1:      
      Decode_op32 generic map ( word_width,rf_registers_addr_width )
                  port map ( d_instr(63 downto 32),
                             d_rs1_1,d_rs2_1,d_rcop1,d_rd1,
                             d_jump_type1,d_alu_command1,d_alu_immed1,
                             d_shift_op1,d_cop_command1,
                             d_mul_command1,
                             d_exe_outsel1,d_mem_command1,
                             exc_illegal_opcode1 );
    
    Operation_decoding32_2:      
      Decode_op32 generic map ( word_width,rf_registers_addr_width )
                  port map ( d_instr(31 downto 0),
                             d_rs1_2,d_rs2_2,d_rcop2,d_rd2,
                             d_jump_type2,d_alu_command2,d_alu_immed2,
                             d_shift_op2,d_cop_command2,
                             d_mul_command2,
                             d_exe_outsel2,d_mem_command2,
                             exc_illegal_opcode2 );

    -- ************************************************************************** 
    -- *                        SHARED RESOURCES
    -- **************************************************************************

    -- Program Flow Control
    process(d_jump_type1,d_jump_type2,d_alu_immed1,d_alu_immed2,branch_rega,branch_regb,branch_regc,branch_regd)
    begin
      if d_jump_type1/=xi_branch_carryon then
        d_jump_path  <='0';
        d_jump_type  <= d_jump_type1;
        d_jump_immed <= d_alu_immed1;
        d_jump_rega  <= branch_rega;
        d_jump_regb  <= branch_regb;
      else
        d_jump_path  <='1';
        d_jump_type  <= d_jump_type2;
        d_jump_immed <= d_alu_immed2;
        d_jump_rega  <= branch_regc;
        d_jump_regb  <= branch_regd;        
      end if;
    end process;
    
    -- Multiply-Accumulate Block
    process(d_mul_command1,d_mul_command2)
    begin
      if d_mul_command1/=xi_mul_nop then
        d_mul_path <= '0';
        d_mul_command <= d_mul_command1;
      else
        d_mul_path <= '1';
        d_mul_command <= d_mul_command2;
      end if;
    end process;

    -- Memory handling block
    process( d_mem_command1,d_mem_command2 )
    begin
      if ( d_mem_command1.mr='0' or d_mem_command1.mw='0' ) then
   
         d_mem_path <= '0';
         d_mem_command <= d_mem_command1;
      else
         d_mem_path <= '1';
         d_mem_command <= d_mem_command2; 
      end if;
    end process;

    -- COPROCESSOR ACCESS
    process( d_cop_command1,d_cop_command2,d_rcop1,d_rcop2)
    begin
      if d_cop_command1.op /= xi_system_null then
         d_cop_path    <= '0';
         d_cop_command <= d_cop_command1;
         d_rcop        <= d_rcop1;
      else
         d_cop_path    <= '0';
         d_cop_command <= d_cop_command2;
         d_rcop        <= d_rcop2;
      end if;
    end process;   


  -- Program flow control logic: Jumps & Branches handling --------------------
       
    Nextpc_decoding: 
      Decode_PC generic map ( include_scc,Word_Width,Instr_width,Iaddr_width )
                port map ( m_serve_exception,d_jump_type,f_currpc,
                           d_jump_rega,d_jump_regb, 
                           d_jump_immed,incoming_servproc_addr,epc,
                           d_nextpc,pc_plus_4 );

    
   -- PIPELINE HAZARDS HANDLE -------------------------------------------------
   -- The hazard handling logic is capable to perform interdatapath bypassing
   -- to support maximum elaboration speed.
   -- All configurations that cannot be solved through bypass, or that would
   -- cause a critical path too costly are broken with a stall command issued
   -- by the stall logic (see file xi_double_hazards.vhd).
    
   bp_logicA: Double_Bypass_Logic port map ( d_rs1_1,
                                             x_rd1,m_rd1,x_rd2,m_rd2,
                                             x_we,m_we,
                                             p_bypcontrolA );
   
   bp_logicB: Double_Bypass_Logic port map ( d_rs2_1,
                                             x_rd1,m_rd1,x_rd2,m_rd2,
                                             x_we,m_we,
                                             p_bypcontrolB );

   bp_logicC: Double_Bypass_Logic port map ( d_rs1_2,
                                             x_rd1,m_rd1,x_rd2,m_rd2,
                                             x_we,m_we,
                                             p_bypcontrolC );
   
   bp_logicD: Double_Bypass_Logic port map ( d_rs2_2,
                                             x_rd1,m_rd1,x_rd2,m_rd2,
                                             x_we,m_we,
                                             p_bypcontrolD );
    

   st_logic: Double_Stall_logic  port map ( p_bypcontrolA,p_bypcontrolB,
                                            p_bypcontrolC,p_bypcontrolD,
                                            d_jump_type1,x_mul_command,
                                            x_mul_path,x_mem_path,m_mem_path,
                                            x_mem_command.mr,m_mem_command.mr,
                                            x_serve_exception,
                                            stall_decode );


 -- OUTPUT PORTS FEED: 
    -- Generation of Register_file inputs.
    -- These signals select the alu operands between the 32 Risc general 
    -- purpose registers. Rs2 and Rs4 can be substituted by immediate
    -- operands, in case of Register/Immediate operations.
    
      rs1_1 <= d_rs1_1;
      rs2_1 <= d_rs2_1;
      rs1_2 <= d_rs1_2;
      rs2_2 <= d_rs2_2;
      rcop <= d_rcop;
    
      alu_immed1  <= d_alu_immed1;
      alu_immed2  <= d_alu_immed2;

      alu_command1.hrdwit <= d_alu_command1.hrdwit;
      alu_command2.hrdwit <= d_alu_command2.hrdwit;      
      alu_command1.isel   <= d_alu_command1.isel;
      alu_command2.isel   <= d_alu_command2.isel;
           

      d_coppath   <= d_cop_path;
      d_mulpath   <= d_mul_path;
      d_mempath   <= d_mem_path;
      x_mempath   <= x_mem_path;
      m_mempath   <= m_mem_path;
    
      dmul_command    <= d_mul_command;
      d_writeenable   <= d_we;
      x_writeenable   <= x_we;
      m_writeenable   <= m_we;
    
      byp_controlA <= p_bypcontrolA;
      byp_controlB <= p_bypcontrolB;
      byp_controlC <= p_bypcontrolC;
      byp_controlD <= p_bypcontrolD;

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
    
    ir_dx: Double_Ireg_Execute
            generic map ( Word_Width,rf_registers_addr_width )
            port map ( clk,int_reset,enable_dx,
                    
                       d_alu_command1,d_alu_command2,
                       d_alu_immed1,d_alu_immed2,
                       d_shift_op1,d_shift_op2,
                       d_exe_outsel1,d_exe_outsel2,
                       d_mul_command,
                       d_mem_command,d_rd1,d_rd2,d_we,

                       x_alu_command1,x_alu_command2,
                       x_alu_immed1,x_alu_immed2,
                       x_shift_op1,x_shift_op2,
                       x_exe_outsel1,x_exe_outsel2,
                       x_mul_command,
                       x_sampled_dmem_command,x_rd1,x_rd2,x_sampled_dwe );
    

  ---------------------------------------------------------------------
   --       EXECUTE  STAGE                                            --
   ---------------------------------------------------------------------         
    

   ------------------------------------------------------------------------------    
    -- OUTPUT PORTS FEED
    -- Transmission of the Alu control signals to datapath logic block
    -- Note: of the 3 fields of alu_command, only immediate is transmitted from
    -- the decode stage, the other two refer to the execution stage    
    
    alu_command1.op     <= x_alu_command1.op;
    alu_command2.op     <= x_alu_command2.op;

    shift_op1           <= x_shift_op1;
    shift_op2           <= x_shift_op2;
    
    exe_outsel1        <= x_exe_outsel1;
    exe_outsel2        <= x_exe_outsel2;

    
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

    ir_xm : Double_Ireg_Memory generic map ( Word_Width,rf_registers_addr_width )
                        port map ( clk,int_reset,enable_xm,
                                   x_alu_command1,x_alu_command2,
                                   x_alu_immed1,x_alu_immed2,
                                   x_mem_command,x_rd1,x_rd2,x_we,
                                   x_serve_exception,
                                   
                                   m_alu_command1,m_alu_command2,
                                   m_alu_immed1,m_alu_immed2,
                                   m_mem_command,m_sampled_xrd1,m_sampled_xrd2,m_we,
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
    
    process(m_we,m_sampled_xrd1,x_serve_exception,m_alu_command1)
    begin
       if include_hrdwit=1 and x_serve_exception='0' and m_alu_command1.hrdwit='0' then
            m_rd1 <= r0;
        elsif (m_we='1') then 
            m_rd1 <= r0;
        else
            m_rd1 <= m_sampled_xrd1;
       end if;
    end process;

    process(m_we,m_sampled_xrd2,x_serve_exception,m_alu_command2)
    begin
       if include_hrdwit=1 and x_serve_exception='0' and m_alu_command2.hrdwit='0' then
            m_rd2 <= r0;
        elsif (m_we='1') then 
            m_rd2 <= r0;
        else
            m_rd2 <= m_sampled_xrd2;
       end if;
    end process;   
    
   
  -- OUTPUT PORT FEED
    rd_1         <= m_rd1;
    rd_2         <= m_rd2;
    
    -- Pipeline Synchronization signals
    en_f   <= enable_f;
    en_fd  <= enable_fd;
    en_dx  <= enable_dx;
    en_xm  <= enable_xm;
    en_mw  <= enable_mw;

    -- END of PIPELINE DESCRIPTION
    
end STRUCTURAL;

   
