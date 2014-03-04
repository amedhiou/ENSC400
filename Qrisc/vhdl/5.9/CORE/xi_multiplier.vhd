---------------------------------------------------------------------------
--                           XI_multiplier.vhd                           --
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


-- This logic block represents the Multiplication / Multiply-Accumulation block
-- inside the main datapath. It is quite parametric, and it
-- can be configured to support single-cycle or double-cycle multiplication
-- and multiply-accumulation.

------------------------------------------------------------------------
--                MAIN ENTITY DEFINITION
------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.basic.all;
  use work.isa_32.all;
  use work.components.all;

entity mult_block is
  generic(  Word_Width      : positive := 32;
            include_mul     : integer  := 1;
            include_mult    : integer  := 1;
            include_mad     : integer  := 1 );
  
   port ( clk,reset                : in    Std_logic;
          en_dx,en_xm,en_mw,m_we   : in    Std_logic;
          d_mul_command            : in    Risc_mulop;
          operand1                 : in    Std_logic_vector(word_width-1 downto 0);
          operand2                 : in    Std_logic_vector(word_width-1 downto 0);

          Multout    : out   Std_logic_vector(word_width-1 downto 0);
          mad_oflow  : out Std_logic );
end mult_block;


architecture BEHAVIORAL of mult_block is

constant half_width : integer := word_width/2;  

signal fill_0 : Std_logic_vector(half_width-1 downto 0);

signal x_mul_command,m_mul_command  : Risc_mulop;
signal multin_en                    : std_logic;
signal x_operand1,x_operand2        : Std_logic_vector(word_width-1 downto 0);
signal m_operand1                   : Std_logic_vector(word_width-1 downto 0);

signal x_mult_out       : Std_logic_vector( (2*word_width-1) downto 0);

signal acc_out,Mult_out,Mad_out     : Std_logic_vector( (2*word_width)-1 downto 0);
signal Mul_out                      : Std_logic_vector(word_width-1 downto 0);
signal In_MulHi,In_MulLo            : Std_logic_vector(word_width-1 downto 0);
signal Out_MulHi,Out_MulLo          : Std_logic_vector(word_width-1 downto 0);


-- Signal handling the mad overflow exception
signal in_madoflow,out_madoflow,acc_madoflow : std_logic;


 --synopsys synthesis_off 
  type spy_mul is (mul_nop,mul_mtlo,mul_mthi,mul_mflo,mul_mfhi,mul_mul,mul_mulu,mul_mad,mul_madu,mul_mult,mul_multu,mul_err);
  signal spy : spy_mul;
 --synopsys synthesis_on     
  

-- Logic '0' signal, used to feed the enable input ports in those
-- registers that must be kept always active and sampling.
signal Lo          : Std_logic;


begin  -- BEHAVIORAL

   --synopsys synthesis_off
  SCCSPY: process(d_mul_command)
  begin
    if (d_mul_command = xi_mul_nop) then
       spy <= mul_nop;
    elsif (d_mul_command = xi_mul_mfhi) then
       spy <= mul_mfhi;
    elsif (d_mul_command = xi_mul_mflo) then
       spy <= mul_mflo;
    elsif (d_mul_command = xi_mul_mthi) then
       spy <= mul_mthi;
    elsif (d_mul_command = xi_mul_mtlo) then
       spy <= mul_mtlo;       
    elsif (d_mul_command = xi_mul_mul) then
       spy <= mul_mul;
    elsif (d_mul_command = xi_mul_mulu) then
       spy <= mul_mulu;
    elsif (d_mul_command = xi_mul_mult) then
       spy <= mul_mult;
    elsif (d_mul_command = xi_mul_multu) then
       spy <= mul_multu;
    elsif (d_mul_command = xi_mul_mad) then
       spy <= mul_mad;
    elsif (d_mul_command = xi_mul_madu) then
       spy <= mul_madu;       
    else
       spy <= mul_err;
    end if;
  end process;
  --synopsys synthesis_on

  
 Lo <= '0'; 
 fill_0 <= ( others => '0');

 -- Mult_enable process, used to sample the input operand only in case of Mult
 -- operations. This allows the Multiply block to mantain its inputs latched when
 -- the multiplier is not accessed, causing a significant decrease in power
 -- consumption
   MULT_ENABLE:
      process(d_mul_command,en_dx)
      begin
        if ( (d_mul_command /= xi_mul_nop) and (en_dx = '0') ) then  -- Operation
                                                                     -- involving
                                                                     -- the Multiplier
           multin_en <= '0';
        else
           multin_en <= '1';
        end if;
      end process;    

