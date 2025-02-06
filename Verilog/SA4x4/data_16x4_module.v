/*
NISHIHARU
*/

module data_16x4_module #(
    parameter DATA_WRITE_ADDR = 8'h02
) (
    // Clock & Reset
    input  wire         Clock,
    input  wire         rst_n,
    // uart
    input wire          uart_rw,
    input wire [7:0]    uart_in,
    output reg [15:0]   saved_data0,
    output reg [15:0]   saved_data1,
    output reg [15:0]   saved_data2,
    output reg [15:0]   saved_data3
);

reg uart_rw_reg;

// uart_rw
always @(posedge Clock or negedge rst_n) begin
    if (!rst_n) begin
        uart_rw_reg <= 0;
    end else begin
        uart_rw_reg <= uart_rw;
    end
end

assign  uart_en = !uart_rw_reg & uart_rw;

// Data Save statemachine
reg [3:0]  state;	
localparam IDLE = 0;
localparam DATA0_WAITING  = 1;
localparam DATA1_WAITING  = 2;
localparam DATA2_WAITING  = 3;
localparam DATA3_WAITING  = 4;

reg [3:0]  sub_state;	
localparam SUB_IDLE   = 0;
localparam WAITING_L  = 1;
localparam WAITING_H  = 2;

// save DATA 16bit
always @(posedge Clock or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        sub_state <= SUB_IDLE;
        saved_data0 <= 0;
        saved_data1 <= 0;
        saved_data2 <= 0;
        saved_data3 <= 0;
    end else begin
        case(state)
            IDLE: begin
                if(uart_en & (uart_in==DATA_WRITE_ADDR)) begin
                    state <= DATA0_WAITING;
                    sub_state <= WAITING_L;
                end
            end

            DATA0_WAITING: begin
                if(uart_en) begin
                    if(sub_state==WAITING_L) begin
                        saved_data0[7:0] <= uart_in;
                        sub_state <= WAITING_H;
                    end else begin
                        saved_data0[15:8] <= uart_in;
                        state <= DATA1_WAITING;
                        sub_state <= WAITING_L;
                    end
                end
            end

            DATA1_WAITING: begin
                if(uart_en) begin
                    if(sub_state==WAITING_L) begin
                        saved_data1[7:0] <= uart_in;
                        sub_state <= WAITING_H;
                    end else begin
                        saved_data1[15:8] <= uart_in;
                        state <= DATA2_WAITING;
                        sub_state <= WAITING_L;
                    end
                end
            end

            DATA2_WAITING: begin
                if(uart_en) begin
                    if(sub_state==WAITING_L) begin
                        saved_data2[7:0] <= uart_in;
                        sub_state <= WAITING_H;
                    end else begin
                        saved_data2[15:8] <= uart_in;
                        state <= DATA3_WAITING;
                        sub_state <= WAITING_L;
                    end
                end
            end

            DATA3_WAITING: begin
                if(uart_en) begin
                    if(sub_state==WAITING_L) begin
                        saved_data3[7:0] <= uart_in;
                        sub_state <= WAITING_H;
                    end else begin
                        saved_data3[15:8] <= uart_in;
                        state <= IDLE;
                        sub_state <= WAITING_L;
                    end
                end
            end

        endcase
    end
end

endmodule
