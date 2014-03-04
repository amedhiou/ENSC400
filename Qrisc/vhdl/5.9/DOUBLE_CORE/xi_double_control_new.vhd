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
  use work.components.all;
  use work.double_components.all;
  use work.definitions.all;
  use work.double_definitions.all;
  use work.double_hazards.all;
   
entity Double_control is
        port( clk                           : in   Std_logic;
              reset,reboot                  : in   Std_logic;
              freeze                        : in   Std_logic;
              stall_IF                      : in   Std_logic;

           -- SIGNALS CONTROLLING OUTSIDE IMEMORY
              -- Curr_pc is also transmitted to the System control
              -- coprocessor to update EPC register in case of exceptions.
              curr_pc                       : out  Risc_iaddr;
	      fetch_address                 : out  Risc_iaddr;
              imem_out                      : in   Risc_instr;
                            
           -- RESULTS PRODUCED BY DATAPATH ELABORATION
              -- Source registers A and B are read from the datapath, to perform
              -- jump register operation or to check branch conditions.
              reg_a                         : in   Risc_word;
              reg_b                         : in   Risc_word;
              reg_c                         : in   Risc_word;
              reg_d                         : in   Risc_word;
              -- The next memory access address is checked
              -- for invalid address configurations.
              NextMemAddress                : in   Risc_daddr;
               
           -- INTERRUPT SERVICE CONTROL SIGNALS
              -- The value produced from data memory access, that is a
              -- pointer to the appropriate Exception servicing procedure,
              -- is forced on the next_pc register in case an exception has
              -- been acknowledged.
              decode_mode                   : in   Std_logic;
              serve_exception               : in   Std_logic;
              incoming_servproc_addr        : in   Risc_iaddr;

           -- DATAPATH CONTROL SIGNALS                            
              -- Register file Control 
              rs1,rs2,rs3,rs4,rd1,rd2       : out  Risc_RegAddr;
              immediate1,immediate2         : out  Risc_word;
              -- Bypass Control
              byp_controlA,byp_controlB,
              byp_controlC,byp_controlD     : out  Risc_bypcontrol;
              -- Alu Execution control
              exe_immed1,exe_immed2         : out  Std_logic;
              alu_op1,alu_op2               : out  Risc_alucode;
              shift_op1,shift_op2           : out  Risc_shiftcode;
              exe_outsel1,exe_outsel2       : out  Risc_exeout;

           -- Single path resources control
              d_sccpath,d_mulpath,
              d_mempath,e_mempath,m_mempath : out  Std_logic;
           -- Multiplication & Accumulation Logic Control
              dec_mul_command               : out  Risc_mulop;
              d_writeenable,e_writeenable   : out  Std_logic;
              
           -- Memory access control
              smdr_enable,dmar_enable,
              e_mread,e_mwrite,
              e_isbyte,e_ishalf,
	      m_mread,m_mwrite,
              m_isbyte,m_ishalf             : out  Std_logic;
              out_dupper,out_mupper         : out  Std_logic;
	      signed_load                   : out  Std_logic;
      
              -- JAR Register feed
	      pc_plus_4                     : out  Risc_iaddr;             
              
          -- EXCEPTION LOGIC CONTROL SIGNALS
              -- Ports carrying exception occurances to exc_handling logic.
              exc_imem_invalid_addr,exc_imem_misalign,exc_imem_prot_warn,
              exc_dmem_invalid_addr,exc_dmem_misalign,exc_dmem_prot_warn,
              exc_illegal_opcode_1,exc_illegal_opcode_2   : out  Std_logic;

              -- Pipeline synchronization signals
              en_decode,en_exec,en_mem      : out  Std_logic;
              
              -- The exception logic must recognize branch delay slots,
              -- traps and MOVi2s instructions, consequently some decoded
              -- instruction word fields must be exported.
              jump_type                     : out Risc_jop;
              sp_op_type                    : out Risc_eop;
              scc_target_reg                : out Risc_RegAddr;

              -- EPC Register value ( Loaded to the PC register
              --                      when a RFE instruction is issued)
              epc                           : in   Risc_iaddr                );
end Double_control;


----------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
----------------------------------------------------------------------------

architecture structural of Double_control is
  
--    Formal conventions for signal declaration:
-- f_xxx :-> Segnals belonging to Fetch stage 
-- d_xxx :->   "         "     "  Decode stage
-- e_xxx :->   "         "     "  Execute stage
-- m_xxx :->   "         "     "  Memory access stage
-- w_xxx :->   "         "     "  Writeback stage 
-- p_xxx :-> Overall pipeline control signals


-- Signals describing the path of the fetched instruction word
-- until the stage where it is decoded into control signals
    signal next_PC,f_iaddr,f_curr_pc : Risc_iaddr;    
    signal f_instr,d_instr: Risc_instr;  
    
    
