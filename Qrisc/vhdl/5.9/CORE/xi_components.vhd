---------------------------------------------------------------------------
--                          XI_components.VHD                --
---------------------------------------------------------------------------
--                                                                       --
-- Created 2001 by F.M.Campi , fcampi@deis.unibo.it          --
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
-- This license is a modification of the Cadence Design Systems Source Code Public
-- License Version 1.0 which is similar to the Netscape public license.
-- We believe this license conforms to requirements adopted by OpenSource.org.
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- This Vhdl package contains a collection of simple logic devices such as
-- Registers and Multiplexers, that rather than being implicitly described in
-- the VHDL code or defined through general vhdl definition models, are
-- described in detail in a more or less DEDICATED entity block.


-- 1) They are not implicitly described in the behavioral VHDL code (i.e. using an
-- if statement rather then defining a MUX entity ), especially in the highest
-- level entities such as the datapath, the control block, or the main entity
-- for two main reasons:
-- a) The synopsys Synthesis tool is based on Wire load models. This means,
-- indipendent groups of logic cells, like the ones that build an "if"
-- statement, when included inside large logic blocks will have an estimated
-- connection load dependent on the Block area, with a consequently overestimated
-- delay leading to a bad timing performance.
-- b) Keeping all the FFs in a single register, or the sub blocks of the multiplexer
-- inside an entity, will ease and enhance the performance of any place&route Tool,
-- because being nested in a single hierarchical entity they will be placed
-- nearby instead of being scattered all over a large area.
--
-- 2) I find the flexibiliy of VHDL not so great, to the point that sometimes it
-- becomes very difficult to define a general purpose model that can be easily
-- reused without drawbacks such us complexity and unreadability.
-- Once decided to use explicit instantiation of Structural entities rather then
-- make inplicit component definition in the VHDL model, I though I might build a
-- library of general purpose components such as Multiplexers, and general purpose
-- Registers, and reuse them in different contexts with a smart utilization of the
-- GENERIC vhdl directive.
-- Unfortunately, such option turned out to be not so feasible:
-- The use of a general purpose register, and even worse of a multiplexer, would
-- have caused a very heavy and most of all UNREADABLE vhdl model.
-- As semplicity and readability are two fundamental aims of the whole
-- project, I preferred to define, when necessary, a huge set of MUXs and
-- Registers, often dedicated to a specific use in a determinate context,
-- instead of trying to adapt to different situation a single generic model.
-- All these specific entity models are collected in this package, that is
-- included by all the VHDL files in the processor hierarchy.

-------------------------------------------------------------------------------
--
-- PIPELINE FLOW SYNCHRONIZATION DEVICES
--
-- In this section are contained ALL the ( behavioral ) logic blocks in the
-- whole model that are actually not combinatorial:
-- All the synchronization device here described are simple arrays of F/Fs,
-- that sample input data on the raising edge of the CLK signal if the
-- ENABLE input is '1', and that can be resetted to a user-defined value
-- asynchronously by the RESET signal whose logic is defined in file
-- basic.vhd ( the reset signal is synchronized as it enters the
-- processor, see file top.vhd ).

-- As introduced before, There should be no need to define all these registers as
-- separate entities, this option has only been chosen to describe with the
-- appropriate names and data_types all the entity ports, and ease code
-- readability, even though all data_types are subtypes of Std_logic_vectors.


-- CONTROL BLOCK REGISTERS

----------------------------------------------------------------------------
-- FETCH REGISTER
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.menu.all;

entity Ireg_Fetch is
  generic ( iaddr_width       :     integer := 24;
            reset_value_lower :     integer := 16#1000#;
            reset_value_upper :     integer := 0;
            reboot_value_lower:     integer := 0;
            reboot_value_upper:     integer := 0 );
  
  port( clk,reset,reboot,enable   : in  std_logic;
        in_pc                     : in  Std_logic_vector(iaddr_width-1 downto 0);
        out_pc                    : out Std_logic_vector(iaddr_width-1 downto 0) );
end Ireg_Fetch;


architecture behavioral of Ireg_Fetch is

begin 
       
 process(CLK,reset)
  begin
    if reset = reset_active then 
      out_pc  <= Conv_std_logic_vector(reset_value_lower,Iaddr_width);  
    else      
      if CLK'event and CLK = '1' then
         if reboot=reset_active then 
           out_pc  <= Conv_std_logic_vector(reboot_value_lower,Iaddr_width);
         else
           if enable = '0' then
             out_pc <= in_pc;
           end if;
         end if;
      end if;
    end if;     
  end process;

end behavioral;



----------------------------------------------------------------------------
-- EXECUTE REGISTER
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.menu.all;
use work.basic.all;
use work.isa_32.all;

