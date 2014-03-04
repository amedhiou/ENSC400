---------------------------------------------------------------------------
--                    XI_Mainchannel.vhd                                 --
--                                                                       --
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
-- This license is a modification of the Cadence Design Systems Source Code Public
-- License Version 1.0 which is similar to the Netscape public license.
-- We believe this license conforms to requirements adopted by OpenSource.org.
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- This logic block represents the Main datapath of the processor model.
------------------------------------------------------------------------
--                ENTITY DEFINITION
------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;  
  use work.basic.all;  
  use work.components.all;
  use work.isa_32.all;
  use work.definitions.all;

entity Main_channel is
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
end Main_channel;


---------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
---------------------------------------------------------------------------

architecture structural of Main_channel is
  
   -- Signals implementing the data flow through the five stages
      
   signal in_rega, in_regb           : Std_logic_vector(word_width-1 downto 0);
   signal out_regA,out_regB          : Std_logic_vector(word_width-1 downto 0);
   signal Alu_in1,Alu_in2            : Std_logic_vector(word_width-1 downto 0);
   signal shamt                      : Std_logic_vector(shift_count_width-1 downto 0);
   signal Alu_result,Shift_result,
          Mult_result                : Std_logic_vector(word_width-1 downto 0);
   signal out_jar                    : Std_logic_vector(iaddr_width-1 downto 0);
   signal long_out_jar               : Std_logic_vector(word_width-1 downto 0);
   signal in_regM, out_regM          : Std_logic_vector(word_width-1 downto 0);
   signal rfile_in                   : Std_logic_vector(word_width-1 downto 0);
   signal mem_baddr                  : Std_logic_vector(1 downto 0);
   
   
   -- Signals handling the input from external data memory
   signal read_data  : Std_logic_vector(word_width-1 downto 0);
   
   -- Logic '0' signal, used to feed the enable input ports in those
   -- registers that must be kept always active and sampling.
   signal Lo : Std_logic;
   
   signal constant_1 : Std_logic_vector(word_width-1 downto 0);

   
begin

   Lo <= '0';
   constant_1 <= Conv_std_logic_vector(1,word_width);
   
   -- Alu Result, Used as data memory address
   ADDRESS_BUS <= Alu_result(Daddr_width-1 downto 0);

--------------------------DECODE STAGE-----------------------------------

 -- Alu operands selection mux !!!!!!!!!!!!
   
   in_rega <= rs1_data;

    -- SECOND ALU INPUT is Selected between the register file output B,
    -- that is rs1 value, and the Constant 1, enabled in case of Hardware
    -- iteration instructions, and immediate in case of immediate-based instructions
    -- Note: Memory access operation are by all means immediate- based;
    -- in case of stores the data to be stored is not passed as operand through
    -- this register but is handled separately by the memhandle block.
   
   RegB_Input_MUX: process(alu_command,rs2_data,constant_1,alu_immed)
   begin
     if alu_command.isel = '0' then
        -- Immediate operation
        in_regb <= alu_immed;        
     elsif alu_command.hrdwit = '0' and include_hrdwit=1 then
        -- Hardware Iteration
        in_regb <= constant_1;
     else
        -- Normal Alu-based operation
        in_regb <= rs2_data;
     end if;
   end process;
                
------------------------EXECUTE  STAGE-----------------------------------
  
  -- Input Registers to the Execute Stage: 
  -- RegA and RegB hold the Alu_operands (B can be substituted by Immediate 
  -- operand in case of Register/Immediate operations).  
             
    regA  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regA,out_regA );
    regB  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regB,out_regB ); 


-- FUNCTIONAL UNITS IN THE EXECUTE STAGE
--
-- 1) THE ALU -----------------------------------------------------------------    
   
    Alu_in1 <= out_regA;
    Alu_in2 <= out_regB;         

   -- MAIN ALU, it is the core of the execution stage.
   -- It is controlled by a set of signals generated by the control logic.
                            
   the_alu : Main_Alu generic map ( Word_Width )
                      port map ( alu_in1,alu_in2,alu_command.op,
                                 alu_result,alu_oflow );

   
-- 2) SHIFTER -----------------------------------------------------------------
    
SHIFT_LOGIC : if include_shift = 1 generate
    
    shamt <= out_regB(shift_count_width-1 downto 0);  
    the_shift : Shifter generic map ( Word_Width,shift_count_width,include_rotate) 
                        port map ( out_regA,shift_op,shamt,shift_result );
    
end generate SHIFT_LOGIC;
    
NO_SHIFT_LOGIC : if include_shift /= 1 generate
    shift_result <= (others => '0');  
end generate NO_SHIFT_LOGIC;    

                 
-- 3) MULTIPLIER --------------------------------------------------------------    
    
MULTIPLICATION_LOGIC: if (include_mad=1 or include_mul=1 or include_mult=1 ) generate
   the_mult : mult_block
              generic map (Word_Width,
                           include_mul,include_mult,include_mad)     
              port map ( clk,reset,
                         en_dx,en_xm,en_mw,m_we,
                         mul_command,
                         in_regA,in_regB,Mult_result,mad_oflow );
 