-- Multiplier Input Registers:
-- This registers are used to latch the multiplier inputs, so that the inputs
-- are actually sampled only in case of mult operation.
-- This will avoid unwanted commutations of the (many) multiplier gates,
-- dramatically decreasing power consumption.
-- The drawback is that I have to store the inputs and the mul commands
-- elsewhere in case of other mult_block operations, increasing chip area and
-- also again power consumption. It's, as usual, a tradeoff.....

-- NOTE: The signal "Mul command" is used to keep trace of mult & mad operation,
-- that have a special cycle latency expressed in the configuration file (xi_basic.vhd)
-- setting the constant "mult_delay_cycles".
-- The signal "x_mul_command" instead keep trace of the mthi,mtlo,Mul operations,
-- that to enhance code compactness mantains a normal pipeline pattern, so that
-- the Mthi/lo operation is performed at the edge the Memory access stage.
-- Another option might have been to have the same latency for all writes on
-- the Hi.Lo registers, but it sounded a bit silly to have a multiple cycle
-- latency for mthi,mtlo.

    multa  :
      Data_Reg generic map ( reg_width => word_width )
               port map (clk,reset,multin_en,operand1,x_operand1 );
    multb  :
      Data_Reg generic map ( reg_width => word_width )
               port map (clk,reset,multin_en,operand2,x_operand2 );

    multop :
      Data_Reg generic map (reg_width => 6)
               port map (clk,reset,en_dx,d_mul_command,x_mul_command);
  
----------------------------------------------------------------------------
--            EXECUTE STAGE                                              --
----------------------------------------------------------------------------
  
  XMULT:
    x_mult_out <= signed( x_operand1 ) * signed ( x_operand2 );

  
SINGLE_CYCLE_LOGIC: if include_mul=1 generate

  -- The MUL must give quick response into a single cycle. For this reason
  -- only its lowest 32 bits are carried as output (and it is already too slow!)
  MulQuick:
    Mul_out <= x_mult_out(word_width-1 downto 0);

end generate SINGLE_CYCLE_LOGIC;
                    
NO_SINGLE_CYCLE_LOGIC:  if include_mul=0 generate
  Mul_out <= (others => '0');
end generate NO_SINGLE_CYCLE_LOGIC;

                        
                    
MULTIPLE_CYCLE_LOGIC: if include_mult=1 or include_mad=1 generate
 
-- Multiplier Output registers:
-- This Multiplier structure was designed to split the Multiplication operation in two cycles
-- to  maximize the elaboration speed. The problem is that such choice will break the
-- normal 5 stages pattern and vanify the bypass structure. 
-- The only way to avoid unconsistency in the flow is consequently to save the
-- multiplication result in a dedicated set of on-chip registers. The result
-- will be read from this register with an appropriate operation, that will fall
-- into the pipeline pattern allowing bypass:
-- Any Mul operation will write those registers that can be read with the mfhi,
-- mflo operations.


 -- MULTIPLICATION LOGIC: STAGE X
 -- During the X stage the multiplication is performed. The first half of the
 -- result is forwarded as output to achieve the 16x16=32 bit operation.
      

  Pipe_command_reg:
      Data_Reg generic map ( init_value => 0, reg_width => 6 )
               port map ( clk,reset,en_xm,x_mul_command,m_mul_command);
    
  Pipe_mtvalue_reg:
      Data_Reg generic map ( init_value => 0, reg_width => word_width )
               port map ( clk,reset,en_xm,x_operand1,m_operand1 );  
  
  Pipe_mult_reg:
      Data_Reg generic map ( init_value => 0, reg_width => (2*word_width) )
               port map ( clk,reset,en_xm,x_mult_out,Mult_out );
  
  
----------------------------------------------------------------------------
--             MEMORY ACCESS  STAGE                                       --
----------------------------------------------------------------------------

 -- MULTIPLICATION LOGIC: STAGE M
     
  
-- Multiply/Accumulate (MAD) logic:
-- The Hi,Lo regoisters can be used as base for MAD (Multiply+add) operations:
-- a dedicated 64-bit adder is issued in the design to perform the
-- Acc = Acc + a(i) OP b(i) operation, where OP can also be * or if chosen any other
-- ALU operation.

   -- NOTE: The Register Accumulation can be considered a no-return write
   --       operation as it affects the processor state.
   --       consequently this command must be invalided if the instruction
   --       had for some reason been deactivated. That's why the m_we signal is
   --       used at the Data_reg enable ports    

