library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.std_logic_arith.all;

library WORK;
	use work.basic.all;
	use work.components.all;
	use work.xi_rom_package.all;
       
entity bootup_rom is
  generic (Instr_width : integer :=32);
  port( clk      : in  std_logic;
        reset    : in  std_logic;
        freeze   : in  std_logic;
        addr_in  : in  std_logic_vector(11 downto 0);
        data_out : out Std_logic_vector(Instr_width-1 downto 0) );
end bootup_rom;

architecture silly of bootup_rom is

  signal reg_addr_in : std_logic_vector(11 downto 0);
  signal not_freeze : std_logic;
  signal Hi,Lo    : std_logic;

begin  -- silly

  Hi <= '1';

  Lo <= '0';

  not_freeze <= not freeze;

  process(reg_addr_in)
  begin
    case reg_addr_in is
      when address_0  => data_out <= EXT(instruction_0,instr_width);
      when address_1  => data_out <= EXT(instruction_1,instr_width);
      when address_2  => data_out <= EXT(instruction_2,instr_width);
      when address_3  => data_out <= EXT(instruction_3,instr_width);
      when address_4  => data_out <= EXT(instruction_4,instr_width);
      when address_5  => data_out <= EXT(instruction_5,instr_width);
      when address_6  => data_out <= EXT(instruction_6,instr_width);
      when address_7  => data_out <= EXT(instruction_7,instr_width);
      when address_8  => data_out <= EXT(instruction_8,instr_width);
      when address_9  => data_out <= EXT(instruction_9,instr_width);
      when address_10  => data_out <= EXT(instruction_10,instr_width);
      when address_11  => data_out <= EXT(instruction_11,instr_width);
      when address_12  => data_out <= EXT(instruction_12,instr_width);
      when address_13  => data_out <= EXT(instruction_13,instr_width);
      when address_14  => data_out <= EXT(instruction_14,instr_width);
      when address_15  => data_out <= EXT(instruction_15,instr_width);
      when address_16  => data_out <= EXT(instruction_16,instr_width);
      when address_17  => data_out <= EXT(instruction_17,instr_width);
      when address_18  => data_out <= EXT(instruction_18,instr_width);
      when address_19  => data_out <= EXT(instruction_19,instr_width);
      when address_20  => data_out <= EXT(instruction_20,instr_width);
      when address_21  => data_out <= EXT(instruction_21,instr_width);
      when address_22  => data_out <= EXT(instruction_22,instr_width);
      when address_23  => data_out <= EXT(instruction_23,instr_width);
      when address_24  => data_out <= EXT(instruction_24,instr_width);
      when address_25  => data_out <= EXT(instruction_25,instr_width);
      when address_26  => data_out <= EXT(instruction_26,instr_width);
      when address_27  => data_out <= EXT(instruction_27,instr_width);
      when address_28  => data_out <= EXT(instruction_28,instr_width);
      when address_29  => data_out <= EXT(instruction_29,instr_width);
      when address_30  => data_out <= EXT(instruction_30,instr_width);
      when address_31  => data_out <= EXT(instruction_31,instr_width);
      when address_32  => data_out <= EXT(instruction_32,instr_width);
      when address_33  => data_out <= EXT(instruction_33,instr_width);
      when address_34  => data_out <= EXT(instruction_34,instr_width);
      when address_35  => data_out <= EXT(instruction_35,instr_width);
      when address_36  => data_out <= EXT(instruction_36,instr_width);
      when address_37  => data_out <= EXT(instruction_37,instr_width);
      when address_38  => data_out <= EXT(instruction_38,instr_width);
      when address_39  => data_out <= EXT(instruction_39,instr_width);
      when address_40  => data_out <= EXT(instruction_40,instr_width);
      when address_41  => data_out <= EXT(instruction_41,instr_width);
      when address_42  => data_out <= EXT(instruction_42,instr_width);
      when address_43  => data_out <= EXT(instruction_43,instr_width);
      when address_44  => data_out <= EXT(instruction_44,instr_width);
      when address_45  => data_out <= EXT(instruction_45,instr_width);
      when address_46  => data_out <= EXT(instruction_46,instr_width);
      when address_47  => data_out <= EXT(instruction_47,instr_width);
      when address_48  => data_out <= EXT(instruction_48,instr_width);
      when address_49  => data_out <= EXT(instruction_49,instr_width);
      when address_50  => data_out <= EXT(instruction_50,instr_width);
      when address_51  => data_out <= EXT(instruction_51,instr_width);
      when address_52  => data_out <= EXT(instruction_52,instr_width);
      when address_53  => data_out <= EXT(instruction_53,instr_width);
      when address_54  => data_out <= EXT(instruction_54,instr_width);
      when address_55  => data_out <= EXT(instruction_55,instr_width);
      when address_56  => data_out <= EXT(instruction_56,instr_width);
      when address_57  => data_out <= EXT(instruction_57,instr_width);
      when address_58  => data_out <= EXT(instruction_58,instr_width);
      when address_59  => data_out <= EXT(instruction_59,instr_width);
      when others => data_out <= (others => '0');  -- Diplomatic no-op
    end case;
  end process;

  synch : Data_reg
    generic map ( reg_width => 12)
    port map ( clk, reset, not_freeze, addr_in, reg_addr_in);
end silly;