-- Signals generated by operation decoding ------------------------------------

    --16 bit ---------------------------------------------------
    signal d_sp_op_type1_16,d_sp_op_type2_16   : Risc_eop;
    signal d_jump_type1_16                     : Risc_jop;
    signal d_rs1_16,d_rs2_16,d_rs3_16,d_rs4_16 : Risc_Regaddr;
    signal d_immediate1_16,d_immediate2_16     : Risc_word;
    
    -- Signals propagating the destination register address
    -- to the Writeback stage
    signal d_rd1_16,e_rd1_16,old_e_rd1_16,m_rd1_16 : Risc_regaddr;
    signal d_rd2_16,e_rd2_16,old_e_rd2_16,m_rd2_16 : Risc_regaddr;

    -- Alu and Immediate operand generator control signals
    signal d_alu_immed1_16,e_alu_immed1_16     : Std_logic;
    signal d_alu_immed2_16,e_alu_immed2_16     : Std_logic;
    signal d_alu_op1_16,e_alu_op1_16           : Risc_alucode;    
    signal d_alu_op2_16,e_alu_op2_16           : Risc_alucode;
    signal d_shift_op1_16,e_shift_op1_16       : Risc_shiftcode;    
    signal d_shift_op2_16,e_shift_op2_16       : Risc_shiftcode;
    signal d_exe_outsel1_16,e_exe_outsel1_16   : Risc_exeout;
    signal d_exe_outsel2_16,e_exe_outsel2_16   : Risc_exeout;

    -- Multiplication & Accumulation logic control signals    
    signal d_mul_command1_16,e_mul_command1_16 : Risc_mulop;
    signal d_mul_command2_16,e_mul_command2_16 : Risc_mulop;

     -- Data memory control signals
    signal d_mem_read1_16,d_mem_write1_16,d_mem_isbyte1_16,d_mem_ishalf1_16,
           e_mem_read1_16,e_mem_write1_16,e_mem_isbyte1_16,e_mem_ishalf1_16,
	   nextm_mem_read1_16,nextm_mem_write1_16,
           nextm_mem_isbyte1_16,nextm_mem_ishalf1_16,
           m_mem_read1_16,m_mem_write1_16,
           m_mem_isbyte1_16,m_mem_ishalf1_16                      : Std_logic;
    signal d_signed_load1_16,e_signed_load1_16,m_signed_load1_16  : Std_logic;
    signal d_upper1_16,e_ad1_16,m_upper1_16  : Std_logic;    
    
    signal d_mem_read2_16,d_mem_write2_16,d_mem_isbyte2_16,d_mem_ishalf2_16,
           e_mem_read2_16,e_mem_write2_16,e_mem_isbyte2_16,e_mem_ishalf2_16,
	   nextm_mem_read2_16,nextm_mem_write2_16,
           nextm_mem_isbyte2_16,nextm_mem_ishalf2_16,
           m_mem_read2_16,m_mem_write2_16,
           m_mem_isbyte2_16,m_mem_ishalf2_16                      : Std_logic;
    signal d_signed_load2_16,e_signed_load2_16,m_signed_load2_16  : Std_logic;
    signal d_upper2_16,e_upper2_16,m_upper2_16  : Std_logic;
    
    --32 bit ---------------------------------------------------
    signal d_sp_op_type1_32                    : Risc_eop;
    signal d_jump_type1_32                     : Risc_jop;
    signal d_rs1_32,d_rs2_32                   : Risc_Regaddr;
    signal d_immediate1_32                     : Risc_word;    
    
    -- Signals propagating the destination register address
    -- to the Writeback stage
    signal d_rd1_32,e_rd1_32,old_e_rd1_32,m_rd1_32 : Risc_regaddr;

    -- Alu and Immediate operand generator control signals
    signal d_alu_immed1_32,e_alu_immed1_32     : Std_logic;
    signal d_alu_op1_32,e_alu_op1_32           : Risc_alucode;
    signal d_shift_op1_32,e_shift_op1_32       : Risc_shiftcode;
    signal d_exe_outsel1_32,e_exe_outsel1_32   : Risc_exeout;
        
    -- Multiplication & Accumulation logic control signals    
    signal d_mul_command1_32,e_mul_command1_32 : Risc_mulop;
         
    -- Data memory control signals
    signal d_mem_read1_32,d_mem_write1_32,d_mem_isbyte1_32,d_mem_ishalf1_32,
           e_mem_read1_32,e_mem_write1_32,e_mem_isbyte1_32,e_mem_ishalf1_32,
	   nextm_mem_read1_32,nextm_mem_write1_32,
           nextm_mem_isbyte1_32,nextm_mem_ishalf1_32,
           m_mem_read1_32,m_mem_write1_32,
           m_mem_isbyte1_32,m_mem_ishalf1_32                      : Std_logic;
    signal d_signed_load1_32,e_signed_load1_32,m_signed_load1_32  : Std_logic;
    signal d_upper1_32,e_upper1_32,m_upper1_32  : Std_logic;
   ----------------------------------------------------------------------------

    -- Control signals resulting from 16/32 decoding multiplexing--------------
    signal d_sp_op_type1,d_sp_op_type2,d_sp_op_type  : Risc_eop;
    signal d_jump_type1,d_jump_type2,d_jump_type     : Risc_jop;
    signal d_rs1,d_rs2,d_rs3,d_rs4                   : Risc_Regaddr;
    signal d_immediate1,d_immediate2                 : Risc_word;
    
    -- Signals propagating the destination register address
    -- to the Writeback stage
    signal d_rd1,e_rd1,old_e_rd1,m_rd1 : Risc_regaddr;
    signal d_rd2,e_rd2,old_e_rd2,m_rd2 : Risc_regaddr;

    -- Alu and Immediate operand generator control signals
    signal d_alu_immed1,e_alu_immed1     : Std_logic;
    signal d_alu_immed2,e_alu_immed2     : Std_logic;
    signal d_alu_op1,e_alu_op1           : Risc_alucode;
    signal d_alu_op2,e_alu_op2           : Risc_alucode;
    signal d_shift_op1,e_shift_op1       : Risc_shiftcode;
    signal d_shift_op2,e_shift_op2       : Risc_shiftcode;
    signal d_exe_outsel1,e_exe_outsel1   : Risc_exeout;
    signal d_exe_outsel2,e_exe_outsel2   : Risc_exeout;

    -- Multiplication & Accumulation logic control signals    
    signal d_mul_command1,e_mul_command1 : Risc_mulop;
    signal d_mul_command2,e_mul_command2 : Risc_mulop;
    signal d_mul_command,e_mul_command   : Risc_mulop;

     -- Data memory control signals
    signal d_mem_read1,d_mem_write1,d_mem_isbyte1,d_mem_ishalf1,
           e_mem_read1,e_mem_write1,e_mem_isbyte1,e_mem_ishalf1,
	   nextm_mem_read1,nextm_mem_write1,
           nextm_mem_isbyte1,nextm_mem_ishalf1,
           m_mem_read1,m_mem_write1,
           m_mem_isbyte1,m_mem_ishalf1                      : Std_logic;
    signal d_signed_load1,e_signed_load1,m_signed_load1     : Std_logic;
    signal d_upper1,e_upper1,m_upper1                       : Std_logic;
    
    signal d_mem_read2,d_mem_write2,d_mem_isbyte2,d_mem_ishalf2,
           e_mem_read2,e_mem_write2,e_mem_isbyte2,e_mem_ishalf2,
	   nextm_mem_read2,nextm_mem_write2,
           nextm_mem_isbyte2,nextm_mem_ishalf2,
           m_mem_read2,m_mem_write2,
           m_mem_isbyte2,m_mem_ishalf2                      : Std_logic;
    signal d_signed_load2,e_signed_load2,m_signed_load2     : Std_logic;
    signal d_upper2,e_upper2,m_upper2                       : Std_logic;
    
    signal d_mem_read,d_mem_write,d_mem_isbyte,d_mem_ishalf,
           e_mem_read,e_mem_write,e_mem_isbyte,e_mem_ishalf,
	   nextm_mem_read,nextm_mem_write,
           nextm_mem_isbyte,nextm_mem_ishalf,
           m_mem_read,m_mem_write,
           m_mem_isbyte,m_mem_ishalf                        : Std_logic;
    signal d_signed_load,e_signed_load,m_signed_load        : Std_logic;
    signal d_upper,e_upper,m_upper        : Std_logic;
        
    ------------------------------------------------------------------------
    
    signal j_immediate, j_reg_a,j_reg_b                     : Risc_word;
    signal exc_illegal_opcode1_32,
           exc_illegal_opcode1_16,exc_illegal_opcode2_16    : std_logic;    

    
