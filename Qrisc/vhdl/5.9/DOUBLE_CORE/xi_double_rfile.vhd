---------------------------------------------------------------------------
--                       DP_REGFILE.VHD                                  --
--                                                                       --
-- Created 2000 by F.M.Campi , fcampi@deis.unibo.it                      --
-- DEIS, Department of Electronics Informatics and Systems,              --
-- University of Bologna, BOLOGNA , ITALY                                -- 
---------------------------------------------------------------------------

-- The register file is a read/write memory, composed by 32 32-bit general
-- purpose registers.
-- It can be addressed by different resources in a concurrent enviroment.
-- This model is a 4-read and 2-writes port especially designed for
-- the processor double-datapath version.


library IEEE;
  use IEEE.std_logic_1164.all;
  use work.basic.all;

  package regfile is

    component Double_RegFile
      generic( Word_Width              : positive := 32;
               rf_registers_addr_width : positive := 5 );
        
	port(  clk    : in  Std_logic;
               reset  : in  Std_logic;
               enable : in  Std_logic;
	       ra     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       a_out  : out Std_logic_vector(Word_width-1 downto 0);
	       rb     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       b_out  : out Std_logic_vector(Word_width-1 downto 0);
               rc     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       c_out  : out Std_logic_vector(Word_width-1 downto 0);
               rd     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       d_out  : out Std_logic_vector(Word_width-1 downto 0);
	       rd1    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       d1_in  : in  Std_logic_vector(Word_width-1 downto 0);
               rd2    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       d2_in  : in  Std_logic_vector(Word_width-1 downto 0) );
    end component;

end regfile;

package body regfile is
end regfile;

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;
  use work.components.all;
  
entity Double_Regfile is
     generic( Word_Width              : positive := 32;
               rf_registers_addr_width : positive := 5 );
        
	port(  clk    : in  Std_logic;
               reset  : in  Std_logic;
               enable : in  Std_logic;
	       ra     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       a_out  : out Std_logic_vector(Word_width-1 downto 0);
	       rb     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       b_out  : out Std_logic_vector(Word_width-1 downto 0);
               rc     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       c_out  : out Std_logic_vector(Word_width-1 downto 0);
               rd     : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       d_out  : out Std_logic_vector(Word_width-1 downto 0);
               
	       rd1    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);               
	       d1_in  : in  Std_logic_vector(Word_width-1 downto 0);
               rd2    : in  Std_logic_vector(rf_registers_addr_width-1 downto 0);
	       d2_in  : in  Std_logic_vector(Word_width-1 downto 0) );
end Double_Regfile;


architecture behavioral of Double_Regfile is

  -- Used for the Register file data structure
  type rf_bus_array is array (2**rf_registers_addr_width-1 downto 0) of Std_logic_vector(Word_width-1 downto 0);

  signal reg_in,reg_out : rf_bus_array;  
  
begin

    -- Register 0 is grounded
  reg_out(0) <= (others => '0');

  
  Registers:for i in 1 to (2**rf_registers_addr_width-1) generate   
     rx : data_reg generic map ( reg_width=> word_width )
                   port map (clk,reset,enable,reg_in(i),reg_out(i));                            
  end generate Registers;  

  
    -- Reg_file Reads
    -- 
  READ_A_MUX: process(reg_out,ra)
    begin
      if Conv_Integer(unsigned(ra)) = 0 then
        a_out <= ( others => '0' );
      else
        a_out <= reg_out(Conv_Integer(unsigned(ra)));
      end if;
  end process;

  READ_B_MUX: process(reg_out,rb)
    begin
      if Conv_Integer(unsigned(rb)) = 0 then
        b_out <= ( others => '0' );
      else
        b_out <= reg_out(Conv_Integer(unsigned(rb)));
      end if;
  end process;

  READ_C_MUX: process(reg_out,rc)
    begin
      if Conv_Integer(unsigned(rc)) = 0 then
        c_out <= ( others => '0' );
      else
        c_out <= reg_out(Conv_Integer(unsigned(rc)));
      end if;
  end process;

  READ_D_MUX: process(reg_out,rd)
    begin
      if Conv_Integer(unsigned(rd)) = 0 then
        d_out <= ( others => '0' );
      else
        d_out <= reg_out(Conv_Integer(unsigned(rd)));
      end if;
  end process;   

  
  -- Reg_file writes. Being clock-dependent, this process separates
  -- the memory access from the Writeback stage: Consequently, there is
  -- no need for an esplicit writeback register for Data or Control
  -- signals.
  WRITE_MUX:process(rd1,d1_in,rd2,d2_in,reg_out)            
  begin      
      for i in 1 to (2**rf_registers_addr_width-1) loop
          if i = Conv_Integer(unsigned(rd1)) then
            reg_in(i) <= d1_in;
          elsif  i = Conv_Integer(unsigned(rd2)) then
            reg_in(i) <= d2_in;
          else
            reg_in(i) <= reg_out(i);
          end if;
      end loop;
  end process;
      

-- BUS MONITOR
    -- The following lines can generate a wb trace that can monitor
    -- the computation and compare it with LISA

    --synopsys synthesis_off
    process(clk)
     file output : text open write_mode is "wbtrace";
     variable l:line;
     variable cycles : integer :=0;
     begin
       if (clk'event and clk='1') then        
         if (conv_integer(unsigned(rd1))/=0) then
           write(l,cycles);
           write(l,string'(":R[") );
           write(l,conv_integer(unsigned(rd1) ));
           write(l,string'("]=") );
           hwrite(l,d1_in,RIGHT,8);  -- Hexadecimal output
           writeline(output,l);           
         end if;
         if (conv_integer(unsigned(rd2))/=0) then
           write(l,cycles);
           write(l,string'(":R[") );
           write(l,conv_integer(unsigned(rd2) ));
           write(l,string'("]=") );
           hwrite(l,d2_in,RIGHT,8);  -- Hexadecimal output
           writeline(output,l);           
         end if;
         cycles:=cycles+1;
       end if;
     end process;
    -- synopsys synthesis_on
     
end behavioral;

