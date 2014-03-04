---------------------------------------------------------------------------
--                    XI_Double_channel.vhd                              --
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


-- This logic block represents the two data channels of the processor model.
-- Here are described all the elaboration resources of the whole processor.
-- Some of them are duplicated between the two channels (Alu, Shifter ),
-- others are shared between the two.
-- 
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

entity Double_channel is
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
end Double_channel;


---------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
---------------------------------------------------------------------------

architecture structural of Double_channel is
  
   -- Signals implementing the data flow through the five stages

   signal in_rega,in_regb,in_regc,in_regd      : Std_logic_vector(word_width-1 downto 0);
   signal out_regA,out_regB,out_regC,out_regD  : Std_logic_vector(word_width-1 downto 0);
   signal Alu1_in1,Alu1_in2,Alu2_in1,Alu2_in2  : Std_logic_vector(word_width-1 downto 0);
   signal shamt1,shamt2                        : Std_logic_vector(shift_count_width-1 downto 0);
   signal Alu_result1,Alu_result2              : Std_logic_vector(word_width-1 downto 0);
   signal Shift_result1,Shift_result2          : Std_logic_vector(word_width-1 downto 0);

   signal Mult_in1,Mult_in2                    : Std_logic_vector(word_width-1 downto 0);
   signal Mult_result                          : Std_logic_vector(word_width-1 downto 0);
   signal out_jar                              : Std_logic_vector(iaddr_width-1 downto 0);
   signal long_out_jar                         : Std_logic_vector(word_width-1 downto 0);
   signal in_regM1, out_regM1                  : Std_logic_vector(word_width-1 downto 0);
   signal in_regM2, out_regM2                  : Std_logic_vector(word_width-1 downto 0);
   signal rfile_in1,rfile_in2                  : Std_logic_vector(word_width-1 downto 0);
   signal MemHandle_in                         : Std_logic_vector(word_width-1 downto 0);
   
   
   -- Signals handling the input from external data memory
   signal read_data  : Std_logic_vector(word_width-1 downto 0);

   -- Logic '0' signal, used to feed the enable input ports in those
   -- registers that must be kept always active and sampling.
   signal Lo : Std_logic;   
   signal constant_1 : Std_logic_vector(word_width-1 downto 0);
    
begin

   Lo <= '0';
   constant_1 <= Conv_std_logic_vector(1,word_width);

   -- Address Bus selects the appropriate alu channel output
   ADDRESS_BUS <= Alu_result1(Daddr_width-1 downto 0) when x_mempath='0'
                        else Alu_result2(Daddr_width-1 downto 0);


   --------------------------DECODE STAGE-----------------------------------

   
 -- Alu operands selection mux !!!!!!!!!!!!
   
   in_rega <= rs1_data;
   in_regc <= rs3_data;

    -- SECOND ALU INPUT is Selected between the register file output B,
    -- that is rs1 value, and the Constant 1, enabled in case of Hardware
    -- iteration instructions, and immediate in case of immediate-based instructions
    -- Note: Memory access operation are by all means immediate- based;
    -- in case of stores the data to be stored is not passed as operand through
    -- this register but is handled separately by the memhandle block.
   
   RegB_Input_MUX: process(alu_command1,rs2_data,constant_1,alu_immed1)
   begin
     if alu_command1.isel = '0' then
        -- Immediate operation
        in_regb <= alu_immed1;        
     elsif alu_command1.hrdwit = '0' and include_hrdwit=1 then
        -- Hardware Iteration
        in_regb <= constant_1;
     else
        -- Normal Alu-based operation
        in_regb <= rs2_data;
     end if;
   end process;

  RegD_Input_MUX: process(alu_command2,rs4_data,constant_1,alu_immed2)
   begin
     if alu_command2.isel = '0' then
        -- Immediate operation
        in_regd <= alu_immed2;        
     elsif alu_command2.hrdwit = '0' and include_hrdwit=1 then
        -- Hardware Iteration
        in_regd <= constant_1;
     else
        -- Normal Alu-based operation
        in_regd <= rs4_data;
     end if;
   end process;   


  ------------------------EXECUTE  STAGE-----------------------------------
  
  -- Input Registers to the Execute Stage: 
  -- RegA,C and RegB,D hold the Alu_operands (B,D can be substituted by Immediate 
  -- operand in case of Register/Immediate operations).  
             
    regA  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regA,out_regA );
    regB  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regB,out_regB );
   
    regC  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regC,out_regC );
    regD  : Data_Reg
      generic map (reg_width => word_width)
      port map ( clk,reset,en_dx,in_regD,out_regD );   


