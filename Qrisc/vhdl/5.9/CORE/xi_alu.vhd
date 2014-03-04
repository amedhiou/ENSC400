----------------------------------------------------------------------
--                   XI_ALU_NEW.VHD                                 --
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

-- This file was modified to support saturation arithmetic by M.Lombardini, Jan
-- 2003


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;

entity adder_8  is
port ( a, b : in  std_logic_vector(7 downto 0);
       cin  : in  std_logic;
       y    : out std_logic_vector(7 downto 0);
       cout : out std_logic );
end adder_8 ;


architecture BEHAVIORAL of adder_8 is
signal sum,cin_v : std_logic_vector(8 downto 0);
begin  -- BEHAVIORAL

  cin_v <= "00000000"&cin;
  
  sum  <= signed(ext(a,9)) + signed(ext(b,9)) + signed(cin_v);
  y    <= sum(7 downto 0);
  cout <= sum(8);

end BEHAVIORAL;


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;

entity sub_8  is
port ( a, b : in  std_logic_vector(7 downto 0);
       sin  : in  std_logic;
       y    : out std_logic_vector(7 downto 0);
       sout : out std_logic );
end sub_8 ;


architecture BEHAVIORAL of sub_8 is
signal diff,sin_v : std_logic_vector(8 downto 0);
begin  -- BEHAVIORAL

  sin_v <= "00000000"&sin;
  
  diff  <= signed(ext(a,9)) - signed(ext(b,9)) - signed(sin_v);
  y    <= diff(7 downto 0);
  sout <= diff(8);

end BEHAVIORAL;


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;

entity adder_32  is
port ( a, b : in  std_logic_vector(31 downto 0);
       y    : out std_logic_vector(31 downto 0);
       cout : out std_logic );
end adder_32 ;


architecture BEHAVIORAL of adder_32 is
signal sum  : std_logic_vector(32 downto 0);
begin  -- BEHAVIORAL  
  
  sum  <= signed(ext(a,33)) + signed(ext(b,33)) ;
  y    <= sum(31 downto 0);
  cout <= sum(32);

end BEHAVIORAL;


library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;

entity sub_32  is
port ( a, b : in  std_logic_vector(31 downto 0);
       y    : out std_logic_vector(31 downto 0);
       sout : out std_logic );
end sub_32 ;


architecture BEHAVIORAL of sub_32 is
signal diff,sin_v : std_logic_vector(32 downto 0);
begin  -- BEHAVIORAL

  
  diff  <= signed(ext(a,33)) - signed(ext(b,33)) ;
  y    <= diff(31 downto 0);
  sout <= diff(32);

end BEHAVIORAL;

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  

entity Main_alu is
    port(  in_a          : in  Risc_word;
           in_b          : in  Risc_word;
           saturate_mode : in  Std_logic;
           op            : in  Risc_Alucode;
           result        : out Std_logic_vector(word_width-1 downto 0);
           overflow      : out Std_logic );
end Main_alu;

architecture structural of Main_alu is

 ----------------------------------------------------------------
 --  Arithmetic operations
 ----------------------------------------------------------------
  component adder_8
    port ( a, b : in  std_logic_vector(7 downto 0);
           cin  : in  std_logic;
           y    : out std_logic_vector(7 downto 0);
           cout : out std_logic );
  end component;

  component sub_8
    port ( a, b : in  std_logic_vector(7 downto 0);
           sin  : in  std_logic;
           y    : out std_logic_vector(7 downto 0);
           sout : out std_logic);
  end component;

  component adder_32
    port ( a, b : in  std_logic_vector(31 downto 0);
           y    : out std_logic_vector(31 downto 0);
           cout : out std_logic);
  end component;
  
 component sub_32
    port ( a, b : in  std_logic_vector(31 downto 0);
           y    : out std_logic_vector(31 downto 0);
           sout : out std_logic);
  end component;
  
 signal cout_addu,cout_subu,cout_add_sub       : std_logic;
 signal Lo                      : std_logic;
 signal sum3,sum2,sum1,sum0     : std_logic_vector(7 downto 0);
 signal diff3,diff2,diff1,diff0 : std_logic_vector(7 downto 0);
 signal sum3_2,sum2_2,sum1_2,sum0_2     : std_logic_vector(7 downto 0);
 signal diff3_2,diff2_2,diff1_2,diff0_2 : std_logic_vector(7 downto 0);
 signal sum3_4,sum2_4,sum1_4,sum0_4     : std_logic_vector(7 downto 0);
 signal diff3_4,diff2_4,diff1_4,diff0_4 : std_logic_vector(7 downto 0); 
 signal cin3,cin2,cin1,cin0     : std_logic;
 signal sin3,sin2,sin1,sin0     : std_logic;
 signal co3,co2,co1,co0         : std_logic;
 signal so3,so2,so1,so0         : std_logic;
 signal sum,diff                : risc_word;
 
 begin

 
