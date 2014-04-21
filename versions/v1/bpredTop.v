`include "header.v"

module bpredTop(
	input	wire					clk,
	//input wire	[31:0]		pc,
	input wire	[31:0]		insn,
	input wire					wren,
	input wire	`btb_word	w_data,
	input wire	`btb_addr	w_addr,
	input wire					taken,
	
	output reg	[31:0]		bTarget
);


reg	[31:0]						pc;
reg									branch_is;
reg									target_computable;
reg	[31:0]						computed_target;
reg	[31:0]						PC4;
reg	[31:0]						PC4_r;
reg	[3:0]							PCH4;

wire	[5:0]							inst_opcode;
wire	[5:0]							inst_opcode_x_h;
wire	[31:0]						OPERAND_IMM16S;
wire	[31:0]						OPERAND_IMM26;


wire	[8:0]							lu_bimodal_index;
reg	[8:0]							lu_bimodal_index_r;
wire	[1:0]							lu_bimodal_data;

wire	[8:0]							up_bimodal_index;
reg	[1:0]							up_bimodal_data;
wire									up_wen;

reg	[8:0]							reset_index;


reg	[31:0]						r_data;
wire	`btb_addr					r_addr;
//wire	`btb_tag						btb_tag;

reg									btb_hit;
wire	[31:0]						btb_result;


//=====================================
// Predecoding
//=====================================

assign inst_opcode						= insn[5:0];
assign inst_opcode_x_h					= insn[16:11];
assign OPERAND_IMM16S					= {{16{insn[21]}}, insn[21:6]};
assign OPERAND_IMM26						= {PCH4, insn[31:6], 2'b00};

assign btb_result							= {r_data[29:0], 2'b00};

// Shouldn't use the lowest 8 bits, set to this for the sake of testing only!!
assign r_addr								= pc[7:0];
//assign btb_tag								= pc[23:2];

// BTB
(* ramstyle = "M9K"	*)
reg `btb_word ram `btb;

initial begin
	pc <= 32'h0;
	ram[0] = 32'hdeadbeef;
	ram[4] = 32'd8;
	ram[8] = 32'd16;
	ram[16] = 32'd32;
	ram[128] = 32'hbeefdead;
	//ram[234] = 32'habcdefab;
end



always @(posedge clk) begin
	if(wren == 1) begin
		ram[w_addr] = w_data;
	end
	r_data = ram[r_addr];
/*
	if(r_data[`btb_word_width - 1 : `btb_word_width - 22] == btb_tag) begin
		btb_hit = 1;
	end
	else begin
		btb_hit = 0;
	end
*/
end

initial begin
	r_data = 0;
	computed_target = 0;
	PC4_r <= 0;
	PCH4 = 0;
	PC4 <= 0;
	pc <= 0;
end



always @ ( * )
begin
	PC4	=	pc + 4;
end


always@( * )
begin
	case (inst_opcode)
		6'h26: begin branch_is			= 1; end
		6'h0e: begin branch_is			= 1; end
		6'h2e: begin branch_is			= 1; end
		6'h16: begin branch_is			= 1; end
		6'h36: begin branch_is			= 1; end
		6'h1e: begin branch_is			= 1; end
		6'h06: begin branch_is			= 1; end
		6'h00: begin branch_is			= 1; end
		6'h01: begin branch_is			= 1; end
		6'h3a:
		begin
			case(inst_opcode_x_h)
				6'h1d: begin branch_is	= 1; end
				6'h01: begin branch_is	= 1; end
				6'h0d: begin branch_is	= 1; end
				6'h05: begin branch_is	= 1; end
				default: begin branch_is= 0; end
			endcase
		end
		default: begin branch_is		= 0; end
	endcase
end

always@( * )
begin
	case (inst_opcode)
		6'h00: begin target_computable	= 0; end
		6'h01: begin target_computable	= 0; end
		6'h3a: begin target_computable	= 0; end
		default: begin target_computable	= 1; end
	endcase
end

always@( * )
begin
	case (inst_opcode)
		//6'h00: begin computed_target	= OPERAND_IMM26; end
		//6'h01: begin computed_target	= OPERAND_IMM26; end
		//SPEED
//		default: begin computed_target	= {PC4_r[31:2] + OPERAND_IMM16S[31:2] + 30'h1, 2'b00}; end
		default: begin computed_target	= PC4_r + OPERAND_IMM16S; end
	endcase
end



always@(posedge clk)
begin
	PCH4		<= pc[31:28];
	PC4_r		<= PC4;
	
	case ({taken, target_computable})
		2'b00, 2'b01: begin
			pc <= PC4;
			bTarget <= 32'hffffffff;
			end
		2'b10: begin
			pc <= btb_result;
			bTarget <= btb_result;
			end
		2'b11: begin
			pc <= computed_target;
			bTarget <= computed_target;
			end
		default: begin
			pc <= 32'h0;
			bTarget <= 32'h0;
			end
	endcase
end


endmodule
