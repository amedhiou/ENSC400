---------------------------------------------------------------------------
--                        XI_DBG.VHD                                     --
--                                                                       --
--   System Control Coprocessor  for  the XiRisc processor model         --
--   double datapath version                                             --
--                                                                       --
---------------------------------------------------------------------------
--  Created 2003 by R.Pelliconi , roberto.pelliconi@st.com               --
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


-- The debug coprocessor is devoted to the handling of the debug operations
-- that can be desired in the XiRisc Processor.
-- Its main function is to break the processor execution flow when a debug
-- condition is satisfied.
-- During the debug phase XiRisc executes a debug routine saved in the instruction
-- memory during the boot phase (it is a simple interrupt handling routine).
--
-- (1) Holding into an array of special registers the current processor
--     state, controlling: context switches, special register writes, and
--     special register read operations.
--
-- (2) Handling exceptions and external interrupts, resolving precedences
--     and tranferring control to the dedicated servicing procedures
--     specified in reserved sections of the instruction memory.
--


------------------------------------------------------------------------
--                ENTITY DEFINITION
------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_unsigned.all;
  use work.menu.all;
  use work.basic.all;
  use work.isa_32.all;
  
entity Dbg  is
  generic ( rf_registers_addr_width : positive := 5;
            Word_Width      : positive := 32;
            Iaddr_width     : positive := 24 );
  
    port(   clk,reset,reboot,freeze     : in  Std_logic;
    	    kernel_mode			: in  Std_logic;
            en_exe,d_we                 : in  Std_logic;
	    d_bds			: in  Std_logic;
	    epc				: in  Std_logic_vector(Iaddr_width-1 downto 0);
            cop_command                 : in  Cop_control;            
            cop_in                      : in  Std_logic_vector(Word_width-1 downto 0);
            cop_out                     : out Std_logic_vector(Word_width-1 downto 0);
            rcop_addr                   : in  Std_logic_vector(4 downto 0);
            
            pc_basevalue                : in  Std_logic_vector(Iaddr_width-1 downto 0);
	    dbg_enable			: in  Std_logic;
	    ext_bp_request		: in  Std_logic;
	    end_dbg			: out Std_logic;
	    dbg_real_op			: out Std_logic;
	    bp_detect			: out Std_logic
	    );
            
end Dbg;


---------------------------------------------------------------------------
--       ARCHITECTURE DEFINITION
---------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use work.menu.all;
  use work.basic.all;
  use work.components.all;

architecture structural of Dbg is

-- Interrupt: Describe the interrupt vector masked by ie and im(7 downto 0)
--            flags.It is copied on the cause register bits 23-16.
-- signal interrupt : Std_logic_vector(7 downto 0);

-- Exception word:  signals that flows through the pipeline with the
-- instruction they are referred to, carrying informations about
-- eventual exceptions to update the cause and epc registers.
-- signal f_exc_word,din_exc_word,d_exc_word,ein_exc_word,e_exc_word,
--       exception_word : Std_logic_vector(5 downto 0);

type bp_status is (new_to_serve, serving, already_served, wait_for_ext_bp_request_drop, status_reg_drop);

signal d_pcbasevalue,e_pcbasevalue		:  Std_logic_vector(Iaddr_width-1 downto 0);

-- signal cause,eps,status                     : Std_logic_vector(15 downto 0);
-- signal next_cause,next_eps,next_status      : Std_logic_vector(15 downto 0);
-- signal status_reg_in,exe_status             : Std_logic_vector(15 downto 0);
-- signal epc,next_epc                         : Risc_iaddr;

signal reg_enable                           : Std_logic;