SAT_ARITHMETIC: if (include_sat_arithmetic=1) generate
  

ADD4_LOGIC: if (include_parallel_alu=1)  generate

   Lo <= '0';

   process(op,co2,co1,co0,Lo)
    begin
     if op=alu_add4 then
      cin3 <= Lo;
      cin2 <= Lo;
      cin1 <= Lo;
      cin0 <= Lo;
     elsif op=alu_add2 then
       
      cin3 <= co2;
      cin2 <= Lo;
      cin1 <= co0;
      cin0 <= Lo;
     else
      cin3 <= co2;
      cin2 <= co1;
      cin1 <= co0;
      cin0 <= Lo;

    
    end if;
  end process;
      
      fa3 : adder_8 port map (in_a(31 downto 24),in_b(31 downto 24),cin3,sum3,cout_addu);
      fa2 : adder_8 port map (in_a(23 downto 16),in_b(23 downto 16),cin2,sum2,co2);
      fa1 : adder_8 port map (in_a(15 downto  8),in_b(15 downto  8),cin1,sum1,co1);
      fa0 : adder_8 port map (in_a( 7 downto  0),in_b( 7 downto  0),cin0,sum0,co0);

 
sum <= sum3&sum2&sum1&sum0;
 

-------------------------------------------------------------------------------
-- CONTROL OF THE OUTPUT DURING ADDITION WITH SATURATION ARITHMETIC
-------------------------------------------------------------------------------

process(co1,sum1,sum0)
  begin
     if co1='1' then
           sum1_2 <= (others => '1');
           sum0_2 <= (others => '1');
     else
           sum1_2 <= sum1;
           sum0_2 <= sum0;
     end if;
  end process;
  

process(cout_addu,sum2,sum3)
  begin
     if cout_addu='1' then
           sum2_2 <= (others => '1');
           sum3_2 <= (others => '1');
         else
           sum2_2 <= sum2;
           sum3_2 <= sum3;
         end if;
     end process;

process(co0,sum0)
  begin
         if co0='1' then
           sum0_4 <= (others => '1');
         else
           sum0_4 <= sum0;
         end if;
  end process;
process(co1,sum1)
  begin
         if co1='1' then
           sum1_4 <= (others => '1');
         else
           sum1_4 <= sum1;
         end if;
  end process;
  
  process(co2,sum2)
    begin
         if co2='1' then
           sum2_4 <= (others => '1');
         else
           sum2_4 <= sum2;
         end if;
    end process;
 process(cout_addu,sum3)
   begin
         if cout_addu='1' then
           sum3_4 <= (others => '1');
         else
           sum3_4 <= sum3;
         end if;
   end process;
-------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------



  process(op,so2,so1,so0,Lo)
  begin
    if op=alu_sub4 then
      sin3 <= Lo;
      sin2 <= Lo;
      sin1 <= Lo;
      sin0 <= Lo;

    elsif op=alu_sub2 then
      sin3 <= so2;
      sin2 <= Lo;
      sin1 <= so0;
      sin0 <= Lo;
     else
      sin3 <= so2;
      sin2 <= so1;
      sin1 <= so0;
      sin0 <= Lo;
     end if;
  end process;

  
      sub4 : sub_8 port map (in_a(31 downto 24),in_b(31 downto 24),sin3,diff3,cout_subu);
      sub3 : sub_8 port map (in_a(23 downto 16),in_b(23 downto 16),sin2,diff2,so2);
      sub2 : sub_8 port map (in_a(15 downto  8),in_b(15 downto  8),sin1,diff1,so1);
      sub1 : sub_8 port map (in_a( 7 downto  0),in_b( 7 downto  0),sin0,diff0,so0);



 diff <= diff3&diff2&diff1&diff0;
