library verilog;
use verilog.vl_types.all;
entity sync_w2r is
    generic(
        ADDRSIZE        : integer := 4
    );
    port(
        rq2_wptr        : out    vl_logic_vector;
        wptr            : in     vl_logic_vector;
        rclk            : in     vl_logic;
        rrst_n          : in     vl_logic
    );
end sync_w2r;
