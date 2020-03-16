`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2019 04:48:21 PM
// Design Name: 
// Module Name: pc
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


module pc #(parameter WIDTH = 32)(
	input wire clk,rst,en,clr,
	input wire[WIDTH-1:0] d,
	input wire[WIDTH-1:0] t,
	output reg[WIDTH-1:0] q
    );
	always @(posedge clk,posedge rst) begin
		if(rst) begin
			q <= 32'hbfc00000;
		end else if(clr) begin
            q <= t;
        end else if(en) begin
            q <= d;
		end else begin
		    q <= q;
		end
	end
endmodule
