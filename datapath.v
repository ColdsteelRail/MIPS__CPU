`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 09:26:55 PM
// Design Name: 
// Module Name: datapath
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


module datapath(
	input  wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input  wire[31:0] instrF,
	//decode stage
	input  wire pcsrcD,
	input  wire branchD,
	input  wire jumpD, jalD, jrD, balD,
	input  wire invalidD,
	output wire equalD,
	output wire [5:0] opD,functD,
	output wire [4:0] rtD,rsD,
	output wire stallD,
	//execute stage
	input  wire memtoregE,
	input  wire cp0toregE,
	input  wire alusrcE,regdstE,
	input  wire regwriteE,
	input  wire[`aluop] alucontrolE,
	input  wire hilo_writeE,
	input  wire jalE,balE,
	output wire stallE,
	output wire flushE,
	//mem stage
	input  wire memtoregM,
	input  wire regwriteM,
	output wire[31:0] aluoutM,writedataM2,
	output wire[3:0] selM2,
	input  wire[31:0] readdataM,
	input  wire[`aluop] alucontrolM,
	output wire stallM,
	output wire flushM,
	input  wire cp0weM,
	input  wire cp0toregM,
	output wire [31:0] excepttypeM,
	//writeback stage
	input  wire memtoregW,
	input  wire regwriteW,
	output wire [4:0]writeregW,
	output wire stallW,
	output wire flushW,
	output wire [31:0] pcW,
	output wire [31:0] resultW,
	//exception
	input [5:0] int,
	input inst_stall,
	input data_stall,
	input stallreq
    );
	
	//fetch stage
	wire stallF;
	wire flushF;
	wire [7:0] exceptF;
	wire is_in_delayslotF;
	
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	wire [31:0] jumptempFD;
	
	//decode stage
	wire [31:0] pcD;
	wire [31:0] pcplus4D,instrD;
	wire [1:0] forwardaD,forwardbD;
	wire [4:0] rdD,saD;
	wire flushD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire [31:0] pcplus8D;
	wire [7:0] exceptD;
	wire syscallD, breakD, eretD;
	wire is_in_delayslotD;
	
	//execute stage
	wire [31:0] pcE;
	wire [1:0]  forwardaE,forwardbE;
	wire [4:0]  rsE,rtE,rdE,saE;
	wire [4:0]  writeregtempE,writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	wire [31:0] hi_alu_inE, lo_alu_inE, hi_alu_outE, lo_alu_outE;
	wire [31:0] hi_inE,lo_inE;
	wire [31:0] pcplus8E;
	wire div_stallE;
	wire div_validE;
	wire div_signE;
	wire [31:0] div_hi_outE;
	wire [31:0] div_lo_outE;
	wire [7:0]  exceptE;
	wire is_in_delayslotE;
	wire overflow;
	
	//mem stage
	wire [31:0] pcM;
	wire [4:0]  rdM;
	wire [4:0]  writeregM;
	wire [31:0] writedataM;
	wire [31:0] readdataM2;
	wire [31:0] resultM;
	wire [3:0] selM;
	//wire [31:0] hi_alu_outM, lo_alu_outM;
	wire [7:0] exceptM;
	wire except_enM;
	wire adelM,adesM; // load memory exception in memory stage & save memory exception in memory stage
	wire [31:0] bad_addrM;
	wire is_in_delayslotM;
	wire [`RegBus] cp0status, cp0cause, cp0data_out,cp0compare,cp0count,cp0epc,cp0config,cp0prid,badvaddr;
	wire cp0timer_int;
	wire [31:0] newpcM;
	
	//writeback stage
	//wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW;
	//wire [31:0] resultW;
	//wire [31:0] hi_alu_outW, lo_alu_outW;

	//hazard detection
	hazard h(
		//fetch stage
		.stallF       (stallF     ),
		.flushF       (flushF     ),
		//decode stage
		.rsD          (rsD        ),
		.rtD          (rtD        ),
		.branchD      (branchD    ),
		.pcsrcD       (pcsrcD     ),
		.jumpD        (jumpD      ), 
		.jalD         (jalD       ), 
		.jrD          (jrD        ),
		.forwardaD    (forwardaD  ), 
		.forwardbD    (forwardbD  ),
		.stallD       (stallD     ),
		.flushD       (flushD     ),
		//execute stage
		.rsE          (rsE        ), 
		.rtE          (rtE        ),
		.writeregE    (writeregE  ),
		.regwriteE    (regwriteE  ),
		.memtoregE    (memtoregE  ),
		.cp0toregE    (cp0toregE  ),
		.div_stallE   (div_stallE ),
		.forwardaE    (forwardaE  ),
		.forwardbE    (forwardbE  ),
		.stallE       (stallE     ),
		.flushE       (flushE     ),
		//mem stage
		.writeregM    (writeregM  ),
		.regwriteM    (regwriteM  ),
		.memtoregM    (memtoregM  ),
		.excepttypeM  (excepttypeM),
		.stallM       (stallM     ),
		.flushM       (flushM     ),
		.cp0_epcM     (cp0epc     ),
		.newpcM       (newpcM     ),
		//write back stage
		.writeregW    (writeregW  ),
		.regwriteW    (regwriteW  ),
		.stallW       (stallW     ),
		.flushW       (flushW     ),
		
		
		.inst_stall	  (inst_stall ),
		.data_stall   (data_stall )
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux ( .d0(pcplus4F), .d1(pcbranchD),
	                .s(pcsrcD), .y(pcnextbrFD) );
	mux2 #(32) jumpmux ( .d0( {pcplus4D[31:28],instrD[25:0],2'b00} ), .d1(srca2D),
	                .s(jrD), .y(jumptempFD) );
	mux2 #(32) pcmux   ( .d0(pcnextbrFD), .d1(jumptempFD),
		            .s(jumpD | jalD | jrD),.y(pcnextFD) );

    assign except_enM = (excepttypeM == 32'h0);
	//regfile (operates in decode and writeback)
	regfile    rf   (.clk      (~clk       ),
	                .we3       (regwriteW  ),
	                .ra1       (rsD        ),
	                .ra2       (rtD        ),
	                .wa3       (writeregW  ),
	                .wd3       (resultW    ),
	                .rd1       (srcaD      ),
	                .rd2       (srcbD      ));

	//======================================== fetch stage ========================================>>
	//=============================================================================================>>
	pc #(32) pcreg (.clk       (clk        ),  // used as PC
	                .rst       (rst        ), 
	                .en        (~stallF    ), 
	                .clr       (flushF     ),
	                .d         (pcnextFD   ), 
	                .t         (newpcM     ), 
	                .q         (pcF        ) );
	adder   pcadd1 ( .a(pcF), .b(32'b100), .y(pcplus4F) );
	assign exceptF = (pcF[1:0] == 2'b00) ? 8'b00000000 : 8'b10000000;//the addr error
	assign is_in_delayslotF = (jumpD|jrD|jalD|branchD);
	
	//======================================== decode stage ========================================>>
	//==============================================================================================>>
	assign opD =       instrD[`op];
	assign functD =    instrD[`funct];
	assign rsD =       instrD[`rs];
	assign rtD =       instrD[`rt];
	assign rdD =       instrD[`rd];
	assign saD =       instrD[`sa];
	
	//exception
	assign syscallD = ( { opD, functD } == { `RTYPE, `syscall } ) & ~stallreq;
	assign breakD   = ( { opD, functD } == { `RTYPE, `break } ) & ~stallreq;
	assign eretD    = (instrD == `eret) & ~stallreq;
	
	flopenrc #(32) r1D    ( .clk(clk), .rst(rst), .en(~stallD), .clear(flushD),
	                   .d(pcplus4F), .q(pcplus4D) );
	flopenrc #(32) r2D    ( .clk(clk), .rst(rst), .en(~stallD), .clear(flushD),
	                   .d(instrF), .q(instrD) );
	flopenrc #(32) rpcD   ( .clk(clk), .rst(rst), .en(~stallD), .clear(flushD),
	                   .d(pcF), .q(pcD) );
	flopenrc #(8)  r3D    ( .clk(clk), .rst(rst), .en(~stallD), .clear(flushD),
	                   .d(exceptF), .q(exceptD) );
	flopenrc #(1)  r4D    ( .clk(clk), .rst(rst), .en(~stallD), .clear(flushD),
	                   .d(is_in_delayslotF), .q(is_in_delayslotD) );
	signext        se     ( .a(instrD[15:0]), .type(instrD[29:28]), .y(signimmD) );
	sl2            immsh  ( .a(signimmD), .y(signimmshD) );
	adder          pcadd2 ( .a(pcplus4D), .b(signimmshD), .y(pcbranchD) );
	adder          pcadd3 ( .a(pcplus4D), .b(32'b100), .y(pcplus8D) );
//	mux2 #(32) forwardamux( .d0(srcaD), .d1(aluoutM),
//	                   .s(forwardaD), .y(srca2D) );
//	mux2 #(32) forwardbmux( .d0(srcbD), .d1(aluoutM),
//	                   .s(forwardbD), .y(srcb2D) );
	mux4 #(32) forwardamux( .d0(srcaD), .d1(aluoutE), .d2(resultM), .d3(resultW),
	                   .s(forwardaD), .y(srca2D) );
	mux4 #(32) forwardbmux( .d0(srcbD), .d1(aluoutE), .d2(resultM), .d3(resultW),
	                   .s(forwardbD), .y(srcb2D) );
	eqcmp          comp   ( .a     (srca2D ),
	                        .b     (srcb2D ), 
	                        .op    (opD    ), 
	                        .rt    (rtD    ), 
	                        .y     (equalD ) );


	//======================================== execute stage ========================================>>
	//===============================================================================================>>
	flopenrc #(32) r1E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(srcaD), .q(srcaE) );
	flopenrc #(32) r2E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(srcbD), .q(srcbE) );
	flopenrc #(32) r3E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(signimmD), .q(signimmE) );
	flopenrc #(5)  r4E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(rsD), .q(rsE) );
	flopenrc #(5)  r5E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(rtD), .q(rtE) );
	flopenrc #(5)  r6E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(rdD), .q(rdE) );
	flopenrc #(5)  r7E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(saD), .q(saE));
	flopenrc #(32) r8E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(pcplus8D), .q(pcplus8E) );
	flopenrc #(32) rpcE( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
	                   .d(pcD), .q(pcE) );
	//judge except instr 
	flopenrc #(8)  r9E ( .clk(clk), .rst(rst), .en(~stallE), .clear(flushE),
		               .d({exceptD[7],syscallD,breakD,eretD,invalidD,exceptD[2:0]}),
		               .q(exceptE));
	flopenrc #(1)  r10E( .clk(clk), .rst(rst), .en(~stallM), .clear(flushE),
	                   .d(is_in_delayslotD), .q(is_in_delayslotE) );

	mux3 #(32) forwardaemux( .d0(srcaE), .d1(resultW), .d2(aluoutM),
	                   .s(forwardaE), .y(srca2E) );
	mux3 #(32) forwardbemux( .d0(srcbE), .d1(resultW), .d2(aluoutM),
	                   .s(forwardbE), .y(srcb2E) );
	mux2 #(32) srcbmux     ( .d0(srcb2E), .d1(signimmE),
	                   .s(alusrcE), .y(srcb3E) );
	alu        alu         (.srcAE         (srca2E     ),
	                        .srcBE         (srcb3E     ), 
	                        .op            (alucontrolE),
	                        .hi_inE        (hi_alu_inE ), 
	                        .lo_inE        (lo_alu_inE ), 
	                        .pcplus8E      (pcplus8E   ),
	                        .sa            (saE        ), 
	                        .aluoutM       (aluoutE    ),
	                        .overflow      (overflow   ),
	                        .hi_alu_out    (hi_alu_outE), 
	                        .lo_alu_out    (lo_alu_outE));
	//hilo module
	mux2 #(32) himux( .d0( hi_alu_outE), .d1(div_hi_outE ),
	                .s(div_validE), .y(hi_inE) ); // judge mult or div
	mux2 #(32) lomux( .d0( lo_alu_outE), .d1(div_lo_outE),
	                .s(div_validE), .y(lo_inE) );
	hilo_reg   hilo ( .clk     (clk        ),
	                .rst       (rst        ),
	                .we        (hilo_writeE && ~div_stallE && except_enM),
	                .hi        (hi_inE     ), 
	                .lo        (lo_inE     ), 
	                .hi_o      (hi_alu_inE ), 
	                .lo_o      (lo_alu_inE ) );
	//div operation
	assign div_validE = (alucontrolE == `sig_div) | (alucontrolE == `sig_divu);
	assign div_signE =  (alucontrolE == `sig_div);
	div_self_align divreg  (.clk           (~clk       ),
	                        .rst           (rst        ),
	                        .a             (srca2E     ), 
	                        .b             (srcb3E     ),
	                        .valid         (div_validE ),
	                        .sign          (div_signE  ),
	                        .div_stall     (div_stallE ),
	                        .result        ({ div_hi_outE, div_lo_outE }) );
	mux2 #(5)  wrmux       ( .d0(rtE), .d1(rdE),
	                   .s(regdstE), .y(writeregtempE) );
	mux2 #(5)  jalmux      ( .d0(writeregtempE), .d1(5'b11111),
	                   .s(jalE | balE), .y(writeregE) );

	//======================================== mem stage ========================================>>
	//===========================================================================================>>
	flopenrc #(32) r1M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(srcb2E), .q(writedataM) );
	flopenrc #(32) r2M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(aluoutE), .q(aluoutM) );
	flopenrc #(5)  r3M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(writeregE), .q(writeregM));
	flopenrc #(32) rpcM( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(pcE), .q(pcM));
	flopenrc #(8)  r4M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d({exceptE[7:3],overflow,exceptE[1:0]}),
	                   .q(exceptM));
	flopenrc #(5)  r5M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(rdE), .q(rdM));
	flopenrc #(1)  r6M ( .clk(clk), .rst(rst), .en(~stallM), .clear(flushM),
	                   .d(is_in_delayslotE), .q(is_in_delayslotM) );
	//flopr #(64) r4M(clk,rst,{hi_alu_outE, lo_alu_outE},{hi_alu_outM, lo_alu_outM});
	sel memsel(    .pc         (pcM        ),
	               .alucontrolM(alucontrolM),
	               .addr       (aluoutM    ), 
	               .wa         (writedataM ), 
	               .ra         (readdataM  ), 
	               .wb         (writedataM2), 
	               .rb         (readdataM2 ), 
	               .sel        (selM       ),
	               .adelM      (adelM      ),
	               .adesM      (adesM      ),
	               .bad_addr   (bad_addrM  ) );
	assign selM2 = selM & { 4{except_enM} };
	            
	exception exp( .rst        (rst        ),
	               .except     (exceptM    ),
	               .adel       (adelM      ),
	               .ades       (adesM      ),
	               .cp0_status (cp0status  ),
	               .cp0_cause  (cp0cause   ),
	               .excepttype (excepttypeM) );
	cp0_reg  cp0(  .clk        (clk        ),
		           .rst        (rst        ),
		           .we_i       (cp0weM     ),
		           .waddr_i    (rdM        ),
		           .raddr_i    (rdM        ),
		           .data_i     (aluoutM    ),
		           .int_i      (int        ),
		           .excepttype_i          (excepttypeM    ),
		           .current_inst_addr_i   (pcM            ),
		           .is_in_delayslot_i     (is_in_delayslotM),
		           .bad_addr_i            (bad_addrM      ),
		           .data_o     (cp0data_out),
		           .count_o    (cp0count  ),
		           .compare_o  (cp0compare),
		           .status_o   (cp0status ),
		           .cause_o    (cp0cause  ),
		           .epc_o      (cp0epc    ),
		           .config_o   (cp0config ),
		           .prid_o     (cp0prid   ),
		           .badvaddr   (badvaddr  ),
		           .timer_int_o(cp0timer_int)  );
		           
    
	assign resultM = (~memtoregM  && ~cp0toregM) ? aluoutM:
									 (memtoregM) ? readdataM2:
					 							   cp0data_out;

	//======================================== writeback stage ========================================>>
	//=================================================================================================>>
	flopenrc #(32) r1W ( .clk(clk), .rst(rst), .en(~stallW), .clear(flushW),
	                   .d(aluoutM), .q(aluoutW) );
	flopenrc #(32) r2W ( .clk(clk), .rst(rst), .en(~stallW), .clear(flushW),
	                   .d(readdataM2), .q(readdataW) );
	flopenrc #(5)  r3W ( .clk(clk), .rst(rst), .en(~stallW), .clear(flushW),
	                   .d(writeregM), .q(writeregW) );
	flopenrc #(32) rpcW( .clk(clk), .rst(rst), .en(~stallW), .clear(flushW),
	                   .d(pcM), .q(pcW) );
	//flopr #(64) r4W(clk,rst,{hi_alu_outM, lo_alu_outM},{hi_alu_outW, lo_alu_outW});
//	mux2  #(32) resmux( .d0(aluoutW), .d1(readdataW), 
//	                   .s(memtoregW), .y(resultW));
	flopenrc #(32) r4W( .clk(clk), .rst(rst), .en(~stallW), .clear(flushW),
	                   .d(resultM), .q(resultW) );
endmodule
