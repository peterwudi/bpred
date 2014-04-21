`timescale 1ns / 100ps 

module test; 
reg					clk;
reg					insnMem_wren = 1'b0;
reg	[31:0]		insnMem_data_w = 32'b0;
reg	[7:0]			insnMem_addr_w = 8'b11111111;
reg	[29:0]		up_btb_data = 30'b1111;
reg	[8:0]			up_carry_data = 9'b00100111;
reg	[3:0]			byte_en = 4'b0001;

wire	[8:0]			bit_carry;
reg					soin_bpredictor_stall = 1'b0;

wire					bpredictor_fetch_p_dir;
wire	[11:0]		bpredictor_fetch_bimodal;

reg					execute_bpredictor_update = 1'b1;
reg	[31:0]		execute_bpredictor_PC4 = 32'd128;
reg	[31:0]		execute_bpredictor_target = 32'b0;
reg					execute_bpredictor_dir = 1'b1;
reg					execute_bpredictor_miss = 1'b0;
reg	[11:0]		execute_bpredictor_bimodal = 2'b11;
	
reg	[31:0]		soin_bpredictor_debug_sel = 2'b00;

reg					execute_missPred = 1'b0;
reg					execute_c_r_after_r = 1'b0;
reg					execute_isCall = 1'b0;


reg					reset = 1'b0;
	
wire	[31:0]		bpredictor_soin_debug;


bpredTop DUP(
	.clk(clk),
	.insnMem_wren(insnMem_wren),
	.insnMem_data_w(insnMem_data_w),
	.insnMem_addr_w(insnMem_addr_w),
	.up_btb_data(up_btb_data),
	.up_carry_data(up_carry_data),
	.byte_en(byte_en),

	.bit_carry(bit_carry),
	.soin_bpredictor_stall(soin_bpredictor_stall),

	.bpredictor_fetch_p_dir(bpredictor_fetch_p_dir),
	.bpredictor_fetch_bimodal(bpredictor_fetch_bimodal),

	.execute_bpredictor_update(execute_bpredictor_update),
	.execute_bpredictor_PC4(execute_bpredictor_PC4),
	.execute_bpredictor_target(execute_bpredictor_target),
	.execute_bpredictor_dir(execute_bpredictor_dir),
	.execute_bpredictor_miss(execute_bpredictor_miss),
	.execute_bpredictor_bimodal(execute_bpredictor_bimodal),
	
	.soin_bpredictor_debug_sel(soin_bpredictor_debug_sel),


	.execute_missPred(execute_missPred),
	.execute_c_r_after_r(execute_c_r_after_r),
	.execute_isCall(execute_isCall),
	.reset(reset),
	
	
	.bpredictor_soin_debug(bpredictor_soin_debug)
);


//clock pulse with a 20 ns period 
always begin   
   #5  clk = ~clk; 
end


initial begin 
	$timeformat(-9, 1, " ns", 6); 
	clk = 1'b0;    // time = 0

	
	#25
	byte_en <= 4'b1111;
	
	
	
	// pc <= 32'h0;
	// beq, I-type, PC <- PC + 4 + IMM16
	// IMM16 = dec 0016
	// btb[1] = 16
	//insn <= 32'b10000100110;
	
	//#15
	//pc <= 32'd16;
	
	// call, J-type, PC <- IMM26 << 2
	// call IMM26 = dec 8, calculated result = dec 32
	// btb[4] = 32
	//insn <= 32'b1000000000;

	//#10
	// callr, R-type, use btb
	// IMM16 = dec 1234
	// pc <= 32'd32;
	// insn <= 32'h3EB43A;
	
	// btb[8] = 48
	//insn <= 32'b 00001000001111101110100000111010;
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
	//#10
	//taken <= 1'b0;
	//insn <= 32'h0;
	
	
end



endmodule