-- Path selection signals used to describe the selected path for shared resources
    signal d_mul_path,d_mem_path,d_scc_path        : std_logic;
    signal e_mul_path,e_mem_path,e_scc_path        : std_logic;
    signal m_mem_path                              : std_logic;
    
    
-- Bypass_multiplexers_handling Signals, sent to the datapaths to activate
-- the bypass channels
    signal p_bypcontrolA,p_bypcontrolB,
           p_bypcontrolC,p_bypcontrolD  : Risc_bypcontrol;

-- Current pc selection signal, determines the curr_pc between reboot,
-- exception servicing and normal functioning
    signal currpc_inmux_sel : Std_logic_vector(1 downto 0);
    signal boot_address     : Risc_iaddr;
    
-- Writes_Enable Signals:
   -- If during its flow through the pipeline an instruction or a couple of
   -- them in double processing mode causes data hazards, or raises an
   -- exception, its (their) completion must be "deactivated" 
   -- before it (they)might perform any no-return unconsistent operation.
   -- The write_enable flag, associated to each instruction (couple),
   -- set to '0',
   -- prevents any memory write or regfile writeback operation.
    signal f_we,d_we,
           next_e_we,e_we,next_m_we,m_we       : Std_logic;
    
-- Exceptions handling signals
    signal icheck_enable,dcheck_enable         : Std_logic;
    signal e_serve_exception,m_serve_exception : Std_logic;
    
-- Stall handling signals
    signal stall_decode                        : Std_logic;
    signal enable_fetch,enable_decode,
           enable_exec,enable_mem              : Std_logic;

    signal aux_active_16,aux_active            : std_logic;

    -- Dummy signals to ease the model readability!!    
    signal Hi           : Std_logic;
    signal zero3        : Std_logic_vector(2 downto 0);
    signal zero4        : Std_logic_vector(3 downto 0);
    signal zero5        : Std_logic_vector(4 downto 0);
    signal zero32       : Std_logic_vector(31 downto 0);

    signal instr32      : Std_logic_vector(31 downto 0);
    signal instr64      : Std_logic_vector(63 downto 0);
    
    signal instr_ishalf : std_logic;
    
    signal old_decode_mode : std_logic;
           
