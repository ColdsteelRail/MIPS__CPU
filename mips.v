`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 09:28:12 PM
// Design Name: 
// Module Name: mips
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


module mycpu_top(
	input  wire        clk,
	input  wire        resetn,
    input [5:0]        int,  //interrupt,high active

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    output wire [3:0]  arid,
    output wire [31:0] araddr,
    output wire [3:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [1:0]  arlock,
    output wire [3:0]  arcache,
    output wire [2:0]  arprot,
    output             arvalid,
    input              arready,
    //r              
    input  wire [3:0]  rid,
    input  wire [31:0] rdata,
    input  wire [1:0]  rresp,
    input              rlast,
    input              rvalid,
    output             rready,
    //aw           
    output wire [3:0]  awid,
    output wire [31:0] awaddr,
    output wire [3:0]  awlen,
    output wire [2:0]  awsize,
    output wire [1:0]  awburst,
    output wire [1:0]  awlock,
    output wire [3:0]  awcache,
    output wire [2:0]  awprot,
    output             awvalid,
    input              awready,
    //w          
    output wire [3:0]  wid,
    output wire [31:0] wdata,
    output wire [3:0]  wstrb,
    output             wlast,
    output             wvalid,
    input              wready,
    //b              
    input  wire [3:0]  bid,
    input  wire [1:0]  bresp,
    input              bvalid,
    output             bready,
    //debug
    output [31:0]      debug_wb_pc,
    output [3:0]       debug_wb_rf_wen,
    output [4:0]       debug_wb_rf_wnum,
    output [31:0]      debug_wb_rf_wdata
    );
    //=================== datapath && controller && debug==========================>>
    //=============================================================================>>
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD;
	wire pcsrcD;
	wire branchD,jumpD,jalD, jrD, balD;
	wire invalidD;
	wire stallD,equalD;

	wire jalE,balE;
	wire regdstE,alusrcE,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM,regwriteW;
	wire [`aluop] alucontrolE,alucontrolM;
	wire stallE,flushE;
	wire hilo_writeE;
	wire cp0toregE;
	
    wire memwriteM;
    wire cp0weM;
    wire cp0toregM;
	wire stallM,flushM;
	wire stallW,flushW;
	wire [31:0]excepttypeM;

    // instruction memory
    wire [31:0]  pcF;
    wire [31:0]  instrF;
    
    // data memory
    wire         memenM;
    wire [3:0]   selM;
    wire [31:0]  aluoutM,writedataM;
    wire [31:0]  readdataM;
    
    // debug
	wire [31:0]  pcW;
	wire [4:0]   writeregW;
	wire [31:0]  resultW;



    
    // instruction memory
    wire             inst_sram_en;
    wire [3:0]       inst_sram_wen;
    wire [31:0]      inst_sram_addr;
    wire [31:0]      inst_sram_wdata;
    wire [31:0]      inst_sram_rdata;
    
    wire             data_sram_en;
    wire             data_sram_write;
    wire [1 :0]      data_sram_size;
    wire [3:0]       data_sram_wen;
    wire [31:0]      data_sram_addr;
    wire [31:0]      data_sram_wdata;
    wire [31:0]      data_sram_rdata;

    // inst memory
    assign inst_sram_en    = 1'b1;
    assign inst_sram_wen   = 4'b0000;
    assign inst_sram_addr  = pcF;
    assign inst_sram_wdata = 32'h0000_0000;
    assign instrF          = inst_sram_rdata;
    
    // data memory
    assign data_sram_en    = memenM & ~(|excepttypeM);
    assign data_sram_write = data_sram_wen[0] || data_sram_wen[1] || data_sram_wen[2] || data_sram_wen[3];
    assign data_sram_size  = (data_sram_wen == 4'b0000 || data_sram_wen == 4'b1111) ? 2'b10:
                             (data_sram_wen == 4'b0011 || data_sram_wen == 4'b1100) ? 2'b01:
                             (data_sram_wen == 4'b0001 || data_sram_wen == 4'b0010 || data_sram_wen == 4'b0100 || data_sram_wen == 4'b1000) ? 2'b00:
                             2'b00;
    assign data_sram_wen   = selM;
    assign data_sram_addr  = (aluoutM[31:16] == 16'hbfaf)?{16'h1faf,aluoutM[15:0]}:aluoutM;
    assign data_sram_wdata = writedataM;
    assign readdataM       = data_sram_rdata;
    
    // debug
    assign debug_wb_pc     = pcW;
    // && ((stallreq_from_if|stallreq_from_mem) == 1'b0)
    assign debug_wb_rf_wen = {4{regwriteW}};
    assign debug_wb_rf_wnum  = writeregW;
    assign debug_wb_rf_wdata = resultW;

    //change sram to axi
    // use a inst_miss signal to denote that the instruction is not loadssss    //cache mux signal
    wire cache_miss,sel_i;
    wire[31:0] i_addr,d_addr,m_addr;
    wire m_fetch,m_ld_st,mem_access;
    wire mem_write,m_st;
    wire mem_ready,m_i_ready,m_d_ready,i_ready,d_ready;
    wire[31:0] mem_st_data,mem_data;
    wire[1:0] mem_size,d_size;// size not use
    wire[3:0] m_sel,d_wen;
    wire stallreq_from_if,stallreq_from_mem;
    wire stallreq;
    
    reg inst_miss;
    //* delete if using cache
    always @(posedge clk) begin
        if (~resetn) begin
            inst_miss <= 1'b1;
        end
        if (m_i_ready & inst_miss) begin // fetch instruction ready
            inst_miss <= 1'b0;
        end else if (~inst_miss & data_sram_en) begin // fetch instruction ready, but need load data, so inst_miss maintain 0
            inst_miss <= 1'b0;
        end else if (~inst_miss & data_sram_en & m_d_ready) begin //load data ready, set inst_miss to 1
            inst_miss <= 1'b1;
        end else begin // other conditions, set inst_miss to 1
            inst_miss <= 1'b1;
        end
    end
    

    assign sel_i = inst_miss;   // use inst_miss to select access memory(for load/store) or fetch(each instruction)
    assign d_addr = (data_sram_addr[31:16] != 16'hbfaf) ? data_sram_addr : {16'h1faf,data_sram_addr[15:0]}; // modify data address, to get the data from confreg
    assign i_addr = inst_sram_addr;
    assign m_addr = sel_i ? i_addr : d_addr;
    // 
    assign m_fetch = inst_sram_en & inst_miss; //if inst_miss equals 0, disable the fetch strobe
    assign m_ld_st = data_sram_en;

    assign inst_sram_rdata = mem_data;
    assign data_sram_rdata = mem_data;
    assign mem_st_data = data_sram_wdata;
    // use select signal
    assign mem_access = sel_i ? m_fetch : m_ld_st; 
    assign mem_size = sel_i ? 2'b10 : data_sram_size;
    assign m_sel = sel_i ? 4'b1111 : data_sram_wen;
    assign mem_write = sel_i ? 1'b0 : data_sram_write;

    //demux
    assign m_i_ready = mem_ready & sel_i;
    assign m_d_ready = mem_ready & ~sel_i;

    //
    assign stallreq_from_if = ~m_i_ready;
    assign stallreq_from_mem = data_sram_en & ~m_d_ready;
    assign stallreq = stallreq_from_if | stallreq_from_mem;

    axi_interface interface(
        .clk        (clk        ),
        .resetn     (resetn     ),
        
         //cache/cpu_core port
        .mem_a      (m_addr     ),
        .mem_access (mem_access ),
        .mem_write  (mem_write  ),
        .mem_size   (mem_size   ),
        .mem_sel    (m_sel      ),
        .mem_ready  (mem_ready  ),
        .mem_st_data(mem_st_data),
        .mem_data   (mem_data   ),
        // add a input signal 'flush', cancel the memory accessing operation in axi_interface, do not need any extra design. 
        .flush      (|excepttypeM), // use excepetion type

        .arid       (arid       ),
        .araddr     (araddr     ),
        .arlen      (arlen      ),
        .arsize     (arsize     ),
        .arburst    (arburst    ),
        .arlock     (arlock     ),
        .arcache    (arcache    ),
        .arprot     (arprot     ),
        .arvalid    (arvalid    ),
        .arready    (arready    ),
                    
        .rid        (rid        ),
        .rdata      (rdata      ),
        .rresp      (rresp      ),
        .rlast      (rlast      ),
        .rvalid     (rvalid     ),
        .rready     (rready     ),
                
        .awid       (awid       ),
        .awaddr     (awaddr     ),
        .awlen      (awlen      ),
        .awsize     (awsize     ),
        .awburst    (awburst    ),
        .awlock     (awlock     ),
        .awcache    (awcache    ),
        .awprot     (awprot     ),
        .awvalid    (awvalid    ),
        .awready    (awready    ),
        
        .wid        (wid        ),
        .wdata      (wdata      ),
        .wstrb      (wstrb      ),
        .wlast      (wlast      ),
        .wvalid     (wvalid     ),
        .wready     (wready     ),
        
        .bid        (bid        ),
        .bresp      (bresp      ),
        .bvalid     (bvalid     ),
        .bready     (bready     )
    );
    
    // ==================== controller module & datapath ====================>>
	// ======================================================================>>
	controller c(
		.clk              (clk        ), 
		.rst              (~resetn    ),
		//decode stage
		.instr_opD        (opD        ),
		.instr_rtD        (rtD        ),
		.instr_rsD        (rsD        ),
		.instr_funD       (functD     ),
		.equalD           (equalD     ),
		.branchD          (branchD    ),
		.pcsrcD           (pcsrcD     ),
		.jumpD            (jumpD      ),
		.jalD             (jalD       ), 
		.jrD              (jrD        ), 
		.balD             (balD       ),
		.invalidD         (invalidD   ),
		.stallD           (stallD     ),
		
		//execute stage
		.stallE           (stallE     ),
		.flushE           (flushE     ),
		.memtoregE        (memtoregE  ),
		.cp0toregE        (cp0toregE  ),
		.alusrcE          (alusrcE    ),
		.regdstE          (regdstE    ),
		.regwriteE        (regwriteE  ),
		.jalE             (jalE       ),
		.balE             (balE       ),
		.alucontrolE      (alucontrolE),
		.hilo_write_enaE  (hilo_writeE),

		//mem stage
		.stallM           (stallM     ),
		.flushM           (flushM     ),
		.memtoregM        (memtoregM  ),
		.memwriteM        (memwriteM  ),
		.regwriteM        (regwriteM  ),
		.memenM           (memenM     ),
		.alucontrolM      (alucontrolM),
		.cp0weM           (cp0weM     ),
		.cp0toregM        (cp0toregM  ),
		//write back stage
		.stallW           (stallW     ),
		.flushW           (flushW     ),
		.memtoregW        (memtoregW  ),
		.regwriteW        (regwriteW  ),
		.stallreq         (stallreq   )
		);
	datapath dp(
		.clk              (clk        ), 
		.rst              (~resetn    ),
		//fetch stage
		.pcF              (pcF        ),
		.instrF           (instrF     ),
		//decode stage
		.pcsrcD           (pcsrcD     ),
		.branchD          (branchD    ),
		.jumpD            (jumpD      ),
		.jalD             (jalD       ),
		.jrD              (jrD        ),
		.balD             (balD       ),
		.equalD           (equalD     ),
		.opD              (opD        ),
		.functD           (functD     ),
		.rtD              (rtD        ),
		.rsD              (rsD        ),
		.invalidD         (invalidD   ),
		.stallD           (stallD     ),
		//execute stage
		.memtoregE        (memtoregE  ),
		.cp0toregE        (cp0toregE  ),
		.alusrcE          (alusrcE    ),
		.regdstE          (regdstE    ),
		.regwriteE        (regwriteE  ),
		.alucontrolE      (alucontrolE),
		.hilo_writeE      (hilo_writeE),
		.jalE             (jalE       ),
		.balE             (balE       ),
		.stallE           (stallE     ),
		.flushE           (flushE     ),
		//mem stage
		.memtoregM        (memtoregM  ),
		.regwriteM        (regwriteM  ),
		.aluoutM          (aluoutM    ),
		.writedataM2      (writedataM ),
		.selM2            (selM       ),
		.readdataM        (readdataM  ),
		.alucontrolM      (alucontrolM),
		.stallM           (stallM     ),
		.flushM           (flushM     ),
		.cp0weM           (cp0weM     ),
		.cp0toregM        (cp0toregM  ),
        .excepttypeM      (excepttypeM),
		//writeback stage
		.memtoregW        (memtoregW  ),
		.regwriteW        (regwriteW  ),
		.writeregW        (writeregW  ),
		.stallW           (stallW     ),
		.flushW           (flushW     ),
		.pcW              (pcW        ),
		.resultW          (resultW    ),
		//exception
		.int              (int        ),
        .inst_stall       (stallreq_from_if ),
        .data_stall       (stallreq_from_mem),
		.stallreq         (stallreq   )
	    );
	// ======================================================================<<
	// ==================== controller module & datapath ====================<<

endmodule