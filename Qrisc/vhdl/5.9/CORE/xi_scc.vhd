---------------------------------------------------------------------------
--                        XI_SCC.VHD                                     --
--                                                                       --
--   System Control Coprocessor  for  the XiRisc processor model         --
--   double datapath version                                             --
--                                                                       --
---------------------------------------------------------------------------
--  Created 1999 by F.M.Campi , fcampi@deis.unibo.it                     --
--  DEIS, Department of Electronics Informatics and Systems,             --
--  University of Bologna, BOLOGNA , ITALY                               --
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


-- The system control coprocessor is devoted to the handling af all the
-- anormal events handling during the processor elaboration flow.
--
-- Its main functions are
--
-- (1) Holding into an array of special registers the current processor
--     state, controlling: context switches, special register writes, and
--     special register read operations.
--
-- (2) Handling exceptions and external interrupts, resolving precedences
--     and tranferring control to the dedicated servicing procedures
--     specified in reserved sections of the instruction memory.
--
--
--
--       OVERVIEW OF THE INTERRUPTS AND EXCEPTIONS HANDLING POLICY
--
-- This logic Block implements the handling of all external interrupt
-- requests, internal exceptions or hazards, and software interrupts
-- (Trap instruction).
-- 
-- If an instruction A during its execution raise an exception, the
-- exception code is saved in an Exception_word dedicated to that particular
-- instruction and all no-return operations (that is, data_writes) for A and
-- for any instruction following A are disabled.
-- When A reaches the Memory access stage the Exception_word and the
-- interrupt vector are checked: if there is a pending request it is served
-- (first interrupts, then exceptions ) , else the instruction A is
-- COMMITTED, that is succesfully concluded.
-- 
-- The servicing of a pending request is performed saving the current PC
-- and the current processor status in the EPC, EPS special registers and
-- FORCING on the next_pc register the servicing procedure 32-bit address
-- relative to that exception code, as described in the lookup table
-- mantained in file BASIC.vhd :
-- All instructions in the pipeline following A will flush harmlessy through
-- the pipeline, and the Exception serving procedure will be executed.
-- At the end of the procedure, the RFE (Return from exception) will
-- repristinate the state of the processor from EPS and restart execution
-- from the EPC address.
-- Note that in case of interrupt the instruction that is about to be
-- committed when the exception is acknowledged must not be ignored
-- (as it happens for excepting instructions), and it will be the first to
-- be reloaded when RFE is issued.

--   Example 1: INTERRUPT
-- 
--   IF                      ID           EXE      MEM       WB
--
--   e                       d             c        b         a
--   INTERRUPT:
--   b is succesfully committed.
--   c,d,e  are prevented from any data write to memory or registers, they
--   will be reloaded and executed after the Interrupt has been served;
--   for the time being they are simply flushed out of the pipeline.
--   interrupt procedure     e'            d'       c'        b
--   i.p.                    i.p.          e'       d'        c'
--   i.p.                    i.p.          i.p.     e'        d'
--   ...........................................................
--   RFE                     int procedure i.p.     i.p.      i. p.
--   nop                     RFE(calls c)  i.p.     i.p.      i. p.
--   c                       nop           RFE      i.p.      i. p.
--   d                       c             nop      RFE       i. p.
--   e                       d             c        nop       RFE 
--   f                       e             d        c         nop
--                           f             e        d         c
--
--    Now c too is succesfully committed.

--   Example 2: EXCEPTION
-- 
--   IF                      ID           EXE      MEM       WB
--
--   d                       c             b        a
--   Instruction C causes illegal opcode error.
--   e                       d             c(*)     b
--   f                       e             d        c(*)      b 

--   ILLEGAL OPCODE EXCEPTION RAISED:
--   b is succesfully committed.
--   c is ignored, and will flow harmlessy out of the pipeline.
--   d,e,f are prevented from any data write to memory or registers, they
--   will be reloaded and executed after the Interrupt has been served;
--   for the time being they are simply flushed out of the pipeline.
--   exception procedure     f'            e'       d'        c'
--   exception procedure     e.p.          f'       e'        d'
--   e.p.                    e.p.          e.p.     e'        d'
--   ...........................................................
--   RFE                     exc procedure e. p.    e.p.      e.p.
--   nop                     RFE(calls d)  e. p.    e.p.      e.p.
--   d                       nop           RFE      e.p.      e.p.
--   e                       d             nop      RFE       e.p.
--   f                       e             d        nop       RFE 
--                           f             e        d         nop
--                                         f        e         d
--    Now d too is succesfully committed.
--
--


--------------------------------------------------------------------------
--       SPECIAL  REGISTERS  DEFINITION   
--------------------------------------------------------------------------

