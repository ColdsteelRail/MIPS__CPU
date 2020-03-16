`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 09:36:02 PM
// Design Name: 
// Module Name: sl2
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


module sl2 #(WIDTH=32)(
    input [WIDTH-1:0] a,
    output [WIDTH-1:0] y
    );

    // shift left by 2
    assign y = { a[WIDTH-3:0], 2'b00 };

endmodule
