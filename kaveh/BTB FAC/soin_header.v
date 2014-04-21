
//`define RESET_VECTOR					32'h00D0_0000
//`define RESET_VECTOR					32'h0000_0000
//`define IRQ_VECTOR						32'h0080_0020

`define RESET_VECTOR					(`MEM_OFFSET + `RESET_OFFSET)
`define IRQ_VECTOR						(`MEM_OFFSET + 32'h20)

`define									EMB_MULT
`define									TRACE_WIDTH			96
`define									TRACE_DEPTH			11'd1024

`define									RUNAHEAD_MAX_UNRESOLVED_BRANCHES	4

// -------------------------------------

`define BITS_F_INST						31:0
`define BITS_F_IMM26					31:6
`define BITS_F_A						31:27
`define BITS_F_B						26:22
`define BITS_F_C						21:17
`define BITS_F_IMM16					21:6
`define BITS_F_IMM16_SIGN 				21
`define BITS_F_OPX						16:6
`define BITS_F_OPXH						16:11
`define BITS_F_OPXL						10:6
`define BITS_F_OP5						5:1
`define BITS_F_OP						5:0

// -------------------------------------

`define FT_ADDSUB						3'b000
`define FT_LOGICAL						3'b001
`define FT_CMP							3'b010
`define FT_IN0							3'b011
`define FT_MUL							3'b100
`define FT_MULX							3'b101
`define FT_SHIFT_ROTATE					3'b110
`define FT_RDCTRL						3'b111

// -------------------------------------

`define BR_NONE							2'b00
`define BR_COND							2'b01
`define BR_UNCOND						2'b10

// -------------------------------------

`define	ctrl_status						0
`define	ctrl_estatus					1
`define	ctrl_bstatus					2
`define	ctrl_ienable					3
`define	ctrl_ipending					4
`define	ctrl_cpuid						5

// -------------------------------------

`define LOGICAL_AND						0
`define LOGICAL_OR						1
`define LOGICAL_NOR						2
`define LOGICAL_XOR						3

// -------------------------------------

`define CMP_EQ							0
`define CMP_NE							1
`define CMP_GE							2
`define CMP_LT							3

`define CMP_SIGNED						1
`define CMP_UNSIGNED					0

// -------------------------------------

`define TARGET_OPERAND_0_PLUS_PC4		0
`define TARGET_OPERAND_0				1

// -------------------------------------

`define BRANCH_COND						0
`define BRANCH_UNCOND					1

//`define BP_META_WIDTH					14 // for soin
`define BP_META_WIDTH					24 // for grselect

// -------------------------------------

`define IC_LINE_WIDTH					6
`define IC_WORD_WIDTH					3

`define DC_LINE_WIDTH					6
`define DC_WORD_WIDTH					3

// -------------------------------------

`define OPCODEX(inst_op, inst_op_x, opx)	((inst_op == 6'h3A) && (inst_op_x == opx))

// -------------------------------------
