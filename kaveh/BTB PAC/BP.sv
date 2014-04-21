module DE3_DDR2(
		////////// CLOCK //////////
		OSC_BA,
		OSC_BB,
		OSC_BC,
		OSC_BD,
		OSC1_50,
		OSC2_50,
		CLK_OUT,
		EXT_CLK,

		////////// LED //////////
		LEDR,
		LEDG,
		LEDB,

		////////// BUTTON //////////
		Button,
		
		DIP_SW,
		SW,
		HEX0,
		HEX0_DP,
		HEX1,
		HEX1_DP,
/*
		////////// mem (J9, DDR2 SO-DIMM), connect to DDR2_SODIMM(DDR2_SODIMM Board) //////////
		mem_cke,
		mem_addr,
		mem_ba,
		mem_ras_n,
		mem_we_n,
		mem_cas_n,
		mem_cs_n,
		mem_odt,
		mem_clk,
		mem_clk_n,
		mem_dm,
		mem_dqsn,
		mem_dqs,
		mem_dq,
		mem_SDA,
		mem_SCL,
		mem_SA,
		
		oct_rdn,
		oct_rup,
*/
		////////// REGULATOR //////////
		JVC_CLK,
		JVC_CS,
		JVC_DATAOUT,
		JVC_DATAIN
);

input                     		OSC_BA;
input                     		OSC_BB;
input                     		OSC_BC;
input                     		OSC_BD;
input                     		OSC1_50;
input                     		OSC2_50;
output                    		CLK_OUT;
input                     		EXT_CLK;

////////// LED //////////
output    	[7:0]           	LEDR;
output    	[7:0]           	LEDG;
output    	[7:0]           	LEDB;

////////// BUTTON //////////
input     	[3:0]           	Button;
input			[3:0]					SW;
input			[7:0]					DIP_SW;

output		[6:0]					HEX0;
output								HEX0_DP;

output		[6:0]					HEX1;
output								HEX1_DP;
/*
////////// mem (J9, DDR2 SO-DIMM), connect to DDR2_SODIMM(DDR2_SODIMM Board) //////////
inout     	[63:0]          	mem_dq;
output    	[7:0]           	mem_dm;
inout     	[7:0]           	mem_dqsn;
inout     	[7:0]           	mem_dqs;
output     	[1:0]           	mem_clk;
output     	[1:0]           	mem_clk_n;
output    	[1:0]           	mem_cke;
output    	[15:0]          	mem_addr;
output    	[2:0]           	mem_ba;
output                    		mem_ras_n;
output                    		mem_we_n;
output    	[1:0]           	mem_cs_n;
output                    		mem_cas_n;
output    	[1:0]           	mem_odt;
inout                     		mem_SDA;
output                    		mem_SCL;
output    	[1:0]           	mem_SA;

input                   		oct_rdn;
input                   		oct_rup;
*/
////////// REGULATOR //////////
output                    		JVC_CLK;
output                    		JVC_CS;
output                    		JVC_DATAOUT;
input                     		JVC_DATAIN;


reg	[31:0]						out;


wire									clk;
wire									reset;
wire									system_reset_n;


wire	[31:0]							fetch_addr_next;
wire	[31:0]							fetch_bpredictor_inst;
wire	[31:0]							fetch_bpredictor_PC;
wire	[31:0]							fetch_redirect_PC;
wire									fetch_redirect;

