
`include "soin_header.v"

module soin_bimodal_predictor(

	input								soin_bpredictor_stall,

	input	[31:0]						fetch_bpredictor_inst,
	input	[31:0]						fetch_bpredictor_PC,

	output	[31:0]						bpredictor_fetch_p_target,
	output								bpredictor_fetch_p_dir,
	output	[11:0]						bpredictor_fetch_bimodal,

	input								execute_bpredictor_update,
	input	[31:0]						execute_bpredictor_PC4,
	input	[31:0]						execute_bpredictor_target,
	input								execute_bpredictor_dir,
	input								execute_bpredictor_miss,
	input	[11:0]						execute_bpredictor_bimodal,
	
	input	[31:0]						soin_bpredictor_debug_sel,
	output	reg [31:0]					bpredictor_soin_debug,

	input								clk,
	input								reset
);

`define BIMODAL_INDEX(PC)				PC[10:2]

parameter BIMODAL_SIZE					= 512;

/*
fetch_bpredictor_PC is to be used before clock edge
fetch_bpredictor_inst is to be used after clock edge
*/

reg										branch_is;
reg										target_computable;
reg		[31:0]							computed_target;
reg		[31:0]							PC4;
reg		[31:0]							PC4_r;
reg		[3:0]							PCH4;

wire	[5:0]							inst_opcode;
wire	[5:0]							inst_opcode_x_h;
wire	[31:0]							OPERAND_IMM16S;
wire	[31:0]							OPERAND_IMM26;

reg		[63:0]							lookup_count;
reg		[63:0]							update_count;
reg		[63:0]							miss_count;
reg		[63:0]							hit_count;

wire	[8:0]							lu_bimodal_index;
reg		[8:0]							lu_bimodal_index_r;
wire	[1:0]							lu_bimodal_data;

wire	[8:0]							up_bimodal_index;
reg		[1:0]							up_bimodal_data;
wire									up_wen;

reg		[8:0]							reset_index;

soin_KMem #(.WIDTH(2), .DEPTH_L(9)) bimodal_mem
(
	.clock								(clk),

	.rdaddress							(lu_bimodal_index),
	.q									(lu_bimodal_data),
	.rden								(1'b1),

	.wraddress							(up_bimodal_index),
	.data								(up_bimodal_data),
	.wren								(up_wen)
);

//=====================================
// Predecoding
//=====================================

assign inst_opcode						= fetch_bpredictor_inst[`BITS_F_OP];
assign inst_opcode_x_h					= fetch_bpredictor_inst[`BITS_F_OPXH];
assign OPERAND_IMM16S					= {{16{fetch_bpredictor_inst[`BITS_F_IMM16_SIGN]}}, fetch_bpredictor_inst[`BITS_F_IMM16]};
assign OPERAND_IMM26					= {PCH4, fetch_bpredictor_inst[`BITS_F_IMM26], 2'b00};

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
		default: begin target_computable= 1; end
	endcase
end

always@( * )
begin
	case (inst_opcode)
		6'h00: begin computed_target	= OPERAND_IMM26; end
		6'h01: begin computed_target	= OPERAND_IMM26; end
		//SPEED
//		default: begin computed_target	= {PC4_r[31:2] + OPERAND_IMM16S[31:2] + 30'h1, 2'b00}; end
		default: begin computed_target	= PC4_r + OPERAND_IMM16S; end
	endcase
end

//=====================================
// Bimodal
//=====================================

wire [31:0] execute_bpredictor_PC		= execute_bpredictor_PC4 - 4;

assign lu_bimodal_index					= `BIMODAL_INDEX(PC4);
//SPEED
//assign up_bimodal_index					= reset ? reset_index : execute_bpredictor_bimodal[9+2-1:2];
assign up_bimodal_index					= reset ? reset_index : `BIMODAL_INDEX(execute_bpredictor_PC4);
assign up_wen							= reset | (~soin_bpredictor_stall & execute_bpredictor_update);

assign bpredictor_fetch_p_dir			= branch_is & target_computable ? lu_bimodal_data[1] : 1'b0;
assign bpredictor_fetch_p_target		= bpredictor_fetch_p_dir ? computed_target : PC4_r;
assign bpredictor_fetch_bimodal			= {lu_bimodal_index_r, lu_bimodal_data};

integer i;

always@(*)
begin
	if (reset)
		up_bimodal_data					= 2'b00;
	else
	begin
	case ({execute_bpredictor_dir, execute_bpredictor_bimodal[1:0]})
		3'b000: begin up_bimodal_data	= 2'b00; end
		3'b001: begin up_bimodal_data	= 2'b00; end
		3'b010: begin up_bimodal_data	= 2'b01; end
		3'b011: begin up_bimodal_data	= 2'b10; end
		3'b100: begin up_bimodal_data	= 2'b01; end
		3'b101: begin up_bimodal_data	= 2'b10; end
		3'b110: begin up_bimodal_data	= 2'b11; end
		3'b111: begin up_bimodal_data	= 2'b11; end
	endcase
	end
end

always@( * )
begin
	//SPEED
	PC4									= fetch_bpredictor_PC + 4;

	case (soin_bpredictor_debug_sel[1:0])
		2'b00: bpredictor_soin_debug	= lookup_count[31:0];
		2'b01: bpredictor_soin_debug	= update_count[31:0];
		2'b10: bpredictor_soin_debug	= miss_count[31:0];
		2'b11: bpredictor_soin_debug	= hit_count[31:0];
		default: bpredictor_soin_debug	= -1;
	endcase
end

always@(posedge clk)
begin
	if (reset)
	begin
		lookup_count					<= 0;
		update_count					<= 0;
		miss_count						<= 0;
		hit_count						<= 0;
		
		if (reset)
			reset_index					<= reset_index + 1;
	end
	else
	begin
		PCH4							<= fetch_bpredictor_PC[31:28];
		PC4_r							<= PC4;
		lu_bimodal_index_r				<= lu_bimodal_index;

		if (!soin_bpredictor_stall)
		begin
			lookup_count				<= lookup_count + 1;

			if (execute_bpredictor_update)
			begin
				update_count			<= update_count + 1;
				miss_count				<= miss_count + execute_bpredictor_miss;
				hit_count				<= hit_count + (execute_bpredictor_miss ? 0 : 1'b1);
			end
		end
	end
end

endmodule