begin

    -- Constant to be defined as signal to be transmitted on subcircuits input
    -- ports
    Hi     <= '1';
    zero5  <= ( others => '0' );
    zero4  <= ( others => '0' );
    zero3  <= ( others => '0' );
    zero32 <= ( others => '0' ); 
    
    ----------------------------------------------------------
    -- FETCH STAGE
    ---------------------------------------------------------- 
    
    enable_fetch <= not( stall_decode and freeze );


    -- INSTRUCTION FETCHING: The Next_pc value is fetched unless an
    -- exception has to be serviced. In this case the next fetched address
    -- is a pointer to the Exception service procedure.
    -- This address is loaded from the interrupt table contained in the
    -- external data memory during the very same cycle in which the
    -- exception is detected, and it is bypassed to this multiplexer
    -- so that the first instruction of the exception servicing procedure
    -- is loaded at the next fetch.
    -- In case the REBOOT signal is active exceptions are ignored and the
    -- control is passed to the boot procedure.
    --    
    currpc_inmux_sel <= reboot&m_serve_exception;
    boot_address <= Conv_std_logic_vector(boot_value,Iaddr_width);
    
    CURRPC_IN_MUX : MUX_4 generic map (width => Iaddr_width)
                         port map (boot_address,boot_address,
                                   incoming_servproc_addr,next_pc,
                                   currpc_inmux_sel,f_iaddr);

    
    Program_counter: Ireg_Fetch generic map (instr_mem_init_value_lower, instr_mem_init_value_upper)
                     port map ( clk,reset,enable_fetch,f_iaddr,
                                f_curr_pc );

    
      ------- Instruction Memory Invalid Address configuration detection logic
      --
      -- The next instruction address, produced by the DecodePc logic,
      -- is checked for invalid address configuration exceptions.
      
      instr_ishalf  <= '1';         
      icheck_enable <= '0';
    
      i_chk : addrchk generic map (    Iaddr_width,
                                       imem_lowerlimitation_control,
                                       imem_upperlimitation_control,
                                       instr_mem_end_value_lower,
                                       instr_mem_end_value_upper,
                                       instr_mem_init_value_lower,
                                       instr_mem_init_value_upper )
                         port map   (  f_curr_pc,   
                                       exc_imem_invalid_addr,
                                       exc_imem_misalign,
                                       exc_imem_prot_warn,
                                       icheck_enable,
                                       instr_ishalf,Hi );
    
    
    -- OUTPUT PORTS FEED:
    -- External Instruction Memory Control
    curr_pc       <= f_curr_pc;
    fetch_address <= f_iaddr;
    f_instr       <= imem_out;
    
    
 -- INSTRUCTION DISABLE
   
    -- If an exception is acknowledged during the memory access cycle the
    -- contemporaneus fetch will be write-disabled, so that the fetched
    -- instruction will flush harmlessy through the pipeline.
    
    process( e_serve_exception,m_serve_exception )
    begin
      if (e_serve_exception = '0') or (m_serve_exception = '0') then
        f_we    <= '1';
      else
        f_we    <= '0';
      end if;
    end process;
    
  -------------------------------------------------------------------------
  -- DECODE STAGE
  -------------------------------------------------------------------------

    enable_decode <= not (stall_decode and freeze and reboot);
        
    ird: Ireg_Decode port map ( clk,reset,enable_decode,f_instr,f_we,
                                d_instr,d_we );
    
 -- INSTRUCTION DECODE:
   
    
 -- CONTROL SIGNALS GENERATION ------------------------------------------------
   -- Generation of Datapath resources control signals:
   -- The incoming instruction can be decoded as a single 32-bit instruction or
   -- as a pair of two parallel 16 bit instructions that will be processed
   -- concurrently.

    
    
