`include "header.v"

module bpredTop(
	input	wire					clk,
	input wire					insnMem_wren,
	input wire	[31:0]		insnMem_data_w,
	input wire	[7:0]			insnMem_addr_w,
	//input wire	[29:0]		up_btb_data,
	input wire	[43:0]			up_carry_data,
	input wire	[3:0]			byte_en,			// byte enable for mem

	output wire	[43:0]		bit_carry,		// bimodal word [43:8] and GHR
														// used to select between bimodals [7:0]
	
	input							soin_bpredictor_stall,

	//input	[31:0]				fetch_bpredictor_inst,
	//input	[31:0]				fetch_bpredictor_PC,

	//output	[31:0]			bpredictor_fetch_p_target,
	output						bpredictor_fetch_p_dir,
	output	[11:0]			bpredictor_fetch_bimodal,

	input							execute_bpredictor_update,
	input	[31:0]				execute_bpredictor_PC4,
	input	[31:0]				execute_bpredictor_target,
	input							execute_bpredictor_dir,
	input							execute_bpredictor_miss,
	input	[11:0]				execute_bpredictor_bimodal,
	
	input	[31:0]				soin_bpredictor_debug_sel,


	input							reset,
	
	
	output reg [31:0]		bpredictor_soin_debug
);

`define BIMODAL_INDEX(PC)				PC[9:2]

parameter BIMODAL_SIZE					= 256*18;

/*
fetch_bpredictor_PC is to be used before clock edge
fetch_bpredictor_inst is to be used after clock edge
*/

reg									branch_is;
reg									target_computable;
//reg	[31:0]						computed_target;
reg	[31:0]						computed_target16;
reg	[31:0]						computed_target26;
reg									isIMM16;	// 0 if compute imm16, 1 if imm26


reg	[31:0]						PC4;
reg	[31:0]						PC4_r;
reg	[3:0]							PCH4;

wire	[5:0]							inst_opcode;
wire	[5:0]							inst_opcode_x_h;
wire	[31:0]						OPERAND_IMM16S;
wire	[31:0]						OPERAND_IMM26;
reg	[35:0]						mem_data_w;

reg	[63:0]						lookup_count;
reg	[63:0]						update_count;
reg	[63:0]						miss_count;
reg	[63:0]						hit_count;


wire	[7:0]							lu_bimodal_index;
reg	[7:0]							lu_bimodal_index_r;
reg	[1:0]							lu_bimodal_data;

wire	[7:0]							up_bimodal_index;
reg	[1:0]							up_bimodal_data;
wire									up_wen;

reg	[31:0]						fetch_bpredictor_PC;
wire	[31:0]						fetch_bpredictor_inst;

reg	[8:0]							reset_index;

wire	[35:0]						mem_data_r;


//reg	[31:0]						r_data;
//wire	`btb_addr					r_addr;
//wire	`btb_tag						btb_tag;

//wire	[31:0]						btb_result;

reg	[7:0]							GHR;

//=====================================
// Predecoding
//=====================================

