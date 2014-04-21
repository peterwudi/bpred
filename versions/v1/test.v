`timescale 1ns / 100ps 

module test; 
reg				clk;
//reg	[31:0]	pc;
reg	[31:0]	insn;
reg				wren;
reg	[31:0]	w_data;
reg	[31:0]	w_addr;
reg				taken;

wire	[31:0]	bTarget;




bpredTop DUT(
	.clk(clk),
	//.pc(pc),
	.insn(insn),
	.wren(wren),
	.w_data(w_data),
	.w_addr(w_addr),
	.taken(taken),
	
	.bTarget(bTarget)
);

//clock pulse with a 20 ns period 
always begin   
   #5  clk = ~clk; 
end


initial begin 
	$timeformat(-9, 1, " ns", 6); 
	clk = 1'b0;    // time = 0

	wren <= 0;
	w_data <= 0;
	w_addr <= 0;
	
	//pc <= 32'h0;
	// beq, I-type, IMM26 OP = dec 4936, PC <- PC + 4 + IMM16
	// IMM16 = dec 1234
	//insn <= 32'b00000000000000010011010010100110;
	
	// IMM16 = dec 0004
	insn <= 32'b100100110;
	taken <= 1'b1;
	
	#15
	//pc <= 32'd8;
	
	// call, J-type, IMM26 = dec 17284 PC <- IMM26 << 2, use btb
	// IMM16 = dec 4321
	//insn <= 32'b00000000000001000011100001000000;
	
	// jump IMM26 = dec 0004, calculated result = dec 0016, btb result = dec 0032
	insn <= 32'b10000000;

	#10
	// callr, R-type, use btb
	// IMM16 = dec 1234
	//pc <= 32'd234;
	//insn <= 32'h3EB43A;
	
	// btb result at 16 is 64, at 32 is 128
	insn <= 32'b 00001000001111101110100000111010;
/*	
	#10
	// bne, I-type, IMM16 = dec 4936, PC <- PC + 4 + IMM16
	//insn <= 32'b00000000000000010011010010011110;
	
	// IMM16 = 16
	insn <= 32'b10000011110;
	
	#10
	// bltu, I-type, IMM16 = dec 4936, PC <- PC + 4 + IMM16
	//pc <= 32'h0;
	insn <= 32'b00000000000000010011010010110110;
*/	
	#10
	taken <= 1'b0;
	insn <= 32'h0;
	
	
end



endmodule

