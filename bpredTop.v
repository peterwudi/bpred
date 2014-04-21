`include "header.v"

module bpredTop(
	input	wire					clk,
	input wire					insnMem_wren,
	input wire	[31:0]		insnMem_data_w,
	input wire	[7:0]			insnMem_addr_w,
	input wire	[29:0]		up_btb_data,
	input wire	[8:0]			up_carry_data,
	input wire	[3:0]			byte_en,			// byte enable for mem

	output wire	[8:0]			bit_carry,		// lower 9 bits of the mem content that needs to get
														// propagated through the pipeline for mem update.
														// [8:6] is the last 3 bits of BTB content, the rest
														// is bimodal
	
	input							soin_bpredictor_stall,
	output						bpredictor_fetch_p_dir,
	output	[11:0]			bpredictor_fetch_bimodal,

	input							execute_bpredictor_update,
	input	[31:0]				execute_bpredictor_PC4,
	input	[31:0]				execute_bpredictor_target,
	input							execute_bpredictor_dir,
	input							execute_bpredictor_miss,
	input	[11:0]				execute_bpredictor_bimodal,
	
	input	[31:0]				soin_bpredictor_debug_sel,

	input							execute_missPred,
	input							execute_c_r_after_r,	// Call or Return after return
	input							execute_isCall,

	input							reset,
	
	
	output reg [31:0]		bpredictor_soin_debug
);

`define BIMODAL_INDEX(PC)				PC[9:2]

parameter BIMODAL_SIZE					= 256;


/*
fetch_bpredictor_PC is to be used before clock edge
fetch_bpredictor_inst is to be used after clock edge
*/


reg									branch_is;

reg	[31:0]						PC4;
reg	[31:0]						PC4_r;
reg	[3:0]							PCH4;

wire	[5:0]							inst_opcode;
wire	[5:0]							inst_opcode_x_h;
wire	[31:0]						OPERAND_IMM16S;
wire	[31:0]						OPERAND_IMM26;
wire	[35:0]						mem_data_w;

reg	[63:0]						lookup_count;
reg	[63:0]						update_count;
reg	[63:0]						miss_count;
reg	[63:0]						hit_count;


wire	[7:0]							lu_bimodal_index;
reg	[7:0]							lu_bimodal_index_r;
wire	[1:0]							lu_bimodal_data;

wire	[7:0]							up_bimodal_index;
reg	[1:0]							up_bimodal_data;
wire									up_wen;

reg	[31:0]						fetch_bpredictor_PC;
wire	[31:0]						fetch_bpredictor_inst;

reg	[8:0]							reset_index;

wire	[35:0]						mem_data_r;

wire	[31:0]						btb_result;

reg									isC_R;	// determines if it is a call or return
reg									isCall;	// determines if it is a call

(* ramstyle = "MLAB,no_rw_check" *) 
reg	[31:0]						ras [15:0];
reg	[3:0]							ras_top;
reg	[3:0]							ras_count;
reg									ras_dec;
reg									ras_inc;
reg									ras_exc_inc;
reg									ras_exc_dec;


//=====================================
// Predecoding
//=====================================

