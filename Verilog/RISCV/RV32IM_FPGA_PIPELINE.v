`timescale 1ns / 1ps
`define DMA_ON

module RV32IM(
    input wire clock,
    input wire reset_n,
    //output wire [31:0] pc_out,
    //output wire [31:0] op_out,
    //output wire [31:0] alu_out,
    output wire [8:0] uart_out,
    input wire [31:0] DMA_in
);
/*
    // 追加: VCD ダンプ用ブロック
    initial begin
        $dumpfile("rv32im.vcd");  // 出力するVCDファイル名
        $dumpvars(0, RV32IM);     // 第1引数: 階層 (0 はこのモジュールを最上位として)
    end
*/

    // DMA ADDR
    localparam [31:0] DMA_ADDR = 32'h400 ; // ADDRESS for DMA ADDRESS

    // ===============================================================
    // State counter
    localparam FETCH    = 0;
    localparam DECODE   = 1;
    localparam EXECUTE  = 2;
    localparam BRANCH   = 3;
    localparam STORE    = 4;

    reg [3:0]  state;

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            state <= FETCH;
        end else begin
            case(state)
                FETCH:      state <= DECODE;
                DECODE:     state <= EXECUTE;
                EXECUTE:    state <= BRANCH;
                BRANCH:     state <= STORE;
                STORE:      state <= FETCH;
            endcase
        end
    end

    // REGISTER
    reg [31:0] pc;
    //assign pc_out = pc; // for DEBUG
    reg [31:0] regs[0:31];

    // MEMORY 2048 word
    reg [7:0] mem[0:2047]; // MEMORY 2048 word
    initial $readmemh("program.hex", mem); // MEMORY INITIALIZE

    // UART OUTPUT and CYCLE COUNTER
    reg [8:0] uart = 9'b0; // uart[8] for output sign, uart[7:0] for data
    assign uart_out = uart;

    localparam [31:0] UART_MMIO_ADDR = 32'h4F0; // ADDRESS for UART DATA
    localparam [31:0] UART_MMIO_FLAG = 32'h4F1; // ADDRESS for UART FLAG
    reg [31:0] counter = 32'b0;
    localparam [31:0] COUNTER_MMIO_ADDR = 32'h0000_fff4; // ADDRESS 0xfff4 for COUNTER

    // ===============================================================
    // FETCH
    reg [31:0] opcode;
    //assign opcode = {mem[pc + 3], mem[pc + 2], mem[pc + 1], mem[pc]}; // little endian
    //assign op_out = opcode; // for DEBUG

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            opcode <= 32'h0;
        end else begin
            if(state==FETCH) begin
                opcode <= {mem[pc + 3], mem[pc + 2], mem[pc + 1], mem[pc]}; // little endian
            end
        end
    end

    // ===============================================================
    // DECODE
    wire [4:0] r_addr1_w, r_addr2_w, w_addr_w;
    wire [31:0] imm_w;
    wire [4:0] alucon_w;
    wire [2:0] funct3_w;
    wire op1sel_w, op2sel_w, mem_rw_w, rf_wen_w;
    wire [1:0] wb_sel_w, pc_sel_w;

    // reg
    reg [4:0] r_addr1, r_addr2, w_addr;
    reg [31:0] imm;
    reg [4:0] alucon;
    reg [2:0] funct3;
    reg op1sel, op2sel, mem_rw, rf_wen;
    reg [1:0] wb_sel, pc_sel;

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
        end else begin
            if(state==DECODE) begin
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
            end
        end
    end

    // ===============================================================
    // EXECUTION

    // REGISTER READ
    wire [31:0] r_data1_w, r_data2_w;
    reg  [31:0] r_data1, r_data2;
    assign r_data1_w = (r_addr1 == 5'b00000) ? 32'b0 : regs[r_addr1];
    assign r_data2_w = (r_addr2 == 5'b00000) ? 32'b0 : regs[r_addr2];

    // SELECTOR
    wire [31:0] s_data1_w, s_data2_w;
    reg  [31:0] s_data1, s_data2;
    assign s_data1_w = (op1sel == 1'b1) ? pc : r_data1_w;
    assign s_data2_w = (op2sel == 1'b1) ? imm : r_data2_w;

    // ALU
    reg [31:0] alu_data;

    function [31:0] ALU_EXEC(
        input [4:0] control,
        input [31:0] data1,
        input [31:0] data2

    ); 
        reg  [63:0] tmpalu;
        reg  [31:0] data1_8b;
        reg  [31:0] data2_8b;
        reg  [31:0] data1_16b;
        reg  [31:0] data2_16b;

        begin
            data1_8b  = {{24'd0}, {data1[7:0]}};
            data2_8b  = {{24'd0}, {data2[7:0]}};
            data1_16b = {{16'd0}, {data1[15:0]}};
            data2_16b = {{16'd0}, {data2[15:0]}};

            case (control)
                5'b00000: // ADD / ADDI (ADD)
                    ALU_EXEC = data1 + data2;
                5'b10000: // SUB
                    ALU_EXEC = data1 - data2;
                5'b00001: // SLL / SLLI (SHIFT LEFT (LOGICAL))
                    ALU_EXEC = data1_8b << data2_8b[4:0];
                5'b00010: // SLT / SLTI (SIGNED)
                    ALU_EXEC = ($signed(data1_8b) < $signed(data2_8b)) ? 32'b1 : 32'b0;
                5'b00011: // SLTU / SLTUI (UNSIGNED)
                    ALU_EXEC = (data1_16b < data2_16b) ? 32'b1 : 32'b0;
                5'b00100: // XOR / XORI
                    ALU_EXEC = data1_16b ^ data2_16b;
                5'b00101: // SRL / SRLI (LOGICAL)
                    ALU_EXEC = data1_8b >> data2_8b[4:0];
                5'b10101: // SRA / SRAI (ARITHMETIC)
                    ALU_EXEC = $signed(data1_8b[31:0]) >>> data2_8b[4:0];
                5'b00110: // OR / ORI
                    ALU_EXEC = data1_16b | data2_16b;
                5'b00111: // AND / ANDI
                    ALU_EXEC = data1_16b & data2_16b;
                5'b01000: // MUL
                    ALU_EXEC = data1_8b * data2_8b;
                5'b01001: begin // MULH
                    tmpalu = $signed(data1_8b) * $signed(data2_8b);
                    ALU_EXEC = $signed(tmpalu) >>> 32;
                end
                5'b01010: begin // MULHSU
                    tmpalu = $signed(data1_8b) * $signed({1'b0, data2_8b});
                    ALU_EXEC = tmpalu >> 32;
                end
                5'b01011: begin // MULHU
                    tmpalu = data1_8b * data2_8b;
                    ALU_EXEC = tmpalu >> 32;
                end
                5'b01100: // DIV (SIGNED)
                    ALU_EXEC = (data2 == 32'b0)
                               ? 32'hffff_ffff
                               : (
                                   (data1 == 32'h8000_0000 && data2 == 32'hffff_ffff)
                                   ? 32'h8000_0000
                                   : $signed($signed(data1_8b) / $signed(data2_8b))
                                 );
                5'b01101: // DIVU (UNSIGNED)
                    ALU_EXEC = (data2 == 32'b0)
                               ? 32'hffff_ffff
                               : (data1_8b / data2_8b);
                5'b01110: // REM (SIGNED)
                    ALU_EXEC = (data2 == 32'b0)
                               ? data1
                               : (
                                   (data1 == 32'h8000_0000 && data2 == 32'hffff_ffff)
                                   ? 32'h0
                                   : $signed($signed(data1_8b) % $signed(data2_8b))
                                 );
                5'b01111: // REMU (UNSIGNED)
                    ALU_EXEC = (data2 == 32'b0)
                               ? data1
                                   : (data1_8b % data2_8b);
                default:  // ILLEGAL
                    ALU_EXEC = 32'b0;
            endcase
        end
    endfunction

    //assign alu_data = ALU_EXEC(alucon, s_data1, s_data2);
    //assign alu_out  = alu_data; // for DEBUG

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            alu_data <= 0; 
            r_data1  <= 0;
            r_data2  <= 0;
            s_data1  <= 0;
            s_data2  <= 0;
        end else begin
            if(state==EXECUTE) begin
                alu_data <= ALU_EXEC(alucon, s_data1_w, s_data2_w);
                r_data1  <= r_data1_w;
                r_data2  <= r_data2_w;
                s_data1  <= s_data1_w;
                s_data2  <= s_data2_w;
            end
        end
    end

    // ===============================================================
    // BRANCH
    reg pc_sel2;

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

    //assign pc_sel2 = BRANCH_EXEC(funct3, r_data1, r_data2, pc_sel);

    always @(posedge clock or negedge reset_n) begin
        if(!reset_n) begin
            pc_sel2 <= 0; 
        end else begin
            if(state==BRANCH) begin
                pc_sel2 <= BRANCH_EXEC(funct3, r_data1, r_data2, pc_sel);
            end
        end
    end

    // ===============================================================
    // MEMORY
    wire [2:0] mem_val;
    wire [31:0] mem_data;
    wire [31:0] mem_addr;
    assign mem_val  = funct3;
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
                              mem[mem_addr][7] == 1'b1
                              ? {24'hffffff, mem[mem_addr]}
                              : {24'h000000, mem[mem_addr]}
                            ) : // LB
                          (mem_val == 3'b001)
                          ? (
                              mem[mem_addr + 1][7] == 1'b1
                              ? {16'hffff, mem[mem_addr + 1], mem[mem_addr]}
                              : {16'h0000, mem[mem_addr + 1], mem[mem_addr]}
                            ) : // LH
                          (mem_val == 3'b010)
                          ? {mem[mem_addr + 3], mem[mem_addr + 2], mem[mem_addr + 1], mem[mem_addr]} : // LW
                          (mem_val == 3'b100)
                          ? {24'h000000, mem[mem_addr]} : // LBU
                          (mem_val == 3'b101)
                          ? {16'h0000, mem[mem_addr + 1], mem[mem_addr]} : // LHU
                          32'b0
                        );

    // MEMORY WRITE
    always @(posedge clock) begin
        if(state==STORE) begin
            if (mem_rw == 1'b1) begin
                case (mem_val)
                    3'b000: // SB
                        mem[mem_addr] <= r_data2[7:0];
                    3'b001: // SH
                        {mem[mem_addr + 1], mem[mem_addr]} <= r_data2[15:0];
                    3'b010: // SW
                        {mem[mem_addr + 3], mem[mem_addr + 2], mem[mem_addr + 1], mem[mem_addr]} <= r_data2;
                    default: begin end // ILLEGAL
                endcase
            end else begin
            // MEMORY MAPPED IO to GPIO
            `ifdef DMA_ON
                mem[DMA_ADDR]       <= DMA_in[7:0];
                mem[DMA_ADDR+1]     <= DMA_in[15:8];
                mem[DMA_ADDR+2]     <= DMA_in[23:16];
                mem[DMA_ADDR+3]     <= DMA_in[31:24];
            `endif
            end

            // MEMORY MAPPED IO to UART
            if ((mem_rw == 1'b1) && (mem_addr == UART_MMIO_ADDR)) begin
                uart <= {1'b1, r_data2[7:0]};
            end else begin
                uart <= 9'b0;
            end
        end
    end

    // REGISTER WRITE BACK
    wire [31:0] w_data;
    assign w_data = (wb_sel == 2'b00)
                    ? alu_data
                    : (wb_sel == 2'b01)
                      ? mem_data
                      : (wb_sel == 2'b10)
                        ? pc + 4
                        : 32'b0; // ILLEGAL

    integer i;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                if(i == 2) begin
                    regs[i] = 16'h04FF;     // SP <= 0x04FF
                end else begin
                    regs[i] <= 32'h0;
                end
            end
        end else begin
            if(state==STORE) begin
                if ((rf_wen == 1'b1) && (w_addr != 5'b00000))
                    regs[w_addr] <= w_data;
            end
        end
    end

    // NEXT PC
    wire [31:0] next_pc;
    assign next_pc = (pc_sel2 == 1'b1) ? {alu_data[31:1], 1'b0} : pc + 4;

    // NEXT PC WRITE BACK and CYCLE COUNTER
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pc      <= 32'b0;
            counter <= 32'b0;
        end else begin
            if(state==STORE) begin
                pc      <= next_pc;
                counter <= counter + 1;
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

    wire FETCH_state    = (state==FETCH)?    1 : 0;
    wire DECODE_state   = (state==DECODE)?   1 : 0;
    wire EXECUTE_state  = (state==EXECUTE)?  1 : 0;
    wire BRANCH_state   = (state==BRANCH)?   1 : 0;
    wire STORE_state    = (state==STORE)?    1 : 0;

endmodule
