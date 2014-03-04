library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.std_logic_arith.all;

library WORK;
	use work.basic.all;
	
package xi_rom_package is
constant address_0 : std_logic_vector(11 downto 0) := "000000000000";
			-- 000
constant instruction_0 : std_logic_vector(31 downto 0) := "00000000000000000011100000110001";
			-- 00003831

constant address_1 : std_logic_vector(11 downto 0) := "000000000100";
			-- 004
constant instruction_1 : std_logic_vector(31 downto 0) := "00001000000000100000000000000010";
			-- 08020002

constant address_2 : std_logic_vector(11 downto 0) := "000000001000";
			-- 008
constant instruction_2 : std_logic_vector(31 downto 0) := "01100100000000100000000000000010";
			-- 64020002

constant address_3 : std_logic_vector(11 downto 0) := "000000001100";
			-- 00c
constant instruction_3 : std_logic_vector(31 downto 0) := "00000000000000000010100000110001";
			-- 00002831

constant address_4 : std_logic_vector(11 downto 0) := "000000010000";
			-- 010
constant instruction_4 : std_logic_vector(31 downto 0) := "00000000000000000011000000110001";
			-- 00003031

constant address_5 : std_logic_vector(11 downto 0) := "000000010100";
			-- 014
constant instruction_5 : std_logic_vector(31 downto 0) := "00001000000001000000000000000011";
			-- 08040003

constant address_6 : std_logic_vector(11 downto 0) := "000000011000";
			-- 018
constant instruction_6 : std_logic_vector(31 downto 0) := "01101100000000110000000000000010";
			-- 6c030002

constant address_7 : std_logic_vector(11 downto 0) := "000000011100";
			-- 01c
constant instruction_7 : std_logic_vector(31 downto 0) := "00001000000000100000001100000001";
			-- 08020301

constant address_8 : std_logic_vector(11 downto 0) := "000000100000";
			-- 020
constant instruction_8 : std_logic_vector(31 downto 0) := "10001000011000101111111111111101";
			-- 8862fffd

constant address_9 : std_logic_vector(11 downto 0) := "000000100100";
			-- 024
constant instruction_9 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_10 : std_logic_vector(11 downto 0) := "000000101000";
			-- 028
constant instruction_10 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_11 : std_logic_vector(11 downto 0) := "000000101100";
			-- 02c
constant instruction_11 : std_logic_vector(31 downto 0) := "01101100000000100000000000000000";
			-- 6c020000

constant address_12 : std_logic_vector(11 downto 0) := "000000110000";
			-- 030
constant instruction_12 : std_logic_vector(31 downto 0) := "00010100010000110000000011111111";
			-- 144300ff

constant address_13 : std_logic_vector(11 downto 0) := "000000110100";
			-- 034
constant instruction_13 : std_logic_vector(31 downto 0) := "01000000100000000001000011000000";
			-- 408010c0

constant address_14 : std_logic_vector(11 downto 0) := "000000111000";
			-- 038
constant instruction_14 : std_logic_vector(31 downto 0) := "01000100011000100001000000000000";
			-- 44621000

constant address_15 : std_logic_vector(11 downto 0) := "000000111100";
			-- 03c
constant instruction_15 : std_logic_vector(31 downto 0) := "00001000100001001111111111111111";
			-- 0884ffff

constant address_16 : std_logic_vector(11 downto 0) := "000001000000";
			-- 040
constant instruction_16 : std_logic_vector(31 downto 0) := "10000000100000111111111111110101";
			-- 8083fff5

constant address_17 : std_logic_vector(11 downto 0) := "000001000100";
			-- 044
constant instruction_17 : std_logic_vector(31 downto 0) := "00000000101000100010100000000001";
			-- 00a22801

constant address_18 : std_logic_vector(11 downto 0) := "000001001000";
			-- 048
constant instruction_18 : std_logic_vector(31 downto 0) := "01100100000000000000000000000010";
			-- 64000002

constant address_19 : std_logic_vector(11 downto 0) := "000001001100";
			-- 04c
constant instruction_19 : std_logic_vector(31 downto 0) := "00001000000000101111111111111111";
			-- 0802ffff

constant address_20 : std_logic_vector(11 downto 0) := "000001010000";
			-- 050
constant instruction_20 : std_logic_vector(31 downto 0) := "10000100101000100000000000010011";
			-- 84a20013

constant address_21 : std_logic_vector(11 downto 0) := "000001010100";
			-- 054
constant instruction_21 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_22 : std_logic_vector(11 downto 0) := "000001011000";
			-- 058
constant instruction_22 : std_logic_vector(31 downto 0) := "00001000000000100000000000000010";
			-- 08020002

constant address_23 : std_logic_vector(11 downto 0) := "000001011100";
			-- 05c
constant instruction_23 : std_logic_vector(31 downto 0) := "01100100000000100000000000000010";
			-- 64020002

constant address_24 : std_logic_vector(11 downto 0) := "000001100000";
			-- 060
constant instruction_24 : std_logic_vector(31 downto 0) := "00001000000001000000000000000011";
			-- 08040003

constant address_25 : std_logic_vector(11 downto 0) := "000001100100";
			-- 064
constant instruction_25 : std_logic_vector(31 downto 0) := "01101100000000110000000000000010";
			-- 6c030002

constant address_26 : std_logic_vector(11 downto 0) := "000001101000";
			-- 068
constant instruction_26 : std_logic_vector(31 downto 0) := "00001000000000100000001100000001";
			-- 08020301

constant address_27 : std_logic_vector(11 downto 0) := "000001101100";
			-- 06c
constant instruction_27 : std_logic_vector(31 downto 0) := "10001000011000101111111111111101";
			-- 8862fffd

constant address_28 : std_logic_vector(11 downto 0) := "000001110000";
			-- 070