-- FUNCTIONAL UNITS IN THE EXECUTE STAGE
--
-- 1) THE ALUS -----------------------------------------------------------------    
   
    Alu1_in1 <= out_regA;
    Alu1_in2 <= out_regB;

    Alu2_in1 <= out_regC;
    Alu2_in2 <= out_regD;

   -- MAIN ALUs, the core of the execution stage.
   -- They are controlled by a set of signals generated by the control logic.
                            
   the_alu1 : Main_Alu generic map ( Word_Width )
                       port map ( alu1_in1,alu1_in2,alu_command1.op,
                                  alu_result1,alu_oflow1 );

   the_alu2 : Main_Alu generic map ( Word_Width )
                       port map ( alu2_in1,alu2_in2,alu_command2.op,
                                  alu_result2,alu_oflow2 );
   

 -- 2) SHIFTERS -----------------------------------------------------------------
    
SHIFT_LOGIC : if include_shift = 1 generate
    
    shamt1 <= out_regB(shift_count_width-1 downto 0);
    shamt2 <= out_regD(shift_count_width-1 downto 0);
    
    the_shift1 : Shifter generic map ( Word_Width,shift_count_width,include_rotate) 
                         port map ( out_regA,shift_op1,shamt1,shift_result1 );

    the_shift2 : Shifter generic map ( Word_Width,shift_count_width,include_rotate) 
                         port map ( out_regC,shift_op2,shamt2,shift_result2 );        
    
end generate SHIFT_LOGIC;

   
NO_SHIFT_LOGIC : if include_shift /= 1 generate
    shift_result1 <= (others => '0');
    shift_result2 <= (others => '0');
end generate NO_SHIFT_LOGIC;      

   
   
 -- 3) MULTIPLIER --------------------------------------------------------------    

   
   -- MULT INPUT MULTIPLEXERS: Driving Datapath resolution
MULTIPLICATION_LOGIC: if (include_mad=1 or include_mul=1 or include_mult=1 ) generate

   -- MULT INPUT MULTIPLEXERS: Driving Datapath resolution
  MULTIN1_MUX: mult_in1 <= in_regA when d_mulpath='0' else in_regC;
  MULTIN2_MUX: mult_in2 <= in_regB when d_mulpath='0' else in_regD;
                         
   the_mult : mult_block
              generic map (Word_Width,
                           include_mul,include_mult,include_mad)     
              port map ( clk,reset,
                         en_dx,en_xm,en_mw,m_we,
                         mul_command,
                         mult_in1,mult_in2,Mult_result,mad_oflow );
 
end generate MULTIPLICATION_LOGIC;
    