assign inst_opcode		= fetch_bpredictor_inst[5:0];
assign inst_opcode_x_h	= fetch_bpredictor_inst[16:11];
assign OPERAND_IMM16S	= {{16{fetch_bpredictor_inst[21]}}, fetch_bpredictor_inst[21:6]};
assign OPERAND_IMM26		= {PCH4, fetch_bpredictor_inst[31:6], 2'b00};

assign bit_carry			= mem_data_r[8:0];

assign btb_result			= {mem_data_r[35:6], 2'b00};
assign lu_bimodal_index	= `BIMODAL_INDEX(fetch_bpredictor_PC);
assign lu_bimodal_data	= mem_data_r[5:4];

// If only update bimodal, we don't care about the higher 27 bits as they'll be ignored.
// Otherwise update both BTB and bimodal.
assign mem_data_w			= (byte_en == 4'b0001) ?
			{27'b0, up_carry_data[8:6], up_bimodal_data[1:0], up_carry_data[3:0]} : {up_btb_data[29:0], up_bimodal_data[1:0], up_carry_data[3:0]};


// Instruction Memory
insnMem insnMem(
	.clock(clk),
	.data(insnMem_data_w),
	.rdaddress(fetch_bpredictor_PC[9:2]),		// using PC[9:2]!
	.wraddress(insnMem_addr_w),
	.wren(insnMem_wren),
	.q(fetch_bpredictor_inst)
);


// BTB
mem mem (
	.byteena_a(byte_en),
	.clock(clk),
	.data(mem_data_w),
	.rdaddress(lu_bimodal_index),
	.wraddress(up_bimodal_index),
	.wren(up_wen),
	.q(mem_data_r)
);

integer i;

initial begin
	fetch_bpredictor_PC <= 32'h0;

	PC4_r <= 0;
	PCH4 = 0;
	PC4 <= 0;
	branch_is = 0;
	
	isC_R <= 0;
	isCall <= 0;
	ras_top <= 0;
	ras_count <= 0;
	
	for (i = 0; i < 16; i = i + 1)
	begin
		ras[i] <= 32'b0;
	end
	
end


always@( * )
begin
	case (inst_opcode)
		6'h26, 6'h0e, 6'h2e, 6'h16, 6'h36,
		6'h1e, 6'h06, 6'h01: begin
				branch_is			= 1;
		end
		6'h00 : begin branch_is			= 1;
		end
		6'h3a:
		begin
			case(inst_opcode_x_h)
				6'h1d: begin branch_is	= 1;
				end
				6'h01: begin branch_is	= 1;
				end
				6'h0d: begin branch_is	= 1;
				end
				6'h05: begin branch_is	= 1;
				end
				default: begin branch_is= 0;
				end
			endcase
		end
		default: begin branch_is		= 0;
		end
	endcase
	isC_R		= (branch_is & (inst_opcode == 6'h00 || ((inst_opcode == 6'h3a) && (inst_opcode_x_h != 6'h0d)))) ? 1 : 0;
	isCall	= (branch_is & (inst_opcode == 6'h00 || ((inst_opcode == 6'h3a) && (inst_opcode_x_h == 6'h1d)))) ? 1 : 0;
end

always @( * )
begin
	if (isC_R) begin
		if (isCall) begin
			// Push PC+4 on RAS
			ras_inc		 <= 1;
			ras_dec		 <= 0;
		end
		else begin
			// Pop RAS
			ras_dec		 <= 1;
			ras_inc		 <= 0;
		end
	end
	else begin
		ras_inc		<= 0;
		ras_dec		<= 0;
	end

	case ({execute_missPred, execute_c_r_after_r, execute_isCall})
		3'b110: begin
			if (isC_R && isCall) begin
				ras_exc_inc <= 0;
				ras_exc_dec <= 1;
			end
			else begin
				ras_exc_inc <= 1;
				ras_exc_dec <= 0;
			end
		end
		3'b111: begin
			if (isC_R && isCall) begin
				ras_exc_inc <= 0;
				ras_exc_dec <= 1;
			end
			else begin
				ras_exc_inc <= 1;
				ras_exc_dec <= 0;
			end
		end
		default: begin
			ras_exc_inc <= 0;
			ras_exc_dec <= 0;
		end
	endcase
end


always@(*)
begin
	case ({bpredictor_fetch_p_dir, isC_R, isCall})
		3'b000, 3'b001, 3'b010, 3'b011: begin
			fetch_bpredictor_PC = PC4;
		end
		3'b100, 3'b101: begin
			fetch_bpredictor_PC = btb_result;
		end
		3'b110: begin
			fetch_bpredictor_PC = ras[ras_top+1];
		end
		default: begin
			fetch_bpredictor_PC = 32'h0;
		end
	endcase
end



//=====================================
// Bimodal
//=====================================

wire [31:0] execute_bpredictor_PC		= execute_bpredictor_PC4 - 4;


//SPEED
//assign up_bimodal_index					= reset ? reset_index : execute_bpredictor_bimodal[9+2-1:2];
assign up_bimodal_index					= reset ? reset_index : `BIMODAL_INDEX(execute_bpredictor_PC4);
assign up_wen							= reset | (~soin_bpredictor_stall & execute_bpredictor_update);


// NOTE: Don't use this pred target for now.
// For baseline BTB only, don't care if target is computable
//assign bpredictor_fetch_p_dir			= branch_is & target_computable ? lu_bimodal_data[1] : 1'b0;
assign bpredictor_fetch_p_dir			= branch_is & lu_bimodal_data[1];
//assign bpredictor_fetch_p_target		= bpredictor_fetch_p_dir ? computed_target : PC4_r;
assign bpredictor_fetch_bimodal			= {lu_bimodal_index_r, lu_bimodal_data};


// Update bimodal data
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
	PC4									= PC4_r + 4;

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
		PC4_r							<= fetch_bpredictor_PC;
		lu_bimodal_index_r		<= lu_bimodal_index;
	
		//RAS
		if (isC_R && isCall)
		begin
			ras[ras_top] <= PC4;
		end

		if (ras_exc_inc) begin
			ras_top <= ras_top + 1;
		end
		else if (ras_exc_dec) begin
			ras_top <= ras_top - 1;
		end
		else if (ras_inc) begin
			ras_top <= ras_top + 1;
		end
		else if (ras_dec) begin
			ras_top <= ras_top - 1;
		end
		
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
