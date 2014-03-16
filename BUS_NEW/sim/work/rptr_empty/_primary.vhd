library verilog;
use verilog.vl_types.all;
entity rptr_empty is
    generic(
        ADDRSIZE        : integer := 4
    );
    port(
        rempty          : out    vl_logic;
        raddr           : out    vl_logic_vector;
        rptr            : out    vl_logic_vector;
        rq2_wptr        : in     vl_logic_vector;
        rinc            : in     vl_logic;
        rclk            : in     vl_logic;
        rrst_n          : in     vl_logic
    );
end rptr_empty;