wire	[31:0]							bpredictor_fetch_p_target;
wire									bpredictor_fetch_p_dir;
wire	[`BP_META_WIDTH-1:0]			bpredictor_fetch_meta;

wire									execute_bpredictor_update;
wire	[31:0]							execute_bpredictor_PC;
wire	[31:0]							execute_bpredictor_target;
wire									execute_bpredictor_dir;
wire									execute_bpredictor_miss;
wire	[31:0]							execute_bpredictor_meta;
//wire									execute_bpredictor_recover_ras;

wire	[31:0]							ic_data;
wire	[7:0]							ic_rdaddress;
wire	[7:0]							ic_wraddress;
wire									ic_wren;
wire	[31:0]							ic_q;

assign system_reset_n					= 1'b1;
assign clk								= OSC1_50;
assign reset							= Button[0];

S2P #(.WIDTH(32))	s2p_0(.clk(clk), .reset(reset), .i(DIP_SW[0]),	.o(ic_data));
S2P #(.WIDTH(8))	s2p_1(.clk(clk), .reset(reset), .i(DIP_SW[1]),	.o(ic_wraddress));
S2P #(.WIDTH(2))	s2p_2(.clk(clk), .reset(reset), .i(DIP_SW[2]),	.o(ic_wren));

S2P #(.WIDTH(2))	s2p_3(.clk(clk), .reset(reset), .i(DIP_SW[3]),	.o(execute_bpredictor_update));
S2P #(.WIDTH(32))	s2p_4(.clk(clk), .reset(reset), .i(DIP_SW[4]),	.o(execute_bpredictor_PC));
S2P #(.WIDTH(32))	s2p_5(.clk(clk), .reset(reset), .i(DIP_SW[5]),	.o(execute_bpredictor_target));
S2P #(.WIDTH(2))	s2p_6(.clk(clk), .reset(reset), .i(DIP_SW[6]),	.o(execute_bpredictor_dir));
S2P #(.WIDTH(2))	s2p_7(.clk(clk), .reset(reset), .i(DIP_SW[7]),	.o(execute_bpredictor_miss));
S2P #(.WIDTH(32))	s2p_8(.clk(clk), .reset(reset), .i(SW[0]),		.o(execute_bpredictor_meta));
//S2P #(.WIDTH(2))	s2p_9(.clk(clk), .reset(reset), .i(SW[1]),		.o(execute_bpredictor_recover_ras));

S2P #(.WIDTH(32))	s2p_10(.clk(clk), .reset(reset), .i(SW[2]),		.o(fetch_redirect_PC));
S2P #(.WIDTH(2))	s2p_11(.clk(clk), .reset(reset), .i(SW[3]),		.o(fetch_redirect));

P2S #(.WIDTH(32))	p2s_0(.clk(clk), .reset(reset), .i(bpredictor_fetch_p_target),	.o(LEDR[0]));
P2S #(.WIDTH(24))	p2s_1(.clk(clk), .reset(reset), .i(bpredictor_fetch_meta),		.o(LEDR[1]));
P2S #(.WIDTH(2))	p2s_2(.clk(clk), .reset(reset), .i(bpredictor_fetch_p_dir),		.o(LEDR[2]));

P2S #(.WIDTH(32))	p2s_3(.clk(clk), .reset(reset), .i(ic_q),						.o(LEDR[3]));

assign fetch_addr_next					= 0 ? fetch_redirect_PC : bpredictor_fetch_p_target;
assign fetch_bpredictor_inst			= ic_q;
assign fetch_bpredictor_PC				= fetch_addr_next;

assign ic_rdaddress						= fetch_addr_next[8+2-1:2];
//S2P #(.WIDTH(32))	s2p_9(.clk(clk), .reset(reset), .i(SW[1]),		.o(ic_rdaddress));

//soin_KMem #(.WIDTH(32), .DEPTH_L(10)) inst_cache(
BRAM_32_8 inst_cache(
	.clock								(clk),

	.rdaddress							(ic_rdaddress),
	.q									(ic_q),

	.wren								(ic_wren),
	.wraddress							(ic_wraddress),
	.data								(ic_data)
);

soin_bimodal_predictor bp(
	.soin_bpredictor_stall				(1'b0),

	.fetch_bpredictor_inst				(fetch_bpredictor_inst),
	.fetch_bpredictor_PC					(fetch_bpredictor_PC),

	.bpredictor_fetch_p_target			(bpredictor_fetch_p_target),
	.bpredictor_fetch_p_dir				(bpredictor_fetch_p_dir),
	.bpredictor_fetch_meta				(bpredictor_fetch_meta),

	.execute_bpredictor_update			(execute_bpredictor_update),
	.execute_bpredictor_PC				(execute_bpredictor_PC),
	.execute_bpredictor_target			(execute_bpredictor_target),
	.execute_bpredictor_dir				(execute_bpredictor_dir),
	.execute_bpredictor_miss			(execute_bpredictor_miss),
	.execute_bpredictor_meta			(execute_bpredictor_meta),
//	.execute_bpredictor_recover_ras		(execute_bpredictor_recover_ras),
	
	.clk								(clk),
	.reset								(reset)
);


/*IOV_A3V3_B1V8_C3V3_D3V3 IOV_Instance(
	.iCLK(OSC2_50),
	.iRST_n(system_reset_n),
	.iENABLE(1'b0),
	.oREADY(),
	.oERR(),
	.oERRCODE(),
	.oJVC_CLK(JVC_CLK),
	.oJVC_CS(JVC_CS),
	.oJVC_DATAOUT(JVC_DATAOUT),
	.iJVC_DATAIN(JVC_DATAIN)
);*/

endmodule