NO_MULTIPLICATION_LOGIC: if (include_mult/=1 and include_mad/=1 and include_mul/=1) generate  
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

   EXEOUT_MUX1 : process(alu_result1,shift_result1,mult_result,cop_output,long_out_jar,exe_outsel1)
    begin
      if exe_outsel1 = xi_shift(5 downto 3) and (include_shift=1) then
         in_regM1 <= shift_result1;
      elsif exe_outsel1 = xi_mul(5 downto 3) and (include_mul=1 or include_mult=1 or include_mad=1) then
         in_regM1 <= mult_result;
      elsif exe_outsel1 = xi_jal(5 downto 3) then
         in_regM1 <= long_out_jar;
      elsif exe_outsel1 = xi_cop(5 downto 3) and (include_scc=1 or include_fpu=1 or include_dbg=1) then
         in_regM1 <= cop_output;
      else
         in_regM1 <= alu_result1;
      end if;
    end process;

   EXEOUT_MUX2 : process(alu_result2,shift_result2,mult_result,cop_output,long_out_jar,exe_outsel2)
    begin
      if exe_outsel2 = xi_shift(5 downto 3) and (include_shift=1) then
         in_regM2 <= shift_result2;
      elsif exe_outsel2 = xi_mul(5 downto 3) and (include_mul=1 or include_mult=1 or include_mad=1) then
         in_regM2 <= mult_result;
      elsif exe_outsel2 = xi_jal(5 downto 3) then
         in_regM2 <= long_out_jar;
      elsif exe_outsel2 = xi_cop(5 downto 3) and (include_scc=1 or include_fpu=1 or include_dbg=1) then
         in_regM2 <= cop_output;
      else
         in_regM2 <= alu_result2;
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
    
  BYPOP1_EXE_VALUE : byp1_x_op <= in_regM1;
  BYPOP2_EXE_VALUE : byp2_x_op <= in_regM2;    
    
  BYPBRANCH_EXE_MUX1 : process(alu_result1,shift_result1,cop_output,long_out_jar,exe_outsel1)
    begin
      if exe_outsel1 = xi_shift(5 downto 3) and (include_shift=1) then
         byp1_x_branch <= shift_result1;
      elsif exe_outsel1 = xi_jal(5 downto 3) then
         byp1_x_branch <= long_out_jar;
      elsif exe_outsel1 = xi_read_cop(5 downto 3) and (include_scc=1) then
         byp1_x_branch <= cop_output;
      else
         byp1_x_branch <= alu_result1;
      end if;
    end process;

   BYPBRANCH_EXE_MUX2 : process(alu_result2,shift_result2,cop_output,long_out_jar,exe_outsel2)
    begin
      if exe_outsel2 = xi_shift(5 downto 3) and (include_shift=1) then
         byp2_x_branch <= shift_result2;
      elsif exe_outsel2 = xi_jal(5 downto 3) then
         byp2_x_branch <= long_out_jar;
      elsif exe_outsel2 = xi_read_cop(5 downto 3) and (include_scc=1) then
         byp2_x_branch <= cop_output;
      else
         byp2_x_branch <= alu_result2;
      end if;
    end process; 
    
      
  BYPOP1_MEM_VALUE : byp1_m_op         <= rfile_in1;
  BYPOP2_MEM_VALUE : byp2_m_op         <= rfile_in2;
    
  BYPBRANCH1_MEM_VALUE : byp1_m_branch <= out_regM1;
  BYPBRANCH2_MEM_VALUE : byp2_m_branch <= out_regM2;
    
    
   -----------------------------------------------------------------------------

    
  --------------------------MEMORY ACCESS STAGE------------------------------

  -- Writeback value coming from Exe stage (Alu, Mul, Jar or Cop read)
  regM1: Data_Reg
     generic map ( reg_width => word_width )
     port map ( clk,reset,en_xm,in_regM1,out_regM1 );
  regM2: Data_Reg
     generic map ( reg_width => word_width )
     port map ( clk,reset,en_xm,in_regM2,out_regM2 );  

    
  MEMIN_MUX : MemHandle_in <= rs2_data when d_mempath='0' else rs4_data;

  -- Memory access handling
  -- read_data is the value produced by an eventual memory read operation
  the_memhandle :
    Mem_handle generic map (Word_Width)
               port map ( clk,reset,
                          smdr_enable,                         
                          MemHandle_in,read_data,
                          m_mem_command,DATA_IN,DATA_OUT );

   -- WRITEBACK_SELECTION: Selection of Writebacked data: The Alu output
  -- is the default option, but in case of memory read is the data_bus
  -- value to be forced to the next stage.
	     
  WB1_IN_MUX:
    rfile_in1 <= read_data when (m_mem_command.mr='0' and m_mempath='0') else out_regM1;

  WB2_IN_MUX:
    rfile_in2 <= read_data when (m_mem_command.mr='0' and m_mempath='0') else out_regM2;

end structural;

