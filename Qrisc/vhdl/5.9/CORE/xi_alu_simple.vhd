----------------------------------------------------------------------
--                   XI_ALU.VHD                                     --
--                                                                  --
-- Created by F.M.Campi , fcampi@deis.unibo.it                      --
-- DEIS, Department of Electronics Informatics and Systems,         --
-- University of Bologna, BOLOGNA , ITALY                           --
----------------------------------------------------------------------

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
-- This license is a modification of the Cadence Design Systems Source Code
-- Public License Version 1.0 which is similar to the Netscape public license.  
-- We believe this license conforms to requirements adopted by OpenSource.org.  
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------

-- Description of a combinatorial Arithmetical/Logical unit
-- for 32-bit Arithmetics

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.isa_32.all;
  use work.basic.all;  

entity Main_alu is
    generic( Word_Width      : positive := 32 );
    port(  in_a         : in  Std_logic_vector(Word_Width-1 downto 0);
           in_b         : in  Std_logic_vector(Word_Width-1 downto 0);
           op           : in  Risc_Alucode;
           result       : out Std_logic_vector(word_width-1 downto 0);
           overflow     : out Std_logic );
end Main_alu;


architecture structural of Main_alu is

 ----------------------------------------------------------------
 --  Arithmetic operations
 ----------------------------------------------------------------
 --synopsys synthesis_off 
  type spy_alu is (alu_add,alu_addu,alu_sub,alu_subu,alu_slt,alu_sltu,alu_and,alu_or,alu_xor,alu_nor,alu_nop,alu_err);
  signal spy : spy_alu;
 --synopsys synthesis_on 
  
 signal sum,diff  : Std_logic_vector(Word_Width-1 downto 0);

 begin

  --synopsys synthesis_off
  ALUSPY: process(op)
  begin
    if (op = xi_alu_add) then
       spy <= alu_add;
    elsif (op = xi_alu_addu) then
       spy <= alu_addu;
    elsif (op = xi_alu_sub) then
       spy <= alu_sub;
    elsif (op = xi_alu_subu) then
       spy <= alu_subu;
    elsif (op = xi_alu_slt) then
       spy <= alu_slt;
    elsif (op = xi_alu_sltu) then
       spy <= alu_sltu;
    elsif (op = xi_alu_and) then
       spy <= alu_and;
    elsif (op = xi_alu_or) then
       spy <= alu_or;
    elsif (op = xi_alu_nor) then
       spy <= alu_nor;
    elsif (op = xi_alu_xor) then
       spy <= alu_xor;
    elsif (op = xi_alu_nop) then
       spy <= alu_nop;
    else
       spy <= alu_err;
    end if;
  end process;
  --synopsys synthesis_on

    
  sum  <= signed(in_a) + signed(in_b);
  diff <= signed(in_a) - signed(in_b);
   
  OUTPUT_RESULT : process(in_a,in_b,op,sum,diff)  
  begin

    if (op = xi_alu_add) or (op = xi_alu_addu) then
                   result <= sum;
    elsif (op = xi_alu_sub) or (op = xi_alu_subu) then
                   result <=  diff;           
                      
     -----------------------------------------------------------------------
     --    COMPARATIONS
     --      
     -- The Alu1 - Alu2 subtraction output is checked to determine the
     -- operation result, that is 0 if the comparation is False, 1 if true.
     -----------------------------------------------------------------------

     elsif op = xi_alu_slt then
           if signed(in_a) < signed(in_b) then
               result <= EXT("1",word_width);
           else
               result <= EXT("0",word_width);
           end if;
     elsif op = xi_alu_sltu then
           if unsigned(in_a) < unsigned(in_b) then
               result <= EXT("1",word_width);
           else
               result <= EXT("0",word_width);
           end if;          
               
     -----------------------------------------------------------------------
     --            LOGIC OPERATORS
     -----------------------------------------------------------------------
           
     elsif op = xi_alu_and then
               result <= in_a and in_b;

     elsif op = xi_alu_or then
               result <= in_a or in_b;

     elsif op = xi_alu_xor then
               result <= in_a xor in_b;

     elsif op = xi_alu_nor then
               result <= in_a nor in_b;

     else result <= in_a;

     end if;
     
  end process;   


  -- Two's component overflow: the overflow is 
  
  OUTPUT_OVERFLOW:
     process(in_a,in_b,sum,diff,op)
     begin
       if op = xi_alu_add then
          if ( in_a(word_width-1) /= in_b(word_width-1) )  or
                ( in_a(word_width-1) = sum(word_width-1) ) then
                overflow <= '1';        -- No overflow configuration.
             else
                overflow <= '0';        -- Overflow configuration
             end if;
                
       elsif op = xi_alu_sub then
             if ( in_a(word_width-1) = in_b(word_width-1) )  or
                ( in_a(word_width-1) = diff(word_width-1) ) then
                overflow <= '1';
             else
                overflow <= '0';
             end if;                     
       else
             overflow <= '1';
       end if;
     end process;
       
end structural;
