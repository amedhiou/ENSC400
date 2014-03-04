---------------------------------------------------------------------------
--                        xi_pport.vhd                                   --
--                                                                       --
-- Created 2001 by F.M.Campi,C.Mucci    fcampi@deis.unibo.it             --
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
-- This license is a modification of the Ricoh Source Code Public 
-- License Version 1.0 which is similar to the Netscape public license.  
-- We believe this license conforms to requirements adopted by OpenSource.org. 
--
-- Please direct any comments regarding this license to xirisc@deis.unibo.it
-------------------------------------------------------------------------------


-- PARALLEL PORT --------------------------------------------------------------

-- The following VHDL file describes an hardware FSM thet implements a subset
-- of the IEEE 1284 protocol for harrdware communication.
-- This component drives a set of 23 signals that can be connected to the
-- parallel port interface of a common PC.
-- It can be used consequently to implement an easy communucation chip/outside
-- world easing the chip usage and testing.
-- The parallel port is composed of four 8-bit internal registers, two of wich
-- are used for the data transfer, and two to implement the protocol control.
-- Data are exchanged on a bidirectional 8-bit bus.
-- The interconnection protocol can be implemented through a harware handshake
-- protocol driven by the NSTROBEOUT_NACKOUT NACKIN_NSTROBEIN signals, or with
-- a software negotiation through the CONTROL (out) and STATUS (in) signals.


-- Note: Main Handshake signals:
--
-- Pport to Host:
-- EXT_CONTROL(3 downto 0): 3 -> Read  Request
--                          2 -> Write Request
--                          1 -> Boot  Request
--                          0 -> Software handshake, not used in rhis implementation
-- NACKOUT_NSTROBEOUT : Handshake signal
--
-- Host to Pport:
-- EXT_STATUS(1 downto 0): 1 -> Unused 
--                         0 -> Unused
--
-- Internal Pport Registers:
-- Register Read by XiRisc: STATUS REGISTER
--
-- Internal Pport Signals:
-- status(9)          <= Boot_request;   
-- status(8)          <= IREQ;
-- status(7)          <= MODE;
-- status(6)          <= Read_request; 
-- status(5)          <= Write_request; 
-- Signals acquired from IO ports:
-- status(4)          <= EXT_DIRECTION;  -- '1' => Tx mode
-- status(3 downto 2) <= EXT_STATUS;
-- status(1)          <= NACKSTROUT;                          
-- status(0)          <= NACKSTRIN;
--
-- Register Written by XiRisc: CONTROL REGISTER
-- 
--  control(7)       <= MODE        
--  control(3)       <= Read_request    -- Only the last four signals are  
--  control(2)       <= Write_request   -- transmitted through the pport interface
--  control(1)       <= Boot_request  
--  control(0)       <= sftw_NACKSTROUT  

library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use work.basic.all;
use work.components.all;

entity PARALLEL_PORT is
  
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
    
end PARALLEL_PORT;


architecture BEHAVIORAL of PARALLEL_PORT is

  subtype pp_fsm is std_logic_vector(2 downto 0);
  constant rx_idle   : pp_fsm := "000";
  constant rx_strobe : pp_fsm := "001";
  constant rx_ack    : pp_fsm := "010";
  constant tx_idle   : pp_fsm := "100";
  constant tx_strobe : pp_fsm := "101";
  constant tx_ack    : pp_fsm := "110";
  constant software  : pp_fsm := "011";

  type pp_spy is (pp_rxidle,pp_rxstrobe,pp_rxack,pp_txidle,pp_txstrobe,pp_txack,pp_software,pp_error);
  type req_spy is (no_req,read_req,write_req,boot_req,err_req);
  signal spy  : pp_spy;
  signal rspy : req_spy;
  
  signal DIR,MODE,IREQ                     : std_logic;
  signal NACKSTRIN                         : std_logic;
  signal NACKSTROUT,sftw_NACKSTROUT        : std_logic;
  signal rx_reg_in,rx_reg_out              : std_logic_vector(7 downto 0);
  signal real_rx_reg_out                   : std_logic_vector(9 downto 0);
  signal tx_reg_in,tx_reg_out              : std_logic_vector(7 downto 0);
  signal ctrl_reg_in,ctrl_reg_out          : std_logic_vector(7 downto 0);
  signal status_reg_in,status_reg_out      : std_logic_vector(9 downto 0);
  signal RX_xicore_read,status_xicore_read : std_logic;
  signal CTRL_xicore_write,TX_xicore_write : std_logic;
  
  -- This signal detect the Rx transmission strobe from the PC and activates the
  -- Rx register sample
  signal rx_reg_sample                           : std_logic;

  -- Signals used to drive the external MUX resolving PP/Dmem Access
  signal ck_status_read,ck_rx_read               : std_logic;
  -- PP internal status
  signal state,next_state                        : pp_fsm;
  -- Signals used by the XiRisc core to master the transmission synchronization
  signal Write_request,Read_request,Boot_request,Direction  :std_logic;
  
  signal Lo : std_logic;
  
