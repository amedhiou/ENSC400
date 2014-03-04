library IEEE;
  use std.textio.all;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;
  use work.menu.all;
  
entity E is
end E; 
Architecture A of E is

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
           cause_bits          : integer := 16#0010#;
           -- Verification Parameters
           include_verify      : integer :=1;
           include_wbtrace     : integer :=1;
           include_selfprofile : integer :=1;
           include_putchar     : integer :=1 );
  
    Port (
           -- System Control Signals
           CLK              : in   Std_logic;
           reset            : in   Std_logic;
           reboot           : in   Std_logic;
           freeze           : in   Std_logic;

           -- Bus access Syncronization
           I_NREADY,D_NREADY  : in   std_logic;
           I_BUSY,D_BUSY    : out  std_logic;

           -- Interrupt Vector
           INTERRUPT_VECTOR : in   Std_logic_vector(7 downto 0) ;

           -- Instruction Bus (Harvard Architecture)
           I_ADDR_OUTBUS    : out  Std_logic_vector(iaddr_width-1 downto 0);
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
           suspend          : out Std_logic
           );  
  end component;

  component bootup_rom
  generic (instr_width : integer :=32 );
  port( clk      : in  std_logic;
        reset    : in  std_logic;
        freeze   : in  std_logic;
        addr_in  : in  std_logic_vector(11 downto 0);
        data_out : out Std_logic_vector(instr_width-1 downto 0) );
  end component;
  
  component xi_memory_banks
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
  end component;
  
  component Dmem_block 
    generic( daddress_width : integer :=16;
             load_file      : string );
    
    port( load,clk,reset        : in  Std_logic;        
          control_in            : in  Std_logic_vector(3 downto 0);
          clocked_control       : out Std_logic_vector(3 downto 0);
          daddr_in              : in  Std_logic_vector(daddress_width-1 downto 0);
          clocked_daddr         : out Std_logic_vector(daddress_width-1 downto 0);
          ddata_in              : in  Std_logic_vector(31 downto 0);
          ddata_out             : out Std_logic_vector(31 downto 0) );
  end component;

  component PARALLEL_PORT
  port ( CLK,reset    : in  std_logic;
         MR,MW        : in  std_logic;
         CS           : in  std_logic;

         DADDR        : in  std_logic_vector(1 downto 0);
         DDATA_IN     : in  std_logic_vector(7 downto 0);
         DDATA_OUT    : out std_logic_vector(9 downto 0);         
         INT_REQUEST  : out std_logic;
    
         EXT_DATA_OUT   : out std_logic_vector(7 downto 0);  -- external bus
         EXT_DATA_IN    : in  std_logic_vector(7 downto 0);  -- external bus
         EXT_CONTROL    : out std_logic_vector(3 downto 0);  -- control signal
         EXT_STATUS     : in  std_logic_vector(1 downto 0);  -- status signal
         EXT_DIRECTION  : in  std_logic;                     -- transfer direction
                                                             -- '0' RX, '1' TX
         NACKOUT_NSTROBEOUT : out std_logic;   -- output signal for handshake
         NSTROBEIN_NACKIN   : in  std_logic); -- input signal for handshake
  end component;

  component VHF
      port( clk          : in  Std_logic;
            pp_data_out  : in  Std_logic_vector(7 downto 0);
            pp_data_in   : out Std_logic_vector(7 downto 0);

            pp_direction : out Std_logic;  
            pp_control   : in  std_logic_vector(3 downto 0);  -- control signal
            pp_status    : out std_logic_vector(1 downto 0);  -- status signal            
              
            pp_out       : in  Std_logic;
            pp_in        : out std_logic );
  end component;

  
 signal load                                     : Std_logic;
 signal CLK,reset,reboot,freeze                  : Std_logic;
 signal I_MEM_NREADY,D_MEM_NREADY                : std_logic;
 signal Ibusy,Dbusy                              : std_logic;
 signal mem_ishalf,mem_isbyte,mem_write,mem_read : std_logic;
 signal dbg_enable, ext_bp_request, end_dbg, real_dbg_op : Std_logic; 
 signal kernel_mode,suspend                      : std_logic;
  
 signal INTERRUPT_VECTOR                   : std_logic_vector(7 downto 0);
 signal IRAM_ADDR                          : Std_logic_vector(iaddr_width-1 downto 0); 
 signal I_ADDR_OUTBUS                      : Std_logic_vector(iaddr_width-1 downto 0);
 signal D_ADDR_OUTBUS                      : Std_logic_vector(daddr_width-1 downto 0);
 signal I_DATA_OUTBUS,I_DATA_INBUS         : Std_logic_vector(instr_width-1 downto 0);
 signal I_DATA_INBUS_RAM,I_DATA_INBUS_ROM  : Std_logic_vector(instr_width-1 downto 0);
  
 signal D_DATA_OUTBUS,D_DATA_INBUS         : Std_logic_vector(word_width-1 downto 0);
 signal D_DATA_INBUS_MEM,D_DATA_INBUS_PP   : Std_logic_vector(word_width-1 downto 0);

 signal ICSN,IOEN,DCSN,DOEN : std_logic;
 signal IWEN : std_logic_vector(0 downto 0);
 signal DWEN : std_logic_vector(3 downto 0);

 signal irom_cs : std_logic;
  
 signal dmem_control,clocked_control : Std_logic_vector(3 downto 0);
 signal clocked_daddr : Std_logic_vector(daddr_width-1 downto 0);

 -- Signals handling parallel port emulation
 signal pp_data_out,pp_data_in  : Std_logic_vector(7 downto 0);
 signal pp_control  : std_logic_vector(3 downto 0);  -- control signal
 signal pp_status   : std_logic_vector(1 downto 0);  -- status signal
 signal pp_direction,pp_out : Std_logic;
 signal pp_in       : std_logic;
 signal pport_cs    : std_logic;
  
 constant PERIOD        : time := 10 ns;
 constant HALF_PERIOD   : time := 5 ns;
 constant SETTLING_TIME : time := 2 ns;

  
 begin

    UUT : Xi_core
        generic map ( include_scc,include_fpu,include_dbg,
                      include_shift,include_rotate,include_hrdwit,
                      include_mul,include_mult,include_mad,
                      include_iaddr_check,include_daddr_check,
                      interrupt_on_exception,include_sticky_logic,
                      shift_count_width,rf_registers_addr_width,
                      Word_Width,Instr_width,Daddr_width,Iaddr_width,
                      imem_lowerlimitation_control,dmem_lowerlimitation_control,
                      imem_upperlimitation_control,dmem_upperlimitation_control,
                      instr_mem_max_addr_upper,instr_mem_max_addr_lower,
                      data_mem_max_addr_upper,data_mem_max_addr_lower,Int_table_base,
                      reboot_value_upper,reboot_value_lower,
                      reset_value_upper,reset_value_lower,
                      status_bits,intproc_status_bits,cause_bits,
                      include_verify,include_wbtrace,include_selfprofile,include_putchar )
                                                                        
        port map ( CLK,reset,reboot,freeze,
                   
                   I_MEM_NREADY,D_MEM_NREADY,
                   Ibusy,Dbusy,
                   
                   INTERRUPT_VECTOR, 

                   I_ADDR_OUTBUS,I_DATA_INBUS, 
                   D_ADDR_OUTBUS,D_DATA_INBUS,D_DATA_OUTBUS,
                   
                   mem_read,mem_write,mem_isbyte,mem_ishalf,                   
                   dbg_enable, ext_bp_request, end_dbg, real_dbg_op,
                   kernel_mode,suspend );                                           


  ------------------------------------------
  --  XiDbg control signals
  ------------------------------------------
    
    dbg_enable <= '1';
    ext_bp_request <= '1';

    -- MEMORY CONTROL SIGNAL SETTING ------------------------------------------
    IWEN(0)    <= '0' when irom_cs='0' else '1';  -- The instruction memory can
                                                  -- be written when data is
                                                  -- loaded from IROM
    IOEN       <= '0';
    ICSN       <= (not Ibusy);
    
    -- INSTRUCTION MEMORY -----------------------------------------------------

    irom_cs <= '0' when ( (unsigned(I_ADDR_OUTBUS) > unsigned(EXT(conv_std_logic_vector(reboot_value_upper,16)&conv_std_logic_vector(reboot_value_lower,16),Iaddr_width) ) )
                         and (unsigned(I_ADDR_OUTBUS) < unsigned(EXT(conv_std_logic_vector(rom_end_value_upper,16)&conv_std_logic_vector(rom_end_value_lower,16),Iaddr_width ) ) ) )
                   else '1';

    IRAM_ADDR <= I_ADDR_OUTBUS when irom_cs='1' else EXT(D_ADDR_OUTBUS,Iaddr_width);
    I_DATA_INBUS <= I_DATA_INBUS_ROM when irom_cs='0' else I_DATA_INBUS_RAM;
    
    IMEM: xi_memory_banks
      generic map ( banks=>1, cell_width=>instr_width, address_width=>14,
                    load_file=>"src/inputs.tv",
                    min_address_upper => instr_mem_init_value_upper,
                    min_address_lower => instr_mem_init_value_lower,
                    max_address_upper => instr_mem_end_value_upper,
                    max_address_lower => instr_mem_end_value_lower )
      port map ( load,CLK,IOEN,IWEN,ICSN,
                 IRAM_ADDR(15 downto 2),D_DATA_OUTBUS,I_DATA_INBUS_RAM);
    
    IROM: bootup_rom
      generic map (instr_width => instr_width)
      port map ( clk,reset,freeze,I_ADDR_OUTBUS(11 downto 0),I_DATA_INBUS_ROM );
    
    ---------------------------------------------------------------------------

    
    -- DATA MEMORY ------------------------------------------------------------
    
    dmem_control(3) <= mem_read or (not Dbusy);
    dmem_control(2) <= mem_write or (not Dbusy);
    dmem_control(1) <= mem_isbyte;
    dmem_control(0) <= mem_ishalf;

    -- To limit computational resources necessary to perform simulation,
    -- the addressing space is cut down entering the Dmemory
    DMEM: Dmem_block
      generic map ( daddress_width=>18,load_file=>"src/inputs.tv" )
      port map ( load,clk,reset,
                 dmem_control,clocked_control,
                 D_ADDR_OUTBUS(17 downto 0),
                 clocked_daddr(17 downto 0),
                 D_DATA_OUTBUS,D_DATA_INBUS_MEM );


    pport_cs <= '0' when ( D_ADDR_OUTBUS(17 downto 2)=conv_std_logic_vector(0,16)
                           and (dmem_control(3)='0' or dmem_control(2)='0') ) else '1';
    
    D_DATA_INBUS <= D_DATA_INBUS_PP when
                        ( clocked_daddr(17 downto 2)=conv_std_logic_vector(0,16) )          
                     else D_DATA_INBUS_MEM;

    D_DATA_INBUS_PP(Word_Width-1 downto 10) <= (others=>'0' );
    
    PPORT: parallel_port port map (  clk,reset,
                                     dmem_control(3),dmem_control(2),pport_cs,
                                     D_ADDR_OUTBUS(1 downto 0),
                                     D_DATA_OUTBUS(7 downto 0),D_DATA_INBUS_PP(9 downto 0),
                                     open,
                                     pp_data_out,pp_data_in,
                                     pp_control,pp_status,
                                     pp_direction,
                                     pp_out,pp_in );

