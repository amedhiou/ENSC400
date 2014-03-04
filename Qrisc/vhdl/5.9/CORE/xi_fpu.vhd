-----------------------------------------------------------------------------------------------------------
--
--
--				                    MILK COPROCESSOR
--
-- Created by Claudio Brunelli, 2004
--
-----------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.menu.all;


entity cop is
    generic( conv_flag    : integer := 1;
             trunc_flag   : integer := 1;
             mul_flag     : integer := 1;
             div_flag     : integer := 1;
             add_flag     : integer := 1;
             sqrt_flag    : integer := 1;
             compare_flag : integer := 1 );
    port( clk,reset,enable : in std_logic;        
          rd_cop, wr_cop   : in std_logic;
	  c_index          : in std_logic_vector(1 downto 0);
	  r_index          : in std_logic_vector(3 downto 0);
	  cop_in           : in  std_logic_vector(word_width-1 downto 0);
	  cop_out          : out std_logic_vector(word_width-1 downto 0);
	  cop_exc          : out std_logic ;
          cop_stall        : out std_logic
        );
end cop;

-----------------------------------------------------------------------------------

architecture milk of cop is
begin
        
end milk;

----------------------------------------------------------------------------
--   COMPONENT DEFINITION
----------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.menu.all;
  

package cop_pack is
  
  component Cop
    generic( conv_flag    : integer := 1;
             trunc_flag   : integer := 1;
             mul_flag     : integer := 1;
             div_flag     : integer := 1;
             add_flag     : integer := 1;
             sqrt_flag    : integer := 1;
             compare_flag : integer := 1 );
    port( clk,reset,enable : in std_logic;        
          rd_cop, wr_cop   : in std_logic;
	  c_index          : in std_logic_vector(1 downto 0);
	  r_index          : in std_logic_vector(3 downto 0);
	  cop_in           : in std_logic_vector(word_width-1 downto 0);
          cop_out          : out std_logic_vector(word_width-1 downto 0);
	  cop_exc          : out std_logic;
          cop_stall        : out std_logic
        );
  end component;

constant fpu_add      : std_logic_vector(5 downto 0) := "000000";
constant fpu_sub      : std_logic_vector(5 downto 0) := "000001";
constant fpu_mul      : std_logic_vector(5 downto 0) := "000010";
constant fpu_div      : std_logic_vector(5 downto 0) := "000011";
constant fpu_sqrt     : std_logic_vector(5 downto 0) := "000100";
constant fpu_abs      : std_logic_vector(5 downto 0) := "000101";
constant fpu_mov      : std_logic_vector(5 downto 0) := "000110";
constant fpu_neg      : std_logic_vector(5 downto 0) := "000111";
constant fpu_nop      : std_logic_vector(5 downto 0) := "001000";
constant fpu_cvt_s    : std_logic_vector(5 downto 0) := "100000";
constant fpu_cvt_w    : std_logic_vector(5 downto 0) := "100100";

end cop_pack;

package body cop_pack is
end cop_pack;

