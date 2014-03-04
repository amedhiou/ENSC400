----------------------------------------------------------------------------
--                     XI_ADDRCHECK.VHD                      --
--                                                                        --
----------------------------------------------------------------------------
-- Created 1999 by F.M.Campi , fcampi@deis.unibo.it          --
-- DEIS, Department of Electronics Informatics and Systems,  --
-- University of Bologna, BOLOGNA , ITALY                    --
----------------------------------------------------------------------------

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


-- This purely combinatorial logic block simply checks the addresses produced
-- by the processor for any access to instruction or data memory, detecting
-- eventual invalid configurations.
--

-- Three possible invalid memory access exceptions might be detected:

-- 1) ADDRESS OUT OF RANGE (Invalid address)
-- This exception is raised if the control logic detects a legal
-- address format which is not physycally mapped on any memory
-- location.
-- If the logical address space is completely mapped on the physical
-- support, this control can be avoided setting to 0
--

-- 2) MISALIGNED ACCESS
-- According to the specified width for a data memory access cycle,
-- the control logic verifies the alignment of the requested address:
-- the address is always valid for byte accesses, but must be a
-- multiple of 2 for halfwords and a multiple of 4 for words.
-- This would make no sense at all for accesses to the instruction
-- memory, as Dlx instruction have fixed 32-bit length and the PC is
-- increased by 4 any cycle.
-- Anyway, a jump immediate or jump register could force the PC to
-- a misaligned address value: this logic block must recognize this
-- occurrance and raise an exception.
--

-- 3) MEMORY PROTECTION VIOLATION
-- In case the specified address belongs to a protected memory
-- location, the addressed data is read anyway, and a warning is
-- issued:the exception handling logic of the processor will then
-- check whether
-- the access has been performed in kernel mode (access allowed) or
-- user mode (access prohibited) and eventually raise the exception.
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity Addrchk is

  generic ( w  : integer := 32;
            ckmn : integer := 1;        -- enable check on the lower limit
            ckmx : integer := 1;        -- enable check on the upper limit
            mxl : integer := 16#ffff#;  -- lower 16 bits of the upper limit of the space address
            mxh : integer := 16#0000#;  -- upper 16 bits of the upper limit of the space address
            mnl : integer := 16#0010#;  -- lower 16 bits of the lower limit of the space address
            mnh : integer := 16#0000# ); -- upper 16 bits of the lower limit of the space address

  port ( ADDRESS : in std_logic_vector(w-1 downto 0);

         invalid_addr : out std_logic;
         misalign     : out std_logic;
         prot_warn    : out std_logic;

         enable : in std_logic;
         isbyte : in std_logic;
         ishalf : in std_logic );

end Addrchk;


architecture behavioral of Addrchk is

begin

  -- MEMORY ADDRESS CONTROL:
  -- Checking the address that will be used for next memory access
  -- The address is checked, and exception signals are raised, only if
  -- ENABLE is active (->'0').

  process( address, enable, isbyte, ishalf )
  begin
    if enable = '0' then
      if isbyte = '0' then
        misalign     <= '1';
      else
        if ishalf = '0' then
          if address(0) = '0' then
            misalign <= '1';
          else
            misalign <= '0';
          end if;
        else
          if address(1 downto 0) = "00" then
            misalign <= '1';
          else
            misalign <= '0';
          end if;
        end if;
      end if;
    else
      misalign       <= '1';
    end if;

  end process;

  MEMPROTECTION_CHECK : if ( ckmn = 1 ) generate
    process( address, enable )
    begin
      if (w     <= 16) then
        if ( enable = '0' ) and
          ( address < Conv_std_logic_vector(mnl, w) ) then
          prot_warn <= '0';
        else
          prot_warn <= '1';
        end if;
      else
        if ( enable = '0' ) and
          ( address < Conv_std_logic_vector(mnh, w-16)&Conv_std_logic_vector(mnl, 16) ) then
          prot_warn <= '0';
        else
          prot_warn <= '1';
        end if;
      end if;
    end process;
  end generate;

  MEMPROTECTION_NOCHECK : if ( ckmn = 0) generate
    prot_warn <= '1';
  end generate;

  MEMSIZE_CHECK : if ( ckmx = 1) generate
    process( address, enable )
    begin
      if (w        <= 16) then
        if ( enable = '0' )
          and ( address > Conv_std_logic_vector(mxl, w) ) then
          invalid_addr <= '0';
        else
          invalid_addr <= '1';
        end if;
      else
        if ( enable = '0' )
          and ( address > Conv_std_logic_vector(mxh, w-16)&Conv_std_logic_vector(mxl, 16) ) then
          invalid_addr <= '0';
        else
          invalid_addr <= '1';
        end if;
      end if;
    end process;
  end generate;

  MEMSIZE_NOCHECK : if ( ckmx = 0) generate
    invalid_addr <= '1';
  end generate;

end behavioral;