assign inst_opcode		= fetch_bpredictor_inst[5:0];
assign inst_opcode_x_h	= fetch_bpredictor_inst[16:11];
assign OPERAND_IMM16S	= {{16{fetch_bpredictor_inst[21]}}, fetch_bpredictor_inst[21:6]};
assign OPERAND_IMM26		= {PCH4, fetch_bpredictor_inst[31:6], 2'b00};

assign bit_carry			= {mem_data_r[35:0], PC4_r[6:2]};

//assign btb_result			= {mem_data_r[35:6], 2'b00};
assign lu_bimodal_index	= GHR;
//assign lu_bimodal_data	= mem_data_r[5:4];

// Selecting between bimodals to read from
always @(*) begin
	case (PC4_r[6:2])
		5'd0: begin
			lu_bimodal_data = mem_data_r[35:34];
		end
		5'd1: begin
			lu_bimodal_data = mem_data_r[33:32];
		end
		5'd2: begin
			lu_bimodal_data = mem_data_r[31:30];
		end
		5'd3: begin
			lu_bimodal_data = mem_data_r[29:28];
		end
		5'd4: begin
			lu_bimodal_data = mem_data_r[27:26];
		end
		5'd5: begin
			lu_bimodal_data = mem_data_r[25:24];
		end
		5'd6: begin
			lu_bimodal_data = mem_data_r[23:22];
		end
		5'd7: begin
			lu_bimodal_data = mem_data_r[21:20];
		end
		5'd8: begin
			lu_bimodal_data = mem_data_r[19:18];
		end
		5'd9: begin
			lu_bimodal_data = mem_data_r[17:16];
		end
		5'd10: begin
			lu_bimodal_data = mem_data_r[15:14];
		end
		5'd11: begin
			lu_bimodal_data = mem_data_r[13:12];
		end
		5'd12: begin
			lu_bimodal_data = mem_data_r[11:10];
		end
		5'd13: begin
			lu_bimodal_data = mem_data_r[9:8];
		end
		5'd14: begin
			lu_bimodal_data = mem_data_r[7:6];
		end
		5'd15: begin
			lu_bimodal_data = mem_data_r[5:4];
		end
		5'd16: begin
			lu_bimodal_data = mem_data_r[3:2];
		end
		5'd17: begin
			lu_bimodal_data = mem_data_r[1:0];
		end
		default: begin
			lu_bimodal_data = mem_data_r[35:34];
		end
	endcase
end


// Selecting between bimodals to write to
always @(*) begin
	case (execute_bpredictor_PC4[6:2])
		5'd0: begin
			mem_data_w = {up_bimodal_data[1:0], up_carry_data[38:5]};
		end
		5'd1: begin
			mem_data_w = {up_carry_data[40:39], up_bimodal_data[1:0], up_carry_data[36:5]};
		end
		5'd2: begin
			mem_data_w = {up_carry_data[40:37], up_bimodal_data[1:0], up_carry_data[34:5]};
		end
		5'd3: begin
			mem_data_w = {up_carry_data[40:35], up_bimodal_data[1:0], up_carry_data[32:5]};
		end
		5'd4: begin
			mem_data_w = {up_carry_data[40:33], up_bimodal_data[1:0], up_carry_data[30:5]};
		end
		5'd5: begin
			mem_data_w = {up_carry_data[40:31], up_bimodal_data[1:0], up_carry_data[28:5]};
		end
		5'd6: begin
			mem_data_w = {up_carry_data[40:29], up_bimodal_data[1:0], up_carry_data[26:5]};
		end
		5'd7: begin
			mem_data_w = {up_carry_data[40:27], up_bimodal_data[1:0], up_carry_data[24:5]};
		end
		5'd8: begin
			mem_data_w = {up_carry_data[40:25], up_bimodal_data[1:0], up_carry_data[22:5]};
		end
		5'd9: begin
			mem_data_w = {up_carry_data[40:23], up_bimodal_data[1:0], up_carry_data[20:5]};
		end
		5'd10: begin
			mem_data_w = {up_carry_data[40:21], up_bimodal_data[1:0], up_carry_data[18:5]};
		end
		5'd11: begin
			mem_data_w = {up_carry_data[40:19], up_bimodal_data[1:0], up_carry_data[16:5]};
		end
		5'd12: begin
			mem_data_w = {up_carry_data[40:17], up_bimodal_data[1:0], up_carry_data[14:5]};
		end
		5'd13: begin
			mem_data_w = {up_carry_data[40:15], up_bimodal_data[1:0], up_carry_data[12:5]};
		end
		5'd14: begin
			mem_data_w = {up_carry_data[40:13], up_bimodal_data[1:0], up_carry_data[10:5]};
		end
		5'd15: begin
			mem_data_w = {up_carry_data[40:11], up_bimodal_data[1:0], up_carry_data[8:5]};
		end
		5'd16: begin
			mem_data_w = {up_carry_data[40:9], up_bimodal_data[1:0], up_carry_data[6:5]};
		end
		5'd17: begin
			mem_data_w = {up_carry_data[40:7], up_bimodal_data[1:0]};
		end
		default: begin
			mem_data_w = {up_bimodal_data[1:0], up_carry_data[38:5]};
		end
	endcase
end


// Instruction Memory
insnMem insnMem(
	.clock(clk),
	.data(insnMem_data_w),
	.rdaddress(fetch_bpredictor_PC[9:2]),		// using PC[9:2]!
	.wraddress(insnMem_addr_w),
	.wren(insnMem_wren),
	.q(fetch_bpredictor_inst)
);


// Bimodals
mem mem (
	.byteena_a(byte_en),
	.clock(clk),
	.data(mem_data_w),
	.rdaddress(lu_bimodal_index),
	.wraddress(up_bimodal_index),
	.wren(up_wen),
	.q(mem_data_r)
);

initial begin
	fetch_bpredictor_PC <= 32'h0;
	computed_target16 = 0;
	computed_target26 = 0;
	PC4_r <= 0;
	PCH4 = 0;
	PC4 <= 0;
	GHR <= 7'd1;
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


// Only calculate PC+4+IMM16
always@( * )
begin
	case (inst_opcode)
		6'h00: begin target_computable	= 1;
			isIMM16 = 0;
		end
		6'h01: begin target_computable	= 1;
			isIMM16 = 0;
		end
		6'h3a: begin target_computable	= 0; end
		default: begin target_computable	= 1;
			isIMM16 = 1;
		end
	endcase
end


always@( * )
begin
	computed_target16	= PC4_r + OPERAND_IMM16S;
	computed_target26 = OPERAND_IMM26;

/*
	case (inst_opcode)
		//6'h00: begin computed_target	= OPERAND_IMM26; end
		//6'h01: begin computed_target	= OPERAND_IMM26; end
		//SPEED
//		default: begin computed_target	= {PC4_r[31:2] + OPERAND_IMM16S[31:2] + 30'h1, 2'b00}; end
		default: begin computed_target	= PC4_r + OPERAND_IMM16S; end
	endcase
*/
end


always@(*)
begin
	case ({bpredictor_fetch_p_dir, target_computable, isIMM16})
		
		3'b111: begin
			fetch_bpredictor_PC = computed_target16;
		end
		3'b110: begin
			fetch_bpredictor_PC = computed_target26;
		end
		default: begin
			// Not taken, or taken but target not computable
			fetch_bpredictor_PC = PC4_r;
		end
	endcase
end



//=====================================
// Bimodal
//=====================================

wire [31:0] execute_bpredictor_PC		= execute_bpredictor_PC4 - 4;


//SPEED
//assign up_bimodal_index					= reset ? reset_index : execute_bpredictor_bimodal[9+2-1:2];
assign up_bimodal_index					= reset ? reset_index : up_carry_data[7:0];
assign up_wen							= reset | (~soin_bpredictor_stall & execute_bpredictor_update);


assign bpredictor_fetch_p_dir			= branch_is & target_computable ? lu_bimodal_data[1] : 1'b0;
//assign bpredictor_fetch_p_dir			= branch_is & lu_bimodal_data[1];
//assign bpredictor_fetch_p_target		= bpredictor_fetch_p_dir ? computed_target : PC4_r;
assign bpredictor_fetch_bimodal			= {lu_bimodal_index_r, lu_bimodal_data};

integer i;

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
		
		GHR								<= 2'b0;
		
		if (reset)
			reset_index					<= reset_index + 1;
	end
	else
	begin
		PCH4							<= fetch_bpredictor_PC[31:28];
		PC4_r							<= PC4;
		lu_bimodal_index_r		<= lu_bimodal_index;
		GHR							<= {execute_bpredictor_dir, GHR[1]};

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