-------------------------------------------------------------------------------
-- CONTROL OF THE OUTPUT DURING SUBTRACTION WITH SATURATION ARITHMETIC 
-------------------------------------------------------------------------------   
 process(so1,diff0,diff1)
   begin
         if so1='1' then
           diff1_2 <= (others => '0');
           diff0_2 <= (others => '0');
         else
           diff1_2 <= diff1;
           diff0_2 <= diff0;
         end if;
   end process;

  process(cout_subu,diff2,diff3)
    begin
          if cout_subu='1' then
           diff3_2 <= (others => '0');
           diff2_2 <= (others => '0');
          else
           diff2_2 <= diff2;
           diff3_2 <= diff3;
          end if;
    end process;

process(so0,diff0)
  begin
          if so0='1' then
           diff0_4 <= (others => '0');
         else
           diff0_4 <= diff0;
         end if;
  end process;
process(so1,diff1)
  begin
         if so1='1' then
           diff1_4 <= (others => '0');
         else
           diff1_4 <= diff1;
         end if;
  end process;
process(so2,diff2)
  begin
         if so2='1' then
           diff2_4 <= (others => '0');
         else
           diff2_4 <= diff2;
         end if;
  end process;
process(cout_subu,diff3)
  begin
         if cout_subu='1' then
           diff3_4 <= (others => '0');
         else
           diff3_4 <= diff3;
         end if;
  end process;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
   
-- Two's component overflow: the overflow is 



 OUTPUT_OVERFLOW:

    process(in_a,in_b,sum,diff,op)
     begin 
       if op = alu_add then
          if  (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) )) then
                overflow <= '1';
                cout_add_sub <='0';
             else
                overflow <= '0';
                cout_add_sub <= '1';
             end if;                    
                
                     
        elsif op=alu_sub   then
             if (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) then
                  overflow<='1';
                  cout_add_sub <= '0';
             else
               overflow<='0';
               cout_add_sub <= '1';
             end if;
    
                       
--         elsif op=alu_add4  then
--                if   (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) ))and
--                     (( in_a(23) /= in_b(23) ) or ( in_a(23) = sum(23))) and
 --                    (( in_a(15) /= in_b(15) ) or ( in_a(15) = sum(15))) and
 --                    ((in_a(7) /= in_b(7)) or (in_a(7) = sum(7))) then
 --                 overflow<='1';
 --                else
 --                  overflow<='0';
 --                end if;
                

         
 --     elsif op = alu_sub4 then 
 --            if  (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) and 
 --                (( in_a(23) = in_b(23) )  or( in_a(23) = diff(23) )) and 
 --                  (( in_a(15) = in_b(15) )  or ( in_a(15) = diff(15) )) and 
 --              (( in_a(7) = in_b(7) )  or ( in_a(7) = diff(7))) then
   
 --                 overflow <= '1';
 --          else
 --              overflow <= '0';
 --          end if;

                  
 --       elsif op=alu_add2  then
 --               if   (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) ))and
 --                    (( in_a(15) /= in_b(15) ) or ( in_a(15) = sum(15))) then
 --                  overflow<='1';
 --                else
 --                  overflow<='0';
 --                end if;
                

         
--      elsif op = alu_sub2 then 
--             if  (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) and 
--                 (( in_a(15) = in_b(15) )  or ( in_a(15) = diff(15) )) then
   
--                  overflow <= '1';
--           else
 --              overflow <= '0';
--           end if;

      else
                 overflow <= '1';         
                 cout_add_sub <= '0';
       end if;

     end process;
    
 end generate ADD4_LOGIC;

 NO_ADD4_LOGIC : if(include_parallel_alu/=1) generate
   
 add1 : adder_32 port map (in_a(31 downto 0),in_b(31 downto 0),sum,cout_addu);
 sub1 : sub_32 port map (in_a(31 downto 0),in_b(31 downto 0),diff,cout_subu);


  
    OUTPUT_OVERFLOW:
     process(in_a,in_b,sum,diff,op)
     begin

       if op = alu_add then
          if  ( in_a(word_width-1) /= in_b(word_width-1) )  or
                ( in_a(word_width-1) = sum(word_width-1) ) then
                overflow <= '1';
                cout_add_sub <= '0';
          else
                overflow <= '0';
                cout_add_sub<='1' ;
          end if;                    
                
       elsif op = alu_sub then
             if ( in_a(word_width-1) = in_b(word_width-1) )  or
                ( in_a(word_width-1) = diff(word_width-1) ) then
                overflow <= '1';
                cout_add_sub<= '0';
             else
                overflow <= '0';
                cout_add_sub<= '1';
             end if;

       else
         overflow <= '1';
         cout_add_sub<= '0';
       end if;
       