begin  -- BEHAVIORAL

  -- synopsys synthesis_off
  PP_MONITOR:process(state)
    begin
      if state=rx_idle then
        spy <= pp_rxidle;
      elsif state=rx_strobe then
        spy <= pp_rxstrobe;
      elsif state=rx_ack then
        spy <= pp_rxack;
      elsif state=tx_idle then
        spy <= pp_txidle;
      elsif state=tx_strobe then
        spy <= pp_txstrobe;
      elsif state=tx_ack then
        spy <= pp_txack;
      elsif state=software then
        spy <= pp_software;
      else
        spy <= pp_error;
      end if;
    end process;

    REQ_MONITOR:process(Write_request,Read_request,Boot_request)
      begin
        if (Write_request='0' and Read_request='0' and Boot_request='0') then
          rspy <= no_req;
        elsif (Write_request='1' and Read_request='0' and Boot_request='0') then
          rspy <= write_req;
        elsif (Write_request='0' and Read_request='1' and Boot_request='0') then
          rspy <= read_req;
        elsif (Write_request='0' and Read_request='0' and Boot_request='1') then
          rspy <= boot_req;
        else
          rspy <= err_req;
        end if;
      end process;
    -- synopsys synthesis_on
  
  Lo <= '0';
  
--  PPort Inputs --------------------------------------------------------------
  
  -- From the outside world (Test PC)
  DIR       <= EXT_DIRECTION;          
  RX_reg_in <= EXT_DATA_IN;
  NACKSTRIN <= NSTROBEIN_NACKIN;

  -- From the XiRisc core
  TX_reg_in   <= DDATA_IN;
  ctrl_reg_in <= DDATA_IN;

  
--  PPort Outputs -------------------------------------------------------------

  -- To the ouside world (Test PC)
  EXT_CONTROL          <= ctrl_reg_out(3 downto 0);
  EXT_DATA_OUT         <= TX_reg_out;
  NACKOUT_NSTROBEOUT   <= NACKSTROUT;

  -- To the XiRisc core and its bus architecture
  INT_REQUEST <= IREQ;

  real_rx_reg_out <= "00"&rx_reg_out;

  
  -- Pport dataout port, on the internal chip bus.
  -- Normally describes the pport status, unless a rx data transfer is active.
  PPORT_DATABUS_CONTROL_F:
    process(CLK,reset)
    begin
      if reset = '0' then
         ck_rx_read     <= '1';
      elsif CLK'EVENT and CLK='1' then
            ck_rx_read     <= RX_xicore_read;
      end if;
    end process;    
  
  PPORT_DATABUS_MUX:
    DDATA_OUT <= real_rx_reg_out when ck_rx_read='0' else status_reg_out;
  
