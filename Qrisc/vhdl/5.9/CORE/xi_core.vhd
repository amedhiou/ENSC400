------------------------------------------------------------------------ 
--                             XI_CORE.VHD                            --
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

-- This Block is the top level entity of the processor model.
-- It synchronizes the functioning of the Datapath, the
-- Control_logic and the System Control Coprocessor.


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_unsigned.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;
  use work.components.all;
  use work.definitions.all;

  use work.scc_pack.all;
  use work.cop_pack.all;
  use work.dbg_pack.all;
  

-- PROCESSOR CORE INTERFACE             --  --  --  --  --  --  --  --  --  --
-- As the processor is highly reconfigurable, many parameters can be set at
-- compilation time in order to customize the processor architecture.
  
entity Xi_core is
  generic(
           -- ARCHITECTURE DEFINITION 
           -- System Control Coprocessor is the coprocessor handling interrupts
           -- and exceptions
           include_scc : integer:= 1;           
           -- Floating point Unit
           include_fpu     : integer := 0;
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
           include_mul     : integer := 0;
           include_mult    : integer := 0;
           include_mad     : integer := 0;
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
           Instr_Width     : positive := 32;
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
           reset_value_lower   : integer := 16#1000#;           
           -- Default values of the Scc Registers           
           status_bits         : integer := 16#c0ff#; 
           intproc_status_bits : integer := 16#0000#;
           cause_bits          : integer := 16#0010#);
  
           
  Port (   -- System Control Signals
           CLK               : in   Std_logic;
           reset             : in   Std_logic;
           reboot            : in   Std_logic;
           freeze            : in   Std_logic;

           -- Bus access Syncronization
           I_NREADY,D_NREADY : in   std_logic;
           I_BUSY,D_BUSY     : out  std_logic;

           -- Interrupt Vector
           INTERRUPT_VECTOR  : in   Std_logic_vector(7 downto 0) ;

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
--                                      --  --  --  --  --  --  --  --  --  --
                                      

Architecture structural of Xi_core is

   
   signal iaddr_out                   : Std_logic_vector(Iaddr_width-1 downto 0);
   signal daddr_out,daddr_outbus      : Std_logic_vector(Daddr_width-1 downto 0);   
   signal ddata_in,ddata_out          : Std_logic_vector(Word_width-1 downto 0);  
   signal idata_in                    : Std_logic_vector(Instr_width-1 downto 0);
   signal epc,PC_Basevalue            : Std_logic_vector(Iaddr_width-1 downto 0);
   signal d_bds                       : Std_logic;

   signal ibusy,dbusy                 : Std_logic;
      
-- BYPASS CONTROL SIGNALS
   -- control signals:
   signal byp_controlA,byp_controlB   : Risc_bypcontrol;
   -- signals carrying bypassed data:
   signal Bypa_x_op,Bypa_x_branch,
          Bypa_m_op,Bypa_m_branch     : Std_logic_vector(word_width-1 downto 0);
      
   -- CONTROL SIGNALS, transmitted from control_logic to the Datapath
   
   -- to decode stage      
   signal Alu_command                  : alu_control;
   signal Alu_immed                    : Std_logic_vector(Word_width-1 downto 0);
   signal d_mul_command                : Risc_mulop;
   signal d_we,x_we,m_we               : Std_logic;
      
   -- to execute stage      
   signal shift_op                     : Risc_shiftcode;
   signal pc_plus_4                    : Std_logic_vector(Iaddr_width-1 downto 0);  
   signal jar_in                       : Std_logic_vector(Iaddr_width-1 downto 0);
   signal exe_outsel                   : Risc_exeout;
        
   -- to writeback stage          
   signal x_mem_command,m_mem_command  : Mem_control;
   signal smdr_enable                  : Std_logic;

      
-- REGISTER FILE CONTROL LOGIC SIGNALS -----------------------------

  -- Register File addressing      
   signal rs1_addr,rs2_addr,rcop_addr : Std_logic_vector(rf_registers_addr_width-1 downto 0);
   signal rd_addr                    : Std_logic_vector(rf_registers_addr_width-1 downto 0);

  -- Register File Output Values
   signal rfile_out1,rfile_out2      : Std_logic_vector(word_width-1 downto 0);
      
  -- Source operands (selected between Rfile outpus and bypass channels)
  -- Please note that Branch operation feature a peculiar own bypass channel
  -- and thus they are loaded by different signals
   signal dpath_rega,dpath_regb      : Std_logic_vector(word_width-1 downto 0);
   signal branch_rega,branch_regb    : Std_logic_vector(word_width-1 downto 0);

---------------------------------------------------------------------         
      
-- EXCEPTION HANDLING SIGNALS

   -- Internal Exception signals
   signal exc                        : exc_list;
   signal serve_exception            : Std_logic;
   signal serve_proc_pointer         : Std_logic_vector(7 downto 0);
   signal serve_proc_addr            : Std_logic_vector(daddr_width-1 downto 0);
   signal int_table_base_word        : Std_logic_vector(daddr_width-1 downto 0);
   signal interrupt_vector_int       : Std_logic_vector(9 downto 0);
   signal break_code                 : Std_logic_vector(word_width-1 downto 0);
   signal bp_detect                  : Std_logic;

   -- Control_logic internal signals exported to Scc coprocessor to handle
   -- special operations:
   signal Cop_command,Cop_command_0   : Cop_control;
   signal Cop_out                     : Std_logic_vector(word_width-1 downto 0);
   signal freezen,resetn              : Std_logic;

   -- Signals to handle the two coprocessors
   signal x_whatcop                   : std_logic_vector(1 downto 0);
   signal scc_out,fpu_out             : Std_logic_vector(word_width-1 downto 0);
   signal fpu_stall                   : Std_logic;

   signal dcheck_enable               : std_logic;
      
   -- (Pipeline synchronization signals)     
   -- Enable signals, controlling the pipeline flow
   signal enable_f,enable_fd,enable_dx,enable_xm,enable_mw  : Std_logic;

   -- Coprocessor handle signals
   signal cop_write,cop_read            : Std_logic;
   signal cop_instruction,cop_input     : Std_logic_vector(word_width-1 downto 0);
   signal cop_reg_in                    : Risc_regaddr;
   signal fpu_out_reg                   : Std_logic_vector(word_width-1 downto 0);

   -- Signals to handle the dgb coprocessor
   signal dbg_out                       : Std_logic_vector(word_width-1 downto 0);
   signal kernel_mode_int               : Std_logic;

   signal Hi,Lo : Std_logic;
      
begin

  Hi <= '1';
  Lo <= '0';
      
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
    daddr_outbus <= serve_proc_addr when ( serve_exception = '0')
                         else daddr_out when (x_mem_command.mr='0' or x_mem_command.mw='0')
                              else (others=>'0');

  -- DATABUS HANDLING:
  -- A wise policy would be to leave the bidirectional bus handling to the
  -- IO Pads. As this model is aimed for the control of SOCs, this core is not meant
  -- to be synthesized as a stand alone chip.
  -- Two data bus ports have consequently been provided, and the resolution
  -- of the bidirectionality left to Highest level entities instantiating
  -- this core in case the bus has to be carried offchip. If this is not the
  -- case,as in any digital design, it is wise to leave all busses
  -- monodirectional. Good memory models and bus architectures have a healthy
  -- horror for 3-state logic !

    D_ADDR_OUTBUS <= daddr_outbus;
  
    D_DATA_OUTBUS <= ddata_out;
    ddata_in <= D_DATA_INBUS;
       
  -- INSTRUCTION BUS HANDLING :
  -- The instruction memory is also located outside the processor core:
  -- Consequently, the control signals for this memory must be exported. Same
  -- horror for bidirectionality and 3state applies!

    I_ADDR_OUTBUS <= iaddr_out(iaddr_width-1 downto 2) & "00";
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
    process(Cop_command,Alu_immed)
    begin
      if ( (Cop_command.op = xi_system_break) and
           (Alu_immed = Conv_std_logic_vector(break_suspend,word_width)) ) then
         suspend <= '0';
      else
         suspend <= '1';
      end if;
    end process; 

  break_code <= Alu_immed;
  
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
            
 SCC_LOGIC: if include_scc=1 generate       
   -- Interrupts, exceptions and special registers administration

   interrupt_vector_int <= interrupt_vector & "0" & bp_detect;
   
   Scc_coproc : Scc     
    generic map ( Word_Width,Iaddr_width,
                  status_bits,intproc_status_bits,cause_bits,
                  interrupt_on_exception,include_sticky_logic )
     port map ( clk,reset,reboot,freeze,
                enable_fd,enable_dx,d_we,x_we,
                Cop_command => Cop_command,
                cop_reg => rcop_addr(2 downto 0),
                cop_in  => dpath_regb,
                cop_out => scc_out,
                epc_out => epc,
                break_code => break_code(4 downto 0),
                
                pc_basevalue => PC_Basevalue,
		
                interrupt_vector => interrupt_vector_int,
                exc => exc,
		
                kernel_mode => kernel_mode_int,
		
                serve_exception => serve_exception,
                serve_proc_pointer => serve_proc_pointer);
   
 end generate SCC_LOGIC;

 NO_SCC_LOGIC: if include_scc /= 1 generate
   cop_out            <= (others => '0');
   kernel_mode_int    <= '1';
   serve_exception    <= '1';
   serve_proc_pointer <= (others => '0');  
 end generate NO_SCC_LOGIC;   


  FPU_LOGIC: if include_fpu=1 generate
    
  -----------------------------------------------------------------------------
  --FPU LOGIC------------------------------------------------------------------
  -----------------------------------------------------------------------------
  
  --cop read/write enable------------------------------------------------------
      
  READ_WRITE: process(lo,hi,cop_command)
    begin
      if (cop_command.op = xi_system_wcop) or  (cop_command.op = fpu_add) or
         (cop_command.op = fpu_sub) or (cop_command.op = fpu_mul) or (cop_command.op = fpu_div) or
         (cop_command.op = fpu_sqrt) or (cop_command.op = fpu_abs) or (cop_command.op = fpu_mov) or
         (cop_command.op = fpu_neg) or (cop_command.op = fpu_cvt_s) or
         (cop_command.op = fpu_cvt_w) then
        cop_write <= Hi;
        cop_read <= Lo;
      elsif (cop_command.op = xi_system_rcop) then
        cop_write <= Lo;
        cop_read <= Hi;
      else
        cop_write <= Lo;
        cop_read <= Lo;
      end if;
    end process;
    
  -----------------------------------------------------------------------------

  cop_instruction <=(("00000000000")&(rs2_addr)&(rs1_addr)&(rcop_addr)&(cop_command.op));
                    
  --cop input signal selection-------------------------------------------------

  IN_COP: process(cop_command, cop_instruction, dpath_regb)
   begin
     if cop_command.op = xi_system_wcop then
         cop_input <= dpath_regb;
     else
         cop_input <= cop_instruction;
     end if;
   end process;
   
  REG_IN_COP: process(rcop_addr,cop_command)
    begin
      if (cop_command.op = xi_system_wcop) or (cop_command.op = xi_system_rcop) then
        cop_reg_in <= rcop_addr;
      else
        cop_reg_in <= "01000";
      end if;
    end process;
     
  -- Arithmetic Coprocessor
    resetn  <= not reset;
    
    Fpu_coproc : Cop port map
      ( clk             => clk,
        reset           => resetn,
        enable          => freeze,
        rd_cop          => cop_read,
        wr_cop          => cop_write,
        c_index         => Cop_command.index, 
        r_index         => cop_reg_in(3 downto 0),
        cop_in          => cop_input,
        cop_out         => fpu_out,
        cop_exc         => exc.fpu,
        cop_stall       => fpu_stall );          

    
  FPU_OUT_DATA_REG :Data_reg generic map (reg_width => word_width)
                        port map (clk,reset,enable_dx,fpu_out,fpu_out_reg);
                        
 end generate FPU_LOGIC;

  
 NO_FPU_LOGIC: if include_fpu=0 generate
    fpu_out_reg <= ( others => '0');   
    exc.fpu   <= '1';
    fpu_stall <= '1';
 end generate NO_FPU_LOGIC;    

  
-------------------------------------------------------------------------------
--DBG LOGIC--------------------------------------------------------------------
-------------------------------------------------------------------------------
  
  DBG_LOGIC: if include_dbg=1 generate
  --    -- Debug Coprocessor

   Dbg_coproc: Dbg port map(
        clk, reset, reboot, freeze,
        kernel_mode_int,
        enable_dx,d_we, d_bds, epc, Cop_command,
        dpath_regb,dbg_out,rcop_addr,
        pc_basevalue,dbg_enable,ext_bp_request,
        end_dbg,real_dbg_op,bp_detect );

   end generate DBG_LOGIC;

   NO_DBG_LOGIC: if include_dbg/=1 generate
        dbg_out        <= (others => '0');
        end_dbg            <= '0';
        bp_detect          <= '0';
        real_dbg_op	   <= '0';
   end generate;

   kernel_mode <= kernel_mode_int;
   
  -----------------------------------------------------------------------------
  --COP SELECTION MULTIPLEXER--------------------------------------------------
  -----------------------------------------------------------------------------

   COP1_OUT_REG:  Data_reg generic map (reg_width=>2)
     port map ( clk,reset, enable_dx,
                Cop_command.index,x_whatcop);
   
  COP_OUT_MUX: process(scc_out,fpu_out_reg,dbg_out,x_whatcop)
   begin
     if x_whatcop="00" and include_scc=1 then
        cop_out <= scc_out;                            
     elsif x_whatcop="01" and include_fpu=1 then
        cop_out <= fpu_out_reg;
     elsif x_whatcop = "10" and include_dbg=1 then
        cop_out <= dbg_out;
     else
        cop_out <= (Others=>'0');
     end if;
  end process;

     
--------------------------------------------------------------------------
 -- MICROPROCESSOR INTERNAL COMPONENTS
 --                     

  -- REGISTER FILE
  regfile: Rfile generic map ( Word_Width,rf_registers_addr_width )
                 port map ( clk,reset,enable_mw,
                            rs1_addr,rfile_out1,
                            rs2_addr,rfile_out2,
                            rd_addr,Bypa_m_op );
       
  -- BYPASS SELECTION MULTIPLEXERS
  -- The following logic determines the Datapath inputs according to the
  -- bypass mode selected by the control logic, preserving program flow
  -- consistency throughout the pipeline

  -- This Multiplexing block is described in components.vhd

  -- Bypass channels for the source operands 
  BYP_OP_MUXA: BYPASS_MUX  generic map ( word_width )
                           port map ( byp_controlA,rfile_out1,
                                      bypa_x_op,bypa_m_op,dpath_rega );
  BYP_OP_MUXB: BYPASS_MUX  generic map ( word_width )
                           port map ( byp_controlB,rfile_out2,
                                      bypa_x_op,bypa_m_op,dpath_regb );    

  -- Bypass channels for branch operation: do not include Multiplications nor
  -- Memory access (This configuration will cause STALLS -> see xi_hazards.vhd).
  BYP_BRANCH_MUXA: BYPASS_MUX  generic map ( word_width )
                               port map ( byp_controlA,rfile_out1,
                                          bypa_x_branch,bypa_m_branch,branch_rega );
  BYP_BRANCH_MUXB: BYPASS_MUX  generic map ( word_width )
                               port map ( byp_controlB,rfile_out2,
                                          bypa_x_branch,bypa_m_branch,branch_regb );
  
  
   -- The next address is saved on the Register file in case of JAL operations
   -- to be recalled in case of j r31 (end of procedure)
   jar_in <= pc_plus_4(Iaddr_width-1 downto 0);
  
   ---------------------------------------------------------------------------
   -- CONTROL BLOCK                                                         --
   ---------------------------------------------------------------------------

      Mcontrol: Main_control
        generic map ( include_scc,include_hrdwit,
                      rf_registers_addr_width,
                      Word_Width,Instr_Width,Iaddr_width,
                      reboot_value_upper,reboot_value_lower,
                      reset_value_upper,reset_value_lower )
        port map
              ( clk,reset,reboot,freeze,
                I_NREADY,D_NREADY,

                iaddr_out,idata_in,                
                branch_rega,branch_regb,
                
                serve_exception,
                D_DATA_INBUS(Iaddr_width-1 downto 0),

                rs1_addr,rs2_addr,rcop_addr,rd_addr,
                
                byp_controlA,byp_controlB,
                
                alu_command,alu_immed,
                shift_op,exe_outsel,

                d_mul_command,
                d_we,x_we,m_we,

                smdr_enable,
                x_mem_command,m_mem_command,

                d_bds,
                PC_Basevalue,pc_plus_4,epc,
                exc.illop1,

                enable_f,enable_fd,enable_dx,enable_xm,enable_mw,
                ibusy,dbusy,

                fpu_stall,Cop_command_0);

       
   -----------------------------------------------------------------------   
   --                         MAIN DATAPATH                             --   
   -----------------------------------------------------------------------
       
    Mpath  : Main_channel
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
                
                 dpath_rega,dpath_regb,
                 alu_command,alu_immed,shift_op,
                 exe_outsel,d_mul_command,
                
                 smdr_enable,               
                 x_mem_command,m_mem_command,

                 jar_in,cop_out,

                 Bypa_x_op,Bypa_x_branch,
                 Bypa_m_op,Bypa_m_branch,
                 exc.alu_oflow1,exc.Mad_oflow,
                 daddr_out,ddata_in,ddata_out  );

  -- Exception signals due to double dpath, are set to Vdd in the single dpath
  -- version
  exc.illop2     <= '1';
  exc.alu_oflow2 <= '1';
  exc.fpu        <= '1';
  
  
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


