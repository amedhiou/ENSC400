-------------------------------------------------------------------------------
-- ubus
-- by fcampi@sfu.ca Feb 2014
--
-- Local Bus for the internal data bus
-- of the Qrisc processor up island
-------------------------------------------------------------------------------

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;

  entity ubus is
    generic(s1_start : Std_logic_vector := X"40001000";
            s1_end   : Std_logic_vector := X"40002000";
            s2_start : Std_logic_vector := X"50000000";
            s2_end   : Std_logic_vector := X"f0000000";
            s3_start : Std_logic_vector := X"00000000";
            s3_end   : Std_logic_vector := X"00000000";
            s4_start : Std_logic_vector := X"00000000";
            s4_end   : Std_logic_vector := X"00000000" );
      
    port ( clk,reset           : in Std_logic;
           -- M1 port
           M1_BUSY,M1_MR,M1_MW : in   Std_logic;
           M1_NREADY           : out  Std_logic;
           M1_ADDR_OUTBUS      : in   Std_logic_vector(31 downto 0);
           M1_DATA_INBUS       : out  Std_logic_vector(31 downto 0);
           M1_DATA_OUTBUS      : in   Std_logic_vector(31 downto 0);

           -- S1 port
           S1_BUSY,S1_MR,S1_MW : out  Std_logic;               
           S1_NREADY           : in   Std_logic;
           S1_ADDR_OUTBUS      : out  Std_logic_vector(31 downto 0);
           S1_DATA_INBUS       : in   Std_logic_vector(31 downto 0);
           S1_DATA_OUTBUS      : out  Std_logic_vector(31 downto 0);
  
           -- S2 port
           S2_BUSY,S2_MR,S2_MW : out  Std_logic;
           S2_NREADY           : in   Std_logic;
           S2_ADDR_OUTBUS      : out  Std_logic_vector(31 downto 0);
           S2_DATA_INBUS       : in   Std_logic_vector(31 downto 0);
           S2_DATA_OUTBUS      : out  Std_logic_vector(31 downto 0);
    
           -- S3 port
           S3_BUSY,S3_MR,S3_MW : out  Std_logic;
           S3_NREADY           : in   Std_logic;
           S3_ADDR_OUTBUS      : out  Std_logic_vector(31 downto 0);
           S3_DATA_INBUS       : in   Std_logic_vector(31 downto 0);
           S3_DATA_OUTBUS      : out  Std_logic_vector(31 downto 0);
  
           -- S4 port
           S4_BUSY,S4_MR,S4_MW : out  Std_logic;
           S4_NREADY           : in   Std_logic;
           S4_ADDR_OUTBUS      : out  Std_logic_vector(31 downto 0);
           S4_DATA_INBUS       : in   Std_logic_vector(31 downto 0);
           S4_DATA_OUTBUS      : out  Std_logic_vector(31 downto 0) );
  end ubus;

  architecture struct of ubus is

  type master_type is (m1, default);
  type slave_type  is (s1,s2,s3,s4, default);
  type acc_type is (nop, read, write);
      
  type Bus_op is
    record
      master : master_type; 
      slave  : slave_type;
      op     : acc_type;
    end record;

  signal c1_op,c2_op       : Bus_op;
  signal c1_addr_outbus    : Std_logic_vector(31 downto 0);
  signal c1_data_outbus    : Std_logic_vector(31 downto 0);
  signal c2_data_inbus     : Std_logic_vector(31 downto 0);
  signal c2_nready,c2_busy : Std_logic;
    
  begin  -- struct

    -- C1 predecoding, Determine master with current priority
    -- (we have just one master now)
    process(M1_BUSY,M1_MR,M1_MW)
    begin
      c1_op.master <= default;
      c1_op.op     <= nop;     
      -- Detecting if Master 1 Is requiring bus service
      if (M1_MR='0' and M1_BUSY='1') then
        c1_op.master <= m1;
        c1_op.op     <= read;              
      elsif (M1_MW='0' and M1_BUSY='1') then
        c1_op.master <= m1;
        c1_op.op     <= write;        
      end if;
    end process;

      
    C1_addr_outbus <= M1_ADDR_OUTBUS when c1_op.master=m1
                      else (others=>'0');
    C1_data_outbus <= M1_DATA_OUTBUS when (c1_op.master=m1 and c1_op.op=write) 
                      else (others=>'0');
    


                        
    -- Cycle Bus 1: Determining the Slave to be addressed
    -- based on the bus address table
    process(C1_addr_outbus,c1_op)    
    begin
        c1_op.Slave <= default;
        if c1_op.op /= nop then
          if    (unsigned(C1_addr_outbus) >= unsigned (s1_start)) and (unsigned(C1_addr_outbus) < unsigned (s1_end))then
              c1_op.slave <= s1;          
          elsif (unsigned(C1_addr_outbus) >= unsigned (s2_start)) and (unsigned(C1_addr_outbus) < unsigned (s2_end))then
              c1_op.slave <= s2;       
          elsif (unsigned(C1_addr_outbus) >= unsigned (s3_start)) and (unsigned(C1_addr_outbus) < unsigned (s3_end))then
              c1_op.slave <= s3; 
          elsif (unsigned(C1_addr_outbus) >= unsigned (s4_start)) and (unsigned(C1_addr_outbus) < unsigned (s4_end))then
              c1_op.slave <= s4; 
          end if;
        end if;
    end process;        

    S1_ADDR_OUTBUS <= C1_addr_outbus when c1_op.slave = s1 else (others=>'0');
    S2_ADDR_OUTBUS <= C1_addr_outbus when c1_op.slave = s2 else (others=>'0');
    S3_ADDR_OUTBUS <= C1_addr_outbus when c1_op.slave = s3 else (others=>'0');                   
    S4_ADDR_OUTBUS <= C1_addr_outbus when c1_op.slave = s4 else (others=>'0');

    S1_DATA_OUTBUS <= C1_data_outbus when c1_op.slave = s1 else (others=>'0');
    S2_DATA_OUTBUS <= C1_data_outbus when c1_op.slave = s2 else (others=>'0');
    S3_DATA_OUTBUS <= C1_data_outbus when c1_op.slave = s3 else (others=>'0');
    S4_DATA_OUTBUS <= C1_data_outbus when c1_op.slave = s4 else (others=>'0');
    
    S1_MR <= '0' when c1_op.op=read and c1_op.slave = s1 else '1';
    S2_MR <= '0' when c1_op.op=read and c1_op.slave = s2 else '1';
    S3_MR <= '0' when c1_op.op=read and c1_op.slave = s3 else '1';
    S4_MR <= '0' when c1_op.op=read and c1_op.slave = s4 else '1';

    S1_MW <= '0' when c1_op.op=write and c1_op.slave = s1 else '1';
    S2_MW <= '0' when c1_op.op=write and c1_op.slave = s2 else '1';
    S3_MW <= '0' when c1_op.op=write and c1_op.slave = s3 else '1';
    S4_MW <= '0' when c1_op.op=write and c1_op.slave = s4 else '1';      

    -- Sequential process sampling the incoming Address in order to route the
    -- relative data upon reading
    process(clk,reset)
    begin
        if reset='0' then
          C2_op.op <= nop;
          C2_op.master <= default;
          C2_op.slave  <= default;
        else
            if clk'event and clk='1' then
                    C2_op.op     <= c1_op.op;
                    C2_op.master <= c1_op.master;
                    C2_op.slave  <= c1_op.slave;
            end if;
        end if;
    end process;

    -- selecting input value from All slaves
    c2_data_inbus <= S1_DATA_INBUS when (c2_op.slave=s1 and c2_op.op=read) else
                     S2_DATA_INBUS when (c2_op.slave=s2 and c2_op.op=read) else
                     S3_DATA_INBUS when (c2_op.slave=s3 and c2_op.op=read) else
                     S4_DATA_INBUS when (c2_op.slave=s4 and c2_op.op=read) else
                     (others=>'0');
    

    c2_nready <= S1_NREADY when c2_op.slave=s1 and c2_op.op=read else
                 S2_NREADY when c2_op.slave=s2 and c2_op.op=read else
                 S3_NREADY when c2_op.slave=s3 and c2_op.op=read else
                 S4_NREADY when c2_op.slave=s1 and c2_op.op=read else
                 '1';

    c2_busy  <= M1_BUSY when c2_op.master=m1 and c2_op.op=read else '1';   
    
    M1_DATA_INBUS <= C2_data_inbus when c2_op.master=m1 else (others=>'0');
    M1_NREADY     <= c2_nready     when c2_op.master=m1 else '1';

      
    S1_BUSY <= c2_busy when c2_op.slave = s1 else '1';
    S2_BUSY <= c2_busy when c2_op.slave = s2 else '1';
    S3_BUSY <= c2_busy when c2_op.slave = s3 else '1';
    S4_BUSY <= c2_busy when c2_op.slave = s4 else '1';      


  end struct;
