---------------------------------------------------------------------------
--                        XI_MENU.VHD                                    --
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
-- This license is a modification of the Ricoh Source Code Public
-- License Version 1.0 which is similar to the Netscape public license.
-- We believe this license conforms to requirements adopted by OpenSource.org.
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------
--
-- Definition of basic parameters,
-- defined to ease the Risc Model code readability.
--
-- all the code here defined must mantain synthesizability !!
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package menu is

  -- BASIC ARCHITECTURAL PARAMETERS CONFIGURATION  -------------------------------


  -- THIS SET OF PARAMETERS MUST BE CONFIGURATED BY THE USER

  -- Datapath Configuration
  -- WARNING: The configuration selected here has strong influence on the
  --          device area, and must be matched correctly by the compiling
  --          software.

  -- DATAPATH COMPONENTS:

  constant include_scc     : integer := 1;  -- System control coprocessor
  constant include_fpu     : integer := 0;
  constant include_dbg     : integer := 0;
  constant include_shift   : integer := 1;
  constant include_rotate  : integer := 1;
  constant include_hrdwit  : integer := 1;  -- Branch Decrement operation   

  -- SHIFT Width:
  -- The Shifter might often be part of the processor critical path,
  -- especially when no multiplier is added to the core.
  -- In such cases, it might be important to define the maximum shift value
  -- needed, to targetize with the appropriate shifter complexity the core.
  -- The following parameter sets the Bit-width of the shifting operand   
 constant shift_count_width : integer := 5;  

 -- Register file width: The number of registers inside the Rfile is easily
 -- configurable, the only problem is to match the compiler.
 -- Of course registers are 2**( rf_registers_addr_width)
 constant rf_registers_addr_width : positive := 5;
  
  -- MUL logic configuration --------------------------------------------------
  -- NOTE:
  -- Mul is a three operands, single cycle operation (rd <- rs1*rs2) with a
  --     32-bits result,
  -- Mult is a two operands, double cycle operation leading to a 64 -
  --     bit result, based on the Hi,Lo special registers
  --  (Hi,Lo) <= rs1 * rs2.
  -- Mad is a 64-bit Multiply-Accumulate operation based on the Hi,Lo registers:
  --     (Hi,Lo) <- rs1 * rs2 + (Hi,Lo)
  -- Of course, mul is less precise and causes a higher critical path, but
  -- Mult leads to a significantly worse optimization of the assembly code.
  -- Hi,Lo Special registers can be read with mfHi, mfLo instructions and
  -- written with mthi,mtlo instructions    
  --
  -- The activation of any of the three will generate an hardware multiplier.
  -- The activation of mul and/or mad will generate the Hi,Lo registers
  --     and the relative handle logic
  -- The activation of mad will generate a 64 bit accumulation adder.
  --
  -- If mad=1 all the logic necessary to execute a mult will be generated anyway
  -- so it might be worth to add mult=1 as well ...

  constant include_mul  : integer := 1;
  constant include_mult : integer := 1;
  constant include_mad  : integer := 1;

  -- The following constants are obsolete but I am still considering whether
  -- to erase them or not at the moment
  -- constant include_parallel_alu   : integer := 0;
  -- constant include_sat_arithmetic : integer := 0;

  -- constant mult_delay_cycles : positive := 2;  -- Must be matched by the compiler
                                        -- Of course, must be >=1

  -- Memory address Check: Significant only if include_scc=1
  constant include_iaddr_check : integer :=1;
  constant include_daddr_check : integer :=1;

  -- System Control Coprocessor Configuration, used only if include Scc=1
  -- Raise an interrupt on internal exceptions

  -- Basically, there are two possible ways to handle internal exceptions:
  -- a) Internal exceptions trigger an interrupt servicing procedure.
  -- b) A sticky logic inside the processor core will maintain informations
  --    on exception that took place in the system since last Reset
  constant interrupt_on_exception  : integer := 1;
  constant include_sticky_logic    : integer := 1;

  ---------------------------------------------------------------------------

  -- INSTRUCTION WIDTH CONFIGURATION 

  -- NOTE:
  -- The XiRisc model can be used with the classic 32-bit instruction set or
  -- with an alternative 16-bit instruction set. (Or both instruction sets can
  -- be used with a runtime switch, which might be costly in terms of chip area)

  constant isa32 : integer := 1;
  -- constant isa16 : integer := 0;
  
  constant Instr_width : integer := 64;

  -- BUS WIDTH CONFIGURATION            ------------------------------------------------

  -- NOTE: The constants here defined regulate the internal bus width, so
  --       they have a relevant impact on the core area.
  --       They are not completely independent: obviously, the Data Memory
  --       addressing logic uses the main data ALU. This means, the data
  --       channel width must be >= the Daddr width.
  --       Only 16 and 32 data bit configurations have been debugged to this
  --       moment.

  constant Word_Width : positive := 32;

  constant Daddr_width     : positive := 32;
  constant Iaddr_width     : positive := 24;
 

  ---------------------------------------------------------------------------
  -- ADDITIONAL MODEL PARAMETERS        ----------------------------------
  ---------------------------------------------------------------------------

  -- Fundamental Model constants

  constant reset_active : std_logic := '0';  --'0'-> negative logic    