--       elsif op = alu_addu then
--         overflow <= '1';
--          if  ( in_a(word_width-1) /= in_b(word_width-1) )  or
--                ( in_a(word_width-1) = sum(word_width-1) ) then
--                cout <= '1';
--             else
--                cout <= '0';
--             end if;                    
--                
--       elsif op = alu_subu then
--         overflow <= '1';
--             if ( in_a(word_width-1) = in_b(word_width-1) )  or
--                ( in_a(word_width-1) = diff(word_width-1) ) then
--                cout <= '1';
--             else
--                cout <= '0';
--             end if;                     
--       else
--             overflow <= '1';
--             cout <= '1';
--       end if;

       
     end process;
       
 end generate NO_ADD4_LOGIC;


     
   
  OUTPUT_RESULT : process(in_a,in_b,op,sum,diff,sum0,sum1,sum2,sum3,diff0,diff1,diff2,diff3,cout_addu,cout_subu,cout_add_sub,saturate_mode,sum0_2,sum1_2,sum2_2,sum3_2,sum0_4,sum1_4,sum2_4,sum3_4,diff0_2,diff1_2,diff2_2,diff3_2,diff0_4,diff1_4,diff2_4,diff3_4)    
  begin

    case op is
      
     -----------------------------------------------------------------------
     --  ARITHMETIC OPERATIONS
     -----------------------------------------------------------------------
    
     when  alu_addu  =>
       if saturate_mode='1' and cout_addu='1' then
         result <= (others => '1');
       else
         result <= sum;
       end if;
       
     when alu_add =>
       if saturate_mode='1' and cout_add_sub='1' then
         if sum(31)='1' then
          result<=(others => '1') ;
          result(word_width-1)<='0';
         else
          result<=(others => '0') ;
          result(word_width-1)<='1';
         end if;
       else   
         result <= sum;
       end if;
      
     when alu_add2 =>
       if saturate_mode='1' then
         result <= sum3_2&sum2_2&sum1_2&sum0_2;
       else
         result <= sum3&sum2&sum1&sum0;
       end if;
         
     when  alu_add4 =>
       if saturate_mode='1' then
         result <= sum3_4&sum2_4&sum1_4&sum0_4;
       else
         result <= sum3&sum2&sum1&sum0;
       end if;
                
     when  alu_sub =>
        if saturate_mode='1' and cout_add_sub='1' then
          if diff(31)='0' then
         
         result <= (others => '0');
         result(word_width-1)<='1';
         else
          result<=(others => '1') ;
          result(word_width-1)<='0';          
         end if;  
       else
         result <= diff;
       end if;
         
     when  alu_subu =>
        if saturate_mode='1' and cout_subu='1' then
          result<=(others => '0');
       else   
         result <= diff;
       end if;


     when  alu_sub2 =>
       if saturate_mode='1' then   
         result <=diff3_2&diff2_2&diff1_2&diff0_2;
       else 
         result  <= diff3&diff2&diff1&diff0;
       end if;
          
     when  alu_sub4  =>
       if saturate_mode='1' then   
           result <=diff3_4&diff2_4&diff1_4&diff0_4;
       else 
           result  <= diff3&diff2&diff1&diff0;
       end if;
          
                 
     -----------------------------------------------------------------------
     --    COMPARATIONS
     --      
     -- The Alu1 - Alu2 subtraction output is checked to determine the
     -- operation result, that is 0 if the comparation is False, 1 if true.
     -----------------------------------------------------------------------

     when  alu_eq =>
           if in_a = in_b then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;
           
     when  alu_lt =>
           if signed(in_a) < signed(in_b) then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;
           
     when  alu_ltu =>
           if unsigned(in_a) < unsigned(in_b) then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;          
               
     -----------------------------------------------------------------------
     --            LOGIC OPERATORS
     -----------------------------------------------------------------------
           
     when  alu_and => result      <= in_a and in_b;

     when  alu_or  => result      <= in_a or in_b;

     when  alu_xor => result      <= in_a xor in_b;

     when  alu_nor => result      <= in_a nor in_b;

     when others => result      <= in_a;

     end case;      
     
  end process;   

