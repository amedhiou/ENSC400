-------------------------------------------------------------------
--                Xi_Memory.vhd                                  --
-------------------------------------------------------------------
-------------------------------------------------------------------
-- Created by A. Gori Scrittori  , agoriscrittori@deis.unibo.it  --
-- DEIS, Department of Electronics Informatics and Systems,      --
-- University of Bologna, BOLOGNA , ITALY                        --
-------------------------------------------------------------------

-------------------------------------------------------------------------
-- This is a NON_SYNTHESIZABLE file, used as an abstract memory model to 
-- run test programs during simulation.
-- 
-- It describes a synchronous memory device, used in association with the
-- XiRisc processor model to build an on-chip bus architecture.
-------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use std.textio.all;
  use IEEE.std_logic_textio.all;
  use work.misc.all;
 
entity xi_memory_banks is
  
    generic( banks         : integer := 4;
             cell_width    : integer := 8;
             address_width : integer := 16;
             load_file     : string;
             min_address_upper   : integer := 0;
             min_address_lower   : integer := 0;
             max_address_upper   : integer := 16#7fff#;
             max_address_lower   : integer := 16#ffff# );
      
    port(  load                 : in  std_logic;
           CLK                  : in  std_logic;
	   OEN                  : in  std_logic;
           WEN                  : in  std_logic_vector(banks-1 downto 0);
	   CSN                  : in  std_logic;
           A                    : in  std_logic_vector(address_width-1 downto 0);
           D                    : in  std_logic_vector(banks*cell_width-1 downto 0);
	   Q                    : out std_logic_vector(banks*cell_width-1 downto 0) );
    
end xi_memory_banks;


architecture structural of xi_memory_banks is 

type mem_array is array (integer range <>) of std_logic_vector(cell_width-1 downto 0); 
type banks_array is array (integer range <>) of mem_array(2**address_width-1 downto 0);

  signal mem_out : banks_array(banks-1 downto 0);
  signal mux_out : Std_logic_vector(banks*cell_width-1 downto 0);

  signal WEN_ck  : Std_logic_vector(banks-1 downto 0);
  signal OEN_ck,CSN_ck : Std_logic;


begin      

  CONTROL_sample:process(CLK)
  begin 
    if (CLK'EVENT and CLK='1') then
       OEN_ck <= OEN;
       CSN_ck <= CSN;
       WEN_ck <= WEN;
    end if;
  end process;

  
  READ_MUX: process(CLK)  
  begin      
        if (CLK'EVENT and CLK='1') then
             memory_banks : for i in banks-1 downto 0 loop
                if CSN='0' and WEN(i)='0' then
                   -- Memory Write: copy on output the written Value
                   mux_out((i+1)*cell_width-1 downto i*cell_width) <= d((i+1)*cell_width-1 downto i*cell_width);
                elsif CSN='0' and WEN(i)='1' then
                   -- Memory Read: copy on output the requested Value
                   mux_out((i+1)*cell_width-1 downto i*cell_width) <= mem_out(i)(Conv_Integer(unsigned(A)));
                end if;
                   -- If CSN ='1' The output does not change, the current
                   -- address is ignored
             end loop;                         
        end if;      
  end process; 

  TRI_STATE: process(OEN_ck,CSN_ck,WEN_ck,mux_out)
  begin
      if (OEN_ck='0') then
           banks_buffers:for i in banks-1 downto 0 loop
              Q((i+1)*cell_width-1 downto i*cell_width) <= mux_out((i+1)*cell_width-1 downto i*cell_width);
           end loop;                    -- i
      else
         Q <= (others=>'Z');
      end if;
  end process; 

  

    -- MEMORY CONTENT LOAD LOGIC        --

    -- This non-synthesizable part is used to program the memory before
    -- simulation !!!
    -- The process is triggered by a raising edge on the load signal, and
    -- carries on until the termination of the input file

    memload:process(CLK,load)
    File program  : TEXT;
    variable open_status : file_open_status;
    Variable L          : LINE;
    variable ch         : character;
    variable data_in    : Std_logic_vector(banks*cell_width-1 downto 0);
    -- The width of this variable must remain a multiple by 4 or the hex2slv wouldn'
    -- t work correctly
    variable address_in,address_max,address_min : Std_logic_vector(31 downto 0);    
    
    begin

    -- Memory Write
    if (CLK'event and CLK='1') then
         memory_banks : for i in banks-1 downto 0 loop
            if (WEN(i)='0' and CSN='0') then
               mem_out(i)(Conv_Integer(unsigned(A))) <= D((i+1)*cell_width-1 downto i*cell_width);
               
            end if;
         end loop;  -- i
   
    else
      
       if (load'event and load='1') then
          file_open(open_status,program,load_file,read_mode);
          if open_status/=open_ok then
             report("Error: Cannot open input file") severity Error;
          end if;
          
          while not endfile(program) loop
            readline (program,L);
            hex2slv(L,address_in);
            -- "ffffffff" is the conventional end of file value!
            if address_in/=X"ffffffff" then
              readline (program,L);
              hex2slv(L,data_in);
              address_min := conv_std_logic_vector(min_address_upper,16)&conv_std_logic_vector(min_address_lower,16);
              address_max := conv_std_logic_vector(max_address_upper,16)&conv_std_logic_vector(max_address_lower,16);              
              if ( (unsigned(address_in)) >= unsigned(address_min)  and
                   (unsigned(address_in)) <= unsigned(address_max) )  then
                   blks:for i in banks-1 downto 0 loop
                     mem_out(i)(Conv_Integer(unsigned(address_in(address_width+1 downto 2)))) <= data_in((i+1)*(cell_width)-1 downto i*cell_width);
                   end loop;  -- i
              end if;
            end if;
          end loop;      
       file_close(program);
       end if;

    end if;
  
  end process;     
  
end structural;
