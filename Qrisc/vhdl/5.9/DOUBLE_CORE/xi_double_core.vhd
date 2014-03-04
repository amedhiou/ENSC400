------------------------------------------------------------------------ 
--                      XI_DOUBLE_CORE.VHD                            --
--                                                                    --
------------------------------------------------------------------------
-- Created 2001 by F.M.Campi , fcampi@deis.unibo.it                   --
-- DEIS, Department of Electronics Informatics and Systems,           --
-- University of Bologna, BOLOGNA , ITALY                             -- 
------------------------------------------------------------------------

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

-- This Block is the top level entity of the double/datapath processor model.
-- It synchronizes the functioning of the two Datapaths, their respective
-- Control_logics and the System Control Coprocessor.
-- I choose to have as few logic components as possible in this block, that is
-- meant as an empty shell containing the high level processor components and
-- thair connection. All the elaboration resources are hidden deeper in the
-- hierarchy. 


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;
  use work.components.all;
  use work.double_components.all;
  use work.regfile.all;
  use work.scc_pack.all;
  use work.definitions.all;
  use work.double_definitions.all;
  
entity Xi_core is 
  generic(
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

           -- Raise an interruption in case of internal exception
           interrupt_on_exception : integer :=1;
           -- Include sticky logic on internal exceptions
           include_sticky_logic : integer :=1;
           -- Depth of the on-chip shifter: Max shift is 2**shift_count_width
           shift_count_width   : positive := 5;
           -- Number of bits to address GP register in the processor Rfile
           -- The number of registers will be 2**rf_registers_addr_width
           rf_registers_addr_width : positive := 5;

           -- BUS WIDTH DEFINITION
           -- Processor Data Width
           Word_Width      : positive := 32;
            -- Processor Instruction Width
           Instr_Width     : positive := 64;
           -- Processor Data addressing space Width (XiRisc has Harvard memory
           -- organization
           Daddr_width     : positive := 32;
           -- Processor Instruction addressing space Width (XiRisc has Harvard
           -- memory organization)
           Iaddr_width     : positive := 24;

           -- CONTROL, STATUS and MEMORY SPACE SETTINGS
           -- Activation of the hardware controls on memory addresses
           imem_lowerlimitation_control : integer := 0;
           dmem_lowerlimitation_control : integer := 0;
           imem_upperlimitation_control : integer := 0;
           dmem_upperlimitation_control : integer := 0;
           -- Higher limit of the processor memory space
           -- (Utilized for hardware controls on memory addresses)
           -- Higher limit of the processor memory space
           -- (Utilized for hardware controls on memory addresses) 
           instr_mem_max_addr_upper     : integer := 16#0000#;
           instr_mem_max_addr_lower     : integer := 16#3fff#;
           data_mem_max_addr_upper      : integer := 16#0000#; 
           data_mem_max_addr_lower      : integer := 16#ffff#;
           -- Base value of the interrupt table (mapped on data memory)
           Int_table_base : integer := 16#4000#;
           -- Instruction Address imposed at reset and reboot
           reboot_value_upper  : integer := 0;
           reboot_value_lower  : integer := 0;
           reset_value_upper   : integer := 0;
           reset_value_lower   : integer := 16#ffc#;           
           -- Default values of the Scc Registers           
           status_bits         : integer := 16#c0ff#; 
           intproc_status_bits : integer := 16#0000#;
           cause_bits          : integer := 16#0010#;
           -- Verification Parameters
           include_verify      : integer :=1;
           include_wbtrace     : integer :=1;
           include_selfprofile : integer :=1;
           include_putchar     : integer :=1 );
             
  Port (
           -- System Control Signals
           CLK               : in   Std_logic;
           reset             : in   Std_logic;
           reboot            : in   Std_logic;
           freeze            : in   Std_logic;

           -- Bus access Syncronization
           I_NREADY,D_NREADY : in   std_logic;
           I_BUSY,D_BUSY     : out  std_logic;

           -- Interrupt Vector
           INTERRUPT_VECTOR  : in   Std_logic_vector(9 downto 0) ;

           -- Instruction Bus (Harvard Architecture)
           I_ADDR_OUTBUS     : out  Std_logic_vector(Iaddr_width-1 downto 0);
           I_DATA_INBUS      : in   Std_logic_vector(Instr_width-1 downto 0);

           -- Data Bus (Harvard Architecture)
           D_ADDR_OUTBUS     : out  Std_logic_vector(Daddr_width-1 downto 0);
           D_DATA_INBUS      : in   Std_logic_vector(Word_width-1 downto 0);
           D_DATA_OUTBUS     : out  Std_logic_vector(Word_width-1 downto 0);

           mem_read          : out  Std_logic;
           mem_write         : out  Std_logic;
           mem_isbyte        : out  Std_logic;
           mem_ishalf        : out  Std_logic;

           --Dbg Signals
           dbg_enable	    : in  Std_logic;
    	   ext_bp_request   : in  Std_logic;
           end_dbg          : out Std_logic;
	   real_dbg_op	    : out Std_logic;

           -- Special Control Signals
           kernel_mode       : out Std_logic;
           suspend           : out Std_logic
           );  
end Xi_core;


Architecture structural of Xi_core is

   signal iaddr_out                   : Std_logic_vector(Iaddr_width-1 downto 0);
   signal daddr_out                   : Std_logic_vector(Daddr_width-1 downto 0);
   signal ddata_in,ddata_out          : Std_logic_vector(Word_width-1 downto 0);  
   signal idata_in                    : Std_logic_vector(Instr_width-1 downto 0);
   signal epc,PC_Basevalue            : Std_logic_vector(Iaddr_width-1 downto 0);
   signal d_bds                       : Std_logic;

   signal ibusy,dbusy                 : Std_logic;
      
-- BYPASS CONTROL SIGNALS
   -- control signals:
   signal byp_control1,byp_control2,
          byp_control3,byp_control4   : Risc_bypcontrol;
   
   -- signals carrying bypassed data:
   signal Byp1_x_op,Byp1_x_branch,
          Byp1_m_op,Byp1_m_branch     : Std_logic_vector(word_width-1 downto 0);
   signal Byp2_x_op,Byp2_x_branch,
          Byp2_m_op,Byp2_m_branch     : Std_logic_vector(word_width-1 downto 0);  
      
   -- CONTROL SIGNALS, transmitted from control_logic to the Datapath
   
   -- to decode stage      
   signal Alu_command1,Alu_command2    : alu_control;
   signal Alu_immed1,Alu_immed2        : Std_logic_vector(Word_width-1 downto 0);
   signal d_mul_command                : Risc_mulop;
   signal d_we,x_we,m_we               : Std_logic;
      
   -- to execute stage      
   signal shift_op1,shift_op2                     : Risc_shiftcode;
   signal pc_plus_4                    : Std_logic_vector(Iaddr_width-1 downto 0);  
   signal jar_in                       : Std_logic_vector(Iaddr_width-1 downto 0);
   signal exe_outsel1,exe_outsel2      : Risc_exeout;

    -- to writeback stage          
   signal x_mem_command,m_mem_command  : Mem_control;
   signal smdr_enable                  : Std_logic;
   
   signal d_jumppath,d_coppath,d_mulpath,d_mempath,x_mempath,m_mempath   : std_logic;

 
 -- REGISTER FILE CONTROL LOGIC SIGNALS -----------------------------

  -- Register File addressing      
   signal rs1_addr,rs2_addr,rcop_addr : Std_logic_vector(rf_registers_addr_width-1 downto 0);
   signal rs3_addr,rs4_addr           : Std_logic_vector(rf_registers_addr_width-1 downto 0);
   signal rd1_addr,rd2_addr           : Std_logic_vector(rf_registers_addr_width-1 downto 0);

  -- Register File Output Values
   signal rfile_out1,rfile_out2,
          rfile_out3,rfile_out4     : Std_logic_vector(word_width-1 downto 0);
      
  -- Source operands (selected between Rfile outpus and bypass channels)
  -- Please note that Branch operation feature a peculiar own bypass channel
  -- and thus they are loaded by different signals
   signal dpath_reg1,dpath_reg2      : Std_logic_vector(word_width-1 downto 0);
   signal dpath_reg3,dpath_reg4      : Std_logic_vector(word_width-1 downto 0);
   
   signal branch_reg1,branch_reg2    : Std_logic_vector(word_width-1 downto 0);
   signal branch_reg3,branch_reg4    : Std_logic_vector(word_width-1 downto 0);
   

---------------------------------------------------------------------
      
-- EXCEPTION HANDLING SIGNALS

   -- Internal Exception signals
   signal exc                        : exc_list;
   signal serve_exception            : Std_logic;
   signal serve_proc_pointer         : Std_logic_vector(7 downto 0);
   signal serve_proc_addr            : Std_logic_vector(daddr_width-1 downto 0);
   signal int_table_base_word        : Std_logic_vector(daddr_width-1 downto 0);

   -- Control_logic internal signals exported to Scc coprocessor to handle
   -- special operations:
   signal Cop_command                 : Cop_control;
   signal Cop_out                     : Std_logic_vector(word_width-1 downto 0);
   signal freezen,resetn              : Std_logic;

   -- Signals to handle the two coprocessors
   signal x_whatcop                   : std_logic_vector(1 downto 0);
   signal scc_out,fpu_out             : Std_logic_vector(word_width-1 downto 0);

   signal cop_in  : Std_logic_vector(word_width-1 downto 0);
   signal cop_imm : Std_logic_vector(4 downto 0);

   signal dcheck_enable               : std_logic;
      
   -- (Pipeline synchronization signals)     
   -- Enable signals, controlling the pipeline flow
   signal enable_f,enable_fd,enable_dx,enable_xm,enable_mw  : Std_logic;

   signal Hi,Lo : Std_logic;
      
begin

      Hi <= '1';
     
-- OUTPUT SIGNALS PROCESSING

  -- The memory control signals are transmitted outside to the data_memory.
      
  MEM_READ    <= '0' when serve_exception='0' else x_mem_command.mr;
  MEM_WRITE   <= '1' when serve_exception='0' else x_mem_command.mw;
  MEM_ISBYTE  <= '1' when serve_exception='0' else x_mem_command.mb;
  MEM_ISHALF  <= '1' when serve_exception='0' else x_mem_command.mh; 
       
  -- ADDRESS_GENERATION: In case the service of a recognized exception is
  -- acknowledged a memory access cycle is executed to determine the
  -- appropriate Servicing Procedure address.
  -- In this case the normal Alu generated address is overwritten by
  -- interrupt_table_base_address (constant described in basic.vhd) +
  -- + Exception_code *4.
  -- Note: Being produced by the data_path every address is a 32-bit number.
  -- But the output Address_bus can be configured in file basic.vhd to have
  -- a smaller width to match the chosen memory configuration:

  int_table_base_word <= Conv_std_logic_vector(Int_table_base, Daddr_width);
  
  serve_proc_addr
     <= EXT( (int_Table_base_word(Daddr_width-1 downto 8)&serve_proc_pointer),Daddr_width );
       
  INTERRUPT_ADDRESS_GENERATION :
    D_ADDR_OUTBUS <= serve_proc_addr when ( serve_exception = '0')
                         else daddr_out when (x_mem_command.mr='0' or x_mem_command.mw='0')
                              else (others=>'0');
      
  -- DATABUS HANDLING: Handling of the bidirectional data bus.
  -- A wise policy would be to leave the bidirectional bus handling to the
  -- IO Pads.
  -- As this model is aimed for the control of SOCs, this core is not meant
  -- to be synthesized as a stand alone chip.
  -- Two data bus ports have consequently been provided, and the resolution
  -- of the bidirectionality left to Highest level entities instantiating
  -- this core.
  
  D_DATA_OUTBUS <= ddata_out;
  ddata_in <= D_DATA_INBUS;

       
  -- INSTRUCTION BUS HANDLING :
  -- The instruction memory is also located outside the processor core:
  -- Consequently, the control signals for this memory must be exported

  I_ADDR_OUTBUS <= iaddr_out(iaddr_width-1 downto 3) & "000";
  idata_in      <= I_DATA_INBUS;    


  -- PIPELINE CONTROL:
  -- A peculiar feature of the Qrisc architecture is that the External memory
  -- is part of the processor pipeline. For this reason, any stall
  -- configuration on the memory model MUST involve as well the external
  -- memory, and the processor must export the pipeline control signals to the
  -- outside world.
  -- The two channels between the processor and the external world are the
  -- Idata and Ddata, so the two Istall, Dstall signals are exported to
  -- normalize the pipeline flow. Of course, these signals represent the
  -- corresponding pipeline enable signals in the processor:

    I_BUSY <= ibusy;
    D_BUSY <= dbusy;

            
  -- SUSPEND INSTRUCTION: user defined auto-freeze
  -- suspend is an assembly instruction that will auto-freeze the processor
  -- for debugging purposes. This option is hardly used when dealing with VHDL
  -- simulation, but is useful in the hardware implementation as it is used to force
  -- a freeze signal on the processor suspending the elaboration for debugging
  -- purposes               
  suspend_sig_generation:
    process(Cop_command,cop_imm)
    begin
      if ( Cop_command.op=xi_system_break and
           cop_imm=Conv_std_logic_vector(16#100#,5) ) then 
         suspend <= '0';
      else
         suspend <= '1';
      end if;
    end process;

 ------------------------------------------------------------------------------
 -- COPROCESSORS:                                                              
 -- The XiRisc processor supports a set of internal coprocessors.
 -- Usually, cop0 is conventionally intended as the System Control Coprocessor,
 -- and the XiRisc software libraries (i.e. exception handling) will use it as
 -- such, but this is not mandatory.
 -- All coprocessors are accessed through the following signals
 --      cop_index => No. of the Addressed Coprocessor
 --      cop_op    => n bits containing the operation to be performed
 --      cop_reg   => Addressed Cop Register
 --      cop_in    => Value written on the Cop Registers
 --      cop_out   => Value read from Cop Registers
 --
 -- The SCC, controlling processor status, needs to receive some additional
 -- informations but such infos are a superset of the normal coprocessor signals
 -------------------------------------------------------------------------------  

  cop_in  <= dpath_reg2 when d_coppath='0' else dpath_reg4;
  cop_imm <= Alu_immed1(4 downto 0) when d_coppath='0' else Alu_immed2(4 downto 0);
      
 SCC_LOGIC: if include_scc=1 generate       
   -- Interrupts, exceptions and special registers administration   
   
   Scc_coproc : Scc     
    generic map ( Word_Width,Iaddr_width,
                  status_bits,intproc_status_bits,cause_bits,
                  interrupt_on_exception,include_sticky_logic )
     port map ( clk,reset,reboot,freeze,
                enable_fd,enable_dx,d_we,x_we,
                Cop_command => Cop_command,
                cop_reg => rcop_addr(2 downto 0),
                cop_in  => cop_in,
                cop_out => cop_out,
                epc_out => epc,
                break_code => cop_imm,
                
                pc_basevalue => PC_Basevalue,
		
                interrupt_vector => interrupt_vector,
                exc => exc,
		
                kernel_mode => kernel_mode,
		
                serve_exception => serve_exception,
                serve_proc_pointer => serve_proc_pointer);
   
 end generate SCC_LOGIC;

 NO_SCC_LOGIC: if include_scc /= 1 generate
   cop_out            <= (others => '0');
   kernel_mode        <= '1';
   serve_exception    <= '1';
   serve_proc_pointer <= (others => '0');  
 end generate NO_SCC_LOGIC;   







--------------------------------------------------------------------------
 -- MICROPROCESSOR INTERNAL COMPONENTS
 --                     

  -- REGISTER FILE
  regfile: Double_RegFile generic map ( Word_Width,rf_registers_addr_width )
                 port map ( clk,reset,enable_mw,
                            rs1_addr,rfile_out1,
                            rs2_addr,rfile_out2,
                            rs3_addr,rfile_out3,
                            rs4_addr,rfile_out4,
                            
                            rd1_addr,Byp1_m_op,
                            rd2_addr,Byp2_m_op );


  -- BYPASS SELECTION MULTIPLEXERS
  -- The following logic determines the Datapath inputs according to the
  -- bypass mode selected by the control logic, preserving program flow
  -- consistency throughout the pipeline

  -- This Multiplexing block is described in components.vhd

  -- Bypass channels for the source operands 
  BYP_OP_MUXA: DOUBLE_BYPASS_MUX  generic map ( word_width )
                           port map ( byp_control1,rfile_out1,
                                      byp1_x_op,byp1_m_op,
                                      byp2_x_op,byp2_m_op,
                                      dpath_reg1 );
  BYP_OP_MUXB: DOUBLE_BYPASS_MUX  generic map ( word_width )
                           port map ( byp_control2,rfile_out2,
                                      byp1_x_op,byp1_m_op,
                                      byp2_x_op,byp2_m_op,
                                      dpath_reg2 );
   
  BYP_OP_MUXC: DOUBLE_BYPASS_MUX  generic map ( word_width )
                           port map ( byp_control3,rfile_out3,
                                      byp1_x_op,byp1_m_op,
                                      byp2_x_op,byp2_m_op,
                                      dpath_reg3 );
  BYP_OP_MUXD: DOUBLE_BYPASS_MUX  generic map ( word_width )
                           port map ( byp_control4,rfile_out4,
                                      byp1_x_op,byp1_m_op,
                                      byp2_x_op,byp2_m_op,
                                      dpath_reg4 );
      
  -- Bypass channels for branch operation: do not include Multiplications nor
  -- Memory access (This configuration will cause STALLS -> see xi_hazards.vhd).
  BYP_BRANCH_MUXA: DOUBLE_BYPASS_MUX  generic map ( word_width )
                               port map ( byp_control1,rfile_out1,
                                          byp1_x_branch,byp1_m_branch,
                                          byp2_x_branch,byp2_m_branch,
                                          branch_reg1 );
  BYP_BRANCH_MUXB: DOUBLE_BYPASS_MUX  generic map ( word_width )
                               port map ( byp_control2,rfile_out2,
                                          byp1_x_branch,byp1_m_branch,
                                          byp2_x_branch,byp2_m_branch,
                                          branch_reg2 );

  BYP_BRANCH_MUXC: DOUBLE_BYPASS_MUX  generic map ( word_width )
                               port map ( byp_control3,rfile_out3,
                                          byp1_x_branch,byp1_m_branch,
                                          byp2_x_branch,byp2_m_branch,
                                          branch_reg3 );
  BYP_BRANCH_MUXD: DOUBLE_BYPASS_MUX  generic map ( word_width )
                               port map ( byp_control4,rfile_out4,
                                          byp1_x_branch,byp1_m_branch,
                                          byp2_x_branch,byp2_m_branch,
                                          branch_reg4 );        
  
  
   -- The next address is saved on the Register file in case of JAL operations
   -- to be recalled in case of j r31 (end of procedure)
   jar_in <= pc_plus_4(Iaddr_width-1 downto 0);
        
   ---------------------------------------------------------------------------
   -- CONTROL BLOCK                                                         --
   ---------------------------------------------------------------------------

      Mcontrol: Double_control
        generic map ( include_scc,include_hrdwit,
                      rf_registers_addr_width,
                      Word_Width,Instr_Width,Iaddr_width,
                      reboot_value_upper,reboot_value_lower,
                      reset_value_upper,reset_value_lower )
        port map
              ( clk,reset,reboot,freeze,
                I_NREADY,D_NREADY,

                iaddr_out,idata_in,                
                branch_reg1,branch_reg2,
                branch_reg3,branch_reg4,
                
                serve_exception,
                D_DATA_INBUS(Iaddr_width-1 downto 0),

                rs1_addr,rs2_addr,rd1_addr,
                rs3_addr,rs4_addr,rd2_addr,
                rcop_addr,
                
                byp_control1,byp_control2,
                byp_control3,byp_control4,
                
                alu_command1,alu_command2,
                alu_immed1,alu_immed2,
                shift_op1,shift_op2,
                exe_outsel1,exe_outsel2,

                d_mul_command,
                d_we,x_we,m_we,

                smdr_enable,
                x_mem_command,m_mem_command,

                d_bds,
                PC_Basevalue,pc_plus_4,epc,

                d_coppath,d_mulpath,d_mempath,
                x_mempath,m_mempath,
                
                exc.illop1,exc.illop2,

                enable_f,enable_fd,enable_dx,enable_xm,enable_mw,
                ibusy,dbusy,  Cop_command);

   -----------------------------------------------------------------------   
   --                         MAIN DATAPATH                             --   
   -----------------------------------------------------------------------
       
    Mpath  : Double_channel
      generic map ( include_scc,include_fpu,include_dbg,
                    include_shift,include_rotate,
                    include_hrdwit,
                    include_mul,include_mult,include_mad,
                    include_iaddr_check,include_daddr_check,
                    shift_count_width,
                    Word_Width,Instr_Width,Daddr_width,Iaddr_width )
      
      port map ( clk,reset,freeze,
                 enable_dx,enable_xm,enable_mw,
                 d_we,x_we,m_we,
                
                 dpath_reg1,dpath_reg2,dpath_reg3,dpath_reg4,
                 alu_command1,alu_command2,
                 alu_immed1,alu_immed2,
                 shift_op1,shift_op2,
                 exe_outsel1,exe_outsel2,
                 d_mul_command,
                
                 smdr_enable,               
                 m_mem_command,

                 jar_in,cop_out,

                 d_mulpath,d_mempath,
                 x_mempath,m_mempath,

                 Byp1_x_op,Byp1_x_branch,
                 Byp1_m_op,Byp1_m_branch, 
                 Byp2_x_op,Byp2_x_branch,
                 Byp2_m_op,Byp2_m_branch,
                 
                 exc.alu_oflow1,exc.alu_oflow2,
                 exc.Mad_oflow,
                 
                 daddr_out,ddata_in,ddata_out  );
      

  -----------------------------------------------------------------------------
  -- MEMORY ADDRESSING CONTROL LOGIC    --
  -----------------------------------------------------------------------------
              
    --- Instruction Memory Invalid Address configuration detection ----------   
      -- The next instruction address, produced by the DecodePc logic,
      -- is checked for invalid address configuration exceptions.
      -- 
    MEMORY_CHECKS: if include_scc = 1 generate
      
     IMEM_ADDRESS_CHECK: if include_iaddr_check = 1 generate
        
         i_chk : addrchk generic map ( Iaddr_width,
                                       imem_lowerlimitation_control,
                                       imem_upperlimitation_control,
                                       instr_mem_end_value_lower,
                                       instr_mem_end_value_upper,
                                       instr_mem_init_value_lower,
                                       instr_mem_init_value_upper )
                         port map   (  iaddr_out,   
                                       exc.imem_inv_addr,
                                       exc.imem_misalign,
                                       exc.imem_prot_warn,
                                       Lo,
                                       Hi,Hi );
     end generate;

     IMEM_ADDRESS_NOCHECK:if include_iaddr_check = 0 generate
       exc.imem_inv_addr     <= '1';
       exc.imem_misalign     <= '1';
       exc.imem_prot_warn    <= '1';
     end generate;
    
     --------- Data Memory Invalid Address configuration detection logic --
      -- The address produced by the alu is checked for invalid address
      -- configuration exception before it is handed over to the Memory access
      -- stage.
      -- This operation is performed only in case of memory accesses and only
      -- if the scc coprocessor is included in the design

     DMEM_ADDRESS_CHECK: if include_daddr_check = 1 generate
       process(x_mem_command)
       begin
         if (x_mem_command.mr='0' or x_mem_command.mw='0') then
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
                                     data_mem_init_value_upper )
                       port map   (  daddr_out,
                                     exc.dmem_inv_addr,
                                     exc.dmem_misalign,
                                     exc.dmem_prot_warn,
                                     dcheck_enable,
                                     x_mem_command.mb,x_mem_command.mh );
     end generate;
      
     DMEM_ADDRESS_NOCHECK:if include_daddr_check = 0 generate
        exc.dmem_inv_addr    <= '1';
        exc.dmem_misalign    <= '1';
        exc.dmem_prot_warn   <= '1';
     end generate;

   end generate;
            
end STRUCTURAL;

