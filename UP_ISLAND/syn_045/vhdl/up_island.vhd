-------------------------------------------------------------------------------
-- up_island
-- by fcampi@sfu.ca Feb 2014
--
-- Simple synthesizable and replicable cell based on the Qrisc processor core
-------------------------------------------------------------------------------

library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;

  
entity up_island is
   generic (UP_ID : integer:=1);
   Port (   -- System Control Signals
           CLK               : in   Std_logic;
           reset             : in   Std_logic;

           -- Data Bus Request
           BUS_NREADY          : in   Std_logic;
           BUS_BUSY            : out  Std_logic;
           BUS_MR, BUS_MW      : out  Std_logic;
           BUS_ADDR_OUTBUS     : out  Std_logic_vector(31 downto 0);
           BUS_DATA_INBUS      : in   Std_logic_vector(31 downto 0);
           BUS_DATA_OUTBUS     : out  Std_logic_vector(31 downto 0) );
end up_island;

Architecture struct of up_island is

  component Xi_core
  generic(
           -- ARCHITECTURE DEFINITION 
           -- System Control Coprocessor is the coprocessor handling interrupts
           -- and exceptions
           include_scc : integer:= 1;           
           -- Floating point Unit
           include_fpu     : integer := 0;
           -- On-chip Unit interfacing XiRisc with an external GDB suite
           include_dbg     : integer := 1;           
           -- Hardware shift logic
           include_shift   : integer := 1;           
           -- Rotate logic
           include_rotate  : integer := 1;
           -- Hardware iterations: allows for the utilization of Branch Decrement
           -- instructions
           include_hrdwit  : integer := 1;

           -- Multiply-Accumulation logic
           include_mul     : integer := 1;
           include_mult    : integer := 1;
           include_mad     : integer := 1;
           -- Hardware check on Imem access
           include_iaddr_check : integer :=1;
           -- Hardware check on Imem access
           include_daddr_check : integer :=1;

           -- Raise an interruption in case of internal exception
           interrupt_on_exception : integer :=1;
           -- Include sticky logic on internal exceptions
           include_sticky_logic : integer :=1;
           -- Depth of the on-chip shifter: Max shift is 2**shift_count_width
           shift_count_width   : positive := 5;
           -- Number of bits to address GP register in the processor Rfile
           -- The number of registers will be 2**rf_registers_addr_width
           rf_registers_addr_width : positive := 5;

           -- BUS WIDTH DEFINITION
           -- Processor Data Width
           Word_Width      : positive := 32;
            -- Processor Instruction Width
           Instr_Width     : positive := 32;
           -- Processor Data addressing space Width (XiRisc has Harvard memory
           -- organization)
           Daddr_width     : positive := 32;
           -- Processor Instruction addressing space Width (XiRisc has Harvard
           -- memory organization)
           Iaddr_width     : positive := 24;

           -- CONTROL, STATUS and MEMORY SPACE SETTINGS
           -- Activation of the hardware controls on memory addresses
           imem_lowerlimitation_control : integer := 0;
           dmem_lowerlimitation_control : integer := 0;
           imem_upperlimitation_control : integer := 0;
           dmem_upperlimitation_control : integer := 0;
           -- Higher limit of the processor memory space
           -- (Utilized for hardware controls on memory addresses) 
           instr_mem_max_addr_upper     : integer := 16#0000#;
           instr_mem_max_addr_lower     : integer := 16#3fff#;
           data_mem_max_addr_upper      : integer := 16#0000#; 
           data_mem_max_addr_lower      : integer := 16#ffff#;
           -- Base value of the interrupt table (mapped on data memory)
           Int_table_base : integer := 16#4000#;
           -- Instruction Address imposed at reset and reboot
           reboot_value_upper  : integer := 0;
           reboot_value_lower  : integer := 0;
           reset_value_upper   : integer := 0;
           reset_value_lower   : integer := 16#1000#;
           
           -- Default values of the Scc Registers           
           status_bits         : integer := 16#c0ff#; 
           intproc_status_bits : integer := 16#0000#;
           cause_bits          : integer := 16#0010# );
  
    Port (
           -- System Control Signals
           CLK              : in   Std_logic;
           reset            : in   Std_logic;
           reboot           : in   Std_logic;
           freeze           : in   Std_logic;

           -- Bus access Syncronization
           I_NREADY,D_NREADY  : in   std_logic;
           I_BUSY,D_BUSY      : out  std_logic;

           -- Interrupt Vector
           INTERRUPT_VECTOR : in   Std_logic_vector(7 downto 0) ;

           -- Instruction Bus (Harvard Architecture)
           I_ADDR_OUTBUS    : out  Std_logic_vector(Iaddr_width-1 downto 0);
           I_DATA_INBUS     : in   Std_logic_vector(instr_width-1 downto 0);

           -- Data Bus (Harvard Architecture)
           D_ADDR_OUTBUS    : out  Std_logic_vector(daddr_width-1 downto 0);
           D_DATA_INBUS     : in   Std_logic_vector(word_width-1 downto 0);
           D_DATA_OUTBUS    : out   Std_logic_vector(word_width-1 downto 0);

           mem_read         : out  Std_logic;
           mem_write        : out  Std_logic;
           mem_isbyte       : out  Std_logic;
           mem_ishalf       : out  Std_logic;

           --Dbg Signals
           dbg_enable	    : in  Std_logic;
    	   ext_bp_request   : in  Std_logic;
           end_dbg          : out Std_logic;
	   real_dbg_op	    : out Std_logic;
           
           -- Special Control Signals
           kernel_mode      : out Std_logic;
           suspend          : out Std_logic );  
  end component;

  component ubus
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
  end component;  

  component SRAM 
  generic ( addr_size : integer := 8; word_size : integer := 16 );
  port (  clk       :   in  std_logic;
          rdn       :   in  std_logic;
          wrn       :   in  std_logic;
          address   :   in  std_logic_vector(addr_size-1 downto 0);
          bit_wen   :   in  std_logic_vector(word_size-1 downto 0);
          data_in   :   in  std_logic_vector(word_size-1 downto 0);
          data_out  :   out std_logic_vector(word_size-1 downto 0) );
  end component;

  component Debug_Tool
    generic (file_name : string := "std_output");
  port (  clk       :   in  std_logic;
          reset     :   in  std_logic;
          wrn       :   in  std_logic;
          address   :   in  std_logic_vector(15 downto 0);
          data_in   :   in  std_logic_vector(31 downto 0);
          clock_out :   out std_logic );
  end component;

signal I_NREADY,D_NREADY,I_BUSY,D_BUSY : std_logic;
signal INTERRUPT_VECTOR : Std_logic_vector(7 downto 0) ;

signal I_ADDR_OUTBUS    : Std_logic_vector(Iaddr_width-1 downto 0);
signal I_DATA_INBUS,I_DATA_OUTBUS : Std_logic_vector(instr_width-1 downto 0);
signal D_ADDR_OUTBUS    : Std_logic_vector(Daddr_width-1 downto 0);
signal D_DATA_INBUS,D_DATA_OUTBUS : Std_logic_vector(word_width-1 downto 0); 
signal dmem_read,dmem_write,dmem_isbyte,dmem_ishalf : Std_logic;

signal dram_addr_outbus,dram_data_inbus,dram_data_outbus : Std_logic_vector(31 downto 0);
signal dram_mr,dram_mw,dram_nready : Std_logic;
  
signal dbg_enable,ext_bp_request,end_dbg,real_dbg_op : Std_logic;
signal kernel_mode,suspend : Std_logic;
signal iram_rd,iram_wr,dram_rd,dram_wr,dt_wr : Std_logic;
signal i_select,d_select : Std_logic_vector(31 downto 0);
signal reboot,freeze : Std_logic;
  
begin 

  UUT : Xi_core
  generic map (reset_value_lower=>16#0000#,include_dbg=>0,include_scc=>0,include_hrdwit=>0)
  port map ( CLK,reset,reboot,freeze,
             
             I_NREADY,D_NREADY,
             I_BUSY,D_BUSY,
             
             INTERRUPT_VECTOR, 
             
             I_ADDR_OUTBUS,I_DATA_INBUS, 
             D_ADDR_OUTBUS,D_DATA_INBUS,D_DATA_OUTBUS,
             
             dmem_read,dmem_write,dmem_isbyte,dmem_ishalf,
             dbg_enable, ext_bp_request, end_dbg, real_dbg_op,
             kernel_mode,suspend );           

  -- Embryo of local bus for resolving datamem accesses
  localbus : ubus
    generic map (s1_start=>X"40010000",s1_end=>X"40012000",
                 s2_start=>X"50000000",s2_end=>X"f0000000",
                 s3_start=>X"00000000",s3_end=>X"00000000",
                 s4_start=>X"00000000",s4_end=>X"00000000")
    port map ( clk,reset,
               -- M1 port
               D_BUSY,dmem_read,dmem_write,D_NREADY,
               D_ADDR_OUTBUS,D_DATA_INBUS,D_DATA_OUTBUS,
               -- S1 port
               open,DRAM_MR,DRAM_MW,DRAM_NREADY,
               DRAM_ADDR_OUTBUS,DRAM_DATA_INBUS,DRAM_DATA_OUTBUS,
               -- S2 port
               BUS_BUSY,BUS_MR,BUS_MW,BUS_NREADY,
               BUS_ADDR_OUTBUS,BUS_DATA_INBUS,BUS_DATA_OUTBUS,
               -- S3 port
               open,open,open,'1',
               open,X"00000000",open,
               -- S4 port
               open,open,open,'1',
               open,X"00000000",open);
  
  
  DMem : SRAM                           -- 8K bytes
    generic map (addr_size => 11,word_size => 32)
    port map (clk,dram_mr,dram_mw,DRAM_ADDR_OUTBUS(12 downto 2),d_select,DRAM_DATA_OUTBUS,DRAM_DATA_INBUS);

  DRAM_NREADY <= '1';   -- This particular slave is never stalled

  
  iram_rd <= '0' when I_BUSY='1' else '1';
  iram_wr <= '1';
  
  IMem : SRAM                           -- 8K bytes
    generic map (addr_size => 11,word_size => 32)
    port map (clk,iram_rd,iram_wr,I_ADDR_OUTBUS(12 downto 2),i_select,I_DATA_OUTBUS,I_DATA_INBUS);
  
  -- Byte access Logic (Selective write operations)
  i_select <= (others=>'0');
  d_select <= X"0000ffff"   when dmem_ishalf='0' and dmem_isbyte='1' and D_ADDR_OUTBUS(1)='0'           else
              X"0000ffff"   when dmem_ishalf='0' and dmem_isbyte='1' and D_ADDR_OUTBUS(1)='1'           else
              X"00ffffff"   when dmem_ishalf='1' and dmem_isbyte='0' and D_ADDR_OUTBUS(1 downto 0)="00" else
              X"ff00ffff"   when dmem_ishalf='1' and dmem_isbyte='0' and D_ADDR_OUTBUS(1 downto 0)="01" else
              X"ffff00ff"   when dmem_ishalf='1' and dmem_isbyte='0' and D_ADDR_OUTBUS(1 downto 0)="10" else
              X"ffffff00"   when dmem_ishalf='1' and dmem_isbyte='0' and D_ADDR_OUTBUS(1 downto 0)="11" else
              (others=>'0');
  
  -- Synopsys synthesis_off
  dt_wr   <= '0' when D_BUSY='1' and dmem_write='0' and D_ADDR_OUTBUS(31 downto 16) = X"0002" else '1';
  DT : Debug_Tool
    generic map (file_name => "std_output" & integer'image(UP_ID))
    port map (clk,reset,dt_wr,D_ADDR_OUTBUS(15 downto 0),D_DATA_OUTBUS,open);
  -- Synopsys synthesis_on
  
  
  
------------------------------------------

  -- Setting unnecessary input control signals to a reliable quiet state.
  -- Note, control signals are all active low

  -- Flow Control Signals
  reboot <= '1';freeze <= '1';
  INTERRUPT_VECTOR <= (others=>'0');     -- This one is active high

  -- BUS Control Signals
  I_NREADY <= '1';           -- Nready='0' means that there is a
                             -- cache miss and the processor must be
                             -- stalled
  I_DATA_OUTBUS <= (others=>'0');
    
  -- XiDbg control signals  
    dbg_enable <= '1'; ext_bp_request <= '1';
-------------------------------------------------------------------------------
  
end struct; 
  