end generate SAT_ARITHMETIC;

NO_SAT_ARITHMETIC: if (include_sat_arithmetic/=1) generate

ADD4_LOGIC :  if (include_parallel_alu=1)  generate

   Lo <= '0';

   process(op,co2,co1,co0,Lo)
    begin
     if op=alu_add4 then
      cin3 <= Lo;
      cin2 <= Lo;
      cin1 <= Lo;
      cin0 <= Lo;
     elsif op=alu_add2 then
       
      cin3 <= co2;
      cin2 <= Lo;
      cin1 <= co0;
      cin0 <= Lo;
     else
      cin3 <= co2;
      cin2 <= co1;
      cin1 <= co0;
      cin0 <= Lo;

    
    end if;
  end process;
      
      fa3 : adder_8 port map (in_a(31 downto 24),in_b(31 downto 24),cin3,sum3,co3);
      fa2 : adder_8 port map (in_a(23 downto 16),in_b(23 downto 16),cin2,sum2,co2);
      fa1 : adder_8 port map (in_a(15 downto  8),in_b(15 downto  8),cin1,sum1,co1);
      fa0 : adder_8 port map (in_a( 7 downto  0),in_b( 7 downto  0),cin0,sum0,co0);

      sum <= sum3&sum2&sum1&sum0;


  process(op,so2,so1,so0,Lo)
  begin
    if op=alu_sub4 then
      sin3 <= Lo;
      sin2 <= Lo;
      sin1 <= Lo;
      sin0 <= Lo;

    elsif op=alu_sub2 then
      sin3 <= so2;
      sin2 <= Lo;
      sin1 <= so0;
      sin0 <= Lo;
     else
      sin3 <= so2;
      sin2 <= so1;
      sin1 <= so0;
      sin0 <= Lo;
     end if;
  end process;

  
      sub4 : sub_8 port map (in_a(31 downto 24),in_b(31 downto 24),sin3,diff3,so3);
      sub3 : sub_8 port map (in_a(23 downto 16),in_b(23 downto 16),sin2,diff2,so2);
      sub2 : sub_8 port map (in_a(15 downto  8),in_b(15 downto  8),sin1,diff1,so1);
      sub1 : sub_8 port map (in_a( 7 downto  0),in_b( 7 downto  0),sin0,diff0,so0);

     
       diff <= diff3&diff2&diff1&diff0;

 