signal dmem_init                            : Std_logic_vector(Word_width-1 downto 0);
signal dmem_end                             : Std_logic_vector(Word_Width-1 downto 0);
signal cop_out_int			    : Std_logic_vector(Word_width-1 downto 0); 
signal mem_download_start		    : Std_logic_vector(Daddr_width-1 downto 0);
signal mem_download_start_new		    : Std_logic_vector(Daddr_width-1 downto 0);
signal mem_download_end			    : Std_logic_vector(Daddr_width-1 downto 0);
signal mem_download_end_new		    : Std_logic_vector(Daddr_width-1 downto 0);
signal status_register			    : Std_logic_vector(Iaddr_width-1 downto 0);
signal status_register_new		    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp0				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp0_new				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp1				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp1_new				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp2				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp2_new				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp3				    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp3_new				    : Std_logic_vector(Iaddr_width-1 downto 0);

signal init_status_reg			    : Std_logic_vector(Iaddr_width-1 downto 0);
signal bp_detect_dbg			    : std_logic;
signal bp_detect_int			    : std_logic;
signal bp_detect_step			    : std_logic;
signal bp_detect_step_c			    : std_logic;
signal bp_detect_internal		    : std_logic;
signal bp_detect_internal_filt		    : std_logic;
signal pres_status			    : bp_status;
signal next_status			    : bp_status;
signal end_dbg_int			    : std_logic;
signal end_dbg_c			    : std_logic;
signal e_bds				    : std_logic;
signal d_glob				    : std_logic_vector(Iaddr_width downto 0);
signal e_glob				    : std_logic_vector(Iaddr_width downto 0);
signal ext_service			    : std_logic;
signal ext_service_new			    : std_logic;

begin
  
--    reg_enable <= not freeze;
      reg_enable <= '0'; 

    