constant instruction_28 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_29 : std_logic_vector(11 downto 0) := "000001110100";
			-- 074
constant instruction_29 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_30 : std_logic_vector(11 downto 0) := "000001111000";
			-- 078
constant instruction_30 : std_logic_vector(31 downto 0) := "01101100000000100000000000000000";
			-- 6c020000

constant address_31 : std_logic_vector(11 downto 0) := "000001111100";
			-- 07c
constant instruction_31 : std_logic_vector(31 downto 0) := "00010100010000110000000011111111";
			-- 144300ff

constant address_32 : std_logic_vector(11 downto 0) := "000010000000";
			-- 080
constant instruction_32 : std_logic_vector(31 downto 0) := "01000000100000000001000011000000";
			-- 408010c0

constant address_33 : std_logic_vector(11 downto 0) := "000010000100";
			-- 084
constant instruction_33 : std_logic_vector(31 downto 0) := "01000100011000100001000000000000";
			-- 44621000

constant address_34 : std_logic_vector(11 downto 0) := "000010001000";
			-- 088
constant instruction_34 : std_logic_vector(31 downto 0) := "00001000100001001111111111111111";
			-- 0884ffff

constant address_35 : std_logic_vector(11 downto 0) := "000010001100";
			-- 08c
constant instruction_35 : std_logic_vector(31 downto 0) := "10000000100000111111111111110101";
			-- 8083fff5

constant address_36 : std_logic_vector(11 downto 0) := "000010010000";
			-- 090
constant instruction_36 : std_logic_vector(31 downto 0) := "00000000110000100011000000000001";
			-- 00c23001

constant address_37 : std_logic_vector(11 downto 0) := "000010010100";
			-- 094
constant instruction_37 : std_logic_vector(31 downto 0) := "01100100000000000000000000000010";
			-- 64000002

constant address_38 : std_logic_vector(11 downto 0) := "000010011000";
			-- 098
constant instruction_38 : std_logic_vector(31 downto 0) := "10100000000000000000000000101001";
			-- a0000029

constant address_39 : std_logic_vector(11 downto 0) := "000010011100";
			-- 09c
constant instruction_39 : std_logic_vector(31 downto 0) := "01101000101001100000000000000000";
			-- 68a60000

constant address_40 : std_logic_vector(11 downto 0) := "000010100000";
			-- 0a0
constant instruction_40 : std_logic_vector(31 downto 0) := "00001000000001110000000000000001";
			-- 08070001

constant address_41 : std_logic_vector(11 downto 0) := "000010100100";
			-- 0a4
constant instruction_41 : std_logic_vector(31 downto 0) := "10000100111000001111111111010111";
			-- 84e0ffd7

constant address_42 : std_logic_vector(11 downto 0) := "000010101000";
			-- 0a8
constant instruction_42 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_43 : std_logic_vector(11 downto 0) := "000010101100";
			-- 0ac
constant instruction_43 : std_logic_vector(31 downto 0) := "11100000000000100010000000000100";
			-- e0022004

constant address_44 : std_logic_vector(11 downto 0) := "000010110000";
			-- 0b0
constant instruction_44 : std_logic_vector(31 downto 0) := "00001000000000111100000000000000";
			-- 0803c000

constant address_45 : std_logic_vector(11 downto 0) := "000010110100";
			-- 0b4
constant instruction_45 : std_logic_vector(31 downto 0) := "00000000010000110001000000110001";
			-- 00431031

constant address_46 : std_logic_vector(11 downto 0) := "000010111000";
			-- 0b8
constant instruction_46 : std_logic_vector(31 downto 0) := "01000000010000000001010000000000";
			-- 40401400

constant address_47 : std_logic_vector(11 downto 0) := "000010111100";
			-- 0bc
constant instruction_47 : std_logic_vector(31 downto 0) := "01000000010000000001010000000010";
			-- 40401402

constant address_48 : std_logic_vector(11 downto 0) := "000011000000";
			-- 0c0
constant instruction_48 : std_logic_vector(31 downto 0) := "11100000000000100010000000000101";
			-- e0022005

constant address_49 : std_logic_vector(11 downto 0) := "000011000100";
			-- 0c4
constant instruction_49 : std_logic_vector(31 downto 0) := "00001000000000100000000100000000";
			-- 08020100

constant address_50 : std_logic_vector(11 downto 0) := "000011001000";
			-- 0c8
constant instruction_50 : std_logic_vector(31 downto 0) := "10101000010000000000000000000000";
			-- a8400000

constant address_51 : std_logic_vector(11 downto 0) := "000011001100";
			-- 0cc
constant instruction_51 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_52 : std_logic_vector(11 downto 0) := "000011010000";
			-- 0d0
constant instruction_52 : std_logic_vector(31 downto 0) := "10101011111000000000000000000000";
			-- abe00000

constant address_53 : std_logic_vector(11 downto 0) := "000011010100";
			-- 0d4
constant instruction_53 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_54 : std_logic_vector(11 downto 0) := "000011011000";
			-- 0d8
constant instruction_54 : std_logic_vector(31 downto 0) := "10101011111000000000000000000000";
			-- abe00000

constant address_55 : std_logic_vector(11 downto 0) := "000011011100";
			-- 0dc
constant instruction_55 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_56 : std_logic_vector(11 downto 0) := "000011100000";
			-- 0e0
constant instruction_56 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_57 : std_logic_vector(11 downto 0) := "000011100100";
			-- 0e4
constant instruction_57 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_58 : std_logic_vector(11 downto 0) := "000011101000";
			-- 0e8
constant instruction_58 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

constant address_59 : std_logic_vector(11 downto 0) := "000011101100";
			-- 0ec
constant instruction_59 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
			-- 00000000

end xi_rom_package;
