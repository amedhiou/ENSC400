------------------------------------------------------------------------ 
--                             XI_VERIFY.VHD                          --
--                                                                    --
------------------------------------------------------------------------
-- Created 2004 by F.M.Campi , fcampi@deis.unibo.it                   --
-- ARCES, Advanced Research Center on Electronic Systems              --
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

-- This block include non-synthesizable logic that can be included in the
-- XiRisc core to provide verification services.

-- All services are handled and controlled by software via specific BREAK codes.
-- In the XiRisc processor architecture break codes from 0 to 63 are used to
-- generate software traps.
-- All other codes can be used to require special services for verification.
-- Essentially, this logic will intercept some break codes that are bound to raise
-- exception, and will instead handle them correctly and produce an idle
-- cop instruction instead.
-- In case (i.e. after synthesis) this logic is not present, the break code
-- will arise the normal exception and will be served by the servicing
-- procedure.In practice, this is a shortcut for special break services!


--             VERIFICATION  SERVICES  OFFERED  BY  XI_VERIFY:

-- 1) Writeback Trace, that can be compared to Gdb/Lisa generated Traces to provide
--    automatic bug spotting
--    break 0x164 -> Trace on
--    break 0x165 -> Trace off
--
-- 2) Putchar, used to implement standard IO on the simulation Host OS
--    break 0x200 -> Put $4 on std_output
--
-- 3) Cycle count (Profiling), to evaluate the cycles spent in a given function
--    break 0x160 -> Reset cycle count
--    break 0x161 -> Write cycle count on std_output

-------------------------------------------------------------------------------
--                               CONVCHAR  --
--                                                                           --
-- Package used to implement writes on std_output from a VHDL environment    --
-------------------------------------------------------------------------------

package convchar is

  use std.textio.all;
  
  procedure conv_char(c: out character; value: in integer);

end convchar;

use std.textio.all;

package body convchar is  

  procedure  conv_char(c: out character; value: in integer) is
  begin
      
        case (value) is
              when character'pos('0') => c:='0'; 
              when character'pos('1') => c:='1';
              when character'pos('2') => c:='2';
              when character'pos('3') => c:='3';
              when character'pos('4') => c:='4';
              when character'pos('5') => c:='5';
              when character'pos('6') => c:='6';
              when character'pos('7') => c:='7';
              when character'pos('8') => c:='8';
              when character'pos('9') => c:='9';                         
              when character'pos('a') => c:='a';
              when character'pos('b') => c:='b';
              when character'pos('c') => c:='c';
              when character'pos('d') => c:='d';
              when character'pos('e') => c:='e';
              when character'pos('f') => c:='f';
              when character'pos('g') => c:='g';
              when character'pos('h') => c:='h';
              when character'pos('i') => c:='i';
              when character'pos('l') => c:='l';
              when character'pos('m') => c:='m';
              when character'pos('n') => c:='n';
              when character'pos('o') => c:='o';
              when character'pos('p') => c:='p';
              when character'pos('q') => c:='q';
              when character'pos('r') => c:='r';
              when character'pos('s') => c:='s';
              when character'pos('t') => c:='t';                         
              when character'pos('u') => c:='u';
              when character'pos('v') => c:='v';
              when character'pos('w') => c:='w';
              when character'pos('z') => c:='z';
              when character'pos('x') => c:='x';
              when character'pos('y') => c:='y';
              when character'pos('j') => c:='j';
              when character'pos('k') => c:='k';
              when character'pos('A') => c:='A';
              when character'pos('B') => c:='B';
              when character'pos('C') => c:='C';
              when character'pos('D') => c:='D';
              when character'pos('E') => c:='E';
              when character'pos('F') => c:='F';
              when character'pos('G') => c:='G';
              when character'pos('H') => c:='H';
              when character'pos('I') => c:='I';
              when character'pos('L') => c:='L';
              when character'pos('M') => c:='M';
              when character'pos('N') => c:='N';
              when character'pos('O') => c:='O';
              when character'pos('P') => c:='P';
              when character'pos('Q') => c:='Q';
              when character'pos('R') => c:='R';
              when character'pos('S') => c:='S';
              when character'pos('T') => c:='T';                         
              when character'pos('U') => c:='U';
              when character'pos('V') => c:='V';
              when character'pos('W') => c:='W';                           
              when character'pos('Z') => c:='Z';
              when character'pos('X') => c:='X';
              when character'pos('Y') => c:='Y';
              when character'pos('J') => c:='J';
              when character'pos('K') => c:='K';              
              when character'pos('(') => c:='(';
              when character'pos(')') => c:=')';                         
              when 91 => c:='[';
              when 93 => c:=']';
              when character'pos('{') => c:='{';
              when character'pos('}') => c:='}';
              when 45 => c:='-';
              when character'pos('`') => c:='`';
              when character'pos('+') => c:='+';
              when character'pos('=') => c:='=';
              when character'pos('*') => c:='*';
              when character'pos('/') => c:='/';
              when character'pos('\') => c:='\';
              when character'pos('>') => c:='>';
              when character'pos('<') => c:='<';
              when character'pos('.') => c:='.';
              when character'pos(',') => c:=',';
              when character'pos(';') => c:=';';
              when character'pos(':') => c:=':';
              when character'pos('!') => c:='!';
              when character'pos('@') => c:='@';
              when character'pos('#') => c:='#';
              when character'pos('$') => c:='$';
              when character'pos('%') => c:='%';
              when character'pos('^') => c:='^';
              when character'pos('&') => c:='&';
              when character'pos('_') => c:='_';
              when character'pos('?') => c:='?';              
              when 0  => c:=nul;                                         
              when 10 => c:=lf; 
              when others => c :=' ';
        end case;
          
    end conv_char;
