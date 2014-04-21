module S2P(i, o, reset, clk);
parameter WIDTH=8;

input i, clk, reset;
output reg [WIDTH-1:0] o;

always@(posedge clk)
begin
	if (reset)
		o <= 0;
	else
		o <= {o[WIDTH-1:1], i};
end

endmodule

module P2S(i, o, reset, clk);
parameter WIDTH=8;

input clk, reset;
output o;
input [WIDTH-1:0] i;
reg [WIDTH-1:0] i_r;

assign o = ^i_r;

always@(posedge clk)
begin
	i_r <= i;
end

endmodule
