`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/16 17:18:10
// Design Name: 
// Module Name: exception
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


module exception(
	input wire rst,
	input wire[7:0] except,
	input wire adel,ades,
	input wire[31:0] cp0_status,cp0_cause,
	output reg[31:0] excepttype
    );

	always @(*) begin
		if(rst) begin
			/* code */
			excepttype <= 32'b0;
		end else begin 
			excepttype <= 32'b0;
			if(((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) &&
				 	(cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin
				/* code */
				excepttype <= 32'h00000001;
			end else if(except[7] == 1'b1 || adel) begin
				/* fetch code, load data error */
				excepttype <= 32'h00000004; // ADEL
			end else if(ades) begin
				/* save data memory */
				excepttype <= 32'h00000005; // ADES
			end else if(except[6] == 1'b1) begin
				/* system call */
				excepttype <= 32'h00000008; // SYS
			end else if(except[5] == 1'b1) begin
				/* break */
				excepttype <= 32'h00000009; // BP
			end else if(except[4] == 1'b1) begin
				/* privillage eret */
				excepttype <= 32'h0000000e; 
			end else if(except[3] == 1'b1) begin
				/* instruction invalid */
				excepttype <= 32'h0000000a; // RI
			end else if(except[2] == 1'b1) begin
				/* overflow */
				excepttype <= 32'h0000000c; // OV
		end
	end
	end
	
endmodule
