`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 09:11:29 PM
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input wire [31:0] srcAE,
    input wire [31:0] srcBE,
    input wire [`aluop] op,
    input wire [4:0] sa,
    input wire [31:0] hi_inE, lo_inE,
    input wire [31:0] pcplus8E,
    output reg [31:0] aluoutM,
    output reg overflow,
	output reg [31:0] hi_alu_out,lo_alu_out
);

wire [31:0] mult_a, mult_b;
                 
//assign hi_alu_out = (op == `sig_mthi)? srcAE : hi_inE;
//assign lo_alu_out = (op == `sig_mtlo)? srcAE : lo_inE;

assign mult_a = ( (op == `sig_mult) && (srcAE[31] == 1'b1) ) ? (~srcAE + 1) : srcAE;
assign mult_b = ( (op == `sig_mult) && (srcBE[31] == 1'b1) ) ? (~srcBE + 1) : srcBE;

always @(*)
begin
    case(op)
        // arithmetic inst
        `sig_add, `sig_addu: aluoutM <= srcAE + srcBE;
        `sig_sub, `sig_subu: aluoutM <= srcAE - srcBE;
        `sig_slt: aluoutM <= $signed(srcAE) < $signed(srcBE)? 32'h00000001: 32'h00000000;
        `sig_sltu:aluoutM <= (srcAE < srcBE) ? 32'h00000001: 32'h00000000;
        `sig_div, `sig_divu: aluoutM <= 32'h00000000;
        // logic inst
        `sig_and: aluoutM <= srcAE & srcBE;
        `sig_or:  aluoutM <= srcAE | srcBE;
        `sig_oppo:aluoutM <= ~srcAE;
        `sig_xor: aluoutM <= srcAE^srcBE;
        `sig_nor: aluoutM <= ~(srcAE | srcBE);
        `sig_lui: aluoutM <= { srcBE[15:0], 16'b0 };
        // shift inst
        `sig_sll: aluoutM <= (srcBE << sa);
        `sig_srl: aluoutM <= (srcBE >> sa);
        `sig_sra: aluoutM <= ( ( {32{srcBE[31]}} << (6'd32-{1'b0,sa}) ) | srcBE >> sa );
        `sig_sllv:aluoutM <= (srcBE << srcAE[4:0]);
        `sig_srlv:aluoutM <= (srcBE >> srcAE[4:0]);
        `sig_srav:aluoutM <= ( ( {32{srcBE[31]}} << (6'd32-{1'b0,srcAE[4:0]}) ) | srcBE >> srcAE[4:0] );
        //data_move inst
        `sig_mfhi:aluoutM <= hi_inE[31:0];
        `sig_mflo:aluoutM <= lo_inE[31:0];
        //jump & branch
        `sig_jal, `sig_jalr, `sig_bal: aluoutM <= pcplus8E;
        `sig_lb, `sig_lbu, `sig_lh, `sig_lhu,
		`sig_lw, `sig_sb, `sig_sh, `sig_sw: aluoutM <= srcAE + srcBE;
		//exception
		`sig_mtc0:aluoutM <= srcBE;
		//hilo op
		`sig_multu: { hi_alu_out, lo_alu_out } = srcAE * srcBE;
		`sig_mult:  { hi_alu_out, lo_alu_out } = (srcAE[31] ^ srcBE[31] == 1'b1)? ~(mult_a * mult_b) + 1: mult_a * mult_b;
		`sig_mthi:  { hi_alu_out, lo_alu_out } = { srcAE, lo_inE};
		`sig_mtlo:  { hi_alu_out, lo_alu_out } = { hi_inE, srcAE };
        default:  aluoutM <= 32'b0;
    endcase
end

                 
always @(*)
begin
    case(op)
        `sig_add: overflow <= srcAE[31] & srcBE[31] & ~aluoutM[31] | ~srcAE[31] & ~srcBE[31] & aluoutM[31];
        `sig_addu:overflow <= 1'b0;
        `sig_sub: overflow <= ( (srcAE[31]&&!srcBE[31])&&!aluoutM[31] ) || ( (!srcAE[31]&&srcBE[31])&&aluoutM[31] );
        `sig_subu:overflow <= 1'b0;
        default:  overflow <= 1'b0;
    endcase
end
                
endmodule