-- The Exception_Handling logic also updates the Special Registers used
-- to describe and save the processor status:
--
--
-- The CAUSE register mantains informations about the last served exception:
-- 
-- cause(15)    = Branch_delay_slot  -> '0' => The exception was raised by
--                an instruction in a branch delay slot.
-- cause(14)    = Extended Instruction -> '0' => The exception was raised
--                by the second field of a 16-bit extended instruction.
-- cause(13-6) = Interrupt_vector   -> 8-bit vector that shows the
--                interrupt vector masked by the im(0 to 7) and ie flags.
--
-- cause(5)     = Software_interrupt -> '0' => The exception was raised by a
--                trap instruction: in this case the exception code simply
--                copies the lowest 5 bits of the immediate operand of the
--                instruction.
-- cause(4-0))  = Exception_code -> The cause of the last raised exception
--                is described by a 5-bit encoding, that is used as offset
--                for the interrupt_table to determine the service procedure
--                address.
--                ( The exception code list is described in file basic.vhd )
--
--
-- The EPC register mantains the address where processing must be resumed
-- after an exception has been serviced, that is next_pc in case of internal
-- exception, or curr_pc in case of external interrupt.
--
-- The EPS register mantains informations about the processor status prior
-- to the interruption, that has to be repristinated after the servicing
-- procedure .
--
-- The STICKY REGISTER collects all internal exceptions, in order to
-- provide an history of the past exception that happened in the system
-- 
--                       STICKY(15) => hardware_reset
--                       STICKY(14) => imem_invalid_address
--                       STICKY(13) => imem_misaligned_access
--                       STICKY(12) => imem_protection_fault
--                       STICKY(11) => illegal_opcode1
--                       STICKY(10) => illegal_opcode2
--                       STICKY(9)  => dmem_invalid_address
--                       STICKY(8)  => dmem_misaligned_access
--                       STICKY(7)  => dmem_protection_fault
--                       STICKY(6)  => alu_overflow1
--                       STICKY(5)  => alu_overflow2 
--                       STICKY(4)  => mad_overflow
--                       STICKY(3)
--                       STICKY(2)
--                       STICKY(1)
--                       STICKY(0)
--
-- The STATUS register contains informations about the state of the
-- processor:
--  
-- status(15)       = Processor mode:
--                      '1' -> User mode, access to certain memory areas
--                       ( bootstrap and interrupt servicing procedures )
--                         is forbidden.
--                      '0' -> Kernel mode, all instruction memory areas are
--                       available. The processor is set to kernel mode
--                       while serving Exceptions, and restored to user
--                       mode by RFE.
-- 
-- status(14)       = Interrupt_enable:
--                      '1' -> Interrupt Enable, 
--                      '0' -> Interrupt Disabled, pending interrupt signals
--                       and raised exceptions are ignored:
--                       This status bit is tipically set to '0'
--                       during interrupt service, but can be user/modified.
-- status(13 downto 10) = 
--                       
--
-- status(9 downto 0) = Interrupt Mask:
--                      A certain interrupt signal is ignored if the
--                      corresponding status_im bit is set to 0.
--

------------------------------------------------------------------------
--                ENTITY DEFINITION
------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;
  
entity Scc  is
     generic( Word_Width              : positive := 32;
              Iaddr_width             : positive := 24;
              status_bits             : integer := 16#c0ff#; 
              intproc_status_bits     : integer := 16#0000#;
              cause_bits              : integer := 16#0010#;
              interrupt_on_exception  : integer :=1;
              include_sticky_logic    : integer :=1 );
     
    port(   clk,reset,reboot,freeze     : in  Std_logic;
            en_dec,en_x,d_we,x_we     : in  Std_logic;
            cop_command                 : in  Cop_control;
            cop_reg                     : in  Std_logic_vector(2 downto 0);
            cop_in                      : in  Std_logic_vector(Word_width-1 downto 0);
            cop_out                     : out Std_logic_vector(Word_width-1 downto 0);
            epc_out                     : out Std_logic_vector(Iaddr_width-1 downto 0);
            break_code                   : in  Std_logic_vector(4 downto 0);
                        
            pc_basevalue                : in  Std_logic_vector(Iaddr_width-1 downto 0);
            
            interrupt_vector            : in  Std_logic_vector(9 downto 0);
            exc                         : in  Exc_list;
	    
            kernel_mode                 : out Std_logic;
            serve_exception             : out Std_logic;
            serve_proc_pointer          : out Std_logic_vector(7 downto 0) );
end Scc;


---------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
---------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.components.all;

architecture structural of Scc is

 --synopsys synthesis_off 
  type spy_cop is (cop_rfe,cop_null,cop_suspend,cop_wcop,cop_rcop,cop_break,cop_err);
  type spy_exc is (illop1,illop2,alu_oflow1,alu_oflow2,mad_oflow,imem_misalign,imem_prot_warn,imem_inv_addr,dmem_misalign,dmem_prot_warn,dmem_inv_addr,fpu,no_exc);
  signal spy  : spy_cop;
  signal spye : spy_exc;
 --synopsys synthesis_on

  
