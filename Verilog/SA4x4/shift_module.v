/*
NISHIHARU
*/

module shift_module #(
    parameter EN_SHIFT_ADDR = 8'h02
) (
    // Clock & Reset
    input  wire         Clock,
    input  wire         rst_n,
    // uart
    input wire          uart_rw,
    input wire [7:0]    uart_in,
    output wire         shift
);

reg shift_en;
reg shift_en_dly;

always @(posedge Clock or negedge rst_n) begin
    if (!rst_n) begin
        shift_en <= 0;
    end else if (uart_rw & (uart_in==EN_SHIFT_ADDR)) begin
        shift_en <= 1;
    end
end

always @(posedge Clock or negedge rst_n) begin
    if (!rst_n) begin
        shift_en_dly <= 0;
    end else begin
        shift_en_dly <= shift_en;
    end
end

assign  shift = !shift_en_dly & shift_en;

endmodule
