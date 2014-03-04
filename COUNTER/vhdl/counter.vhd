-------------------------------------------------------------------------------
-- counter
-- by fcampi@sfu.ca Feb 2014
--
-------------------------------------------------------------------------------

-- Device implementing a counter for performance estimation
-- It is designed to lie on the external bus, and can support
-- a programmable number of counters from 1 to 16.
-- The operation to be computed is expressed by the address bus
-- So, the last 4 bit of every instruction are used to
-- specify the addressed counter, and are expressed as X
-- in the following.
-- At the moment 
-- 
-- Instruction Set:
-- Reset Conter             0x1X
-- Enable Counter onward    0x2X
-- Enable Counter backwards 0x3X (Not supported yet)
-- Stop  Counter            0x4X
-- Preload Counter          0x5X (Not supported yet)
-- Read  Counter            0x6X

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  
entity counter is
  generic ( addr_size : integer := 8;
            word_size : integer := 16;
            num_counters : integer := 4 );
  port (  clk,resetn :   in  std_logic; 
          rdn        :   in  std_logic;
          wrn        :   in  std_logic;
          address    :   in  std_logic_vector(addr_size-1 downto 0);
          data_in    :   in  std_logic_vector(word_size-1 downto 0);
          data_out   :   out std_logic_vector(word_size-1 downto 0) );
end counter;

architecture beh of counter is

type count_type is array (0 to num_counters-1) of std_logic_vector(word_size-1 downto 0);  
signal count,next_count : count_type;
signal cenable,next_cenable,creset  : std_logic_vector(num_counters-1 downto 0);
signal read_addr,next_read_addr     : std_logic_vector(3 downto 0);
begin  -- beh

  -- Input detection Logic
  process(address,wrn,rdn)
  variable sel : integer;
  begin

    sel := to_integer(unsigned(address(3 downto 0)));
       
    for i in 0 to num_counters-1 loop
      next_cenable(i) <= cenable(i);
      creset(i) <= '0';
    end loop;  -- i

    next_read_addr <= (others=>'0');
    
    case address(7 downto 4) is      
      when X"1" =>
        -- reset counter
        creset(sel) <= '1';
      when X"2" =>
        -- enable counter
        next_cenable(sel) <= '1';
      when X"4" =>
        -- stop counter
        next_cenable(sel) <= '0';
      when X"6" =>
        -- Read counter
        next_read_addr <= address(3 downto 0); 
      when others => null;
    end case;
  end process;

  increments: for i in 0 to num_counters-1 generate
    next_count(i) <=
      (others=>'0') when creset(i)='1'  else
      count(i)    when cenable(i)='0' else 
      std_logic_vector(unsigned(count(i))+to_unsigned(1,word_size));
  end generate;  -- i
    
  counters: for i in 0 to num_counters-1 generate
     
   CounterN: process(clk,resetn)
   begin 
     if resetn='0' then
       count(i)   <= (others=>'0');
       cenable(i) <= '0';
       read_addr  <= (others=>'0');
     else
       if clk'event and clk='1' then
         cenable(i) <= next_cenable(i);
         read_addr  <= next_read_addr;
         if creset(i)='1' then
           count(i) <= (others=>'0');
         end if;
         if next_cenable(i)='1' then
           count(i) <= next_count(i);
         end if;
       end if;
     end if;
   end process;
  end generate;  -- i

  data_out <= count(to_integer(unsigned(read_addr)));
  -- data_out <= count(1);
end beh;