-- Interrupt: Describe the interrupt vector masked by ie and im(7 downto 0)
--            flags.It is copied on the cause register bits 23-16.
signal interrupt : Std_logic_vector(9 downto 0);

-- Exception word:  signals that flows through the pipeline with the
-- instruction they are referred to, carrying informations about
-- eventual exceptions to update the cause and epc registers.
signal f_exc_word,din_exc_word,d_exc_word,ein_exc_word : Std_logic_vector(5 downto 0);
signal x_exc_word,x_int_word : Std_logic_vector(5 downto 0);

signal d_pcbasevalue,x_pcbasevalue          : Std_logic_vector(Iaddr_width-1 downto 0); 

signal interrupt_active,exception_active,raise_exception : Std_logic;

signal cause,eps,status                     : Std_logic_vector(15 downto 0);
signal next_cause,next_eps,next_status      : Std_logic_vector(15 downto 0);
signal next_sticky,sticky                   : Std_logic_vector(15 downto 0);
signal sticky_bits,next_sticky_temp         : Std_logic_vector(15 downto 0);
signal status_reg_in,x_status             : Std_logic_vector(15 downto 0);
signal epc,next_epc                         : Std_logic_vector(Iaddr_width-1 downto 0);

signal cop_op,x_cop_op,mem_cop_op         : Std_logic_vector(5 downto 0);
signal x_cop_reg                          : Std_logic_vector(2 downto 0);

signal reg_enable                           : Std_logic;


