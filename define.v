`timescale 1ns / 1ps

// ========== INSTRUCTION SLICE ==========>>
`define op      31:26
`define funct   5:0
`define rs      25:21 
`define rt      20:16 
`define rd      15:11
`define sa      10:6
`define address 15:0
`define RegBus  31:0

`define aluop   7:0

// ========== CONTROLLER INPUT SIGNAL ==========>>
`define RTYPE 6'b000000
//arithmetic
        `define add   6'b100000
        `define sub   6'b100010
        `define addu  6'b100001
        `define subu  6'b100011
`define addi  6'b001000
`define addiu 6'b001001
        `define slt   6'b101010
        `define sltu  6'b101011
`define slti  6'b001010
`define sltiu 6'b001011
        `define mult  6'b011000
        `define multu 6'b011001
        `define div   6'b011010
        `define divu  6'b011011
//logic
        `define and   6'b100100
        `define or    6'b100101
        `define xor   6'b100110
        `define nor   6'b100111
`define andi  6'b001100
`define xori  6'b001110
`define ori   6'b001101
`define lui   6'b001111
//shift
        `define sll   6'b000000
        `define srl   6'b000010
        `define sra   6'b000011
        `define sllv  6'b000100
        `define srlv  6'b000110
        `define srav  6'b000111
//data move
        `define mfhi  6'b010000
        `define mflo  6'b010010
        `define mthi  6'b010001
        `define mtlo  6'b010011
//memory op
`define lw    6'b100011
`define sw    6'b101011
`define lb    6'b100000
`define lbu   6'b100100
`define lh    6'b100001
`define lhu   6'b100101
`define sb    6'b101000
`define sh    6'b101001
//branch
`define beq   6'b000100
`define bgtz  6'b000111
`define blez  6'b000110
`define bne   6'b000101
`define regimm_inst 6'b000001
    `define bltz    5'b00000
    `define bltzal  5'b10000
    `define bgez    5'b00001
    `define bgezal  5'b10001
`define j     6'b000010
`define jal   6'b000011
        `define jr    6'b001000
        `define jalr  6'b001001

//exception
        `define break   6'b001101
        `define syscall 6'b001100
`define eret    32'b01000010000000000000000000011000
`define eret_funct 6'b011000
`define SPECIAL3_INST 6'b010000
    `define rs_mtc0 5'b00100
    `define rs_mfc0 5'b00000
    `define rs_eret 5'b10000


// ========== CONTROLLER OUTPUT SIGNAL ==========>>
// | regwriteD | regdstD | alusrcD | branchD | memwriteD | memtoregD | jumpD | jalD | jrD | balD | memen
`define ctrl_Rtype  11'b11000000000
//logic
`define ctrl_andi   11'b10100000000
`define ctrl_xori   11'b10100000000
`define ctrl_lui    11'b10100000000
`define ctrl_ori    11'b10100000000
//shift ==>> all is Rtype
//arithmetic
`define ctrl_addi   11'b10100000000
`define ctrl_slti   11'b10100000000
`define ctrl_mult_div 11'b00000000000
//data move 
`define ctrl_datamf 11'b11000000000
`define ctrl_datamt 11'b00000000000
//memory op
`define ctrl_load   11'b10100100001
`define ctrl_save   11'b00101000001
//branch
`define ctrl_beq    11'b00010000000
`define ctrl_bal    11'b10010000010
`define ctrl_jump   11'b00000010000
`define ctrl_jal    11'b10000001000
`define ctrl_jr     11'b00000010100
`define ctrl_jalr   11'b11000000100
//exception
`define ctrl_break  11'b00000000000
`define ctrl_syscall 11'b00000000000
`define ctrl_mtc0   11'b00000000000
`define ctrl_mfc0   11'b10000000000
`define ctrl_eret   11'b00000000000

// ========== ALU SIGNAL ==========>>
//arithmetic
`define sig_add   8'b00000010
`define sig_addu  8'b00010010
`define sig_sub   8'b00000011
`define sig_subu  8'b00010011
`define sig_slt   8'b00000101
`define sig_sltu  8'b00010101
`define sig_mult  8'b00010110
`define sig_multu 8'b00011110
`define sig_div   8'b00010111
`define sig_divu  8'b00011111
//logic
`define sig_and   8'b00000000
`define sig_or    8'b00000001
`define sig_oppo  8'b00000100
`define sig_xor   8'b00000110
`define sig_nor   8'b00000111
`define sig_lui   8'b00001000
//shift
`define sig_sll   8'b00001001
`define sig_srl   8'b00001010
`define sig_sra   8'b00001011
`define sig_sllv  8'b00001100
`define sig_srlv  8'b00001101
`define sig_srav  8'b00001110
//data move
`define sig_mfhi  8'b00011000
`define sig_mflo  8'b00011010
`define sig_mthi  8'b00011001
`define sig_mtlo  8'b00011011
//jump & branch
`define sig_jal   8'b00100000
`define sig_jalr  8'b00100001
`define sig_bal   8'b00100010
//memory
`define sig_lw    8'b10000000
`define sig_sw    8'b10000001
`define sig_lb    8'b10000010
`define sig_lbu   8'b10000011
`define sig_lh    8'b10000100
`define sig_lhu   8'b10000101
`define sig_sh    8'b10000110
`define sig_sb    8'b10000111
//exception
`define sig_mtc0  8'b00100100
`define sig_mfc0  8'b00100101

`define sig_zero  8'b00000000