DOUBLE32: if Instr_width = 32 generate

    instr32 <= EXT(d_instr,32);
    Operation_decoding32: 
      Decode_op32 port map ( instr32,
                             d_rs1_32,d_rs2_32,d_rd1_32,d_immediate1_32,
                             d_jump_type1_32,d_sp_op_type1_32,
                             d_alu_immed1_32,d_alu_op1_32,d_shift_op1_32,
                             d_exe_outsel1_32,
                             d_mem_read1_32,d_mem_write1_32,
                             d_mem_isbyte1_32,d_mem_ishalf1_32,
                             d_signed_load1_32,d_upper1_32,exc_illegal_opcode1_32,
                             d_mul_command1_32 );
  
    Mdecode16: 
      Main_Decodeop16 port map (instr32(31 downto 16),d_instr(15 downto 0),
                                d_rs1_16,d_rs2_16,d_rd1_16,d_immediate1_16,
                                d_jump_type1_16,d_sp_op_type1_16,
                                d_alu_immed1_16,d_alu_op1_16,d_shift_op1_16,
                                d_exe_outsel1_16,
                                d_mem_read1_16,d_mem_write1_16,
                                d_mem_isbyte1_16,d_mem_ishalf1_16,
                                d_signed_load1_16,exc_illegal_opcode1_16,
                                d_mul_command1_16,
                                aux_active_16);


    -- DECODE MODE Multiplexing
    ---------------------------------------------------------------------------
    -- The following multiplexers allow to TOGGLE instruction mode between 16-
    -- and 32- bit decoding.
    -- The mode to be selected is referred to the previous instruction
    -- to allow branch delay slot to be processed with the appropriate mode:
    -- ES 32bit_instruction  (decode_mode is '1' -> 32-bit)
    --    32bit_Jalx         (decode_mode is set to '0' -> 16-bit)
    --    32bit_DelaySlot    (decode_mode is 0, but old_decode_mode still '1')
    --    16bit_FirstInstruction (old_decode_mode is '0' too )
    
    DecodeMUX_main :
      Decode_mux port map      (d_rs1_32,d_rs2_32,d_rd1_32,d_immediate1_32,
                                d_jump_type1_32,d_sp_op_type1_32,
                                d_alu_immed1_32,d_alu_op1_32,d_shift_op1_32,
                                d_exe_outsel1_32,
                                d_mem_read1_32,d_mem_write1_32,
                                d_mem_isbyte1_32,d_mem_ishalf1_32,
                                d_signed_load1_32,d_upper1_32,exc_illegal_opcode1_32,
                                d_mul_command1_32,

                                d_rs1_16,d_rs2_16,d_rd1_16,d_immediate1_16,
                                d_jump_type1_16,d_sp_op_type1_16,
                                d_alu_immed1_16,d_alu_op1_16,d_shift_op1_16,
                                d_exe_outsel1_16,
                                d_mem_read1_16,d_mem_write1_16,
                                d_mem_isbyte1_16,d_mem_ishalf1_16,
                                d_signed_load1_16,d_upper1_16,exc_illegal_opcode1_16,
                                d_mul_command1_16,

                                old_decode_mode,

                                d_rs1,d_rs2,d_rd1,d_immediate1,
                                d_jump_type1,d_sp_op_type1,
                                d_alu_immed1,d_alu_op1,d_shift_op1,
                                d_exe_outsel1,
                                d_mem_read1,d_mem_write1,
                                d_mem_isbyte1,d_mem_ishalf1,
                                d_signed_load1,d_upper1,exc_illegal_opcode_1,
                                d_mul_command1 );

    
    -- The auxiliary channel is active if the mode is 16-bit AND the current 16-bit
    -- instruction decoded by the main channel is not an extended instruction
    aux_active <= old_decode_mode or aux_active_16; 

    Adecode16: 
      Aux_Decodeop16 port map ( aux_active,instr32(15 downto 0),
                                d_rs3_16,d_rs4_16,d_rd2_16,d_immediate2_16,
                                d_sp_op_type2_16,
                                d_alu_immed2_16,d_alu_op2_16,d_shift_op2_16,
                                d_exe_outsel2_16,
                                d_mem_read2_16,d_mem_write2_16,
                                d_mem_isbyte2_16,d_mem_ishalf2_16,
                                d_signed_load2_16,exc_illegal_opcode2_16,
                                d_mul_command2_16 );

    DecodeMUX_aux :
      Decode_mux     port map (zero5,zero5,zero5,zero32,
                               zero4,zero4,
                               Hi,zero4,zero3,
                               zero3,
                               Hi,Hi,Hi,Hi,
                               Hi,Hi,Hi,
                               zero4,

                               d_rs3_16,d_rs4_16,d_rd2_16,d_immediate2_16,
                               zero4,zero4,
                               d_alu_immed2_16,d_alu_op2_16,d_shift_op2_16,
                               d_exe_outsel2_16,
                               d_mem_read2_16,d_mem_write2_16,
                               d_mem_isbyte2_16,d_mem_ishalf2_16,
                               d_signed_load2_16,d_upper2_16,exc_illegal_opcode2_16,
                               d_mul_command2_16,

                               decode_mode,

                               d_rs3,d_rs4,d_rd2,d_immediate2,
                               d_jump_type2,d_sp_op_type2,
                               d_alu_immed2,d_alu_op2,d_shift_op2,
                               d_exe_outsel2,
                               d_mem_read2,d_mem_write2,
                               d_mem_isbyte2,d_mem_ishalf2,
                               d_signed_load2,d_upper2,exc_illegal_opcode_2,
                               d_mul_command2 );
end generate DOUBLE32;

DOUBLE64: if Instr_width = 64 generate

    -- This dummy extension is provided to force synopsys to accept this compilation
    -- in both 32 and 64 bit case to grant scalability of the model
    instr64 <= EXT(d_instr,64);
    
    Mdecode32: 
      Decode_op32 port map ( instr64(63 downto 32),
                             d_rs1,d_rs2,d_rd1,d_immediate1,
                             d_jump_type1,d_sp_op_type1,
                             d_alu_immed1,d_alu_op1,d_shift_op1,
                             d_exe_outsel1,
                             d_mem_read1,d_mem_write1,
                             d_mem_isbyte1,d_mem_ishalf1,
                             d_signed_load1,d_upper1,exc_illegal_opcode_1,
                             d_mul_command1 );
    Adecode32: 
      Decode_op32 port map ( instr64(31 downto 0),
                             d_rs3,d_rs4,d_rd2,d_immediate2,
                             d_jump_type2,d_sp_op_type2,
                             d_alu_immed2,d_alu_op2,d_shift_op2,
                             d_exe_outsel2,
                             d_mem_read2,d_mem_write2,
                             d_mem_isbyte2,d_mem_ishalf2,
                             d_signed_load2,d_upper2,exc_illegal_opcode_2,
                             d_mul_command2 );    