--     VHF_inteface: VHF port map (  clk,
--                                   pp_data_out,pp_data_in,
--                                   pp_direction,
--                                   pp_control,pp_status,
--                                   pp_out,pp_in );

        
    ---------------------------------------------------------------------------
    --                 SIMULATION ENGINE PROCESS                             --
    ---------------------------------------------------------------------------

    sim_engine:process
    begin
      load <= '0';
      wait for Settling_time;
            
      -- 1: Load Predefined values on the onchip Memories
       load <= '1';
       wait for Half_Period-settling_time;
       load <= '0';

      -- 2: Reset the Microprocessor to the execution correct address
      reset    <= '0';
      reboot   <= '1';
      -- reset  <= '1';
      -- reboot <= '0';
      
      CLK <= '0'; 
      wait for Half_Period;
      CLK <= '1';
      wait for Half_Period;

      CLK <= '0'; 
      wait for Half_Period;
      CLK <= '1';
      wait for Half_Period;

      -- 3: Start (forever) normal execution
      CLK <= '0'; 
      wait for Half_Period;

      reset    <= '1';
      reboot   <= '1';
      
      while(1=1) loop
        CLK <= '1';
        wait for Half_Period;
        CLK <= '0';
        if suspend='0' then wait;
        end if;
        wait for Half_Period;
      end loop;

    end process;
  -------------------------------------------
  --  Generation of an interrupt exception --
  -------------------------------------------
   process
   begin
     INTERRUPT_VECTOR <= "00000000";
     wait for 1000 ns;
     INTERRUPT_VECTOR <= "00000000";   -- Maybe raise some interrupts to debug ????
     wait for 100 ns;
     INTERRUPT_VECTOR <= "00000000";
     --wait for 100 ns;
   end process;
        