ACCUMULATION_LOGIC:if include_mad = 1 generate
  
    -- ACCUMULATION ADDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    acc_out <= out_MulHi&out_MulLo;    

    accumulate : gp_adder generic map (width => 2*word_width)
                          port map (acc_out,Mult_out,Mad_out,acc_madoflow);

    -- Handling of the mad overflow exception: in case the accumulator overflows,
    -- the Flip Flop is set and any accumulator read will raise the overflow flag.
    -- The first external write on the accumulator will erase the flag.
    -- Please note that, after a mad that has overflown, the exception is not
    -- caused by the mad itself, that is a no-writeback operation, but by the
    -- first mfhi/mflo after that mad, unless a new mthi/mtlo was generated
    
    madoflow_inmux:process(m_mul_command,acc_madoflow,out_madoflow)
      begin
        if ( m_mul_command=xi_mul_mtlo or m_mul_command=xi_mul_mthi ) then
          in_madoflow <= '1';
        elsif ( m_mul_command=xi_mul_mad ) then
          in_madoflow <= acc_madoflow;
        else
          in_madoflow <= out_madoflow;
        end if;
      end process;
      
    madoflow_FF :
      FlipFlop port map ( clk,reset,en_mw,in_madoflow,out_madoflow);

    -- In case a value that generated a Mad_oflow wxception is read the internal
    -- exception signal is raised
    mad_oflow_mux: process(x_mul_command,out_madoflow)
    begin
      if (x_mul_command=xi_mul_mfhi or x_mul_command=xi_mul_mflo) then
        Mad_oflow <= out_madoflow;
      else
        Mad_oflow <= '1';
      end if;
    end process;
    
end generate ACCUMULATION_LOGIC;
                   
NO_ACCUMULATION_LOGIC: if include_mad /= 1 generate  
    Mad_out   <= (others => '0');
    mad_oflow <= '1';
end generate NO_ACCUMULATION_LOGIC;         


    -- The following process allows the update of Hi,Lo registers 
    
    MulLo_Input_mux:
      process(Mult_out,Mad_out,m_operand1,m_mul_command,m_we,out_MulLo)
      begin
        if ( (m_mul_command = xi_mul_mtlo) and (m_we ='0') ) then 
                 in_MulLo <= m_operand1;
        elsif (( (m_mul_command = xi_mul_mult) or (m_mul_command = xi_mul_multu)) and m_we ='0' ) then
                 in_MulLo <= Mult_out(word_width-1 downto 0);
        elsif (( (m_mul_command = xi_mul_mad)  or (m_mul_command = xi_mul_madu)) and m_we ='0' ) then
                 in_MulLo <= Mad_out(word_width-1 downto 0);
        else
                 in_MulLo <= Out_MulLo;
        end if;
      end process;        

    MulHi_Input_mux:
      process(Mult_out,Mad_out,m_operand1,m_mul_command,m_we,out_MulHi)
      begin
        if ( (m_mul_command = xi_mul_mthi) and (m_we ='0') ) then 
                 in_MulHi <= m_operand1;
        elsif (( (m_mul_command = xi_mul_mult) or (m_mul_command = xi_mul_multu)) and m_we='0' ) then
                 in_MulHi <= Mult_out( (word_width*2)-1 downto word_width);
        elsif (( (m_mul_command = xi_mul_mad)  or (m_mul_command = xi_mul_madu)) and m_we='0' ) then
                 in_MulHi <= Mad_out(  (word_width*2)-1 downto word_width );
        else
                 in_MulHi <= Out_MulHi;
        end if;
      end process;
 

-- HI , LO   Special Registers --------------------------------------------
 
    MulLo_reg :
      Data_reg generic map ( Reg_width => word_width )
               port map ( clk,reset,en_mw,in_MulLo,out_MulLo );

    MulHi_reg :
      Data_reg generic map ( Reg_width => word_width )
               port map ( clk,reset,en_mw,in_MulHi,out_MulHi );

---------------------------------------------------------------------------

    
end generate MULTIPLE_CYCLE_LOGIC;

NO_MULTIPLE_CYCLE_LOGIC: if include_mad=0 and include_mult=0 generate
  out_MulHi <= (others=>'0');
  out_MulLo <= (others=>'0');
  mad_oflow <= '1';
end generate NO_MULTIPLE_CYCLE_LOGIC;

                         
 ------------------------------------------------------------------------------
 -- OUTPUT MULTIPLEXER
 ------------------------------------------------------------------------------

  OUTPUT_MUX : process(x_mul_command,out_MulHi,out_MulLo,Mul_out)
  begin
    if x_mul_command = xi_mul_mfhi then
        Multout <= out_MulHi;
    elsif x_mul_command = xi_mul_mflo then
        Multout <= out_MulLo;
    else
        Multout <= Mul_out;
    end if;
  end process;
  
end BEHAVIORAL;
