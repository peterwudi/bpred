`include "header.v"


module btb(
	input wire					wren,
	input wire	`btb_addr	r_addr,
	input wire	`btb_word	r_data,
	input wire	`btb_addr	w_addr,
	input wire	`btb_word	w_data
);

	(* ramstyle = "M9K"	*)
	reg `btb_word ram `btb;

	always @( * ) begin
		if(wren == 1) begin
			ram[w_addr] = w_data;
		end
		read_data = ram[r_addr];
	end

	initial begin
		r_data = 0;
	end
endmodule       

