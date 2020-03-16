module i_cache #(parameter A_WIDTH = 32, parameter C_INDEX = 6)
(
    input [A_WIDTH-1:0] p_a,
    output [31:0] p_din,
    input p_strobe,
    output p_ready,
    output cache_miss,
    input clk,clrn,

    output [A_WIDTH:0] m_a,
    input [31:0] m_dout,
    output m_strobe,
    input m_ready
);
localparam T_WIDTH = A_WIDTH - C_INDEX - 2;

reg d_valid[0: (1<<C_INDEX)-1];
reg [T_WIDTH-1:0] d_tags[0: (1<<C_INDEX)-1];
reg [31:0] d_data[0:(1<<C_INDEX)-1];
wire [C_INDEX-1:0] index = p_a[C_INDEX+1:2];
wire [T_WIDTH-1:0] tag = p_a[A_WIDTH-1: C_INDEX+2];

//write to cache
integer i;
always@(posedge clk or negedge clrn)
    if(clrn == 0 ) begin
        for(i = 0; i < (1<<C_INDEX); i=i+1)
            d_valid[i]<=1'b0;
    end else if(c_write)
        d_valid[index] <= 1'b1;
        
always@(posedge clk)
    if(c_write) begin
        d_tags[index] <= tag;
        d_data[index] <= c_din;
    end

//read from cache
wire valid = d_valid[index];
wire [T_WIDTH-1:0] tagout = d_tags[index];
wire [31:0] c_dout = d_data[index];
//cache control
wire cache_hit = valid & (tagout == tag);//hit
assign cache_miss = ~cache_hit;
assign m_a = p_a;
assign m_strobe = p_strobe & cache_miss;//read on miss
assign p_ready = cache_hit | cache_miss & m_ready;
wire c_write = cache_miss & m_ready;
wire sel_out = cache_hit;
wire [31:0] c_din = m_dout;
assign p_din = sel_out ? c_dout : m_dout;

endmodule