end convchar;


-------------------------------------------------------------------------------
--                      XI_VERIFY                                            --
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

-- synopsys synthesis_off
use IEEE.std_logic_textio.all;
use std.textio.all;
use work.convchar.all;
-- synopsys synthesis_on

use work.menu.all;
use work.basic.all;
use work.isa_32.all;


  
entity xi_verify is
  
  generic( Word_Width              : positive := 32;
           Iaddr_width             : positive := 24;
           rf_registers_addr_width : positive := 5;
           include_wbtrace     : integer :=1;
           include_selfprofile : integer :=1;
           include_putchar     : integer :=1 );
  
  port( clk,reset,enable_dx,enable_mw,d_we : in Std_logic;

        argument  : in Std_logic_vector(Word_width-1 downto 0);
              
        rd1    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
        d1_in  : in  Std_logic_vector(Word_width-1 downto 0);

        break_code      : in  Std_logic_vector(Word_width-1 downto 0);
        
        Cop_command_in  : in  Cop_control;               
        Cop_command_out : out Cop_control
        );
  
end xi_verify;

architecture NON_SYNTH of xi_verify is

begin  -- NON_SYNTH

  -- synopsys synthesis_off
 
  -- The following process can generate a wb trace that can monitor
  -- the computation and compare it with LISA
