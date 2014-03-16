library verilog;
use verilog.vl_types.all;
entity sync_r2w is
    generic(
        ADDRSIZE        : integer := 4
    );
    port(
        wq2_rptr        : out    vl_logic_vector;
        rptr            : in     vl_logic_vector;
        wclk            : in     vl_logic;
        wrst_n          : in     vl_logic
    );
end sync_r2w;