end generate DOUBLE64;          
    
  -- Program flow control logic: Jumps & Branches handling --------------------
       
   Nextpc_decoding: 
     Decode_PC port map ( reset,enable_fetch,d_we,
                          d_jump_type,f_curr_pc,j_reg_a,j_reg_b,
                          j_immediate,
                          epc,next_pc,pc_plus_4 );


  -- Path resolution for shared resources: --------------------------------       
  
  -- Note that the first data channel has absolute precedence: access to
  -- a shared resource is granted to the second channel only in case
  -- the first channel instruction does not use it.

    -- Program flow control
    process(d_jump_type1,d_jump_type2,reg_a,reg_b,reg_c,reg_d,
            d_immediate1,d_immediate2)
    begin
      if d_jump_type1 = j_carryon and d_jump_type2 /= j_carryon then
         d_jump_type <= d_jump_type2;
         j_reg_a <= reg_c;
         j_reg_b <= reg_d;
         j_immediate <= d_immediate2;
      else
         d_jump_type <= d_jump_type1;
         j_reg_a <= reg_a;
         j_reg_b <= reg_b;
         j_immediate <= d_immediate1;        
      end if;
    end process;
    
    -- Multiply-Accumulate Block
    process(d_mul_command1,d_mul_command2)
    begin
      if d_mul_command1 = mul_null and d_mul_command2 /= mul_null then
        d_mul_path <= '1';
        d_mul_command <= d_mul_command2;
      else
        d_mul_path <= '0';
        d_mul_command <= d_mul_command1;
      end if;
    end process;

    -- Memory handling block
    process( d_mem_read1,d_mem_write1,d_mem_isbyte1,d_mem_ishalf1,d_signed_load1,d_upper1,
             d_mem_read2,d_mem_write2,d_mem_isbyte2,d_mem_ishalf2,d_signed_load2,d_upper2 )
    begin
      if (d_mem_read1 = '1' and d_mem_write1 = '1') and
         (d_mem_read2 = '0' or  d_mem_write2 = '0') then
         d_mem_path <= '1';
         d_mem_read    <= d_mem_read2;   d_mem_write  <= d_mem_write2;
         d_mem_ishalf  <= d_mem_ishalf2; d_mem_isbyte <= d_mem_isbyte2;
         d_signed_load <= d_signed_load2;d_upper <= d_upper2;
      else
         d_mem_path <= '0';
         d_mem_read    <= d_mem_read1;   d_mem_write  <= d_mem_write1;
         d_mem_ishalf  <= d_mem_ishalf1; d_mem_isbyte <= d_mem_isbyte1;
         d_signed_load <= d_signed_load1;d_upper  <= d_upper1;

      end if;
    end process;

    -- System Control Coprocessor
    process( d_sp_op_type1,d_sp_op_type2,d_instr )
    begin
      if d_sp_op_type1 = e_none and d_sp_op_type2 /= e_none  then

         d_scc_path     <= '1';
         d_sp_op_type   <= d_sp_op_type2;
         scc_target_reg <= d_instr(15 downto 11);
         
      else
         d_scc_path     <= '0';
         d_sp_op_type   <= d_sp_op_type1;
         scc_target_reg <= d_instr(47 downto 43);
      end if;
    end process;


    
  -----------------------------------------------------------------------------
  
    
   -- PIPELINE HAZARDS HANDLE -------------------------------------------------
   -- The hazard handling logic is capable to perform interdatapath bypassing
   -- to support maximum elaboration speed.
   -- All configurations that cannot be solved through bypass, or that would
   -- cause a critical path too costly are broken with a stall command issued
   -- by the stall logic (see file xi_double_hazards.vhd).
    
   bp_logicA: Double_Bypass_Logic port map ( d_rs1,
                                             e_rd1,m_rd1,e_rd2,m_rd2,
                                             e_we,m_we,
                                             p_bypcontrolA );
   
   bp_logicB: Double_Bypass_Logic port map ( d_rs2,
                                             e_rd1,m_rd1,e_rd2,m_rd2,
                                             e_we,m_we,
                                             p_bypcontrolB );

   bp_logicC: Double_Bypass_Logic port map ( d_rs3,
                                             e_rd1,m_rd1,e_rd2,m_rd2,
                                             e_we,m_we,
                                             p_bypcontrolC );
   
   bp_logicD: Double_Bypass_Logic port map ( d_rs4,
                                             e_rd1,m_rd1,e_rd2,m_rd2,
                                             e_we,m_we,
                                             p_bypcontrolD );
    

   st_logic: Double_Stall_logic  port map ( p_bypcontrolA,p_bypcontrolB,
                                            p_bypcontrolC,p_bypcontrolD,
                                            d_jump_type1,e_mul_command,
                                            e_mem_read,m_mem_read,
                                            e_mul_path,e_mem_path,m_mem_path,
                                            e_serve_exception,stall_IF,
                                            stall_decode );
  -----------------------------------------------------------------------------

    
  -- OUTPUT PORTS FEED: -------------------------------------------------------
    -- Generation of Register_file inputs.
    -- These signals select the alu operands between the 32 Risc general 
    -- purpose registers. Rs2 and Rs4 can be substituted by immediate
    -- operands, in case of Register/Immediate operations.
      rs1 <= d_rs1;
      rs2 <= d_rs2;
      rs3 <= d_rs3;
      rs4 <= d_rs4;
    
      immediate1      <= d_immediate1;
      immediate2      <= d_immediate2;

      d_sccpath       <= d_scc_path;
      d_mulpath       <= d_mul_path;    
    
      dec_mul_command <= d_mul_command;
      d_writeenable   <= next_e_we;
      e_writeenable   <= next_m_we;
    
      byp_controlA <= p_bypcontrolA;
      byp_controlB <= p_bypcontrolB;
      byp_controlC <= p_bypcontrolC;
      byp_controlD <= p_bypcontrolD;
    
    -- Control signals exported to exc_logic to handle trap, rfe
    -- and Mov instructions
      jump_type      <= d_jump_type1;
      sp_op_type     <= d_sp_op_type;
      
    
    -- INSTRUCTION DISABLE
    -- In case the decoded stage is going to be stalled, the current
    -- instruction will stay, and a dummy will be passed on to execute
    -- stage.
    -- Obviously this dummy must be write disabled !
    process(d_we,e_serve_exception,stall_decode,d_sp_op_type)
    begin
      if (d_we = '1') or                     -- An interrupt was issued
                                             -- while Fetching the instr
         (e_serve_exception = '0') or        -- An interrupt is being issued
         (stall_decode = '0') then           -- The instr is being stalled

           next_e_we <= '1';
      else
           next_e_we <= '0';
      end if;
    end process;
    
    ---------------------------------------------------------------------
    --       EXECUTE  STAGE                                            --
    --------------------------------------------------------------------- 
    
    enable_exec <= not ( freeze );
    ire1: Double_Ireg_Execute
            port map ( clk,reset,enable_exec,

                       decode_mode,
                       d_alu_immed1,d_alu_immed2,
                       d_alu_op1,d_alu_op2,
                       d_shift_op1,d_shift_op2,
                       d_exe_outsel1,d_exe_outsel2,
                       d_mul_path,d_mem_path,
                       d_mul_command,
                       d_mem_read,d_mem_write,d_mem_isbyte,d_mem_ishalf,
                       d_signed_load,d_upper,
                       d_rd1,d_rd2,
                       next_e_we,

                       old_decode_mode,
                       e_alu_immed1,e_alu_immed2,
                       e_alu_op1,e_alu_op2,
                       e_shift_op1,e_shift_op2,
                       e_exe_outsel1,e_exe_outsel2,
                       e_mul_path,e_mem_path,
                       e_mul_command,
                       e_mem_read,e_mem_write,e_mem_isbyte,e_mem_ishalf,
                       e_signed_load,e_upper,
                       e_rd1,e_rd2,
                       e_we   ); 
    
      --------- Data Memory Invalid Address configuration detection logic
      -- The address produced by the alu is checked for invalid address
      -- configuration exception before it is handed over to the Memory access
      -- stage.
      -- This operation is performed only in case of memory accesses.
      process(e_mem_read,e_mem_write)
      begin
        if (e_mem_read='0' or e_mem_write='0')  then
           dcheck_enable <= '0';
        else
           dcheck_enable <= '1';
        end if;
      end process;
      
      d_chk : addrchk generic map ( Daddr_width,
                                    dmem_lowerlimitation_control,
                                    dmem_upperlimitation_control,
                                    data_mem_end_value_lower,
                                    data_mem_end_value_upper,
                                    data_mem_init_value_lower,
                                    data_mem_init_value_upper)
                      port map   (  NextMemAddress,
                                    exc_dmem_invalid_addr,
                                    exc_dmem_misalign,
                                    exc_dmem_prot_warn,
                                    dcheck_enable,
                                    e_mem_isbyte,e_mem_ishalf );
    
 -- OUTPUT PORTS FEED
    -- Transmission of the Alu control signals to datapath logic block
    exe_immed1     <= e_alu_immed1;
    exe_immed2     <= e_alu_immed2;

    alu_op1        <= e_alu_op1;
    alu_op2        <= e_alu_op2;
    shift_op1      <= e_shift_op1;
    shift_op2      <= e_shift_op2;      
    
    exe_outsel1    <= e_exe_outsel1;
    exe_outsel2    <= e_exe_outsel2;

    -- Single path resources control
    d_mempath <= d_mem_path;
    e_mempath <= e_mem_path;
    m_mempath <= m_mem_path;
       
    -- MEMORY ACCESS ADDRESS GENERATION: 
    -- In case the current instruction is a memory access, the target
    -- address must be transmitted to the outgoing address bus sampling
    -- the alu_output.
    -- The DMAR (Data Memory Access Register) holds the next addresses
    -- for any memory access.
    -- The SMDR latches hold the word to be stored in case of STORE
    -- operations, Sampled from the in_regB signal, that is the second
    -- register file output.
    smdr_enable <= d_mem_write;
    dmar_enable <= e_mem_read and e_mem_write;

   e_serve_exception <= serve_exception;
    
    -- Memory access control:    
    --  If an exception has been acknowledged during the current memory
    --  stage, mem_read must be set to '0' to read the servicing procedure
    --  address
    --  from the interrupt table in the reserved section of the data memory.
    process( e_we,e_serve_exception,
	     e_mem_read,e_mem_write,e_mem_isbyte,e_mem_ishalf )
    begin
       if e_serve_exception = '0'  then
          nextm_mem_read    <= '0';
          nextm_mem_write   <= '1';
	  nextm_mem_isbyte  <= '1';
	  nextm_mem_ishalf  <= '1';
       else
          if e_we = '0' then
             nextm_mem_read   <= e_mem_read;
	     nextm_mem_write  <= e_mem_write;
	     nextm_mem_isbyte <= e_mem_isbyte;
	     nextm_mem_ishalf <= e_mem_ishalf;
          else
             nextm_mem_read    <= '1';
	     nextm_mem_write   <= '1';
	     nextm_mem_isbyte  <= '1';
	     nextm_mem_ishalf  <= '1';
          end if;
       end if;
    end process;    
    
    next_m_we   <= e_we or (not e_serve_exception);
    
  -------------------------------------------------------------------------
  --        MEMORY_ACCESS STAGE                                          
  -------------------------------------------------------------------------
    
  -- At the beginning of the memory stage all possible exception cause have
  -- been verified, and the interrupt vector has been sampled.
  -- During this execution stage two alternative patterns of execution are
  -- possible:
  --
  -- (A) If in the last exception stage an Exception or Interrupt has
  --     been acknowledged, the alu-generated data memory address is overwritten
  --     by the interrupt Table pointer produced using the appropriate Exception
  --     code (see file basic.vhd for Risc exception codes).
  --     Processor mode is switched to kernel, cause register is updated,
  --     and the current program counter is saved on EPC register.
  --     Consequently, a memory access cycle is performed over the
  --     protected portion of the data memory fetching the specified
  --     exception procedure address, that is redirected over the PC
  --     register. Rd is set to r0 to disable unwanted writebacks.
  --
  --
  -- (B) If No exceptions or interrupt are pending, the instruction is
  --     committed, that is the normal memory access cycle scheduled by the
  --     instruction decoding logic is normally executed.
  --     
    
    enable_mem <= not freeze;
    irm: Double_Ireg_Memory
            port map ( clk,reset,enable_mem,
                       e_mem_path,
                       nextm_mem_read,nextm_mem_write,
		       nextm_mem_isbyte,nextm_mem_ishalf,
                       e_signed_load,e_upper,
                       e_rd1,e_rd2,
                       next_m_we,e_serve_exception,

                       m_mem_path,
                       m_mem_read,m_mem_write,
		       m_mem_isbyte,m_mem_ishalf,
                       m_signed_load,m_upper,
                       old_e_rd1,old_e_rd2,
                       m_we,m_serve_exception );


    -- MEMORY CONTROL SIGNALS -----------------------------------------

    e_mread  <= nextm_mem_read;
    e_mwrite <= nextm_mem_write;
    e_isbyte <= nextm_mem_isbyte;
    e_ishalf <= nextm_mem_ishalf;
    m_mread  <= m_mem_read;
    m_mwrite <= m_mem_write;
    m_isbyte <= m_mem_isbyte;
    m_ishalf <= m_mem_ishalf;
    
    -- this last signal determines the kind of sign extension performed by
    -- datapath memory stage over byte or halfword loaded data.
    signed_load <= m_signed_load;
    out_mupper  <= m_upper;
    out_dupper  <= d_upper;
    ------------------------------------------------------------------

    
    -- INSTRUCTION DISABLE
    -- Writebacks over the register file are inhibited in case :
    -- (a) The instruction has been write-disabled before.
    -- (b) The instruction has raised an exception acknowledged in this very
    --     stage.
    -- (c) Processor execution has been frozen.

    -- Writeback control
    process(m_we,old_e_rd1,old_e_rd2)
    begin
       if ( m_we ) = '0' then
         m_rd1 <= old_e_rd1;
         m_rd2 <= old_e_rd2;         
       else
         m_rd1 <= r0;
         m_rd2 <= r0;
       end if;
    end process;
     
    
    -------------------------------------------------------------
    --     WRITEBACK STAGE                                     --
    -------------------------------------------------------------
    
     -- If an instruction reaches the writeback stage it is considered
     -- "committed", and its execution can not be halted or restarted.
     -- Consequently, the writeback stage can never be stalled.
     -- Only, in case rd has been forced to zero, (deactivated instructions
     -- or simple r0 directed instructions) the stage will be idle.
     -- In the datapath and in the control_block no explicit writeback stage
     -- has been defined: The writeback is synchronized by
     -- the register file itself, that writes data on the clock raising edge.

 -- OUTPUT PORT FEED
    rd1         <= m_rd1;
    rd2         <= m_rd2;
        
    -- Pipeline Synchronization signals
    en_decode  <= enable_decode;
    en_exec    <= enable_exec;
    en_mem     <= enable_mem;

end STRUCTURAL;

