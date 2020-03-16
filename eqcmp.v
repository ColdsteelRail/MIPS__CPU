`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 02:59:17 PM
// Design Name: 
// Module Name: eqcmp
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


module eqcmp(
	input wire [31:0] a,b,
	input wire [5:0] op,
	input wire [4:0] rt,
	output wire y
    );

	assign y = (op == `beq && a == b) ? 1 :      // beq signal
	           (op == `bne && ~(a == b)) ? 1 :   // bne signal
	           (op == `bgtz && (a[31] == 0 && a != 32'b0)) ? 1 :
	           (op == `blez && (a[31] == 1 || a == 32'b0)) ? 1 :
	           (op == `regimm_inst) ? ( (rt == `bltz && a[31] == 1) ? 1 :
	                                    (rt == `bltzal && a[31] == 1) ? 1 :
	                                    (rt == `bgez && a[31] == 0) ? 1 :
	                                    (rt == `bgezal && a[31] == 0) ? 1 :0 ) :
	           0;
endmodule
