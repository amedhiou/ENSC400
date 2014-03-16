library verilog;
use verilog.vl_types.all;
entity fifo1 is
    generic(
        DSIZE           : integer := 8;
        ASIZE           : integer := 4
    );
    port(
        rdata           : out    vl_logic_vector;
        wfull           : out    vl_logic;
        rempty          : out    vl_logic;
        wdata           : in     vl_logic_vector;
        winc            : in     vl_logic;
        wclk            : in     vl_logic;
        wrst_n          : in     vl_logic;
        rinc            : in     vl_logic;
        rclk            : in     vl_logic;
        rrst_n          : in     vl_logic
    );
end fifo1;
