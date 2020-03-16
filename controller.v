`timescale 1ns / 1ps
`include "define.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2019 07:59:43 PM
// Design Name: 
// Module Name: controller
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


module controller(
    input clk,rst,
    // decode stage
    input [`op] instr_opD,
    input [`rt] instr_rtD,
    input [`rs] instr_rsD,
    input [`funct] instr_funD,
    input equalD,
    output branchD,
    output pcsrcD,
    output jumpD, jalD, jrD, balD,
    output invalidD,
    input stallD,
    // execution stage
    input stallE,flushE,
    output memtoregE,
    output cp0toregE,
    output alusrcE,
    output regdstE,
    output regwriteE,
    output jalE, balE,
    output [`aluop] alucontrolE,
    output hilo_write_enaE,
    // Memory Request stage
    input stallM,flushM,
    output memtoregM,
    output memwriteM,
    output regwriteM,
    output memenM,
    output [`aluop] alucontrolM,
    output cp0weM,
    output cp0toregM,
    // write back stage
    input stallW,flushW,
    output memtoregW,
    output regwriteW,
    // axi_request
    input stallreq
    );
    
    //decode stage
    wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD,memenD;
    wire [`aluop] alucontrolD;
    wire hilo_write_enaD;
    //execute stage
    wire memwriteE,memenE;
    //wire hilo_write_enaE;
    
    //Memory Request stage
    //wire hilo_write_enaM;
    
    
    //exception
    wire cp0weD,cp0weE; // cp0 write enable signal
    wire cp0toregD;
    //assign cp0weD = { instr_opD, instr_rsD } == { `SPECIAL3_INST, `rs_mtc0 };
    //assign cp0toregD = { instr_opD, instr_rsD } == { `SPECIAL3_INST, `rs_mfc0 };    
    
    //assign hilo_write_enaD = (en_mthi == 1) || (en_mtlo == 1) || (en_mult == 1) || (en_multu == 1) || (en_div == 1) || (en_divu == 1);

    
    reg [19:0] controls;
    reg [2:0]  hilo_cp0;

    assign { regwriteD , regdstD, alusrcD, branchD, memwriteD, memtoregD, jumpD, jalD, jrD, balD, memenD,
             alucontrolD, invalidD } = controls;
    assign { cp0weD, cp0toregD, hilo_write_enaD } = hilo_cp0;
    
    always @(*)
    begin
        case(instr_opD)
            `SPECIAL3_INST:
            if(~stallreq) begin
                case(instr_rsD)
                    `rs_mtc0: hilo_cp0 <= 3'b100;
                    `rs_mfc0: hilo_cp0 <= 3'b010;
                    default: hilo_cp0 <= 3'b000;
                endcase
            end 
            else begin
                hilo_cp0 <= 3'b000;
            end
            `RTYPE:
                case(instr_funD)
                    `mult: hilo_cp0 <= 3'b001;
                    `multu:hilo_cp0 <= 3'b001;
                    `div:  hilo_cp0 <= 3'b001;
                    `divu: hilo_cp0 <= 3'b001;
                    `mthi: hilo_cp0 <= 3'b001;
                    `mtlo: hilo_cp0 <= 3'b001;
                    default: hilo_cp0 <= 3'b000;
                endcase
            default: hilo_cp0 <= 3'b000;
        endcase
    end
    
    always @(*)
    begin
        controls<=0;
        if(~stallreq)begin
        case(instr_opD)
            `RTYPE:
                case(instr_funD)
                    // arithmetic
                    `add:  controls <= { `ctrl_Rtype, `sig_add,  1'b0 };
                    `addu: controls <= { `ctrl_Rtype, `sig_addu, 1'b0 };
                    `sub:  controls <= { `ctrl_Rtype, `sig_sub,  1'b0 };
                    `subu: controls <= { `ctrl_Rtype, `sig_subu, 1'b0 };
                    `slt:  controls <= { `ctrl_Rtype, `sig_slt,  1'b0 };
                    `sltu: controls <= { `ctrl_Rtype, `sig_sltu, 1'b0 };
                    `mult: controls <= { `ctrl_mult_div, `sig_mult,  1'b0 };
                    `multu:controls <= { `ctrl_mult_div, `sig_multu, 1'b0 };
                    `div:  controls <= { `ctrl_mult_div, `sig_div,   1'b0 };
                    `divu: controls <= { `ctrl_mult_div, `sig_divu,  1'b0 };
                    // logic
                    `and:  controls <= { `ctrl_Rtype, `sig_and,  1'b0 };
                    `xor:  controls <= { `ctrl_Rtype, `sig_xor,  1'b0 };
                    `or:   controls <= { `ctrl_Rtype, `sig_or,   1'b0 };
                    `nor:  controls <= { `ctrl_Rtype, `sig_nor,  1'b0 };
                    // shift
                    `sll:  controls <= { `ctrl_Rtype, `sig_sll,  1'b0 };
                    `srl:  controls <= { `ctrl_Rtype, `sig_srl,  1'b0 };
                    `sra:  controls <= { `ctrl_Rtype, `sig_sra,  1'b0 };
                    `sllv: controls <= { `ctrl_Rtype, `sig_sllv, 1'b0 };
                    `srlv: controls <= { `ctrl_Rtype, `sig_srlv, 1'b0 };
                    `srav: controls <= { `ctrl_Rtype, `sig_srav, 1'b0 };
                    // data move
                    `mfhi: controls <= { `ctrl_datamf,`sig_mfhi, 1'b0 };
                    `mflo: controls <= { `ctrl_datamf,`sig_mflo, 1'b0 };
                    `mthi: controls <= { `ctrl_datamt,`sig_mthi, 1'b0 };
                    `mtlo: controls <= { `ctrl_datamt,`sig_mtlo, 1'b0 };
                    // branch
                    `jr:   controls <= { `ctrl_jr,    `sig_zero, 1'b0 };
                    `jalr: controls <= { `ctrl_jalr,  `sig_jalr, 1'b0 };
                    // exception
                    `break:  controls <= (~stallD)? { `ctrl_break, `sig_zero, 1'b0 } : 20'b1;
                    `syscall:controls <= (~stallD)? { `ctrl_syscall, `sig_zero, 1'b0 }:20'b1;
                    default: controls <= 20'b1; // illegal instruction
                endcase
            // arithmetic
            `addi: controls <= { `ctrl_addi, `sig_add,   1'b0 };
            `addiu:controls <= { `ctrl_addi, `sig_addu,  1'b0 };
            `slti: controls <= { `ctrl_slti, `sig_slt,   1'b0 };
            `sltiu:controls <= { `ctrl_slti, `sig_sltu,  1'b0 };
            // logic
            `andi: controls <= { `ctrl_andi, `sig_and,   1'b0 };
            `xori: controls <= { `ctrl_xori, `sig_xor,   1'b0 };
            `ori:  controls <= { `ctrl_ori,  `sig_or,    1'b0 };
            `lui:  controls <= { `ctrl_lui,  `sig_lui,   1'b0 };
            // branch
            `beq:  controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
            `bne:  controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
            `bgtz: controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
            `blez: controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
            `regimm_inst:
                case(instr_rtD)
                    `bltz: controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
                    `bgez: controls <= { `ctrl_beq,  `sig_zero,  1'b0 };
                    `bltzal: controls <= { `ctrl_bal, `sig_bal,  1'b0 };
                    `bgezal: controls <= { `ctrl_bal, `sig_bal,  1'b0 };
                    default: controls <= 20'b1; // illegal instruction
                endcase
            `j:    controls <= { `ctrl_jump, `sig_zero,  1'b0 };
            `jal:  controls <= { `ctrl_jal,  `sig_jal,   1'b0 };
            //memory
            `lw:   controls <= { `ctrl_load,  `sig_lw,   1'b0 };
            `lb:   controls <= { `ctrl_load,  `sig_lb,   1'b0 };
            `lbu:  controls <= { `ctrl_load,  `sig_lbu,  1'b0 };
            `lh:   controls <= { `ctrl_load,  `sig_lh,   1'b0 };
            `lhu:  controls <= { `ctrl_load,  `sig_lhu,  1'b0 };
            `sw:   controls <= { `ctrl_save,  `sig_sw,   1'b0 };
            `sb:   controls <= { `ctrl_save,  `sig_sb,   1'b0 };
            `sh:   controls <= { `ctrl_save,  `sig_sh,   1'b0 };
            //privilege
            `SPECIAL3_INST:
                case(instr_rsD)
                    `rs_mtc0: controls <= { `ctrl_mtc0, `sig_mtc0, 1'b0 };
                    `rs_mfc0: controls <= { `ctrl_mfc0, `sig_mfc0, 1'b0 };
                    `rs_eret: controls <= { `ctrl_eret, `sig_zero, 1'b0 };
                    default: controls <= 20'b1; // illegal instruction
                endcase
            default: controls <= 20'b1; // illegal instruction
        endcase
       end
    end

    assign pcsrcD = branchD & equalD ;

	//pipeline registers
	flopenrc #( .WIDTH(19) ) regE(
		clk,rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_write_enaD,jalD,balD,memenD,cp0weD,cp0toregD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_write_enaE,jalE,balE,memenE,cp0weE,cp0toregE}
		);
	flopenrc #( .WIDTH(14) ) regM(
		clk,rst,
		~stallM,
		flushM,
		{memtoregE,memwriteE,regwriteE,memenE,alucontrolE,cp0weE,cp0toregE},
		{memtoregM,memwriteM,regwriteM,memenM,alucontrolM,cp0weM,cp0toregM}
		);
	flopenrc #( .WIDTH(2) ) regW(
		clk,rst,
		~stallW,
		flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);

endmodule
