`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2019 02:50:43 PM
// Design Name: 
// Module Name: hazard
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


module hazard(
	//fetch stage
	output stallF,
	output flushF,
	//decode stage
	input  [4:0] rsD,rtD,
	input  branchD,
	input  pcsrcD,
	input  jumpD, jalD, jrD,
	output [1:0] forwardaD,forwardbD,
	output stallD,
	output flushD,
	//execute stage
	input  [4:0] rsE,rtE,
	input  [4:0] writeregE,
	input  regwriteE,
	input  memtoregE,
	input  cp0toregE,
	input  div_stallE,
	output [1:0] forwardaE,forwardbE,
	output stallE,
	output flushE,
	//mem stage
	input  [4:0] writeregM,
	input  regwriteM,
	input  memtoregM,
	input  [31:0] excepttypeM,
	output stallM,
	output flushM,
	input  [31:0] cp0_epcM,
	output reg [31:0] newpcM,
	//write back stage
	input  [4:0] writeregW,
	input  regwriteW,
	output stallW,
	output flushW,
	
	input  inst_stall,
	input  data_stall
    );
    
//////////////////// resolve the add excute -- put data forward
//  if      ((rsE != 0) AND (rsE == WriteRegM) AND RegWriteM)     
//		then 	ForwardAE = 10
//	else if ((rsE != 0) AND (rsE == WriteRegW) AND RegWriteW) 
//		then 	ForwardAE = 01
//	else	    	ForwardAE = 00
    assign forwardaE = ( (rsE != 0) & (rsE == writeregM) & regwriteM )? 2'b10:
                        ( (rsE != 0) & (rsE == writeregW) & regwriteW )? 2'b01 : 2'b00;
    assign forwardbE = ( (rtE != 0) & (rtE == writeregM) & regwriteM )? 2'b10:
                        ( (rtE != 0) & (rtE == writeregW) & regwriteW )? 2'b01 : 2'b00;
    
//////////////////// resolve the branch excute
// forwarding logic
//  ForwardAD = (rsD !=0) AND (rsD == WriteRegM) AND RegWriteM
//	ForwardBD = (rtD !=0) AND (rtD == WriteRegM) AND RegWriteM
//    assign forwardaD = (rsD !=0) & (rsD == writeregM) & regwriteM;
//    assign forwardbD = (rtD !=0) & (rtD == writeregM) & regwriteM;
    assign forwardaD =  (rsD == 0)?2'b00:
                        ((rsD !=0) & (rsD == writeregE) & regwriteE)?2'b01:
                        ((rsD !=0) & (rsD == writeregM) & regwriteM)?2'b10:
                        ((rsD !=0) & (rsD == writeregW) & regwriteW)?2'b11:2'b00;
    assign forwardbD =  (rtD == 0)?2'b00:
                        ((rtD !=0) & (rtD == writeregE) & regwriteE)?2'b01:
                        ((rtD !=0) & (rtD == writeregM) & regwriteM)?2'b10:
                        ((rtD !=0) & (rtD == writeregW) & regwriteW)?2'b11:2'b00;
// Stalling logic:
//	branchstall = BranchD AND RegWriteE AND 
//                   (WriteRegE == rsD OR WriteRegE == rtD) 
//                 OR BranchD AND MemtoRegM AND 
//                   (WriteRegM == rsD OR WriteRegM == rtD)
//	StallF = StallD = FlushE = lwstall OR branchstall
    wire branchstall;
	wire mfc0stall, flush_except;
    assign branchstall = ( (branchD | jumpD | jalD | jrD) & regwriteE & 
                   (writeregE == rsD | writeregE == rtD) )
                 | ( (branchD | jumpD | jalD | jrD) & memtoregM & 
                   (writeregM == rsD | writeregM == rtD) );


//////////////////// resolve the lw excute -- pipeline stall
//    lwstall = ((rsD==rtE) OR (rtD==rtE)) AND MemtoRegE
    wire lwstall;               
    assign lwstall = ( (rsD==rtE) | (rtD==rtE) ) & memtoregE; 
    
	assign mfc0stall = ( (rsD ==  rtE| rtD == rtE) ) & cp0toregE;
    assign stallF = lwstall | branchstall | inst_stall | mfc0stall | data_stall | div_stallE;
    assign stallD = lwstall | branchstall | inst_stall | mfc0stall | data_stall | div_stallE;
    assign stallE = div_stallE | data_stall;
    assign stallM = data_stall;
    assign stallW = 0;
    
    //assign flushD = (jumpD | jalD | jrD) | pcsrcD;
	assign flush_except = (excepttypeM != 32'b0);

	assign flushF = flush_except;
	assign flushD = flush_except;
	assign flushE = lwstall | flush_except | branchstall | mfc0stall;
	assign flushM = flush_except;
	assign flushW = flush_except | data_stall;
    
    always @(*) begin
		if(excepttypeM != 32'b0) begin
			/* code */
			case (excepttypeM)
				32'h00000001:begin 
					newpcM <= 32'hBFC00380;
				end
				32'h00000004:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h00000005:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h00000008:begin 
					newpcM <= 32'hBFC00380;
					// new_pc <= 32'h00000040;
				end
				32'h00000009:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h0000000a:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h0000000c:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h0000000d:begin 
					newpcM <= 32'hBFC00380;

				end
				32'h0000000e:begin 
					newpcM <= cp0_epcM;
				end
				default : newpcM <= 32'hBFC00380;
			endcase
		end
	end
    
endmodule