WBTRACE_LOGIC: if include_wbtrace=1 generate

  RFILE_TRACE: process(clk)
    file output : text open write_mode is "wbtrace";
    variable l:line;
    variable trace_active : integer :=1;
    variable trace_cycles : integer :=0;
  begin
    if (clk'event and clk='0') then
      
      if (conv_integer(unsigned(rd1))/=0 and enable_mw='0') then
        write(l,trace_cycles);
        write(l,string'(":R[") );
        write(l,conv_integer(unsigned(rd1) ));
        write(l,string'("]=") );
        hwrite(l,d1_in,RIGHT,8);  -- Hexadecimal output
        writeline(output,l);

      elsif ( enable_dx='0' and Cop_command_in.op=xi_system_break
              and conv_integer( unsigned(break_code) )=16#164# ) then
        trace_active := 1;
      elsif ( enable_dx='0' and Cop_command_in.op=xi_system_break
              and conv_integer( unsigned(break_code) )=16#165#) then
        trace_active := 0;
      end if;
      
      trace_cycles := trace_cycles+1;            
    end if;               
end process;    

end generate WBTRACE_LOGIC;
     
  -- This logic can reset/perform a cycle count to profile applications
  -- directly on hardware

SELFPROFILE_LOGIC: if include_selfprofile=1 generate               
  PROF_HANDLE: process(clk)
    file output : text;
    variable open_status : file_open_status;
    variable l : line;
    variable c : character;  
    variable prof_cycles : integer;
  begin
    if clk'event and clk='0' then
      
      if conv_integer(unsigned(break_code) )=16#160# then
        prof_cycles := 0;
      else
        prof_cycles := prof_cycles+1;
      end if;

    elsif ( enable_dx='0' and d_we='0' and Cop_command_in.op=xi_system_break
            and Conv_integer(unsigned(break_code) )=16#161# )  then
      
      file_open(open_status,output,"std_output",append_mode);
      if open_status/=open_ok then
        report("Experiencing problems in opening output file!") severity Error;
      else
        write(l,string'("Profiling Cycles: ") );
        write(l,prof_cycles);
        writeline(output,l);
        file_close(output);
      end if;
      
    end if;
  end process;

end generate SELFPROFILE_LOGIC;


PUTCHAR_LOGIC: if include_putchar=1 generate
                                        
  -- This logic performs putchars and putints
  PUTCHAR_HANDLE: process(CLK)
    file output : text;
    variable open_status : file_open_status;
    variable l:line;
    variable c:character;
    variable v:integer;
  begin
    if clk'event and clk='0' then
      
      if reset=reset_active then
        -- Cleaning the std_output file
        file_open(open_status,output,"std_output",write_mode);
        if open_status/=open_ok then
          report("Experiencing problems in opening output file!") severity Error;
        else
          file_close(output);
        end if;             
      
      elsif ( enable_dx='0' and d_we='0' and Cop_command_in.op=xi_system_break
              and Conv_integer( unsigned(break_code) )=16#200# ) then
        -- Break 0x200, PUTCHAR
        file_open(open_status,output,"std_output",append_mode);
      
        v:=conv_integer(unsigned(argument) );
        conv_char(c,v);
        
        if (c=lf) or (c=nul) then
          writeline(output,l);
          file_close(output);
        else
          write(l,c);
        end if;       
        
      elsif ( enable_dx='0' and Cop_command_in.op=xi_system_break and
           conv_integer( unsigned(break_code) )=16#201# ) then      
           -- Break 0x201, PUTINT
           file_open(open_status,output,"std_output",append_mode);      
           hwrite(l,argument,RIGHT,8);  -- Hexadecimal output
           writeline(output,l);
           file_close(output);
      end if;
      
    end if;
  end process;

end generate PUTCHAR_LOGIC;
   
  
  -- synopsys synthesis_on

  -- If the break code is not one of the breaks served by this logic it is
  -- passed over to the Scc !!!
  process(Cop_command_in,break_code)
  begin

    Cop_command_out.op <= Cop_command_in.op;

    -- synopsys synthesis_off
    
    if (Cop_command_in.op = xi_system_break) and 
      ( conv_integer(unsigned(break_code))=16#106# or
        conv_integer(unsigned(break_code))=16#160# or
        conv_integer(unsigned(break_code))=16#161# or
        conv_integer(unsigned(break_code))=16#164# or
        conv_integer(unsigned(break_code))=16#165# or
        conv_integer(unsigned(break_code))=16#200# or
        conv_integer(unsigned(break_code))=16#201# ) then
      
      Cop_command_out.op <= xi_system_null;
    else  
      Cop_command_out.op <= Cop_command_in.op;
    end if;

    -- synopsys synthesis_on
    
  end process;
  
end NON_SYNTH;