-- -- --          EXCEPTION  DETETECTING  --  --  --  --  --  --  --  --  -- 
  
   ---------------------DECODE STAGE----------------------------------------

   -- Note: the pc_basevalue, generated by a dedicated logic block in the main
   -- core, is the RETURN address that has to be saved on EPC in case the instruction
   -- currently being decoded were interrupted.
   -- It is generated outside this logic block by the pcbvgen block
   d_pcbasevalue <= pc_basevalue;
    
  --------------------EXECUTE STAGE--------------------------------------

    
   -- Registers used to keep trace of the Current PC value to be saved on EPC
   -- in case of interruption

	d_glob		<=	d_bds&d_pcbasevalue;
	e_bds		<=	e_glob(Iaddr_width);
	e_pcbasevalue	<=	e_glob(Iaddr_width-1 downto 0);
   
   exe_basevalue_reg :
     Data_reg generic map (reg_width => Iaddr_width+1 ,init_value=>16#01000#)
              port map (clk,reset,en_exe,d_glob,e_glob);
    
-- -- -- -- -- -- -- -- -- WRITING ON SPECIAL REGISTERS  --  --  --  --  --
-- 
-- NOTE: All Special Registers can be rewritten except the CAUSE Register,
-- whose last 8 bits are used as a path to produce the address for the
-- interrupt table read cycle and have to be updated quickly and in a
-- software-indipendent way.
-- Actually, STATUS EPS and EPC can be written by a MTC0 only unless an
-- Exception is signalled durning the same cycle:
-- In this case processor control would be overtaken by the Exception service
-- and the scheduled MTC0 would only take place when the normal program flow
-- is repristinated.



--	0. STATUS_DBG

   process(reset, status_register, cop_in, cop_command, d_we,rcop_addr)
   begin
   	if (reset = '0') then
		status_register_new(15 downto 1)	<= (others => '0');
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00000") and (d_we = '0')) then
		status_register_new(15 downto 1)	<= cop_in(15 downto 1);
	else
		status_register_new(15 downto 1)	<= status_register(15 downto 1);
	end if;
   end process;

		status_register_new(0)			<=	bp_detect_dbg;
   

--	1. MEM_DOWNLOAD_START
      
   dmem_init <= conv_std_logic_vector(data_mem_init_value_upper,16) & conv_std_logic_vector(data_mem_init_value_lower,16);   
   process(reset, mem_download_start, cop_in, cop_command, d_we, dmem_init,rcop_addr)
   begin
   	if (reset = '0') then
		mem_download_start_new	<= dmem_init(Daddr_width-1 downto 0);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00001") and (d_we = '0')) then
		mem_download_start_new	<= cop_in(Daddr_width-1 downto 0);
	else
		mem_download_start_new	<= mem_download_start;
	end if;
   end process;
   

--	2. MEM_DOWNLOAD_END 

   dmem_end <= conv_std_logic_vector(data_mem_end_value_upper,16) & conv_std_logic_vector(data_mem_end_value_lower,16);
   process(reset, mem_download_end, cop_in, cop_command, d_we,dmem_end,rcop_addr)
   begin
   	if (reset = '0') then
		mem_download_end_new	<= dmem_end(Daddr_width-1 downto 0);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00010") and (d_we = '0')) then
		mem_download_end_new	<= cop_in(Daddr_width-1 downto 0);
	else
		mem_download_end_new	<= mem_download_end;
	end if;
   end process;
   

--	4. BREAKPOINT 0

   process(reboot, reset, bp0, cop_in, cop_command, d_we, rcop_addr)
   begin
   	if ((reboot = '0') or (reset = '0')) then
		bp0_new		<= conv_std_logic_vector(instr_mem_init_value_lower+16,Iaddr_width);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00100") and (d_we = '0')) then
		bp0_new		<= cop_in(Iaddr_width-1 downto 0);
	else
		bp0_new		<= bp0;
	end if;
   end process;
   
--	5. BREAKPOINT 1

   process(reboot, reset, bp1, cop_in, cop_command, d_we,rcop_addr)
   begin
   	if ((reboot = '0') or (reset = '0')) then
		bp1_new		<= conv_std_logic_vector(instr_mem_init_value_lower+16,Iaddr_width);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00101") and (d_we = '0')) then
		bp1_new		<= cop_in(Iaddr_width-1 downto 0);
	else
		bp1_new		<= bp1;
	end if;
   end process;
   
--	6. BREAKPOINT 2

   process(reboot, reset, bp2, cop_in, cop_command, d_we,rcop_addr)
   begin
   	if ((reboot = '0') or (reset = '0')) then
		bp2_new		<= conv_std_logic_vector(instr_mem_init_value_lower+16,Iaddr_width);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00110") and (d_we = '0')) then
		bp2_new		<= cop_in(Iaddr_width-1 downto 0);
	else
		bp2_new		<= bp2;
	end if;
   end process;
   
--	7. BREAKPOINT 3

   process(reboot, reset, bp3, cop_in, cop_command, d_we,rcop_addr)
   begin
   	if ((reboot = '0') or (reset = '0')) then
		bp3_new		<= conv_std_logic_vector(instr_mem_init_value_lower+16,Iaddr_width);
	elsif ((cop_command.op = xi_system_wcop) and (cop_command.index = "10") and (rcop_addr = "00111") and (d_we = '0')) then
		bp3_new		<= cop_in(Iaddr_width-1 downto 0);
	else
		bp3_new		<= bp3;
	end if;
   end process;
   
	bp_detect_internal	<= '1'	when	(
						((e_pcbasevalue = bp0) or 
				     		(e_pcbasevalue = bp1) or
				     		(e_pcbasevalue = bp2) or
				     		(e_pcbasevalue = bp3))
						and ((d_glob /= e_glob) and (e_bds = '1'))
						)
			 		else 	'0';
	bp_detect_step		<= '1'	when	((status_register(14) = '1') and (e_pcbasevalue = epc))
					else	'0';
	bp_detect_internal_filt	<= '1'	when	(bp_detect_internal = '1') and ((status_register(14) = '0') and (e_pcbasevalue /= epc))
					else	'0';
	bp_detect_int		<= '1'	when	(
						(pres_status = new_to_serve) and
						((bp_detect_internal = '1') or
						(ext_bp_request = '0') or
						((bp_detect_step_c = '1') and (e_bds = '1'))
						))
					else	'0';
	

   process(reset, bp_detect_int, dbg_enable, pres_status, status_register, bp_detect_internal, kernel_mode,
   	   ext_bp_request, ext_service, epc, e_pcbasevalue)
   begin
   	case pres_status is
	when new_to_serve	=>
				if ((reset = '0') or (dbg_enable = '1')) then
					next_status	<=	new_to_serve;
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'1';
				  	ext_service_new	<=	'0';
				elsif ((bp_detect_int = '1') and (kernel_mode = '1')) then
					next_status	<=	serving;
					bp_detect_dbg	<=	'1';
					end_dbg_int	<=	'0';
				  if ((ext_bp_request = '0') and (bp_detect_internal = '0'))then
				  	ext_service_new	<=	'1';
				  else
				  	ext_service_new	<=	'0';
				  end if;
				else
					next_status	<=	new_to_serve;
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'1';
				  	ext_service_new	<=	'0';
				end if;
	when serving	=>
				if ((reset = '0') or (dbg_enable = '1')) then
					next_status	<=	new_to_serve;
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'1';
				  	ext_service_new	<=	'0';
				elsif ((status_register(15) = '1')) then
					next_status	<=	wait_for_ext_bp_request_drop;
					bp_detect_dbg	<=	'1';
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
				else
					next_status	<=	serving;
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
					bp_detect_dbg	<=	'1';
				end if;
	when wait_for_ext_bp_request_drop	=>
				if ((reset = '0') or (dbg_enable = '1')) then
					next_status	<=	new_to_serve;
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'1';
				  	ext_service_new	<=	'0';
				elsif ((bp_detect_int = '0') and (ext_bp_request = '1'))then
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
					next_status	<=	status_reg_drop;
				else
					bp_detect_dbg	<=	'1';
					next_status	<=	wait_for_ext_bp_request_drop;
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
				end if;
	when status_reg_drop	=>
					bp_detect_dbg	<=	'0';
				if ((reset = '0') or (dbg_enable = '1')) then
					next_status	<=	new_to_serve;
					end_dbg_int	<=	'1';
				  	ext_service_new	<=	'0';
				elsif (status_register(15) = '0') then
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
				  if (ext_service = '1') then
					next_status	<=	new_to_serve;
				  else
					next_status	<=	already_served;
				  end if;
				else
					next_status	<=	status_reg_drop;
					end_dbg_int	<=	'0';
				  	ext_service_new	<=	ext_service;
				end if;
	when already_served	=>
					bp_detect_dbg	<=	'0';
				  	ext_service_new	<=	'0';
				if ((reset = '0') or (dbg_enable = '1')) then
					next_status	<=	new_to_serve;
					end_dbg_int	<=	'1';
				elsif ((bp_detect_internal = '1') or
                                       ((epc = e_pcbasevalue) and (status_register(14) = '1'))) and
                                       (kernel_mode = '1')then
					next_status	<=	new_to_serve;
					end_dbg_int	<=	'1';
				else
					next_status	<=	already_served;
					end_dbg_int	<=	'0';
				end if;
	when others		=>
					next_status	<=	new_to_serve;
					bp_detect_dbg	<=	'0';
					end_dbg_int	<=	'1';
					ext_service_new	<=	'0';
	end case;
   end process;

   	end_dbg		<=	end_dbg_int;
	bp_detect	<=	bp_detect_dbg;

   process(clk, reset)
   begin
   	if (reset = '0') then
		pres_status	<=	new_to_serve;
		end_dbg_c	<=	'1';
		bp_detect_step_c<=	'0';
		ext_service	<=	'0';
	elsif ((clk'event) and (clk = '1')) then
		pres_status	<=	next_status;
		end_dbg_c	<=	end_dbg_int;
		ext_service	<=	ext_service_new;
		bp_detect_step_c<=	bp_detect_step;
	end if;
   end process;

   -- READ REGISTER

   process(reset, cop_command, rcop_addr, status_register, mem_download_start, mem_download_end,
   	   bp0, bp1, bp2, bp3)
   begin
   	if (reset = '0') then
			cop_out_int	<= (others => '0');
	elsif (cop_command.op = xi_system_rcop) then
	   case rcop_addr is
	   	when "00000"	=>
			cop_out_int<= EXT(status_register,Word_width);			
	   	when "00001"	=>
                        cop_out_int <= EXT(mem_download_start,Word_width);                    
	   	when "00010"	=>
                        cop_out_int <= EXT(mem_download_end,Word_width); 
	   	when "00100"	=>
			cop_out_int  <= EXT(bp0,Word_width);
	   	when "00101"	=>
			cop_out_int  <= EXT(bp1,Word_width);
	   	when "00110"	=>
			cop_out_int  <= EXT(bp2,Word_width);
	   	when "00111"	=>
			cop_out_int  <= EXT(bp3,Word_width);
		when others	=>
			cop_out_int	<= (others => '0');
	   end case;
	else
			cop_out_int	<= (others => '0');
	end if;
   end process;



   -- -- -- -- -- -- -- REGISTERS --  --  --  --  --  --  --
   
 
 		 init_status_reg		<= conv_std_logic_vector(0,Iaddr_width);
    STATUS_REG_1 : Data_reg
                 generic map ( init_value => 0,
                               reg_width => Iaddr_width)
                 port map (clk,reset,reg_enable,status_register_new,status_register);

    DOWNLOAD_START_REG : Data_reg
                 generic map ( init_value => 0,
                               reg_width => Daddr_width )  
                 port map (clk,reset,reg_enable,mem_download_start_new,mem_download_start);

    DOWNLOAD_END_REG : Data_reg
                 generic map ( init_value => 0,
                               reg_width => Daddr_width )  
                 port map (clk,reset,reg_enable,mem_download_end_new,mem_download_end);

    BP0_REG : Data_reg
                 generic map ( init_value => instr_mem_init_value_lower+16,
                               reg_width => Iaddr_width )
                 port map (clk,reset,reg_enable,bp0_new,bp0);

    BP1_REG : Data_reg
                 generic map ( init_value => instr_mem_init_value_lower+16,
                               reg_width => Iaddr_width )
                 port map (clk,reset,reg_enable,bp1_new,bp1);

    BP2_REG : Data_reg
                 generic map ( init_value => instr_mem_init_value_lower+16,
                               reg_width => Iaddr_width )
                 port map (clk,reset,reg_enable,bp2_new,bp2);

    BP3_REG : Data_reg
                 generic map ( init_value => instr_mem_init_value_lower+16,
                               reg_width => Iaddr_width )
                 port map (clk,reset,reg_enable,bp3_new,bp3);

    COP_OUT_REG : Data_reg
                 generic map ( init_value => 0,
                               reg_width => Word_width )
                 port map (clk,reset,en_exe,cop_out_int,cop_out);

	dbg_real_op	<=	status_register(15);

end structural;  

----------------------------------------------------------------------------
--   COMPONENT DEFINITION
----------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use work.menu.all;
  use work.basic.all;

package dbg_pack is
  
  component Dbg
    generic ( rf_registers_addr_width : positive := 5;
              Word_Width      : positive := 32;
              Iaddr_width     : positive := 24 );
    
    port(   clk,reset,reboot,freeze     : in  Std_logic;
    	    kernel_mode			: in  Std_logic;
            en_exe,d_we                 : in  Std_logic;
	    d_bds			: in  Std_logic;
	    epc				: in  Std_logic_vector(Iaddr_width-1 downto 0);
            cop_command                 : in  Cop_control;            
            cop_in                      : in  Std_logic_vector(Word_width-1 downto 0); 
            cop_out                     : out Std_logic_vector(Word_width-1 downto 0);
            rcop_addr                   : in  Std_logic_vector(4 downto 0);
                        
            pc_basevalue                : in  Std_logic_vector(Iaddr_width-1 downto 0);
	    dbg_enable			: in  Std_logic;
	    ext_bp_request		: in  Std_logic;
	    end_dbg			: out Std_logic;
	    dbg_real_op			: out Std_logic;
	    bp_detect			: out Std_logic
	    );
  end component;
    
end dbg_pack;

package body dbg_pack is
end dbg_pack;
