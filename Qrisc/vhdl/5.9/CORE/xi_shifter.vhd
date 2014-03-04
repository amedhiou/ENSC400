
------------------------------------------------------------------------ 
--                             XI_SHIFTER.VHD                            --
--                                                                    --
------------------------------------------------------------------------
-- Created 2001 by F.M.Campi , fcampi@deis.unibo.it                   --
-- DEIS, Department of Electronics Informatics and Systems,           --
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

-- Variable width shifter entity, may also include rotates!


-- ROTATE LEFT

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.menu.all;
use work.basic.all;

entity rot_left is
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );
        
	port (  in1  : in   std_logic_vector(word_width-1 downto 0);
                in2  : in   integer range 0 to (2**shift_count_width) -1;
                out1 : out  std_logic_vector(word_width-1 downto 0)  );
end rot_left;

architecture behavioral of rot_left is 
 signal temp : unsigned(word_width-1 downto 0);
begin
  temp <= unsigned(in1) rol in2;
  assign: for i in 0 to word_width-1 generate
    out1(i) <= temp(i);
  end generate assign;
end behavioral;

-- ROTATE RIGHT

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.menu.all;
use work.basic.all;

entity rot_right is
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );
       
	port (  in1  : in  std_logic_vector(word_width-1 downto 0);
                in2  : in  integer range 0 to (2**shift_count_width) -1;
                out1 : out std_logic_vector(word_width-1 downto 0) );
end rot_right;

architecture behavioral of rot_right is
  signal temp : unsigned(word_width-1 downto 0);
begin
  temp <= unsigned(in1) ror in2;
  assign: for i in 0 to word_width-1 generate
    out1(i) <= temp(i);
  end generate assign;
end behavioral;

-- SHIFT RIGHT ARITHMETICAL

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;

entity sh_right_arith is
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );
                
	port (  in1  : in  std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out std_logic_vector(word_width-1 downto 0) ); 
end sh_right_arith;

architecture behavioral of sh_right_arith is
begin
  out1 <= Conv_std_logic_vector( SHR(signed(in1),unsigned(in2) ), word_width );
end behavioral;

-- SHIFT RIGHT LOGICAL

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;

entity sh_right_log is
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );
        
	port (  in1  : in  std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out std_logic_vector(word_width-1 downto 0) );
end sh_right_log;

architecture behavioral of sh_right_log is
begin
  out1 <= Conv_std_logic_vector( SHR(unsigned(in1),unsigned(in2) ), word_width );
end behavioral;

-- SHIFT LEFT LOGICAL

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;

entity sh_left_log is
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );
   
	port (  in1  : in  std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out std_logic_vector(word_width-1 downto 0) );	
end sh_left_log;

architecture behavioral of sh_left_log is
begin
  out1 <= Conv_std_logic_vector( SHL(unsigned(in1),unsigned(in2)), word_width );
end behavioral;



-------------------------------------------------------------------------------
--                         SHIFTER MAIN ENTITY                               --
-------------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;  
   
entity SHIFTER is
  generic ( Word_Width          : positive := 32;
            shift_count_width   : positive := 5;
            include_rotate      : integer := 1 );     
  port( a        : in  Std_logic_vector(word_width-1 downto 0);
        op       : in  Risc_shiftcode;
        shamt    : in  Std_logic_vector(shift_count_width-1 downto 0);
        sh       : out Std_logic_vector(word_width-1 downto 0)  );
end SHIFTER;
 
 
architecture behavioral of SHIFTER is

  component rot_left
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );    
	port (  in1  : in  Std_logic_vector(word_width-1 downto 0);
                in2  : in  integer range 0 to (2**shift_count_width) -1;
                out1 : out Std_logic_vector(word_width-1 downto 0) );
  end component;

  component rot_right
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );     
	port (  in1  : in  Std_logic_vector(word_width-1 downto 0);
                in2  : in  integer range 0 to (2**shift_count_width) -1;
                out1 : out Std_logic_vector(word_width-1 downto 0) );
  end component;

  component sh_left_log
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );        
	port (  in1  : in  Std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out Std_logic_vector(word_width-1 downto 0) );
  end component;

  component sh_right_arith
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );        
	port (  in1  : in  Std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out Std_logic_vector(word_width-1 downto 0) ); 
  end component;

  component sh_right_log
        generic ( Word_Width          : positive := 32;
                  shift_count_width   : positive := 5 );       
	port (  in1  : in  Std_logic_vector(word_width-1 downto 0);
                in2  : in  Std_logic_vector(shift_count_width-1 downto 0);
                out1 : out Std_logic_vector(word_width-1 downto 0) );
  end component;

 
  signal count : integer range 0 to 2**shift_count_width -1;
  signal sh_rol,sh_ror,sh_srl,sh_sll,sh_sra : Std_logic_vector(word_width-1 downto 0);  

  
begin

  count   <= Conv_integer(unsigned(shamt));

  ROTATE_LOGIC: if include_rotate=1 generate
    S_ROL : rot_left generic map (word_width,shift_count_width)
                     port map(a,count,sh_rol);
    S_ROR: rot_right generic map (word_width,shift_count_width)
                     port map(a,count,sh_ror);
  end generate ROTATE_LOGIC;
  
  S_SRA: sh_right_arith generic map (word_width,shift_count_width)
                        port map(a,shamt,sh_sra);
  S_SRL: sh_right_log   generic map (word_width,shift_count_width)
                        port map(a,shamt,sh_srl);
  S_SLL: sh_left_log    generic map (word_width,shift_count_width)
                        port map(a,shamt,sh_sll);
  
  OUTPUT_MUX:process(op,sh_rol,sh_ror,sh_sra,sh_srl,sh_sll)
  begin
    if op = xi_shift_srl(2 downto 0) then
       sh <= sh_srl;
    elsif op = xi_shift_sra(2 downto 0) then      
       sh <= sh_sra;       
    elsif op = xi_shift_ror(2 downto 0) and include_rotate=1 then
       sh <= sh_ror;
    elsif op = xi_shift_rol(2 downto 0) and include_rotate=1 then
       sh <= sh_rol;
    else
       sh <= sh_sll;
    end if;
  end process;
end behavioral;