begin

  COPROCESSOR_SELECTION:
  process(cop_command)
  begin
      if cop_command.index = "00" or (cop_command.op = xi_system_break) then 
         cop_op  <= cop_command.op;
      else
         cop_op  <= xi_system_null;                 
      end if;
  end process;

  --synopsys synthesis_off
  SCCSPY: process(cop_op)
  begin
    if (cop_op = xi_system_rfe) then
       spy <= cop_rfe;
    elsif (cop_op = xi_system_null) then
       spy <= cop_null;
    elsif (cop_op = xi_system_suspend) then
       spy <= cop_suspend;
    elsif (cop_op = xi_system_wcop) then
       spy <= cop_wcop;
    elsif (cop_op = xi_system_rcop) then
       spy <= cop_rcop;
    elsif (cop_op = xi_system_break) then
       spy <= cop_break;    
    else
       spy <= cop_err;
    end if;
  end process;

  EXCSPY: process(exc)
  begin
    if (exc.illop1='0') then
      spye <= illop1;
    elsif (exc.illop2='0') then
      spye <= illop2;
    elsif (exc.alu_oflow1='0') then
      spye <= alu_oflow1;
    elsif (exc.alu_oflow2='0') then    
      spye <= alu_oflow2;
    elsif (exc.mad_oflow='0') then
      spye <= mad_oflow;
    elsif (exc.imem_misalign='0') then
      spye <= imem_misalign;
    elsif (exc.imem_inv_addr='0') then
      spye <= imem_inv_addr;
    elsif (exc.imem_prot_warn='0') then
      spye <= imem_prot_warn;
    elsif (exc.dmem_misalign='0') then
      spye <= dmem_misalign;
    elsif (exc.dmem_inv_addr='0') then
      spye <= dmem_inv_addr;
    elsif (exc.dmem_prot_warn='0') then
      spye <= dmem_prot_warn;
    elsif (exc.fpu='0') then
      spye <= fpu;
    else
      spye <= no_exc;
    end if;
  end process;
  --synopsys synthesis_on
  
  reg_enable <= not freeze;

   
  -- -- --          EXCEPTION  DETETECTING  --  --  --  --  --  --  --  --  -- 
  
   -----------------FETCH STAGE---------------------------------------------

   -- Memory Protection Fault detection: Status_mode='1' is User mode, access
   -- to kernel reserved memory areas is forbidden

   process( exc,status )
   variable exc_imem_prot_fault : Std_logic;
   begin
     
     exc_imem_prot_fault := (not status(15)) or exc.imem_prot_warn;

     if exc.imem_inv_addr = '0' then
       f_exc_word    <= imem_invalid_address;
     elsif exc.imem_misalign = '0' then
       f_exc_word <= imem_misaligned_access;
     elsif exc_imem_prot_fault = '0' then
       f_exc_word <= imem_protection_fault;
     else
       f_exc_word <= no_problem;
     end if;
     
   end process;               
    
   ---------------------DECODE STAGE----------------------------------------
   dec_eword_reg :
     Data_reg generic map (reg_width => 6, init_value=> 16#3f#)
              port map (clk,reset,en_dec,f_exc_word,din_exc_word);          
    
   -- DECODE Stage Exceptions Detecting --
   process( cop_op,din_exc_word,exc,break_code )
   begin  
     if din_exc_word = no_problem then

   -- The TRAP instruction might specify an argument field up to 5 bits long,
   -- that will be copied directly in the exception word that is the pointer
   -- to the Interrupt table.       
        if cop_op = xi_system_break then
           d_exc_word(5) <= '1';
           d_exc_word(4 downto 0) <= break_code;
        elsif exc.illop1 = '0' then
           d_exc_word <= illegal_opcode1;
        elsif exc.illop2 = '0' then
           d_exc_word <= illegal_opcode2;
        else
           d_exc_word <= no_problem;
        end if;         
     else
       d_exc_word <= din_exc_word;
     end if;
       
   end process;      
    
  --------------------EXECUTE STAGE--------------------------------------
   x_eword_reg :
     Data_reg generic map (reg_width => 6, init_value=> 16#3f#)
              port map (clk,reset,en_x,d_exc_word,ein_exc_word);
 


  -----------------------------------------------------------------------------
  -- PIPELINE SYNCHRONIZATION
  -----------------------------------------------------------------------------
  
    -- Note: the pc_basevalue, generated by a dedicated logic block in the main
   -- core, is the RETURN address that has to be saved on EPC in case the instruction
   -- currently being decoded were interrupted.
   -- It is generated outside this logic block by the pcbvgen block
   d_pcbasevalue <= pc_basevalue;
   
   -- Registers used to keep trace of the Current PC value to be saved on EPC
   -- in case of interruption
   x_basevalue_reg :
     Data_reg generic map (reg_width => Iaddr_width,init_value => reset_value_lower + 4)
              port map (clk,reset,en_x,d_pcbasevalue,x_pcbasevalue);
    
   -- Register used to keep trace of the processor status through the pipeline
   -- stages to write it on EPS in case of interruption
   X_status_reg :
      Data_reg generic map ( init_value => status_bits,reg_width => 16 )
               port map (clk,reset,en_x,status,x_status);
       
   Delay_ref_reg_e : Data_reg generic map (reg_width => 6,init_value=>7)
                              port map (clk,reset,en_x,cop_op,x_cop_op);
   Delay_ref_reg_m : Data_reg generic map (reg_width => 6,init_value=>7)
                              port map (clk,reset,en_x,x_cop_op,mem_cop_op);

   Delay_scc_target : Data_reg generic map (reg_width => 3)
                               port map (clk,reset,en_x,cop_reg(2 downto 0),x_cop_reg);    


    -- EXECUTE Stage Exceptions Detecting
   process( ein_exc_word,exc,status )
   variable exc_dmem_prot_fault : Std_logic;  
   begin
     exc_dmem_prot_fault := (not status(15)) or exc.dmem_prot_warn;
     
     if ein_exc_word = no_problem then       
        if exc.alu_oflow1 = '0' then          
          x_exc_word <= alu_overflow1;
        elsif exc.alu_oflow2 = '0' then
          x_exc_word <= alu_overflow2;
        elsif exc.mad_oflow = '0' then
          x_exc_word <= mad_overflow;  
        elsif exc.dmem_inv_addr = '0' then
          x_exc_word <= dmem_invalid_address;
        elsif exc.dmem_misalign = '0' then
          x_exc_word <= dmem_misaligned_access;
        elsif exc_dmem_prot_fault = '0' then
          x_exc_word <= dmem_protection_fault;               
        else
          x_exc_word <= no_problem;
        end if;    
     else x_exc_word <= ein_exc_word;
     end if;
   end process;

  -- EXECUTE STAGE EXCEPTION DETECTING
   -- Masking of interrupt input signals:
   -- status(7 downto 0) is the Interrupt masking vector.
  interrupt <= interrupt_vector and status(9 downto 0);    
  process ( status,interrupt )
   begin
     if status(14)='1' then
        -- External Interrupt Handling
        if interrupt(9) = '1' then
             x_int_word <= interrupt_9;
        elsif interrupt(8) = '1' then
             x_int_word <= interrupt_8;
        elsif interrupt(7) = '1' then
             x_int_word <= interrupt_7;
        elsif interrupt(6) = '1' then
             x_int_word <= interrupt_6;
        elsif interrupt(5) = '1' then
             x_int_word <= interrupt_5;
        elsif interrupt(4) = '1' then
             x_int_word <= interrupt_4;
        elsif interrupt(3) = '1' then
             x_int_word <= interrupt_3;
        elsif interrupt(2) = '1' then
             x_int_word <= interrupt_2;
        elsif interrupt(1) = '1' then
             x_int_word <= interrupt_1;
        elsif interrupt(0) = '1' then
             x_int_word <= interrupt_0;
        else
             x_int_word <= no_problem;
        end if;
     else
       x_int_word <= no_problem;
     end if;
   end process;
   
  -- EXCEPTION RESOLUTION  -- - - - - - -   
  exception_active <= '0' when (x_exc_word/=no_problem and interrupt_on_exception=1) else '1';

  -- INTERRUPT RESOLUTION  -- - - - - - -
  interrupt_active <= '0' when (interrupt/="0000000000") else '1';
   
    
  -- -- -- -- -- -- --  EXCEPTIONS  SERVICING --  --  --  --  --  --  --

   -- If an external interrupt is pending it is served; if there is no
   -- pending interrupt the oldest exception referred to the instruction
   -- currently in the memory stage is dealt with.
   -- In case no exception and no pending interrupt are signalled the
   -- current instruction is COMMITTED and can be forwarded through the
   -- pipeline to the writeback stage.
   --
   -- Every Exception, internal or external, has a dedicated address
   -- that refers to the location of its servicing procedure in the reserved
   -- section of the instruction memory.
   -- These addresses are specified through an array of constants, that
   -- is defined in file basic.vhd .
   --
   -- In case of multiple exceptions only one exception is considered a time,
   -- with the following precedence rules:
   --    1) External Interrupts, from 7 (first served) to 0
   -- When the servicing procedure is called eventual interrupts are ignored.
   -- if a second interrupt is pending in slot 4 when slot 1 is served, it
   -- will be served at the completion of the first only if it is still
   -- pending and no other interrupt is pending at slots 7,6,5.
   -- This unfair politic is acceptable as the frequency of interrupt
   -- occurrances should be significantly lower then instruction fetching
   -- rate.

   
   -- This process actually raise exceptions causing all critical paths in the
   -- design and tringgering exception servivcing.
   -- Please note that cause(5 => 0) will be used to determine the correct
   -- pointer to the interrupt table
   process(status,interrupt_active,exception_active,interrupt,x_int_word,x_exc_word,cause)
   begin          
   if status(14) = '1' then
     if interrupt_active='0' then
       
       raise_exception <= '0';
       -- CAUSE Register Update  
       
       -- Masked interrupt vector
       next_cause(15 downto 6)   <= interrupt;
       -- Exception code
       next_cause(5  downto  0)  <= x_int_word;
       
     elsif (exception_active='0' and interrupt_on_exception=1) then
       
       raise_exception <= '0';
       -- CAUSE Register Update       
      
       -- Masked interrupt vector
       next_cause(15 downto 6)   <= interrupt;
       -- Exception code
       next_cause(5  downto  0)  <= x_exc_word;
       
     else
       
       raise_exception <= '1';
       next_cause <= cause;
     end if;
   else
       raise_exception <= '1';
       next_cause <= cause;
   end if;
   end process;
       

-- -- -- -- -- -- -- -- -- WRITING ON SPECIAL REGISTERS  --  --  --  --  --
-- 
-- NOTE: All Special Registers can be rewritten except the CAUSE Register,
-- whose last 8 bits are used as a path to produce the address for the
-- interrupt table read cycle and have to be updated quickly and in a
-- software-indipendent way.
-- Actually, STATUS EPS and EPC can be written by a wcop only unless an
-- Exception is signalled durning the same cycle:
-- In this case processor control would be overtaken by the Exception service
-- and the scheduled wcop would only take place when the normal program flow
-- is repristinated.


   -- 1) STATUS REGISTER

   process( cop_op,cop_reg,mem_cop_op,cop_in,
            raise_exception,status,x_status,eps,d_we,x_we,reboot )
   begin
     if (reboot = '0' or raise_exception = '0') then
       
       -- Reboot or Interrupt Servicing Procedure: 
        -- The Interrupt Enable status flag is set to zero at the beginning
        -- of any exception service. Consequently, an exception service
        -- procedure can not be interrupted, unless the procedure itself
        -- would set ie to '1' using the wcop instruction. In this case,
        -- before doing so it must save EPC, status and cause registers
        -- and any other information that should not be overwrited.
        -- All exception procedures are defaulted to 32-bit status.
        -- During their execution they can easily switch to 16- bit mode.
        -- The execution mode prior to the interruption is saved in the EPS
        -- register and will be repristinated by rfe.
        -- In any case the default processor status configuration issued
        -- during interrupt servicing can be programmed in file basic.vhd.
        
        -- During Reboot & interrupts the processor should be set to kernel mode,
        -- so it is advised not to change bit 15 to 1 !
        next_status <= conv_std_logic_vector(intproc_status_bits,16);
       
     else
       
       if (cop_op = xi_system_rfe) and (d_we = '0') then
       
          -- RFE INSTRUCTION : 
          -- The call to any exception procedure switches the processor
          -- to kernel mode and deactivate any further interruption until
          -- the called servicing procedure is finished: Any Servicing
          -- procedure must terminate with a RFE instruction, that will
          -- switch back the processor to the status it had prior to
          -- the exception, saved in EPS.
          -- At present, neither the interrupt service nor the internal
          -- exception service can be interrupted unless the interrupt
          -- servicing routine itself would change the ie flag using the
          -- RCOP instruction.
          -- NOTE : The Interrupt enable flag must not be changed here,
          --        because this modification will take place in the EXE stage.
          --        The interrupt must not be re-enabled until the RFE else has reached the Mem 

             next_status(15)           <= EPS(15);
             next_status(14)           <= status(14);
             next_status(13 downto 0)  <= eps(13 downto 0);

       elsif (mem_cop_op = xi_system_rfe) then

             -- This logic switches back the interrupt enable flag after the
             -- RFE instruction has been committed, So that the interrupt servicing
             -- procedure does not get interrupted.
             
             next_status(14)          <= eps(14);

             next_status(15)          <= status(15);
             next_status(13 downto 0) <= status(13 downto 0);
                                         
       elsif (cop_op = xi_system_wcop) and (d_we = '0') then

          -- WCOP INSTRUCTION :
          -- The wcop instruction is a particular operation code 
          -- that allows the user to modify through a
	  -- software command the special registers of the processor.
          --
          -- Writes on the special registers may affect all the instructions
          -- following the wcop , for
          -- 1) Altering the exception handling policy
          --    ( disable Interruptions, alter the interrupt mask)
          -- 2) Switching to kernel mode elaboration
          -- 3) Switching between 16- or 32-bit mode elaboration
            
          -- In this model, the only special register that can be
          -- user-modified are EPC and status register, and in particular:
          -- status(15) bit, that can switch the processor to kernel mode
          --            allowing the user access to reserved memory areas. 
          -- status(14) bit, that can disable exception servicing
          --            ( or allow an interrupt serving procedure to enable
          --              further nested interruptions.
          --              EPC and CAUSE registers must be saved before
          --              doing so!!!!  )
          -- status(7-0) bits, that allow the software to disable
          --            certain interrupt inputs. At the moment, single
          --            specific exceptions cannot be disabled.
          -- Mtc0 is a register register operation, that copies the content
          -- of the first addressed register into the special register
          -- specified by the second operand ( the special register addresses
          -- are described in file basic.vhd ).
          
             if cop_reg(2 downto 0) = sr_status then
	         next_status(15 downto 0) <= cop_in(15 downto 0);
	     else
		 next_status <= status;
             end if;             

       else next_status <= status;
                  
       end if;
          
     end if;
   end process;

 
   -- 2) EPC REGISTER

   -- This is a bit complicated. To feature a PRECISE handling of the
   -- interrupts XiRisc must be capable to RESTORE COMPLETELY the processor
   -- status prior to the exception at the end of the exception service.
   -- The problem is that, as introduced above, the exceptions are served only
   -- when the relative instruction is in the memory access pipeline stage.
   -- One may think that no no-return operation was performed up to this point,
   -- as I stated previously. True, but unfortunately the processor state has
   -- changed, due to instructions that hasn't been committed and will be
   -- deactivated. THIS MEANS THAT THE RFE instruction will have to restore
   -- the processor status DISCARDING ANY MODIFICATION CAUSED BY INSTRUCTIONS
   -- FOLLOWING THE EXCEPTING ONE.

   -- The processor status is held in the PC, and STATUS registers.
   -- this logic memorizes the old status values for instructions not
   -- yet committed, saving on EPC and EPS the processor status of any excepting
   -- or interrupted instruction.

   process( x_cop_op,x_cop_reg,cop_in,interrupt_active,
	    raise_exception,epc,d_pcbasevalue,x_pcbasevalue,x_we )
   begin
     if raise_exception = '0' then

       -- An Exception or Interrupt has been raised during this cycle.
       -- EPC must be reprogrammed with the appropriate return address:
       -- In case of interrupt the interrupted instruction's address,
       -- in case of exceptions the next instruction's address.
       
       if interrupt_active = '0' then
                            
              -- Case 1: Interrupts     
              next_EPC <= x_pcbasevalue;

       else           
             -- Case 2: Exceptions
             -- In all other cases the Program C value to be saved 
             -- must be the address of the instruction following the excepting
             -- one.
             -- Actually though, if the jump itself has raised an exception,
             -- (typically inconsistent or invalid instruction memory access)
             -- the program flow will be hopelessy unconsistent and can
             -- in no way be repristinated. The only way out will be to
             -- reset from outside the processor state.
             next_EPC <= d_pcbasevalue;

       end if;

       
     elsif (x_cop_op = xi_system_wcop) and (x_we = '0') then

          -- Wcop INSTRUCTION :
	  -- The EPC register may be accessed during a
	  -- servicing routine to alter at need the procedure return address.
	     
          if x_cop_reg = sr_epc then
	     next_epc <= cop_in(Iaddr_width-1 downto 0);
          else
	     next_epc <= epc;
	  end if;
      
     else next_epc <= epc;              
     end if;
     
   end process;

   epc_out <= epc;
    
   -- 3) EPS  REGISTER

   process( x_cop_op,x_cop_reg,cop_in,raise_exception,x_status,eps,x_we,status,interrupt_active)
   begin
     if raise_exception = '0' then

       -- An Exception or Interrupt was raised during this cycle.
       -- EPS must be reprogrammed with the current processor status.
       -- The Current processor status is defined as the status of the
       -- interrupted instruction, that is the instruction whose address is
       -- saved in the EPC register        
           
        if interrupt_active = '0' then
           -- INTERRUPT
           -- The instruction currently in the EXE stage will be deactivated,
           -- and will be reload and re-executed later. Consequently we must
           -- set the processor state to the state it was in before this
           -- instruction was decoded. This is not true in case the interrupt enable
           -- flag has just been activated: in this case we cannot copy the old
           -- status value because it will leave us with the interrupts
           -- permanently disabled.
           if x_status(14) = '0' then
              next_EPS <= status;
           else
              next_EPS <= x_status;
           end if;   
        else
           -- Exceptions
           next_EPS <= status;
        end if;          
       
     elsif (x_cop_op = xi_system_wcop) and (x_we = '0') then

          -- wcop INSTRUCTION :
	  -- The EPS register may be accessed during a
	  -- servicing routine to alter at need the returned processor status.
	     
          if x_cop_reg = sr_eps then
	     next_eps(15 downto 0) <= cop_in(15 downto 0);
          else
	     next_eps <= eps;
	  end if;
      
     else next_eps <= eps;              
     end if;
     
   end process;
           
   
   -- -- -- -- -- -- --  SPECIAL REGISTERS --  --  --  --  --  --  --
   
 
