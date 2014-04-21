
`include "soin_header.v"

module soin_bimodal_predictor(

	input								soin_bpredictor_stall,

	input	[31:0]						fetch_bpredictor_inst,
	input	[31:0]						fetch_bpredictor_PC,
	input	[31:0]						fetch_redirect_PC,
	input								fetch_redirect,

	output	[31:0]						bpredictor_fetch_p_target,
	output								bpredictor_fetch_p_dir,
	output	[`BP_META_WIDTH-1:0]		bpredictor_fetch_meta,

	input								execute_bpredictor_update,
	input	[31:0]						execute_bpredictor_PC,
	input	[31:0]						execute_bpredictor_target,
	input								execute_bpredictor_dir,
	input								execute_bpredictor_miss,
	input	[`BP_META_WIDTH-1:0]		execute_bpredictor_meta,
	input								execute_bpredictor_recover_ras,
	
	input	[31:0]						soin_bpredictor_debug_sel,
	output	[31:0]						bpredictor_soin_debug,

	input								clk,
	input								reset
);

`define LU_INDEX(x)						x[12+2-1:2]

/*
fetch_bpredictor_PC is to be used before clock edge
fetch_bpredictor_inst is to be used after clock edge
*/

reg										branch_is;
reg										branch_cond;
reg										target_computable;
reg		[31:0]							computed_target;
wire									branch_ok;

reg		[31:0]							PC;
reg		[31:0]							PC4;
reg		[3:0]							PCH4;
reg		[7:0]							GHR;

wire	[31:0]							OPERAND_IMM16S;
wire	[31:0]							OPERAND_IMM26;
wire	[31:0]							TARGET_IMM16S;
wire	[31:0]							TARGET_IMM26;

wire	[7:0]							lu_index;
reg		[7:0]							lu_index_r;
wire	[31:0]							lu_data;

wire	[7:0]							up_index;
wire	[31:0]							up_data;
wire									up_wen;
wire	[3:0]							up_be;

wire	[1:0]							lu_bimodal_data;
reg										lu_bimodal_data_h;
wire	[7:0]							lu_bimodal_datas;
reg		[1:0]							up_bimodal_data;
reg		[7:0]							lu_bimodal_bun;

wire									p_taken;
reg		[31:0]							p_target;

wire	[3:0]							ras_index;
wire	[31:0]							ras_top_addr;

wire									is_branch;
wire									is_cond;
wire									is_ind;
wire									is_call;
wire									is_ret;
wire									is_16;
wire									is_26;

wire	[1:0]							is_p_mux;
wire									is_p_uncond;
wire									is_p_ret;
wire									is_p_call;
	
//=====================================
// Assignments
//=====================================

assign bpredictor_soin_debug			= 0;

assign bpredictor_fetch_p_dir			= p_taken;
assign bpredictor_fetch_p_target		= p_target;
assign bpredictor_fetch_meta			= {ras_index, lu_bimodal_datas, lu_index_r};

//=====================================
// Instantiations
//=====================================

//soin_KMem_be #(.WIDTH(32), .DEPTH_L(8)) bimodal_mem
BRAM_32_8 bimodal_mem
(
	.clock								(clk),

	.rdaddress							(lu_index),
	.q									(lu_data),

	.byteena_a							(up_be),
	.wraddress							(up_index),
	.data								(up_data),
	.wren								(up_wen)
);

soin_bpredictor_decode d_inst(
	.inst								(fetch_bpredictor_inst),

	.is_branch							(is_branch),
	.is_cond							(is_cond),
	.is_ind								(is_ind),
	.is_call							(is_call),
	.is_ret								(is_ret),
	.is_16								(is_16),
	.is_26								(is_26),

	.is_p_mux							(is_p_mux),
	.is_p_uncond						(is_p_uncond),
	.is_p_ret							(is_p_ret),
	.is_p_call							(is_p_call)
);

soin_bpredictor_ras ras_inst(
	.clk								(clk),

	.f_PC4								(PC4),
	.f_call								(is_p_call),
	.f_ret								(is_p_ret),

	.e_recover							(execute_bpredictor_recover_ras),
	.e_recover_index					(execute_bpredictor_meta[8+8+4+4-1:8+8+4]),

	.ras_index							(ras_index),
	.top_addr							(ras_top_addr)
);

//=====================================
// Direction
//=====================================

assign lu_index							= GHR;

assign up_index							= execute_bpredictor_meta[7:0];
assign up_data							= {4{execute_bpredictor_meta[8+8-1:8]}};
assign up_be							= execute_bpredictor_meta[8+8+4-1:8+8];
assign up_wen							= execute_bpredictor_update;

assign p_taken							= is_p_uncond | lu_bimodal_data_h;

wire	[15:0]							lu_data_h;
reg										lu_bimodal_data_h0;
reg										lu_bimodal_data_h1;
reg										lu_bimodal_data_h2;
reg										lu_bimodal_data_h3;

assign lu_data_h						= {lu_data[31-0], lu_data[31-2], lu_data[31-4], lu_data[31-6], lu_data[31-8], lu_data[31-10], lu_data[31-12], lu_data[31-14], lu_data[31-16], lu_data[31-18], lu_data[31-20], lu_data[31-22], lu_data[31-24], lu_data[31-26], lu_data[31-28], lu_data[31-30]};

//assign lu_bimodal_data					= (lu_data) >> ({PC[5:2], 1'b0});
assign lu_bimodal_datas					= (lu_data) >> ({PC[5:4], 3'b000});


always@(*)
begin
	PC4									= PC + 4;
	lu_bimodal_data_h					= lu_data_h[PC[5:2]];

end

//=====================================
// Target
//=====================================

assign OPERAND_IMM16S					= {{16{fetch_bpredictor_inst[`BITS_F_IMM16_SIGN]}}, fetch_bpredictor_inst[`BITS_F_IMM16]};
assign OPERAND_IMM26					= {PCH4, fetch_bpredictor_inst[`BITS_F_IMM26], 2'b00};
assign TARGET_IMM16S					= {PC4[31:2] + OPERAND_IMM16S[31:2], 2'b00};
//assign TARGET_IMM16S					= {PC[31:2] + OPERAND_IMM16S[31:2] + 30'b1, 2'b00};
assign TARGET_IMM26						= OPERAND_IMM26;

//`define MUX_ADD

`ifdef MUX_ADD

reg		[31:0]							p_target_0;
reg		[31:0]							p_target_1;

always@(*)
begin
	p_target							= p_target_0 + p_target_1;

	case (is_p_mux & {2{is_p_uncond | p_taken}})
		2'b00:
		begin
			p_target_0					= PC4;
			p_target_1					= 0;
		end
		2'b01:
		begin
			p_target_0					= ras_top_addr;
			p_target_1					= 0;
		end
		2'b10:
		begin
			p_target_0					= PC4;
			p_target_1					= OPERAND_IMM16S;
		end
		2'b11:
		begin
			p_target_0					= OPERAND_IMM26;
			p_target_1					= 0;
		end
	endcase
end


`else

always@(*)
begin
	casex ({fetch_redirect, is_p_mux & {2{is_p_uncond | p_taken}}})
		3'b1xx:
		begin
			p_target					= fetch_redirect_PC;
		end
		3'b000:
		begin
			p_target					= PC4;
		end
		3'b001:
		begin
			p_target					= ras_top_addr;
		end
		3'b010:
		begin
			p_target					= TARGET_IMM16S;
		end
		3'b011:
		begin
			p_target					= TARGET_IMM26;
		end
	endcase
/*
	case (is_p_mux & {2{is_p_uncond | p_taken}})
		2'b00:
		begin
			p_target					= PC4;
		end
		2'b01:
		begin
			p_target					= ras_top_addr;
		end
		2'b10:
		begin
			p_target					= TARGET_IMM16S;
		end
		2'b11:
		begin
			p_target					= TARGET_IMM26;
		end
	endcase
*/
end

`endif

//=====================================
// Sequential Logic
//=====================================

always@(posedge clk)
begin
	if (reset)
	begin
		GHR								<= 0;
	end
	else
	begin
		PCH4							<= fetch_bpredictor_PC[31:28];
		PC								<= fetch_bpredictor_PC;
//		PC4								<= {fetch_bpredictor_PC[31:16], fetch_bpredictor_PC[15:0] + 16'h4};
		lu_index_r						<= lu_index;
		
		if (execute_bpredictor_update)
			GHR							<= {GHR[6:0], execute_bpredictor_dir};
	end
end


endmodule

























module soin_bpredictor_decode(
	input	[31:0]						inst,
	output	reg							is_branch,
	output	reg							is_cond,
	output	reg							is_ind,
	output	reg							is_call,
	output	reg							is_ret,
	output	reg							is_16,
	output	reg							is_26,
	
	output	reg	[1:0]					is_p_mux,
	output	reg							is_p_uncond,
	output	reg							is_p_ret,
	output	reg							is_p_call
	
);

wire	[5:0]							inst_opcode;
wire	[5:0]							inst_opcode_x_h;

assign inst_opcode						= inst[`BITS_F_OP];
assign inst_opcode_x_h					= inst[`BITS_F_OPXH];

always@( * )
begin
	case (inst_opcode)
		6'h26: begin is_branch			= 1; end
		6'h0e: begin is_branch			= 1; end
		6'h2e: begin is_branch			= 1; end
		6'h16: begin is_branch			= 1; end
		6'h36: begin is_branch			= 1; end
		6'h1e: begin is_branch			= 1; end
		6'h06: begin is_branch			= 1; end
		6'h00: begin is_branch			= 1; end
		6'h01: begin is_branch			= 1; end
		6'h3a:
		begin
			case(inst_opcode_x_h)
				6'h1d: begin is_branch	= 1; end
				6'h01: begin is_branch	= 1; end
				6'h0d: begin is_branch	= 1; end
				6'h05: begin is_branch	= 1; end
				default: begin is_branch= 0; end
			endcase
		end
		default: begin is_branch		= 0; end
	endcase
end

always@( * )
begin
	case (inst_opcode)
		6'h0e: begin is_cond			= 1; end
		6'h16: begin is_cond			= 1; end
		6'h1e: begin is_cond			= 1; end
		6'h26: begin is_cond			= 1; end
		6'h2e: begin is_cond			= 1; end
		6'h36: begin is_cond			= 1; end

		default: begin is_cond			= 0; end
	endcase
end

always@( * )
	is_ind								= inst_opcode == 6'h3A;

always@( * )
	is_call								= (inst_opcode == 6'h00) | ((inst_opcode == 6'h3A) & (inst_opcode_x_h == 6'h1D));

always@( * )
	is_ret								= (inst_opcode == 6'h3A) & (inst_opcode_x_h == 6'h05);

always@( * )
	is_26								= (inst_opcode == 6'h00) | (inst_opcode == 6'h01);

always@( * )
	is_16								= (inst_opcode != 6'h3A) & (~is_26);

always@( * )
	is_p_mux							= inst[31:30];

always@( * )
	is_p_uncond							= inst[29];

always@( * )
	is_p_ret							= is_ret;

always@( * )
	is_p_call							= inst[27];
endmodule




































module soin_bpredictor_ras(
	input								clk,

	input	[31:0]						f_PC4,
	input								f_call,
	input								f_ret,

	input								e_recover,
	input	[3:0]						e_recover_index,
	
	output	reg [3:0]					ras_index,
	output	[31:0]						top_addr
);

MLAB_32_4 ras(
	.clock								(clk),
	.address							(ras_index),
	.q									(top_addr),
	.data								(e_recover_index),
	.wren								(f_call)
);

//reg		[31:0]							ras					[15:0];

always@(posedge clk)
begin
	if (e_recover)
		ras_index						<= e_recover_index;
	else
	if (f_call)
	begin
//		ras[ras_index]					<= f_PC4;
		ras_index						<= ras_index + 4'h1;
	end
	else
	if (f_ret)
		ras_index						<= ras_index - 4'h1;
end

//assign top_addr							= ras[ras_index];

endmodule