-------------------------------------------------------------------------------
--                   PPORT  Internal Registers
-------------------------------------------------------------------------------

  -- Read from External PC Register: Samples from ext bus data entering the chip
  RX_REG :
    Data_reg generic map (init_value=>0,reg_width=>8)
             port map ( CLK,reset,rx_reg_sample,RX_reg_in,rx_reg_out );

  -- Transmit to External PC Register: Samples data leaving the chip
  TX_REG :
    Data_reg generic map (init_value=>0,reg_width=>8)
             port map ( CLK,reset,TX_xicore_write,TX_reg_in,TX_reg_out );

  -- Control Register: Maintains the PP programming mode
  -- Default is Receive mode to avoid conflicts. The PP transmits only if the
  -- DIRECTION=0 flag is issued  
  CTRL_REG :
    Data_reg generic map (init_value=>16#10#,reg_width => 8)
             port map ( CLK,reset,CTRL_xicore_write,ctrl_reg_in,ctrl_reg_out);

  STATUS_REG :
    Data_reg generic map (init_value=>16#071#,reg_width => 10)
             port map (CLK,reset,status_xicore_read,status_reg_in,status_reg_out);
  
  
 -- CONTROL REGISTER MAPPING --------------------------------------------------
  
  MODE             <= ctrl_reg_out(7);
  Read_request     <= ctrl_reg_out(3);  -- Only the last four signals are  
  Write_request    <= ctrl_reg_out(2);  -- transmitted through the pport interface
  Boot_request     <= ctrl_reg_out(1);
  Direction        <= EXT_DIRECTION;
  sftw_NACKSTROUT  <= ctrl_reg_out(0); 
  
 ------------------------------------------------------------------------------

  
 -- STATUS REGISTER UPDATE ----------------------------------------------------
  
  -- The status register samples the PPort status at every processor read.
  -- Signals driven by the internal control port

  status_reg_in(9)          <= Boot_request;   
  status_reg_in(8)          <= IREQ;
  status_reg_in(7)          <= MODE;
  status_reg_in(6)          <= Read_request;    -- '1' => Write request
  status_reg_in(5)          <= Write_request;   -- '1' => Read Request  
  -- Signal acquired from IO ports
  status_reg_in(4)          <= EXT_DIRECTION;  -- '1' => Tx mode
  status_reg_in(3 downto 2) <= EXT_STATUS;
  status_reg_in(1)          <= NACKSTROUT;                          
  status_reg_in(0)          <= NACKSTRIN;
 ------------------------------------------------------------------------------
  
 
  
  -- PARALLEL PORT EVENT RECOGNITION -----------------------------------------------
    
  -- Control/Status register write enable: Recognizes memory writes on the
  -- PP control register.
  process(DADDR,mw,CS)
  begin
    if ( CS = '0' and DADDR = "10" and mw='0' ) then
       CTRL_xicore_write <= '0';
    else
       CTRL_xicore_write <= '1'; 
    end if;
  end process;

  -- Control/Status register read enable: Recognizes memory reads on the
  -- PP control/status register, freezing the pport status read from the
  -- micro
  process(DADDR,mr,CS)
  begin
    if ( CS='0' and DADDR="10" and mr='0') then 
       status_xicore_read <= '0';
    else
       status_xicore_read <= '1'; 
    end if;
  end process;

  -- Transmission register write enable: Recognizes memory writes on the
  -- PP data_in port. Enables also the Tx Strobe signal
  process(DADDR,mw,CS)
  begin
    if ( CS='0' and DADDR="00" and mw='0') then 
       TX_xicore_write <= '0';
    else
       TX_xicore_write <= '1';
    end if;
  end process;
  
  -- XiRisc Reads of the sampled data : Recognizes memory reads on the
  -- PP data_in register. Enables also the Rx Acknowledge signal and switches off
  -- the internal interrupt request
  process(DADDR,mr,CS)
  begin
    if ( CS='0' and DADDR="00" and MR='0') then 
       RX_xicore_read <= '0';
    else
       RX_xicore_read <= '1';
    end if;
  end process;

  
  -----------------------------------------------------------------------------

  
  -----------------------------------------------------------------------------
  --  PARALLEL PORT    finite state machine
  --
  -- This Moore's FSM paces the PP functioning gererating the correct
  -- hadshake waveforms
  -----------------------------------------------------------------------------
  
  FSM_MACHINE:
    process(state,DIR,MODE,NACKSTRIN,TX_xicore_write,RX_xicore_read,
            sftw_NACKSTROUT,ctrl_reg_out)        
    begin
      
      case state is
        when rx_idle   => rx_reg_sample   <= '1';
                          NACKSTROUT  <= '1';
                          IREQ <= '0';

                          if MODE = '1' then
                             next_state <= software;
                          elsif DIR = '1' then
                             next_state <= tx_idle;
                          elsif NACKSTRIN = '0' then  -- Rx Request from PC:
                                                             -- the PC has put
                                                             -- valid data on
                                                             -- the bus
                             next_state <= rx_strobe;
                          else
                             next_state <= rx_idle;
                          end if;
        
        -- As a protocol rule,
        -- The periperal (PP) samples data put on the bus by the PC on the
        -- raising edge of the NSTROBEIN signal. On the first, falling
        -- edge of NSTROBEIN the PP simply acknowledge the transer beginning
        -- lowering in turn its NACKOUT signal
        when rx_strobe => rx_reg_sample   <= '1';
                          NACKSTROUT  <= '0';
                          IREQ <= '0';

                          if NACKSTRIN = '1' then
                             next_state <= rx_ack;
                          else
                             next_state <= rx_strobe;
                          end if;
                          
        -- When the input data is safe on the RX register, lowers the ACK signal and
        -- raises an internal interrupt request.
        -- Then we are stuck in this state as long as the Xirisc core hasn't
        -- read the TX register.
        -- Once the Xirisc core has read the icoming data from the input TX
        -- register, the interrupt request is switched off and the NACKOUT signal
        -- may inform the PC that this Rx transfer is over.                      
        when rx_ack    => rx_reg_sample  <= '0';
                          NACKSTROUT     <= '0';
                          IREQ <= '1';

                          if RX_xicore_read = '0' then
                             next_state <= rx_idle;
                          else
                             next_state <= rx_ack;
                          end if;  

-------------------------------------------------------------------------------
                          
        when tx_idle   =>  rx_reg_sample  <= '1';
                           NACKSTROUT     <= '1';
                           IREQ <= '0'; 

                           if MODE = '1' then
                              next_state <= software;
                           elsif DIR = '0' then
                              next_state <= rx_idle;                           
                           elsif TX_xicore_write = '0' then
                              next_state <= tx_strobe;
                           else
                              next_state <= tx_idle;
                           end if;

        -- When the PPORT is in TX mode, and the XiRisc performs a memwrite
        -- operation on the PPort address, The hanshake begins.
        -- The PPort copies data on the bus and Lowers the NSTROBEOUT signal,
        -- waiting for the PC to NACKIN.
        when tx_strobe =>  rx_reg_sample <= '1';
                           NACKSTROUT    <= '0';
                           IREQ <= '0';

                           if NACKSTRIN = '0' then
                              next_state <= tx_ack;
                           else
                              next_state <= tx_strobe;
                           end if;

        -- The PC has sent his acknowledge: Data are now stable on
        -- the PP outport. The second, raising edge of the NSTROUT signal
        -- marks the read of the data by the PC.
        -- Then the PC will raise his ack signal and the handshake will
        -- conclude.
        when tx_ack    =>  rx_reg_sample  <= '1';
                           NACKSTROUT     <= '1';
                           IREQ <= '0';                           
                           
                           if NACKSTRIN = '1' then
                              next_state <= tx_idle;
                           else
                              next_state <= tx_ack;
                           end if;      
                           
-------------------------------------------------------------------------------
                           
        when software  =>  NACKSTROUT    <= sftw_NACKSTROUT;
                           IREQ          <= '0';
                           rx_reg_sample <= ctrl_reg_out(1);
                          
                           if MODE = '0' then
                              next_state <= tx_idle;
                           else
                              next_state <= software;
                           end if;                  
                        
        when others    =>  NACKSTROUT    <= '1';
                           IREQ          <= '0';
                           rx_reg_sample <= '1';

                           next_state <= tx_idle;                       
      end case;
    end process;

    SEQUENTIAL_BLOCK:
      Data_reg generic map (init_value => 0, reg_width => 3)
               port map (CLK,RESET,Lo,next_state,state);
      
end BEHAVIORAL;