-------------------------------------------
  --  Generation of manual freeze --
  -------------------------------------------
   process
   begin
     freeze <= '1';
     wait for 600 ns;
     freeze <= '1';   -- Maybe raise some freeze to debug ???? 
     wait for 100 ns;
     freeze <= '1';
     --wait for 180 ns;
   end process;


---------------------------------------------
  --  Generation of manual icache_miss --
  -------------------------------------------
   process
   begin
     I_MEM_NREADY <= '1';
     wait for 46360 ns;
     I_MEM_NREADY <= '1';   -- Maybe raise some cache misses ???? 
     wait for 100 ns;
     I_MEM_NREADY <= '1';
     wait for 200000 ns;
   end process;



-------------------------------------------
  --  Generation of manual dcache_miss --
-------------------------------------------
   process
   begin
     D_MEM_NREADY <= '1';
     wait for 46360 ns;
     D_MEM_NREADY <= '1';    -- Maybe raise some cache misses ???? 
     wait for 100 ns;
     D_MEM_NREADY <= '1';
     wait for 200000 ns;
   end process;  

 end A; 
  

-----------------------------------------------------------------------------
--             CONFIGURATION DEFINITIONS
-----------------------------------------------------------------------------
 
configuration CFG_TESTBENCH of E is
   for A
   end for;
end CFG_TESTBENCH;
