library verilog;
use verilog.vl_types.all;
entity wptr_full is
    generic(
        ADDRSIZE        : integer := 4
    );
    port(
        wfull           : out    vl_logic;
        waddr           : out    vl_logic_vector;
        wptr            : out    vl_logic_vector;
        wq2_rptr        : in     vl_logic_vector;
        winc            : in     vl_logic;
        wclk            : in     vl_logic;
        wrst_n          : in     vl_logic
    );
end wptr_full;