-- Two's component overflow: the overflow is 



 OUTPUT_OVERFLOW:

    process(in_a,in_b,sum,diff,op)
     begin 
       if op = alu_add then
          if  (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) )) then
                overflow <= '1';
             else
                overflow <= '0';
             end if;                    
                
                     
        elsif op=alu_sub   then
             if (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) then
                  overflow<='1';
             else
               overflow<='0';
             end if;
    
                       
         elsif op=alu_add4  then
                if   (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) ))and
                     (( in_a(23) /= in_b(23) ) or ( in_a(23) = sum(23))) and
                     (( in_a(15) /= in_b(15) ) or ( in_a(15) = sum(15))) and
                     ((in_a(7) /= in_b(7)) or (in_a(7) = sum(7))) then
                  overflow<='1';
                 else
                   overflow<='0';
                 end if;
                

         
      elsif op = alu_sub4 then 
             if  (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) and 
                 (( in_a(23) = in_b(23) )  or( in_a(23) = diff(23) )) and 
                   (( in_a(15) = in_b(15) )  or ( in_a(15) = diff(15) )) and 
               (( in_a(7) = in_b(7) )  or ( in_a(7) = diff(7))) then
   
                  overflow <= '1';
           else
               overflow <= '0';
           end if;

                  
        elsif op=alu_add2  then
                if   (( in_a(word_width-1) /= in_b(word_width-1) )  or ( in_a(word_width-1) = sum(word_width-1) ))and
                     (( in_a(15) /= in_b(15) ) or ( in_a(15) = sum(15))) then
                   overflow<='1';
                 else
                   overflow<='0';
                 end if;
                

         
      elsif op = alu_sub2 then 
             if  (( in_a(word_width-1) = in_b(word_width-1) )  or ( in_a(word_width-1) = diff(word_width-1))) and 
                 (( in_a(15) = in_b(15) )  or ( in_a(15) = diff(15) )) then
   
                  overflow <= '1';
           else
               overflow <= '0';
           end if;
       else
                 overflow <= '1';         

       end if;

     end process;
    
 end generate ADD4_LOGIC;

 NO_ADD4_LOGIC : if(include_parallel_alu/=1) generate
   sum <= signed(in_a) + signed(in_b);
   diff<= signed(in_a) - signed(in_b);

    OUTPUT_OVERFLOW:
     process(in_a,in_b,sum,diff,op)
     begin
       if op = alu_add or op=alu_add4 then
          if  ( in_a(word_width-1) /= in_b(word_width-1) )  or
                ( in_a(word_width-1) = sum(word_width-1) ) then
                overflow <= '1';
             else
                overflow <= '0';
             end if;                    
                
       elsif op = alu_sub or op=alu_sub4 then
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
       
 end generate NO_ADD4_LOGIC;
   
  OUTPUT_RESULT : process(in_a,in_b,op,sum,diff)  
  begin

    case op is
      
     -----------------------------------------------------------------------
     --  ARITHMETIC OPERATIONS
     -----------------------------------------------------------------------
    
     when  alu_add4 | alu_add | alu_add2 | alu_addu  =>   result <= sum;
     
     when  alu_sub | alu_subu | alu_sub2 | alu_sub4  =>   result <= diff;           
                      
     -----------------------------------------------------------------------
     --    COMPARATIONS
     --      
     -- The Alu1 - Alu2 subtraction output is checked to determine the
     -- operation result, that is 0 if the comparation is False, 1 if true.
     -----------------------------------------------------------------------

     when  alu_eq =>
           if in_a = in_b then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;
           
     when  alu_lt =>
           if signed(in_a) < signed(in_b) then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;
           
     when  alu_ltu =>
           if unsigned(in_a) < unsigned(in_b) then
             result <= EXT("1",word_width);
           else
             result <= EXT("0",word_width);
           end if;          
               
     -----------------------------------------------------------------------
     --            LOGIC OPERATORS
     -----------------------------------------------------------------------
           
     when  alu_and => result      <= in_a and in_b;

     when  alu_or  => result      <= in_a or in_b;

     when  alu_xor => result      <= in_a xor in_b;

     when  alu_nor => result      <= in_a nor in_b;

     when others => result      <= in_a;

     end case;      
     
  end process;   

end generate NO_SAT_ARITHMETIC;

              
end structural;

----------------------------------------------------------------------------
--            PACKAGE   DEFINITION                                        --
----------------------------------------------------------------------------

Library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;

package alu is

   component Main_Alu
     port(  in_a          : in  Risc_word;
            in_b          : in  Risc_word;
            saturate_mode : in  Std_logic;
            op            : in  Risc_Alucode;
            result        : out Std_logic_vector(word_width-1 downto 0);
            overflow      : out Std_logic     );
   end component;

   component Shifter
     port( a        : in  Risc_word;
           op       : in  Risc_shiftcode;
           shamt    : in  Std_logic_vector(shift_count_width-1 downto 0);
           sh       : out Risc_word  );

  end component;

  component mult_block 
    port ( clk,reset           : in    Std_logic;
           en_exe,d_we,e_we    : in    Std_logic;
           dec_mul_command     : in    Risc_mulop;
           operand1            : in    Risc_word;
           operand2            : in    Risc_word;

           Mulout              : out   Risc_word ); 
  end component;

  component mem_handle
  port ( clk,reset    : in  Std_logic;
         en_exe,en_mem,
         smdr_enable,
         dmar_enable  : in  Std_logic;       -- Data and address sample control         
         NextMemAddr  : in  Risc_daddr;      -- The DMemory address, calculated by the Alu.
         stored_data  : in  Risc_word;       -- The data to be stored => datapath in_regB signal
         read_data    : out Risc_word;       -- The data read from memory
         
         m_isbyte,
         m_ishalf,
         d_upper,
         m_upper,
         signed_load : in  Std_logic;       -- Memory access control signals
         ADDRESS_BUS : out Risc_daddr;
         DATA_IN     : in  Risc_word;       -- ddata_in bus
         DATA_OUT    : out Risc_word   );   -- ddata_out bus  
  end component;
    
end alu;

package body alu is
end alu;




