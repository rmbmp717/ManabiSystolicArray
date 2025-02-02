/*
NISHIHARU
*/
`timescale 1ns / 1ps
//`define GPIO

// =====================================================================================
// Top module
// =====================================================================================
module RV32IM(
    input wire clock,
    input wire reset_n,
    //output wire [31:0] pc_out,
    //output wire [31:0] op_out,
    //output wire [31:0] alu_out,
    output wire [8:0] uart_out,
    input wire [31:0] gpio_in
);
    // 追加: VCD ダンプ用ブロック
    initial begin
        $dumpfile("rv32im.vcd");  // 出力するVCDファイル名
        $dumpvars(0, RV32IM);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
    end

    // GPIO ADDR
    localparam [31:0] GPIO_ADDR = 32'd1022 ; // ADDRESS for UART DATA

    // ===============================================================
    // State counter
    localparam IDLE     = 0;
    localparam FETCH    = 1;
    localparam DECODE   = 2;
    localparam EXECUTE  = 3;
    localparam BRANCH   = 4;
    localparam STORE    = 5;

    reg [3:0]  state, state2, state3, state4;
    wire dual_enb = dual_enb_a & dual_enb_b;
    wire dual_enb2 = dual_enb_b & dual_enb_c;
    wire dual_enb3 = dual_enb_c & dual_enb_d;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            state <= FETCH;
            state2 <= IDLE;
            state3 <= IDLE;
            state4 <= IDLE;
        end else begin
            // state
            case(state)
                IDLE:   
                    if(state2==IDLE) begin
                        state <= FETCH;
                    end
                FETCH:      state <= DECODE;
                DECODE:     state <= EXECUTE;
                EXECUTE:    state <= BRANCH;
                BRANCH:     state <= STORE;
                STORE:      state <= IDLE;
            endcase
            // state2
            case(state2)
                IDLE:
                    if(dual_enb && state==DECODE) begin
                        state2 <= DECODE;
                    end
                FETCH:      state2 <= DECODE;
                DECODE:     state2 <= EXECUTE;
                EXECUTE:    state2 <= BRANCH;
                BRANCH:     state2 <= STORE;
                STORE:      state2 <= IDLE;
            endcase
            // state3
            case(state3)
                IDLE:
                    if(dual_enb2 && state2==DECODE) begin
                        state3 <= DECODE;
                    end
                FETCH:      state3 <= DECODE;
                DECODE:     state3 <= EXECUTE;
                EXECUTE:    state3 <= BRANCH;
                BRANCH:     state3 <= STORE;
                STORE:      state3 <= IDLE;
            endcase
            // state4
            case(state4)
                IDLE:
                    if(dual_enb3 && state3==DECODE) begin
                        state4 <= DECODE;
                    end
                FETCH:      state4 <= DECODE;
                DECODE:     state4 <= EXECUTE;
                EXECUTE:    state4 <= BRANCH;
                BRANCH:     state4 <= STORE;
                STORE:      state4 <= IDLE;
            endcase
        end
    end

    wire decode_enb     = (state==DECODE) | (state2==DECODE) | (state3==DECODE)  | (state4==DECODE);
    wire execute_enb    = (state==EXECUTE) | (state2==EXECUTE) | (state3==EXECUTE)  | (state4==EXECUTE);
    wire branch_enb     = (state==BRANCH) | (state2==BRANCH) | (state3==BRANCH)  | (state4==BRANCH);
    wire store_enb      = (state==STORE) | (state2==STORE) | (state3==STORE)  | (state4==STORE);

    // ===============================================================
    // REGISTER MEM
    reg [31:0] pc_reg;
    //assign pc_out = pc; // for DEBUG
    reg [31:0] regs[0:31];

    // MEMORY 2048 word
    reg [7:0] mem[0:2047]; // MEMORY 2048 word
    initial $readmemh("program.hex", mem); // MEMORY INITIALIZE

    // ===============================================================
    // UART OUTPUT and CYCLE COUNTER
    reg [8:0] uart = 9'b0; // uart[8] for output sign, uart[7:0] for data
    assign uart_out = uart;

    // ===============================================================
    // 1: FETCH
    wire [31:0] pc = pc_out;
    reg [31:0] opcode1, opcode2, opcode3, opcode4;
    reg [31:0] counter_reg;
    //assign opcode = {mem[pc + 3], mem[pc + 2], mem[pc + 1], mem[pc]}; // little endian
    //assign op_out = opcode; // for DEBUG


    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            opcode1 <= 32'h0;
            opcode2 <= 32'h0;
            opcode3 <= 32'h0;
            opcode4 <= 32'h0;
            pc_reg  <= 32'h0;
            counter_reg <= 32'h0;
        end else begin
            if(state==FETCH) begin
                opcode1 <= {mem[pc + 3], mem[pc + 2], mem[pc + 1], mem[pc]};        // little endian
                opcode2 <= {mem[pc + 7], mem[pc + 6], mem[pc + 5], mem[pc + 4]};    // little endian
                opcode3 <= {mem[pc + 11], mem[pc + 10], mem[pc + 9], mem[pc + 8]};    // little endian
                opcode4 <= {mem[pc + 15], mem[pc + 14], mem[pc + 13], mem[pc + 12]};    // little endian
                pc_reg  <= pc_out;
                counter_reg <= counter;
            end
        end
    end

    // ===============================================================
    // 2: DECODE

    reg [4:0] r_addr1;
    reg [4:0] r_addr2; 
    reg [4:0] w_addr;
    reg [31:0] imm;
    reg [4:0] alucon;
    reg [2:0] funct3;
    reg op1sel, op2sel, mem_rw, rf_wen;
    reg [1:0] wb_sel;
    reg [1:0] pc_sel;

    wire [4:0] r_addr1_a, r_addr1_b, r_addr1_c, r_addr1_d;
    wire [4:0] r_addr2_a, r_addr2_b, r_addr2_c, r_addr2_d; 
    wire [4:0] w_addr_a, w_addr_b, w_addr_c, w_addr_d;
    wire [31:0] imm_a, imm_b, imm_c, imm_d;
    wire [4:0] alucon_a, alucon_b, alucon_c, alucon_d;
    wire [2:0] funct3_a, funct3_b, funct3_c, funct3_d;
    wire op1sel_a, op2sel_a, mem_rw_a, rf_wen_a;
    wire op1sel_b, op2sel_b, mem_rw_b, rf_wen_b;
    wire op1sel_c, op2sel_c, mem_rw_c, rf_wen_c;
    wire op1sel_d, op2sel_d, mem_rw_d, rf_wen_d;
    wire [1:0] wb_sel_a, wb_sel_b, wb_sel_c, wb_sel_d;
    wire [1:0] pc_sel_a, pc_sel_b, pc_sel_c, pc_sel_d;
    wire dual_enb_a, dual_enb_b, dual_enb_c, dual_enb_d;

    Decorder dec1(
        .clock(clock), .reset_n(reset_n), .decode_enb(decode_enb), .opcode(opcode1),
        // output 
        .r_addr1(r_addr1_a), .r_addr2(r_addr2_a), .w_addr(w_addr_a), .imm(imm_a), .alucon(alucon_a), .funct3(funct3_a), .op1sel(op1sel_a), 
        .op2sel(op2sel_a), .mem_rw(mem_rw_a), .rf_wen(rf_wen_a), .wb_sel(wb_sel_a), .pc_sel(pc_sel_a), .dual_enb(dual_enb_a)
    );

    Decorder dec2(
        .clock(clock), .reset_n(reset_n), .decode_enb(decode_enb), .opcode(opcode2),
        // output 
        .r_addr1(r_addr1_b), .r_addr2(r_addr2_b), .w_addr(w_addr_b), .imm(imm_b), .alucon(alucon_b), .funct3(funct3_b), .op1sel(op1sel_b), 
        .op2sel(op2sel_b), .mem_rw(mem_rw_b), .rf_wen(rf_wen_b), .wb_sel(wb_sel_b), .pc_sel(pc_sel_b), .dual_enb(dual_enb_b)
    );

    Decorder dec3(
        .clock(clock), .reset_n(reset_n), .decode_enb(decode_enb), .opcode(opcode3),
        // output 
        .r_addr1(r_addr1_c), .r_addr2(r_addr2_c), .w_addr(w_addr_c), .imm(imm_c), .alucon(alucon_c), .funct3(funct3_c), .op1sel(op1sel_c), 
        .op2sel(op2sel_c), .mem_rw(mem_rw_c), .rf_wen(rf_wen_c), .wb_sel(wb_sel_c), .pc_sel(pc_sel_c), .dual_enb(dual_enb_c)
    );

    Decorder dec4(
        .clock(clock), .reset_n(reset_n), .decode_enb(decode_enb), .opcode(opcode4),
        // output 
        .r_addr1(r_addr1_d), .r_addr2(r_addr2_d), .w_addr(w_addr_d), .imm(imm_d), .alucon(alucon_d), .funct3(funct3_d), .op1sel(op1sel_d), 
        .op2sel(op2sel_d), .mem_rw(mem_rw_d), .rf_wen(rf_wen_d), .wb_sel(wb_sel_d), .pc_sel(pc_sel_d), .dual_enb(dual_enb_d)
    );
    
    reg [31:0] pc_reg_decode;
    reg [31:0] counter_decode;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            pc_reg_decode <= 0;
            counter_decode <= 0;
        end else begin
            if(state==DECODE) begin
                pc_reg_decode <= pc_reg;
                counter_decode <= counter_reg;
            end else if(state2==DECODE) begin
                pc_reg_decode <= pc_reg + 4;
                counter_decode <= counter_reg + 1;
            end else if(state3==DECODE) begin
                pc_reg_decode <= pc_reg + 8;
                counter_decode <= counter_reg + 2;
            end else if(state4==DECODE) begin
                pc_reg_decode <= pc_reg + 12;
                counter_decode <= counter_reg + 3;
            end
        end
    end

    // ===============================================================
    // 3: EXECUTION
    
    always @(*) begin
        case (1'b1)
            (state == EXECUTE): begin
                r_addr1 <= r_addr1_a;
                r_addr2 <= r_addr2_a;
                w_addr  <= w_addr_a;
                imm     <= imm_a;
                alucon  <= alucon_a;
                funct3  <= funct3_a;
                op1sel  <= op1sel_a;
                op2sel  <= op2sel_a;
                mem_rw  <= mem_rw_a;
                rf_wen  <= rf_wen_a;
                wb_sel  <= wb_sel_a;
                pc_sel  <= pc_sel_a;
            end
            (state2 == EXECUTE): begin
                r_addr1 <= r_addr1_b;
                r_addr2 <= r_addr2_b;
                w_addr  <= w_addr_b;
                imm     <= imm_b;
                alucon  <= alucon_b;
                funct3  <= funct3_b;
                op1sel  <= op1sel_b;
                op2sel  <= op2sel_b;
                mem_rw  <= mem_rw_b;
                rf_wen  <= rf_wen_b;
                wb_sel  <= wb_sel_b;
                pc_sel  <= pc_sel_b;
            end
            (state3 == EXECUTE): begin
                r_addr1 <= r_addr1_c;
                r_addr2 <= r_addr2_c;
                w_addr  <= w_addr_c;
                imm     <= imm_c;
                alucon  <= alucon_c;
                funct3  <= funct3_c;
                op1sel  <= op1sel_c;
                op2sel  <= op2sel_c;
                mem_rw  <= mem_rw_c;
                rf_wen  <= rf_wen_c;
                wb_sel  <= wb_sel_c;
                pc_sel  <= pc_sel_c;
            end
            (state4 == EXECUTE): begin
                r_addr1 <= r_addr1_d;
                r_addr2 <= r_addr2_d;
                w_addr  <= w_addr_d;
                imm     <= imm_d;
                alucon  <= alucon_d;
                funct3  <= funct3_d;
                op1sel  <= op1sel_d;
                op2sel  <= op2sel_d;
                mem_rw  <= mem_rw_d;
                rf_wen  <= rf_wen_d;
                wb_sel  <= wb_sel_d;
                pc_sel  <= pc_sel_d;
            end
            default: begin
                r_addr1 <= 'b0;
                r_addr2 <= 'b0;
                w_addr  <= 'b0;
                imm     <= 'b0;
                alucon  <= 'b0;
                funct3  <= 'b0;
                op1sel  <= 'b0;
                op2sel  <= 'b0;
                mem_rw  <= 'b0;
                rf_wen  <= 'b0;
                wb_sel  <= 'b0;
                pc_sel  <= 'b0;
            end
        endcase
    end

    wire [31:0] alu_data;
    wire [31:0] reg_data_addr1;
    wire [31:0] reg_data_addr2;
    wire [31:0] r_data1_w, r_data2_w;
    wire [31:0] r_data1, r_data2;

    assign reg_data_addr1 = regs[r_addr1];
    assign reg_data_addr2 = regs[r_addr2];
    
    reg [1:0]   pc_sel_alu;
    reg [1:0]   wb_sel_alu;
    reg [2:0]   funct3_alu;
    reg         mem_rw_alu;
    reg         rf_wen_alu;
    reg [31:0]  pc_reg_alu;
    reg [31:0]  counter_alu;
    reg [4:0]   w_addr_alu;

    Execule exec1(
        .clock          (clock),
        .reset_n        (reset_n),
        .execute_enb    (execute_enb),
        .r_addr1        (r_addr1),
        .r_addr2        (r_addr2), 
        .reg_data_addr1 (reg_data_addr1),
        .reg_data_addr2 (reg_data_addr2),
        .op1sel         (op1sel), 
        .op2sel         (op2sel), 
        .alucon         (alucon),
        .imm            (imm),
        .pc             (pc_reg_decode),
        // output 
        .alu_data       (alu_data),
        .r_data1_w      (r_data1_w),
        .r_data2_w      (r_data2_w),
        .r_data1        (r_data1),
        .r_data2        (r_data2)
    );

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            pc_sel_alu <= 0;
            wb_sel_alu <= 0;
            funct3_alu <= 0;
            mem_rw_alu <= 0;
            rf_wen_alu <= 0;
            pc_reg_alu <= 0;
            w_addr_alu <= 0;
        end else begin
            pc_sel_alu <= pc_sel;
            wb_sel_alu <= wb_sel;
            funct3_alu <= funct3;
            mem_rw_alu <= mem_rw;
            rf_wen_alu <= rf_wen;
            pc_reg_alu <= pc_reg_decode;
            counter_alu  <= counter_decode;
            w_addr_alu <= w_addr;
        end
    end

    // ===============================================================
    // 4: BRANCH

    wire        pc_sel2;
    reg [1:0]   wb_sel_branch;
    reg [31:0]  alu_data_branch;
    reg [2:0]   funct3_branch;
    reg         mem_rw_branch;
    reg [31:0]  pc_reg_brach;
    reg [31:0]  r_data2_branch;
    reg [31:0]  counter_branch;
    reg         rf_wen_branch;    
    reg [4:0]   w_addr_branch;

    Branch branch1(
        .clock          (clock),
        .reset_n        (reset_n),
        .branch_enb     (branch_enb),
        .funct3         (funct3_alu),
        .r_data1        (r_data1),
        .r_data2        (r_data2),
        .pc_sel         (pc_sel_alu),
        // output 
        .pc_sel2        (pc_sel2)
    );

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            wb_sel_branch   <= 0;
            alu_data_branch <= 0;
            funct3_branch   <= 0;
            mem_rw_branch   <= 0;
            pc_reg_brach    <= 0;
            r_data2_branch  <= 0;
            counter_branch  <= 0;
            rf_wen_branch   <= 0;
            w_addr_branch   <= 0;
        end else begin
            wb_sel_branch <= wb_sel_alu;
            alu_data_branch <= alu_data;
            funct3_branch <= funct3_alu;
            mem_rw_branch   <= mem_rw_alu;
            pc_reg_brach    <= pc_reg_alu;
            r_data2_branch  <= r_data2;
            counter_branch  <= counter_alu;
            rf_wen_branch   <= rf_wen_alu;
            w_addr_branch   <= w_addr_alu;
        end
    end

    // ===============================================================
    // 5: STORE MEMORY
    localparam [31:0] UART_MMIO_ADDR = 32'h0000_fff0; // ADDRESS 0xfff0 for UART DATA
    localparam [31:0] UART_MMIO_FLAG = 32'h0000_fff1; // ADDRESS 0xfff1 for UART FLAG
    localparam [31:0] COUNTER_MMIO_ADDR = 32'h0000_fff4; // ADDRESS 0xfff4 for COUNTER

    integer i;
    wire [31:0] pc_out;
    wire [31:0] counter;
    wire [31:0] mem_data;
    wire [31:0] w_data;

    MemoryStore #(
        .COUNTER_MMIO_ADDR  (COUNTER_MMIO_ADDR),
        .UART_MMIO_FLAG     (UART_MMIO_FLAG),
        .COUNTER_MMIO_ADDR  (COUNTER_MMIO_ADDR)
        ) memstore1(
        .clock          (clock),
        .reset_n        (reset_n),
        .store_enb      (store_enb),
        .mem_rw         (mem_rw_branch),
        .wb_sel         (wb_sel_branch),
        .pc_sel2        (pc_sel2),
        .alu_data       (alu_data_branch),
        .mem_val        (funct3_branch),
        .mem_data_p0    (mem[mem_addr]),
        .mem_data_p1    (mem[mem_addr + 1]),
        .mem_data_p2    (mem[mem_addr + 2]),
        .mem_data_p3    (mem[mem_addr + 3]),
        .r_data2        (r_data2_branch),
        .gpio_in        (gpio_in),
        .pc             (pc_reg_brach),
        .counter        (counter_branch),
        // output 
        .w_data         (w_data),
        .pc_out         (pc_out),
        .counter_out    (counter)
);

    wire [31:0] mem_addr;
    assign mem_addr = alu_data_branch;

    // MEMORY WRITE
    always @(posedge clock) begin
        if(store_enb) begin
            if (mem_rw_branch == 1'b1) begin
                case (funct3_branch)
                    3'b000: // SB
                        mem[mem_addr] <= r_data2_branch[7:0];
                    3'b001: // SH
                        {mem[mem_addr + 1], mem[mem_addr]} <= r_data2_branch[15:0];
                    3'b010: // SW
                        {mem[mem_addr + 3], mem[mem_addr + 2], mem[mem_addr + 1], mem[mem_addr]} <= r_data2_branch;
                    default: begin end // ILLEGAL
                endcase
            end 
            // MEMORY MAPPED IO to UART
            if ((mem_rw_branch == 1'b1) && (mem_addr == UART_MMIO_ADDR)) begin
                uart <= {1'b1, r_data2_branch[7:0]};
            end else begin
                uart <= 9'b0;
            end
        end
    end

    localparam [15:0] SP_INIT_DATA = 16'h04FF;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                if(i == 2) begin
                    regs[i] <= SP_INIT_DATA;     // SP 
                end else begin
                    regs[i] <= 32'h0;
                end
            end
        end else begin
            if(store_enb) begin
                if ((rf_wen_branch == 1'b1) && (w_addr_branch != 5'b00000))
                    regs[w_addr_branch] <= w_data;
            end
        end
    end

    // Debug out
    wire [31:0] reg0 = regs[0];
    wire [31:0] reg1 = regs[1];
    wire [31:0] reg2 = regs[2];
    wire [31:0] reg3 = regs[3];
    wire [31:0] reg4 = regs[4];
    wire [31:0] reg5 = regs[5];
    wire [31:0] reg6 = regs[6];
    wire [31:0] reg7 = regs[7];
    wire [31:0] reg8 = regs[8];
    wire [31:0] reg9 = regs[9];
    wire [31:0] reg10 = regs[10];
    wire [31:0] reg11 = regs[11];
    wire [31:0] reg12 = regs[12];
    wire [31:0] reg13 = regs[13];
    wire [31:0] reg14 = regs[14];
    wire [31:0] reg15 = regs[15];

endmodule


// =====================================================================================
// Sub module
// =====================================================================================
module Decorder(
    input wire clock,
    input wire reset_n,
    input wire decode_enb,
    input wire [31:0] opcode,
    // output 
    output reg [4:0] r_addr1, 
    output reg [4:0] r_addr2, 
    output reg [4:0] w_addr,
    output reg [31:0] imm,
    output reg [4:0] alucon,
    output reg [2:0] funct3,
    output reg op1sel, 
    output reg op2sel, 
    output reg mem_rw, 
    output reg rf_wen,
    output reg [1:0] wb_sel,
    output reg [1:0] pc_sel,
    output reg dual_enb
);

// 2: DECODE
    wire [4:0] r_addr1_w, r_addr2_w, w_addr_w;
    wire [31:0] imm_w;
    wire [4:0] alucon_w;
    wire [2:0] funct3_w;
    wire op1sel_w, op2sel_w, mem_rw_w, rf_wen_w;
    wire [1:0] wb_sel_w, pc_sel_w;

    // reg
    wire [6:0] op;
    assign op = opcode[6:0];

    localparam [6:0] RFORMAT       = 7'b0110011;
    localparam [6:0] IFORMAT_ALU   = 7'b0010011;
    localparam [6:0] IFORMAT_LOAD  = 7'b0000011;
    localparam [6:0] SFORMAT       = 7'b0100011;
    localparam [6:0] SBFORMAT      = 7'b1100011;
    localparam [6:0] UFORMAT_LUI   = 7'b0110111;
    localparam [6:0] UFORMAT_AUIPC = 7'b0010111;
    localparam [6:0] UJFORMAT      = 7'b1101111;
    localparam [6:0] IFORMAT_JALR  = 7'b1100111;
    localparam [6:0] ECALLEBREAK   = 7'b1110011;
    localparam [6:0] FENCE         = 7'b0001111;
    localparam [6:0] MULDIV        = 7'b0110011;

    assign r_addr1_w = (op == UFORMAT_LUI) ? 5'b0 : opcode[19:15];
    assign r_addr2_w = opcode[24:20];
    assign w_addr_w  = opcode[11:7];

    assign imm_w[31:20] = ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC)) ? opcode[31:20] :
                          (opcode[31] == 1'b1) ? 12'hfff : 12'b0;
    assign imm_w[19:12] = ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC) || (op == UJFORMAT)) ? opcode[19:12] :
                          (opcode[31] == 1'b1) ? 8'hff : 8'b0;
    assign imm_w[11] = (op == SBFORMAT) ? opcode[7] :
                       ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC)) ? 1'b0 :
                       (op == UJFORMAT) ? opcode[20] : opcode[31];
    assign imm_w[10:5] = ((op == UFORMAT_LUI) || (op == UFORMAT_AUIPC)) ? 6'b0 : opcode[30:25];
    assign imm_w[4:1]  = ((op == IFORMAT_ALU) || (op == IFORMAT_LOAD) || (op == IFORMAT_JALR) || (op == UJFORMAT))
                       ? opcode[24:21] :
                       ((op == SFORMAT) || (op == SBFORMAT)) ? opcode[11:8] : 4'b0;
    assign imm_w[0]    = ((op == IFORMAT_ALU) || (op == IFORMAT_LOAD) || (op == IFORMAT_JALR))
                         ? opcode[20] :
                         (op == SFORMAT) ? opcode[7] : 1'b0;

    assign alucon_w = ((op == RFORMAT) || (op == MULDIV))
                      ? {opcode[30], opcode[25], opcode[14:12]} :
                      ((op == IFORMAT_ALU) && (opcode[14:12] == 3'b101))
                      ? {opcode[30], opcode[25], opcode[14:12]} : // SRLI or SRAI
                      (op == IFORMAT_ALU)
                      ? {2'b00, opcode[14:12]} : 5'b0;

    assign funct3_w = opcode[14:12];
    assign op1sel_w = ((op == SBFORMAT) || (op == UFORMAT_AUIPC) || (op == UJFORMAT)) ? 1'b1 : 1'b0;
    assign op2sel_w = ((op == RFORMAT) || (op == MULDIV)) ? 1'b0 : 1'b1;
    assign mem_rw_w = (op == SFORMAT) ? 1'b1 : 1'b0;
    assign wb_sel_w = (op == IFORMAT_LOAD) ? 2'b01 :
                      ((op == UJFORMAT) || (op == IFORMAT_JALR)) ? 2'b10 : 2'b00;
    assign rf_wen_w = (
                        ((op == RFORMAT) && ({opcode[31], opcode[29:25]} == 6'b000000)) ||
                        ((op == MULDIV) && (opcode[31:25] == 7'b000001)) ||
                        ((op == IFORMAT_ALU) &&
                         (
                          ({opcode[31:25], opcode[14:12]} == 10'b00000_00_001) ||
                          ({opcode[31], opcode[29:25], opcode[14:12]} == 9'b0_000_00_101) ||  // SLLI or SRLI or SRAI
                          (opcode[14:12] == 3'b000) ||
                          (opcode[14:12] == 3'b010) ||
                          (opcode[14:12] == 3'b011) ||
                          (opcode[14:12] == 3'b100) ||
                          (opcode[14:12] == 3'b110) ||
                          (opcode[14:12] == 3'b111)
                        )
                        ) ||
                        (op == IFORMAT_LOAD) || (op == UFORMAT_LUI) || (op == UFORMAT_AUIPC) ||
                        (op == UJFORMAT) || (op == IFORMAT_JALR)
                      )
                      ? 1'b1 : 1'b0;
    assign pc_sel_w = (op == SBFORMAT) ? 2'b01 :
                    ((op == UJFORMAT) || (op == IFORMAT_JALR) || (op == ECALLEBREAK)) ? 2'b10 : 2'b00;

    // Pipeline dual ok
    wire dual_enb_w;
    assign dual_enb_w = (((op == IFORMAT_LOAD) && (funct3_w == 3'b010)) || (op == SFORMAT))  ? 1'b1 : 1'b0;
    //assign dual_enb_w = (((op == IFORMAT_LOAD) && (funct3_w == 3'b010)))  ? 1'b1 : 1'b0;


    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            r_addr1 <= 0; 
            r_addr2 <= 0;
            w_addr  <= 0;
            imm     <= 0;
            alucon  <= 0;
            funct3  <= 0;
            op1sel  <= 0; 
            op2sel  <= 0; 
            mem_rw  <= 0; 
            rf_wen  <= 0;
            wb_sel  <= 0; 
            pc_sel  <= 0;
            dual_enb <= 0;
        end else begin
            if(decode_enb) begin
                r_addr1 <= r_addr1_w; 
                r_addr2 <= r_addr2_w;
                w_addr  <= w_addr_w;
                imm     <= imm_w;
                alucon  <= alucon_w;
                funct3  <= funct3_w;
                op1sel  <= op1sel_w; 
                op2sel  <= op2sel_w; 
                mem_rw  <= mem_rw_w; 
                rf_wen  <= rf_wen_w;
                wb_sel  <= wb_sel_w; 
                pc_sel  <= pc_sel_w;
                dual_enb <= dual_enb_w;
            end
        end
    end
endmodule

// =====================================================================================
module Execule(
    input wire clock,
    input wire reset_n,
    input wire execute_enb,
    input wire [4:0]  r_addr1,
    input wire [4:0]  r_addr2,
    input wire [31:0] reg_data_addr1,
    input wire [31:0] reg_data_addr2,
    input wire op1sel,
    input wire op2sel,
    input wire [4:0]  alucon,
    input wire [31:0] imm,
    input wire [31:0] pc,
    // output 
    output reg [31:0] alu_data,
    output reg [31:0] r_data1_w,
    output reg [31:0] r_data2_w,
    output reg [31:0] r_data1,
    output reg [31:0] r_data2
);

    // REGISTER READ
    assign r_data1_w = (r_addr1 == 5'b00000) ? 32'b0 : reg_data_addr1;
    assign r_data2_w = (r_addr2 == 5'b00000) ? 32'b0 : reg_data_addr2;

    // SELECTOR
    wire [31:0] s_data1_w;
    wire [31:0] s_data1_w1, s_data1_w2, s_data2_w;
    reg  [31:0] s_data1, s_data2;
    assign s_data1_w = (op1sel == 1'b1) ? pc: r_data1_w;
    assign s_data2_w = (op2sel == 1'b1) ? imm : r_data2_w;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            alu_data <= 0; 
            r_data1  <= 0;
            r_data2  <= 0;
            s_data1  <= 0;
            s_data2  <= 0;
        end else begin
            if(execute_enb) begin
                alu_data <= ALU_EXEC(alucon, s_data1_w, s_data2_w);
                r_data1  <= r_data1_w;
                r_data2  <= r_data2_w;
                s_data1  <= s_data1_w;
                s_data2  <= s_data2_w;
            end
        end
    end
endmodule

// =====================================================================================
function [31:0] ALU_EXEC(
    input [4:0] control,
    input [31:0] data1,
    input [31:0] data2
);
    reg [63:0] tmpalu;
    case (control)
        5'b00000: // ADD / ADDI (ADD)
            ALU_EXEC = data1 + data2;
        5'b10000: // SUB
            ALU_EXEC = data1 - data2;
        5'b00001: // SLL / SLLI (SHIFT LEFT (LOGICAL))
            ALU_EXEC = data1 << data2[4:0];
        5'b00010: // SLT / SLTI (SIGNED)
            ALU_EXEC = ($signed(data1) < $signed(data2)) ? 32'b1 : 32'b0;
        5'b00011: // SLTU / SLTUI (UNSIGNED)
            ALU_EXEC = (data1 < data2) ? 32'b1 : 32'b0;
        5'b00100: // XOR / XORI
            ALU_EXEC = data1 ^ data2;
        5'b00101: // SRL / SRLI (LOGICAL)
            ALU_EXEC = data1 >> data2[4:0];
        5'b10101: // SRA / SRAI (ARITHMETIC)
            ALU_EXEC = $signed(data1[31:0]) >>> data2[4:0];
        5'b00110: // OR / ORI
            ALU_EXEC = data1 | data2;
        5'b00111: // AND / ANDI
            ALU_EXEC = data1 & data2;
        5'b01000: // MUL
            ALU_EXEC = data1 * data2;
        5'b01001: begin // MULH
            tmpalu = $signed(data1) * $signed(data2);
            ALU_EXEC = $signed(tmpalu) >>> 32;
        end
        5'b01010: begin // MULHSU
            tmpalu = $signed(data1) * $signed({1'b0, data2});
            ALU_EXEC = tmpalu >> 32;
        end
        5'b01011: begin // MULHU
            tmpalu = data1 * data2;
            ALU_EXEC = tmpalu >> 32;
        end
        5'b01100: // DIV (SIGNED)
            ALU_EXEC = (data2 == 32'b0)
                        ? 32'hffff_ffff
                        : (
                            (data1 == 32'h8000_0000 && data2 == 32'hffff_ffff)
                            ? 32'h8000_0000
                            : $signed($signed(data1) / $signed(data2))
                            );
        5'b01101: // DIVU (UNSIGNED)
            ALU_EXEC = (data2 == 32'b0)
                        ? 32'hffff_ffff
                        : (data1 / data2);
        5'b01110: // REM (SIGNED)
            ALU_EXEC = (data2 == 32'b0)
                        ? data1
                        : (
                            (data1 == 32'h8000_0000 && data2 == 32'hffff_ffff)
                            ? 32'h0
                            : $signed($signed(data1) % $signed(data2))
                            );
        5'b01111: // REMU (UNSIGNED)
            ALU_EXEC = (data2 == 32'b0)
                        ? data1
                        : (data1 % data2);
        default:  // ILLEGAL
            ALU_EXEC = 32'b0;
    endcase
endfunction

// =====================================================================================
module Branch(
    input wire clock,
    input wire reset_n,
    input wire branch_enb,
    input wire [2:0] funct3,
    input wire [31:0] r_data1,
    input wire [31:0] r_data2,
    input wire [1:0] pc_sel,
    // output 
    output reg pc_sel2
);
    
    function BRANCH_EXEC(
        input [2:0] branch_op,
        input [31:0] data1,
        input [31:0] data2,
        input [1:0] pc_sel
    );
        case (pc_sel)
            2'b00: // PC + 4
                BRANCH_EXEC = 1'b0;
            2'b01: begin // BRANCH
                case (branch_op)
                    3'b000: // BEQ
                        BRANCH_EXEC = (data1 == data2) ? 1'b1 : 1'b0;
                    3'b001: // BNE
                        BRANCH_EXEC = (data1 != data2) ? 1'b1 : 1'b0;
                    3'b100: // BLT (SIGNED)
                        BRANCH_EXEC = ($signed(data1) < $signed(data2)) ? 1'b1 : 1'b0;
                    3'b101: // BGE (SIGNED)
                        BRANCH_EXEC = ($signed(data1) >= $signed(data2)) ? 1'b1 : 1'b0;
                    3'b110: // BLTU (UNSIGNED)
                        BRANCH_EXEC = (data1 < data2) ? 1'b1 : 1'b0;
                    3'b111: // BGEU (UNSIGNED)
                        BRANCH_EXEC = (data1 >= data2) ? 1'b1 : 1'b0;
                    default: // ILLEGAL
                        BRANCH_EXEC = 1'b0;
                endcase
            end
            2'b10: // JAL / JALR
                BRANCH_EXEC = 1'b1;
            default: // ILLEGAL
                BRANCH_EXEC = 1'b0;
        endcase
    endfunction

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            pc_sel2   <= 0;
        end else begin
            if(branch_enb) begin
                pc_sel2 <= BRANCH_EXEC(funct3, r_data1, r_data2, pc_sel);
            end
        end
    end

endmodule

// =====================================================================================
module MemoryStore #(
    parameter UART_MMIO_ADDR    = 32'h0000_fff0,
    parameter UART_MMIO_FLAG    = 32'h0000_fff1,
    parameter COUNTER_MMIO_ADDR = 32'h0000_fff4
    )(
    input wire clock,
    input wire reset_n,
    input wire store_enb,
    input wire mem_rw,
    input wire [1:0] wb_sel,
    input wire pc_sel2,
    input wire [31:0] alu_data,
    input wire [2:0]  mem_val,
    input wire [7:0] mem_data_p0,
    input wire [7:0] mem_data_p1,
    input wire [7:0] mem_data_p2,
    input wire [7:0] mem_data_p3,
    input wire [31:0] r_data2,
    input wire [31:0] gpio_in,
    input wire [31:0] pc,
    input wire [31:0] counter,
    // output 
    output wire [31:0] w_data,
    output reg [31:0] pc_out,
    output reg [31:0] counter_out
);
    wire [31:0] mem_data;
    wire [31:0] mem_addr;
    assign mem_addr = alu_data;

    // MEMORY READ
    assign mem_data = (mem_rw == 1'b1)
                      ? 32'b0 // when MEMORY WRITE, the output from MEMORY is 32'b0
                      : (
                          // MEMORY MAPPED IO for CLOCK CYCLE COUNTER
                          ((mem_val == 3'b010) && (mem_addr == COUNTER_MMIO_ADDR))
                          ? counter :
                          // MEMORY MAPPED IO for UART FLAG (always 1)
                          ((mem_val[1:0] == 2'b00) && (mem_addr == UART_MMIO_FLAG))
                          ? 8'b1 :
                          (mem_val == 3'b000)
                          ? (
                              mem_data_p0[7] == 1'b1
                              ? {24'hffffff, mem_data_p0}
                              : {24'h000000, mem_data_p0}
                            ) : // LB
                          (mem_val == 3'b001)
                          ? (
                              mem_data_p1[7] == 1'b1
                              ? {16'hffff, mem_data_p1, mem_data_p0}
                              : {16'h0000, mem_data_p1, mem_data_p0}
                            ) : // LH
                          (mem_val == 3'b010)
                          ? {mem_data_p3, mem_data_p2, mem_data_p1, mem_data_p0} : // LW
                          (mem_val == 3'b100)
                          ? {24'h000000, mem_data_p0} : // LBU
                          (mem_val == 3'b101)
                          ? {16'h0000, mem_data_p1, mem_data_p0} : // LHU
                          32'b0
                        );

    // REGISTER WRITE BACK
    assign w_data = (wb_sel == 2'b00)
                    ? alu_data
                    : (wb_sel == 2'b01)
                      ? mem_data
                      : (wb_sel == 2'b10)
                        ? pc + 4
                        : 32'b0; // ILLEGAL

    // NEXT PC
    wire [31:0] next_pc;
    wire [31:0] next_counter;
    assign next_pc = (pc_sel2 == 1'b1) ? {alu_data[31:1], 1'b0} : pc + 4;
    assign next_counter = counter + 1;

    // NEXT PC WRITE BACK and CYCLE COUNTER
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc_out      <= 32'b0;
            counter_out <= 32'b0;
        end else begin
            if(store_enb) begin
                pc_out      <= next_pc;
                counter_out <= next_counter;
            end
        end
    end

endmodule