entity Ireg_Execute is
  generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  
  port( clk, reset, enable : in std_logic;

        in_alu_command               : in Alu_control;
        in_alu_immed                 : in Std_logic_vector(word_width-1 downto 0);
        in_shift_op1                 : in Risc_shiftcode;
        in_exe_outsel1               : in Risc_exeout;
        in_mul_command               : in Risc_mulop;
        in_mem_command               : in Mem_control;
        in_rd1                       : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;

        out_alu_command              : out Alu_control;
        out_alu_immed                : out Std_logic_vector(word_width-1 downto 0);
        out_shift_op1                : out Risc_shiftcode;
        out_exe_outsel1              : out Risc_exeout;
        out_mul_command              : out Risc_mulop;
        out_mem_command              : out Mem_control;
        out_rd1                      : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic );
end Ireg_Execute;

architecture behavioral of Ireg_Execute is
begin
  process(CLK, reset)
  begin

    if reset = reset_active then
      out_alu_command <= ( isel=>'1',op=>xi_alu_add,hrdwit=>'1' );
      out_alu_immed   <= ( others=>'0' );
      out_shift_op1   <= xi_shift_sll(2 downto 0);
      out_exe_outsel1 <= "000";
      out_mul_command <= xi_mul_nop;
      out_mem_command <= (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');

      out_rd1   <= (others => '0');
      out_rf_we <= '1';

    elsif CLK'event and CLK = '1' then
      if Enable = '0' then
        out_alu_command <= in_alu_command;
        out_alu_immed   <= in_alu_immed;
        out_shift_op1   <= in_shift_op1;
        out_exe_outsel1 <= in_exe_outsel1;
        out_mul_command <= in_mul_command;
        out_mem_command <= in_mem_command;

        out_rd1   <= in_rd1;
        out_rf_we <= in_rf_we;
      end if;
    end if;

  end process;
end behavioral;

----------------------------------------------------------------------------
-- MEMORY ACCESS REGISTER
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.menu.all;
use work.basic.all;
use work.isa_32.all;

entity Ireg_Memory is
  generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  port( clk, reset, enable : in std_logic;

        in_alu_command               : in Alu_control;
        in_alu_immed                 : in Std_logic_vector(word_width-1 downto 0);
        in_mem_command               : in Mem_control;
        in_rd1                       : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;
        in_serve_exception           : in std_logic;

        out_alu_command              : out Alu_control;
        out_alu_immed                : out Std_logic_vector(word_width-1 downto 0);
        out_mem_command              : out Mem_control;
        out_rd1                      : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic;
        out_serve_exception          : out std_logic );
end Ireg_Memory;

architecture behavioral of Ireg_Memory is
begin
  process(CLK, reset)
  begin

    if reset = reset_active then

      out_alu_command     <=  (isel=>'1',op=>xi_alu_add,hrdwit=>'1');
      out_alu_immed       <=  ( others => '0' );
      out_mem_command     <=  (mr=>'1',mw=>'1',mb=>'1',mh=>'1',sign=>'1');
      out_rd1             <= (others => '0');
      out_rf_we           <= '1';
      out_serve_exception <= '1';


    elsif CLK'event and CLK = '1' then
      if Enable = '0' then
        out_alu_command     <= in_alu_command;
        out_alu_immed       <= in_alu_immed;
        out_mem_command     <= in_mem_command;
        out_rd1             <= in_rd1;
        out_rf_we           <= in_rf_we;
        out_serve_exception <= in_serve_exception;
      end if;
    end if;

  end process;
end behavioral;


-------------------------------------------------------------------------------
-- DATA REGISTER
--
-- Generic word_width-Bit register,
-- used for the datapath registers, holds a plain Risc_word.
-- The value forced to output at RESET = active can be user-defined
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.menu.all;

entity Data_Reg is
  generic( init_value       :     integer := 0;
           reg_width        :     integer := 32 );
  
  port ( clk, reset, enable : in  std_logic;
         data_in            : in  std_logic_vector(reg_width-1 downto 0);
         data_out           : out std_logic_vector(reg_width-1 downto 0) );
end Data_Reg;


architecture behavioral of Data_Reg is
begin

  process(CLK, reset)
  begin

    if reset = reset_active then data_out <=
                                   Conv_std_logic_vector( init_value, reg_width );

    elsif CLK'event and CLK = '1' then
      if enable = '0' then data_out <= data_in;
      end if;
    end if;

  end process;

end behavioral;

-------------------------------------------------------------------------------
-- GENERAL PURPOSE Flip Flop
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.menu.all;

entity FlipFlop is
  port ( clk, reset, enable : in  std_logic;
         d           : in  std_logic;
         q           : out std_logic );
end FlipFlop;

architecture behavioral of FlipFlop is
begin

  process(CLK, reset)
  begin

    if reset = reset_active then q <= '0';
    elsif CLK'event and CLK = '1' then
      if enable = '0' then q <= d;
      end if;
    end if;

  end process;

end behavioral;


----------------------------------------------------------------------------
-- BYPASS CHANNEL SELECTION MULTIPLEXER  --
----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.basic.all;

entity BYPASS_MUX is
  generic( Word_Width      : positive := 32 );
  port ( byp_control : in  Risc_bypcontrol;
         rfile_out   : in  Std_logic_vector(Word_width-1 downto 0);
         Mainexe_out : in  Std_logic_vector(Word_width-1 downto 0);
         Mainmem_out : in  Std_logic_vector(Word_width-1 downto 0);
         byp_channel : out Std_logic_vector(Word_width-1 downto 0) );
end BYPASS_MUX;

architecture BEHAVIORAL of BYPASS_MUX is

begin  -- BEHAVIORAL

  process(byp_control, rfile_out, Mainexe_out, Mainmem_out)
  begin
    case byp_control is
      when Main_exe => byp_channel <= Mainexe_out;
      when Main_mem => byp_channel <= Mainmem_out;
      when others   => byp_channel <= rfile_out;
    end case;
  end process;

end BEHAVIORAL;


-- General purpose ADDER ------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;


entity gp_adder is
  generic ( width   :     integer := 32 );
  port ( in_a, in_b : in  std_logic_vector(width-1 downto 0);
         output     : out std_logic_vector(width-1 downto 0);
         overflow   : out std_logic );
end gp_adder;

architecture behavioral of gp_adder is

  signal sum : std_logic_vector(width downto 0);

begin  -- behavioral

  sum <= signed('0'&in_a) + signed('0'&in_b);

  overflow <= not ( sum(width) xor sum(width-1) );
  output   <= sum(width-1 downto 0);

end behavioral;

-------------------------------------------------------------------------------



------------------------------------------
-- COMPONENTS PACKAGE                   --
------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.basic.all;

package components is

  component Ireg_Fetch
    generic ( iaddr_width       :     integer := 24;
              reset_value_lower :     integer := 16#1000#;
              reset_value_upper :     integer := 0;
              reboot_value_lower:     integer := 0;
              reboot_value_upper:     integer := 0 );
    port( clk,reset,reboot,enable   : in  std_logic;
          in_pc                     : in  Std_logic_vector(iaddr_width-1 downto 0);
          out_pc                    : out Std_logic_vector(iaddr_width-1 downto 0) );
  end component;

  component Ireg_Execute
    generic( Word_Width      : positive := 32;
             rf_registers_addr_width : positive := 5 );
  
    port( clk, reset, enable : in std_logic;
          
          in_alu_command               : in Alu_control;
          in_alu_immed                 : in Std_logic_vector(word_width-1 downto 0);
          in_shift_op1                 : in Risc_shiftcode;
          in_exe_outsel1               : in Risc_exeout;
          in_mul_command               : in Risc_mulop;
          in_mem_command               : in Mem_control;
          in_rd1                       : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
          in_rf_we                     : in std_logic;

          out_alu_command              : out Alu_control;
          out_alu_immed                : out Std_logic_vector(word_width-1 downto 0);
          out_shift_op1                : out Risc_shiftcode;
          out_exe_outsel1              : out Risc_exeout;
          out_mul_command              : out Risc_mulop;
          out_mem_command              : out Mem_control;
          out_rd1                      : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
          out_rf_we                    : out std_logic );
  end component;

  component Ireg_Memory
  generic( Word_Width      : positive := 32;
           rf_registers_addr_width : positive := 5 );
  port( clk, reset, enable : in std_logic;

        in_alu_command               : in Alu_control;
        in_alu_immed                 : in Std_logic_vector(word_width-1 downto 0);
        in_mem_command               : in Mem_control;
        in_rd1                       : in Std_logic_vector(rf_registers_addr_width-1 downto 0);
        in_rf_we                     : in std_logic;
        in_serve_exception           : in std_logic;

        out_alu_command              : out Alu_control;
        out_alu_immed                : out Std_logic_vector(word_width-1 downto 0);
        out_mem_command              : out Mem_control;
        out_rd1                      : out Std_logic_vector(rf_registers_addr_width-1 downto 0);
        out_rf_we                    : out std_logic;
        out_serve_exception          : out std_logic ); 
  end component;

  component Data_Reg
    generic( init_value       :     integer := 0;
             reg_width        :     integer := 32 );
  
    port ( clk, reset, enable : in  std_logic;
           data_in            : in  std_logic_vector(reg_width-1 downto 0);
           data_out           : out std_logic_vector(reg_width-1 downto 0) ); 
  end component;

  component FlipFlop is
   port ( clk, reset, enable : in  std_logic;
          d           : in  std_logic;
          q           : out std_logic );
  end component;   

  component BYPASS_MUX
    generic( Word_Width      : positive := 32 );
    port ( byp_control : in  Risc_bypcontrol;
           rfile_out   : in  Std_logic_vector(Word_width-1 downto 0);
           Mainexe_out : in  Std_logic_vector(Word_width-1 downto 0);
           Mainmem_out : in  Std_logic_vector(Word_width-1 downto 0);
           byp_channel : out Std_logic_vector(Word_width-1 downto 0) ); 
  end component;

  component GP_ADDER
    generic ( width   :     integer := 32 );
    port ( in_a, in_b : in  std_logic_vector(width-1 downto 0);
           output     : out std_logic_vector(width-1 downto 0);
           overflow   : out std_logic );  
  end component;

end components;

package body components is
end components;

