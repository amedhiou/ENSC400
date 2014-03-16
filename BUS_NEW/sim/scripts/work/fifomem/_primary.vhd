library verilog;
use verilog.vl_types.all;
entity fifomem is
    generic(
        DATASIZE        : integer := 8;
        ADDRSIZE        : integer := 4
    );
    port(
        rdata           : out    vl_logic_vector;
        wdata           : in     vl_logic_vector;
        waddr           : in     vl_logic_vector;
        raddr           : in     vl_logic_vector;
        wclken          : in     vl_logic;
        wfull           : in     vl_logic;
        wclk            : in     vl_logic
    );
end fifomem;
