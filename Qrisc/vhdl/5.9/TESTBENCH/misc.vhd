-----------------------------------------------------------------------
--                     MISC.vhd
-----------------------------------------------------------------------

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

-- Package describing a simple interface Hex_string / Std_logic_vector


library IEEE;
  use IEEE.std_logic_1164.all;

package misc is

  use std.textio.all;
  
  procedure hex2slv(l: inout Line ; value: out Std_logic_vector);

end misc;


package body misc is

  use std.textio.all;

  procedure hex2slv(l: inout Line ; value: out Std_logic_vector) is

   constant digits     : Integer := (value'length /4);
   variable c          : Character;
   variable four_bits  : Std_logic_vector(3 downto 0);
   variable Good_digit : Boolean;
        
    begin

        for i in 0 to digits-1 loop
            read (l,c,good_digit);
            case (c) is
              when '0' => four_bits := "0000";
              when '1' => four_bits := "0001";
              when '2' => four_bits := "0010";
              when '3' => four_bits := "0011";
              when '4' => four_bits := "0100";
              when '5' => four_bits := "0101";
              when '6' => four_bits := "0110";
              when '7' => four_bits := "0111";
              when '8' => four_bits := "1000";
              when '9' => four_bits := "1001";
              when 'a' => four_bits := "1010";
              when 'b' => four_bits := "1011";
              when 'c' => four_bits := "1100";
              when 'd' => four_bits := "1101";
              when 'e'=> four_bits := "1110";
              when 'f' => four_bits := "1111";
              when 'A' => four_bits := "1010";
              when 'B' => four_bits := "1011";
              when 'C' => four_bits := "1100";
              when 'D' => four_bits := "1101";
              when 'E'=> four_bits := "1110";
              when 'F' => four_bits := "1111";            
              when others => four_bits :="0000";
            end case;
            value( value'length-1 -4*i downto value'length-4 -4*i ) := four_bits;
        end loop;            
    end hex2slv;

end misc;