-------------------------------------------------------------------------------
-- ADDRESS SPACE MAPPING ------------------------------------------------------
-------------------------------------------------------------------------------

  constant Int_table_base : integer := 16#40000000#;
                                        -- The interrupt table is
                                        -- located in data memory
                                        -- from the address here
                                        -- specified on; the offset
                                        -- for each different
                                        -- Exception is determined
                                        -- by its exception code
                                        -- (see file dlx.vhd).
                                        -- This address must be a
                                        -- multiple of 256,as its
                                        -- least significant 8 bits
                                        -- must be 0 to be
                                        -- overwritten by the
                                        -- exception code.


  
  -- Reset Address & Bootup ROM Address ---------------------------------------
  -- The top level architecture (see file xi_top.vhd) contains a Bootup ROM,
  -- where is saved the code used to load the desired program code into the
  -- device through the PP interface.
  -- A low value on the REBOOT pin will force the Xirisc to run the bootup
  -- procedure usually contained in a ROM,likely in order to wait for external
  -- programming on some IO port.  
  -- The RESET pin may be used to restart elaboration from address reset_value
  -- without any explicit code load procedure.
  
  constant reset_value_upper   : integer := 0;
  constant reset_value_lower   : integer := 16#100#;  

  constant reboot_value_upper  : integer := 0;
  constant reboot_value_lower  : integer := 0;
  
  
  -- Bootup ROM
  constant rom_end_value_upper : integer := 0;
  constant rom_end_value_lower : integer := 16#0FF#;  
                                        -- this is the last address of the ROM;
                                        -- the first address is set in the
                                        -- constant boot_value 

  -- The following values are significant only if the runtime checks on memory
  -- addresses are set active (and in the Testbench, in case you use mine!)
  -- Instruction memory
  constant instr_mem_init_value_lower : natural := 16#0000#;
  constant instr_mem_init_value_upper : natural := 16#4000#;
  constant instr_mem_end_value_lower  : natural := 16#efff#;
  constant instr_mem_end_value_upper  : natural := 16#4000#;

  -- Data memory
  constant data_mem_init_value_lower : natural := 16#f000#;  
  constant data_mem_init_value_upper : natural := 16#4000#;
  constant data_mem_end_value_lower  : natural := 16#FFFF#;  
  constant data_mem_end_value_upper  : natural := 16#4003#;  
  
  ------------------------------------------------------------------------------

  -- Memory limitation control:
  -- In case the SCC was included, the following parameters allow the
  -- customization of the memory access control:

  -- Reserved memory areas access control. If the limitation_control flag is
  -- 1, the address produced in the data_path are verified to be < max_addr.
  constant imem_lowerlimitation_control : integer := 0;
  constant dmem_lowerlimitation_control : integer := 0;

  -- Highest address control. If the limitation_control flag is 1,
  -- the address produced in the data_path are verified to be min_addr < addr < max_addr.
  constant imem_upperlimitation_control : integer := 0;
  constant dmem_upperlimitation_control : integer := 0;
  
  constant instr_mem_max_addr_lower     : integer := 16#3fff#;
  constant instr_mem_max_addr_upper     : integer := 0;  
  constant data_mem_max_addr_lower      : integer := 16#ffff#;
  constant data_mem_max_addr_upper      : integer := 16#ffff#;

  constant instr_mem_min_addr_lower     : integer := 16#3fff#;
  constant instr_mem_min_addr_upper     : integer := 0;
  constant data_mem_min_addr_lower      : integer := 16#ffff#;
  constant data_mem_min_addr_upper      : integer := 16#ffff#;
    

  -- SCC STATUS REGISTER STARTUP VALUES ----------------------------------------

  -- a) STATUS REGISTER
  
  -- Startup value of the status register:
  -- User mode, Enable interrupts, unmask all interrupts
  constant status_bits : integer := 16#c0ff#; 
  
  -- status during reboot and interrupt servicing (kernel mode, interrupt disable,
  -- force Masking on all interrupts)
  -- During Reboot & interrupts the processor should be set to kernel mode,
  -- so it is strongly advised not to change bit 15 to 1 !
  constant intproc_status_bits : integer:= ( 16#0000#);
    
  -- b) CAUSE REGISTER
  -- (Specifies exception code "001100", that is hardware_reset (Issued at startup)
  constant cause_bits      : integer := 16#000c#;
  
  -- c) EPC and EPS are reset to 0 and can not be written, are only set in case
  -- of exception to describe what kind of exception has asked service

  
  -----------------------------------------------------------------------------
  --                     VERIFICATION   PARAMETERS  --
  -----------------------------------------------------------------------------

  -- The following constants will specify the processor behaviour with respect
  -- to its non-synthesizable verification logic.
  -- XiRisc allow the inclusion during simulation of a non-synthesizable block in the
  -- Xi_Core file, that represents the main processor entity.
  -- This block offers some debug and verification services that can be quite
  -- useful developing sotware and verifying the core behaviour. Services are
  -- offered intercepting processor breaks and serving them on the simulation Host
  -- rather than calling the appropriate servicing procedure as it would be the
  -- case on the HW implementation. Break services can also be selected separately.
  -- Note that this logic may slow down simulation speed, and was only tested
  -- on Modelsim though all constructs are standard VHDL!
  -- 

  constant include_verify      : integer :=1;
  constant include_wbtrace     : integer :=0;
  constant include_selfprofile : integer :=1;
  constant include_putchar     : integer :=1;

  -----------------------------------------------------------------------------
  --               BREAK  CODES                                              --
  -----------------------------------------------------------------------------

  constant break_suspend : integer := 16#100#;
  constant break_putchar : integer := 16#200#;
  constant break_putint  : integer := 16#201#;
  
end menu;

-- 
-- menu_body
--

package body menu is  
end menu;