-- SPECIAL REGISTERS : 

    -- Exception Cause register: READ-ONLY register.
    -- this register is updated by the Exception handling logic every time an
    -- exception is served.
    -- It holds informations about the nature of the exception, that can be
    -- read using the MFT0 instruction:
    -- cause(31 downto 28)  -> Unused
    -- cause(27 downto 20) -> Interrupt_vector
    -- cause(6) -> If set to '1', signals that the current exception
    --             has been raised by a software interrupt (Trap).
    -- cause(5 downto 0) -> Exception code, as described in file basic.vhd
 
    CAUSE_REG : Data_reg
                 generic map ( init_value => cause_bits,
                               reg_width => 16 )
                 port map (clk,reset,raise_exception,next_cause,cause);

    -- Exception return Program Counter: READ-WRITE register.
    -- Used in case of Exceptions to memorize the pc value that is to be
    -- repristinated after the interrupt routine has concluded.
    -- It is updated by the exception logic every time an exception is
    -- served; normally it is read by the hardware when an RFE (return
    -- from exception) instruction is decoded, but for diagnostic purposes
    -- it can be read using the RCOP instruction.
    -- It can also be modified using the WCOP instruction.
                                         
    EPC_REG : Data_reg
       generic map ( init_value => 0,
                     reg_width => Iaddr_width )
       port map ( clk,reset,reg_enable,next_epc,epc );

    -- Exception return Processor Status: READ-WRITE register.
    -- Used in case of Exceptions to memorize the current processor status
    -- register, that is to be repristinated after the interrupt routine has
    -- concluded.
    -- It is updated by the exception logic every time an exception is
    -- served; normally it is read by the hardware when an RFE (return
    -- from exception) instruction is decoded, but for diagnostic purposes
    -- it can be read using the RCOP instruction.
    -- It can also be modified using the WCOP instruction.
                                         
    EPS_REG : Data_reg
       generic map (reg_width => 16 )
       port map ( clk,reset,reg_enable,next_eps,eps );
    
   -- Status register: READ-WRITE Register.
   -- In the status register are saved flags that describe the current
   -- processor condition: These flags can be read and modified by
   -- software using the RCOP and WCOP instructions.
   -- 
   -- status(15) -> Processor mode Flag: '1'-> user mode , '0'-> Kernel mode
   -- status(14) -> Interrupt Enable Flag   
   -- status(7 downto 0) -> INTERRUPT MASKING flags
           
    STATUS_REG : Data_reg
       generic map ( init_value => status_bits,
                     reg_width => 16 )         
       port map ( clk,reset,reg_enable,next_status,status );


 STICKY_LOGIC: if include_sticky_logic=1 generate

  -- STICKY_BITS_RESOLUTION:
  Sticky_setting:process(x_exc_word)
    begin
      if x_exc_word=hardware_reset then
        sticky_bits<=conv_std_logic_vector(16#8000#,16);
      elsif x_exc_word=imem_invalid_address then
        sticky_bits<=conv_std_logic_vector(16#4000#,16);
      elsif x_exc_word=imem_misaligned_access then
        sticky_bits<=conv_std_logic_vector(16#2000#,16);
      elsif x_exc_word=imem_protection_fault then
        sticky_bits<=conv_std_logic_vector(16#1000#,16);
      elsif x_exc_word=illegal_opcode1 then
        sticky_bits<=conv_std_logic_vector(16#0800#,16);
      elsif x_exc_word=illegal_opcode2 then
        sticky_bits<=conv_std_logic_vector(16#0400#,16);
      elsif x_exc_word=dmem_invalid_address then
        sticky_bits<=conv_std_logic_vector(16#0200#,16);
      elsif x_exc_word=dmem_misaligned_access then
        sticky_bits<=conv_std_logic_vector(16#0100#,16);
      elsif x_exc_word=dmem_protection_fault then
        sticky_bits<=conv_std_logic_vector(16#0080#,16);
      elsif x_exc_word=alu_overflow1 then
        sticky_bits<=conv_std_logic_vector(16#0040#,16);
      elsif x_exc_word=alu_overflow2 then
        sticky_bits<=conv_std_logic_vector(16#00020#,16);
      elsif x_exc_word=mad_overflow then
        sticky_bits<=conv_std_logic_vector(16#00010#,16);
      else
        sticky_bits<=conv_std_logic_vector(16#00000#,16);      
      end if;
    end process;
  
   -- STICKY REGISTER   
   process(cop_op,cop_reg,cop_in,sticky,d_we)
   begin
     if ( (cop_op=xi_system_wcop) and (d_we='0') and (cop_reg(2 downto 0)=sr_sticky) ) then
	    next_sticky_temp <= cop_in(15 downto 0);
      else
	    next_sticky_temp <= sticky;
      end if;                  
   end process;

   next_sticky <= next_sticky_temp or sticky_bits;        
    
   STICKY_REG : Data_reg
     generic map ( reg_width => 16 )
     port map ( clk,reset,reg_enable,next_sticky,sticky );
   
end generate;
              
NO_STICKY_LOGIC: if include_sticky_logic=0 generate
  sticky <= (others=>'0');
end generate;

                 
   
     -- OUTPUT PORTS FEED:
     --
     -- 1) The Scc coprocessor outputs the internal registers content in case of
     --    RCOP instructions.
     -- 2) The EPC value must be produced in case of RFE instruction to
     --    repristinate the pre-interruption PC.
     -- 3) In case of Exception raise, the Scc produces appropriate Interrupt
     --    table pointer to determine the servicing procedure address.
     -- 4) Finally, some 16-bit PC-relative instructions require an appropriate
     --    PC value for the current instruction ( LWPC, ADJPC ).
     --    ( whose last two bits are cleared )
     -- Note: There appears to be a light inconsistency, in that the rfe cause
     -- a read operation in the decode stage while all other registers are read
     -- in the exe state. But no conflictions are possible as no RCOP operation
     -- may ever happen befor a ref, because prior to rfe only register restore
     -- operations may be performed according to the template specified in the
     -- exception handling XiRisc software library exc.c
      
     SPECIAL_REGISTER_READ_MUX:
     process(cause,epc,eps,status,x_cop_op,x_cop_reg,sticky)
     begin
       if x_cop_op = xi_system_rcop then
          case x_cop_reg is
	      when sr_cause  => cop_out <= EXT(cause,word_width);
	      when sr_epc    => cop_out <= EXT(epc,word_width);
              when sr_eps    => cop_out <= EXT(eps,word_width);      
	      when sr_status => cop_out <= EXT(status,word_width);
              when sr_sticky => cop_out <= EXT(sticky,word_width);
              when others => cop_out <= ( others => '0');
          end case;

       else         
          cop_out <= ( others => '0');
          
       end if; 
     end process;


    -- OUTPUT SIGNALS GENERATION
    kernel_mode        <= status(15);
    serve_exception    <= raise_exception;
    serve_proc_pointer <= next_cause(5 downto 0)&"00";    
    
end structural;  

----------------------------------------------------------------------------
--   COMPONENT DEFINITION
----------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.basic.all;

package scc_pack is
  
  component Scc
      generic( Word_Width              : positive := 32;
              Iaddr_width             : positive := 24;
              status_bits             : integer := 16#c0ff#; 
              intproc_status_bits     : integer := 16#0000#;
              cause_bits              : integer := 16#0010#;
              interrupt_on_exception  : integer :=1;
              include_sticky_logic    : integer :=1 );
     
    port(   clk,reset,reboot,freeze     : in  Std_logic;
            en_dec,en_x,d_we,x_we     : in  Std_logic;
            cop_command                 : in  Cop_control;
            cop_reg                     : in  Std_logic_vector(2 downto 0);
            cop_in                      : in  Std_logic_vector(Word_width-1 downto 0);
            cop_out                     : out Std_logic_vector(Word_width-1 downto 0);
            epc_out                     : out Std_logic_vector(Iaddr_width-1 downto 0);
            break_code                   : in  Std_logic_vector(4 downto 0);
                        
            pc_basevalue                : in  Std_logic_vector(Iaddr_width-1 downto 0);
            
            interrupt_vector            : in  Std_logic_vector(9 downto 0);
            exc                         : in  Exc_list;
	    
            kernel_mode                 : out Std_logic;
            serve_exception             : out Std_logic;
            serve_proc_pointer          : out Std_logic_vector(7 downto 0) );
  end component;
end scc_pack;

package body scc_pack is
end scc_pack;
