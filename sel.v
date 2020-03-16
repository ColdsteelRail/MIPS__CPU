`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2019 10:10:17 AM
// Design Name: 
// Module Name: sel
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


module sel(
    input wire [31:0] pc,
    input wire [`aluop] alucontrolM,
    input wire [31:0] addr,
    input wire [31:0] wa,
    input wire [31:0] ra,
    output reg [31:0] wb,
    output reg [31:0] rb,
    output reg [3:0]  sel,
    output reg adelM,adesM,
    output [31:0] bad_addr
    );
    
    
    always @(*)
    begin
        adesM <= 1'b0;
        adelM <= 1'b0;
        wb <= wa;
        rb <= ra;
        sel <= 4'b0000;
        case(alucontrolM)
        // ============================== save option ==============================>>
            `sig_sw: begin
                if (addr[1:0] == 2'b00) begin
                    sel <= 4'b1111;
                end else begin
                    adesM <= 1'b1;
                    sel <= 4'b0000;
                end
            end
            `sig_sh: begin
                wb <= { wa[15:0], wa[15:0] };
                case (addr[1:0])
                    2'b10: sel <= 4'b1100;
                    2'b00: sel <= 4'b0011;
                    default: begin
                        adesM <= 1'b1;
                        sel <= 4'b0000;
                    end
                endcase
            end
            `sig_sb: begin
                wb <= { wa[7:0], wa[7:0], wa[7:0], wa[7:0] };
                case (addr[1:0])
                    2'b11:sel <= 4'b1000;
					2'b10:sel <= 4'b0100;
					2'b01:sel <= 4'b0010;
					2'b00:sel <= 4'b0001;
                endcase
            end
        // ============================== save option ==============================>>
            `sig_lw: begin
                if (addr[1:0] != 2'b00) begin
                    adelM <= 1'b1;
                end else begin
                    rb <= ra;
                end
            end
            `sig_lh:
                case(addr[1:0])
                    2'b10: rb <= { {16{ra[31]}}, ra[31:16] };
                    2'b00: rb <= { {16{ra[15]}}, ra[15:0 ] };
                    default: adelM <= 1'b1;
                endcase
            `sig_lhu:
                case(addr[1:0])
                    2'b10: rb <= { {16{1'b0}}, ra[31:16] };
                    2'b00: rb <= { {16{1'b0}}, ra[15:0 ] };
                    default: adelM <= 1'b1;
                endcase
             `sig_lb:
                case(addr[1:0])
                    2'b11: rb <= {{24{ra[31]}}, ra[31:24]};
                    2'b10: rb <= {{24{ra[23]}}, ra[23:16]};
                    2'b01: rb <= {{24{ra[15]}}, ra[15:8] };
                    2'b00: rb <= {{24{ra[7] }}, ra[7 :0] };
                endcase
             `sig_lbu:
                case(addr[1:0])
                    2'b11: rb <= {{24{1'b0}}, ra[31:24]};
                    2'b10: rb <= {{24{1'b0}}, ra[23:16]};
                    2'b01: rb <= {{24{1'b0}}, ra[15:8] };
                    2'b00: rb <= {{24{1'b0}}, ra[7 :0] };
                endcase
        endcase
    end
    
    
    
//    assign sel = (alucontrolM == `sig_sw)? 4'b1111:
//                 (alucontrolM == `sig_sh)? ((addr[1:0] == 2'b00)? 4'b0011:
//                                            (addr[1:0] == 2'b10)? 4'b1100:
//                                            4'b0000):
//                 (alucontrolM == `sig_sb)? ((addr[1:0] == 2'b00)? 4'b0001:
//                                            (addr[1:0] == 2'b01)? 4'b0010:
//                                            (addr[1:0] == 2'b10)? 4'b0100:
//                                            (addr[1:0] == 2'b11)? 4'b1000:
//                                            4'b0000):
//                 4'b0000;
    
//    assign wb = (alucontrolM == `sig_sw)? wa:
//                    (alucontrolM == `sig_sb)?
//                                    ((addr[1:0] == 2'b11)? {wa[7:0],{24{wa[0]}}}:
//                                     (addr[1:0] == 2'b10)? {{8{1'b0}},wa[7:0],{16{1'b0}}}:
//                                     (addr[1:0] == 2'b01)? {{16{1'b0}},wa[7:0],{8{1'b0}} }:
//                                     (addr[1:0] == 2'b00)? {{24{1'b0}},wa[7:0] }: wa): 
//                    (alucontrolM == `sig_sh)?
//                                    (//(addr[1:0] == 2'b01 | addr[1:0] == 2'b10)?Ž¥·¢ŽíÎó
//                                     (addr[1:0] == 2'b10)? {wa[15:0], {16{1'b0}}}:
//                                     (addr[1:0] == 2'b00)? {{16{1'b0}}, wa[15:0] }: wa):
//                    wa;

//    assign rb = (alucontrolM == `sig_lw)? ra:
//                    (alucontrolM == `sig_lb)?
//                                    ((addr[1:0] == 2'b11)? {{24{ra[31]}}, ra[31:24]}:
//                                     (addr[1:0] == 2'b10)? {{24{ra[23]}}, ra[23:16]}:
//                                     (addr[1:0] == 2'b01)? {{24{ra[15]}}, ra[15:8] }:
//                                     (addr[1:0] == 2'b00)? {{24{ra[7] }}, ra[7:0] }: ra):               
//                    (alucontrolM == `sig_lbu)?
//                                    ((addr[1:0] == 2'b11)? {{24{1'b0}}, ra[31:24]}:
//                                     (addr[1:0] == 2'b10)? {{24{1'b0}}, ra[23:16]}:
//                                     (addr[1:0] == 2'b01)? {{24{1'b0}}, ra[15:8] }:
//                                     (addr[1:0] == 2'b00)? {{24{1'b0}}, ra[7:0] }: ra):                     
//                    (alucontrolM == `sig_lh)?
//                                    (//(addr[1:0] == 2'b01 | addr[1:0] == 2'b10)?Ž¥·¢ŽíÎó
//                                     (addr[1:0] == 2'b10)? {{16{ra[31]}}, ra[31:16]}:
//                                     (addr[1:0] == 2'b00)? { {16{ra[15]}}, ra[15:0] }: ra):
//                    (alucontrolM == `sig_lhu)?
//                                    (//(addr[1:0] == 2'b01 | addr[1:0] == 2'b10)?Ž¥·¢ŽíÎó
//                                     (addr[1:0] == 2'b10)? {{16 {1'b0}}, ra[31:16]}:
//                                     (addr[1:0] == 2'b00)? {{16 {1'b0}}, ra[15:0] }: ra):
//                    ra;
                    
//    assign adelM = (alucontrolM == `sig_lw)?
//                                    ( (addr[1:0] == 2'b00)? 1'b0 :1'b1 ):
//                   (alucontrolM == `sig_lh || alucontrolM == `sig_lhu)?
//                                    ( (addr[0] == 1'b0)? 1'b0 :1'b1 ): 1'b0;
//    assign adesM = (alucontrolM == `sig_sw)?
//                                    ( (addr[1:0] == 2'b00)? 1'b0 :1'b1 ):
//                   (alucontrolM == `sig_sh)?
//                                    ( (addr[0] == 1'b0)? 1'b0 :1'b1 ): 1'b0;
                                    
    assign bad_addr = (adelM == 1'b1 || adesM == 1'b1) ? addr : pc; //previous: pc - 8
endmodule
