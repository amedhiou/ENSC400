---------------------------------------------------------------------------
--                          XI_VHF.VHD                                   --
--                                                                       --
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

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;
  use std.textio.all; 
  
  entity VHF is      
      port( clk          : in  Std_logic;
            pp_data_out  : in  Std_logic_vector(7 downto 0);
            pp_data_in   : out Std_logic_vector(7 downto 0);

            pp_direction : out Std_logic;  
            pp_control   : in  std_logic_vector(3 downto 0);  -- control signal
            pp_status    : out std_logic_vector(1 downto 0);  -- status signal            
              
            pp_out       : in  Std_logic;
            pp_in        : out std_logic );
    end VHF;
          
architecture BEH of VHF is

  signal control_out      : std_logic_vector(7 downto 0);
  signal status_in        : std_logic_vector(7 downto 0);
  signal data_out,data_in : std_logic_vector(7 downto 0);
  
begin  -- BEH

  -- Parallel port protocol: The pp is emulated through two integers, one
  -- representing all control bits, and one representing data bits.
  -- The pp is emulated as a bidirectional channel on files
  -- /usr/tmp/pp_to_host.vhf /usr/tmp/host_to_pp.vhf

  control_out(7)          <= '0';
  control_out(6)          <= pp_out;
  control_out(4)          <= pp_control(3);  -- Read Request
  control_out(5)          <= pp_control(2);  -- Write Request
  control_out(3)          <= pp_control(1);  -- Boot Request
  control_out(2 downto 0) <= "000";
                             
  pp_direction <= status_in(1);
  pp_in        <= status_in(0);
  pp_status    <= status_in(3 downto 2);

  data_out <= pp_data_out;
  pp_data_in <=data_in;
  
  process(CLK)
  file host_to_pp : text;
  variable open_status : file_open_status;
  variable l : line;
  variable c : character;
  variable datain_v,status_v : Integer;
  begin
      file_open(open_status,host_to_pp,"/usr/tmp/pport_host_to_pp.vhf",read_mode);
      
      if open_status/=open_ok then
        report("Trying to connect to External device");
        -- Connection still undone, default values come from pport
        datain_v := 0;
        status_v := 3;
      else
        readline(host_to_pp,l);
        read(l,datain_v);
        read(l,c);
        read(l,status_v);
        file_close(host_to_pp);
      end if;
            
      data_in    <= Conv_std_logic_vector(datain_v,8);
      status_in  <= Conv_std_logic_vector(status_v,8);      
  end process;

  
  process(CLK)
  file pp_to_host : text;
  variable open_status : file_open_status;
  variable l:line;
  begin
      file_open(open_status,pp_to_host,"/usr/tmp/pport_pp_to_host.vhf",write_mode);
      while open_status/=open_ok loop
        report("Trying to produce output towards external device");
        file_open(open_status,pp_to_host,"/usr/tmp/pport_pp_to_host.vhf",write_mode);
      end loop;     
        write(l,conv_integer(unsigned(data_out)) );
        write(l,string'(",") );
        write(l,conv_integer(unsigned(control_out)) );
        writeline(pp_to_host,l);
      file_close(pp_to_host);
  end process;

  
end BEH;