end generate MULTIPLICATION_LOGIC;
    
NO_MULTIPLICATION_LOGIC: if (include_mult/=1 and include_mad/=1 and
                             include_mul/=1) generate  
  Mult_result   <= (others => '0');
  mad_oflow     <= '1';
end generate NO_MULTIPLICATION_LOGIC;  
                         
 -- 4) JUMP AND LINK REGISTER (Writebacks current PC on $31) ------------------
   
  -- Jumpandlink_Return_Address_Register
  -- It is used as a path to Writeback the current_pc value over the link
  -- register in case of Jump and link instructions.
    
  JAR : Data_Reg generic map ( init_value => 0,
                               reg_width  => Iaddr_width)
                 port map ( clk,reset,en_dx,jar_in,out_jar );

   long_out_jar <= EXT(out_jar,word_width);

                         
  -- ALU OUTPUT SELECTION:
  -- Multiplexer Used to select the value to be forwarded from the
  -- execute stage to the following pipeline stages:
  -- 1) (default) The alu_result signal
  -- 2) The shift_result signal
  -- 3) The JAR register value in case of JAL instructions to writeback the
  --    return address.
  -- 4) One of the multiplication storing Registers or Mac accumulation
  --    registers

   EXEOUT_MUX : process(alu_result,shift_result,mult_result,cop_output,long_out_jar,exe_outsel)
    begin
      if exe_outsel = xi_shift(5 downto 3) and (include_shift=1) then
         in_regM <= shift_result;
      elsif exe_outsel = xi_mul(5 downto 3) and (include_mul=1 or include_mult=1 or include_mad=1) then
         in_regM <= mult_result;
      elsif exe_outsel = xi_jal(5 downto 3) then
         in_regM <= long_out_jar;
      elsif exe_outsel = xi_cop(5 downto 3) and (include_scc=1 or include_fpu=1 or include_dbg=1) then
         in_regM <= cop_output;
      else
         in_regM <= alu_result;
      end if;
    end process;

  -----------------------------------------------------------------------------    
  -- Bypass channels:
  -- The bypass channels are different depending on the utilization of the
  -- bypassed value:
  -- Operand bypass: This value is simply stored (Alternatively to the rfile
  --                 read value) on the Reg_A, Reg_B operand registers that reside
  --                 in at the beginning of the execution stage.
  --                 Branch argument bypass: On the contrary, to limit the critical
  --                 path, the branch instructions (that involve a long
  --                 combinatorial computation in the decode stage) will
  --                 receive only bypass that do not imply long paths BEFORE
  --                 the bypass step. So Memory reads are not bypassed from
  --                 the memory stage to branches, nor Multiplication results
  --                 from the execute stage.
  -- Of course, this "depopulation" of the branch writeback channel make sense
  -- only if coupled with an appropriate stall logic that will avoid the
  -- utilization of the "depopulated" channel that would have costed not
  -- acceptable critical paths
    
  BYPOP_EXE_VALUE :  bypa_x_op <= in_regM; 
    
  BYPBRANCH_EXE_MUX : process(alu_result,shift_result,cop_output,long_out_jar,exe_outsel)
    begin
      if exe_outsel = xi_shift(5 downto 3) and (include_shift=1) then
         bypa_x_branch <= shift_result;
      elsif exe_outsel = xi_jal(5 downto 3) then
         bypa_x_branch <= long_out_jar;
      elsif exe_outsel = xi_read_cop(5 downto 3) and (include_scc=1) then
         bypa_x_branch <= cop_output;
      else
         bypa_x_branch <= alu_result;
      end if;
    end process;
      
  BYPOP_MEM_VALUE : bypa_m_op         <= rfile_in;
  BYPBRANCH_MEM_VALUE : bypa_m_branch <= out_regM;

  -----------------------------------------------------------------------------

    
  --------------------------MEMORY ACCESS STAGE------------------------------

  -- Writeback value coming from Exe stage (Alu, Mul, Jar or Cop read)
  regM: Data_Reg
     generic map ( reg_width => word_width )
     port map ( clk,reset,en_xm,in_regM,out_regM );

  regMaddr: Data_Reg
    generic map (reg_width => 2 )
    port map ( clk,reset,en_xm,Alu_result(1 downto 0),mem_baddr);

  -- Memory access handling
  -- read_data is the value produced by an eventual memory read operation
  the_memhandle :
    Mem_handle generic map (Word_Width)
               port map ( clk,reset,
                          smdr_enable,mem_baddr,                         
                          rs2_data,read_data,
                          x_mem_command,m_mem_command,
                          DATA_IN,DATA_OUT );
       
  -- WRITEBACK_SELECTION: Selection of Writebacked data: The Alu output
  -- is the default option, but in case of memory read is the data_bus
  -- value to be forced to the next stage.
	     
  WB_IN_MUX:
    rfile_in <= read_data when (m_mem_command.mr = '0') else out_regM;

  -- The Writeback stage consists simply in the writing of the rfile_in value
  -- on the clock rising edge. There is no disabling this stage, and as well no
  -- writeback is performed
    
end structural;


