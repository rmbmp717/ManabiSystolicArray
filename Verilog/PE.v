module PE (
    // Clock & Reset
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,
    
    // B input
    input  wire [15:0]  b_reg,
    input  wire         b_we,

    // A / partial sum from left / top
    input  wire [15:0]  a_in,
    input  wire [15:0]  ps_in,

    // Output
    output wire [15:0]  a_shift_to_right,
    output wire [15:0]  partial_sum_to_bottom
);

    //========================================================
    // Internal Registers
    //========================================================
    reg [15:0] b_reg_internal;         // Register to hold B value
    reg [15:0] a_reg;                  // Register to hold A value
    reg [15:0] ps_reg;                 // Register to hold partial_sum

    // Registers for 5-stage pipeline (Assumes 1 multiplier takes 5 cycles to execute)
    reg [15:0] mul_pipe [0:4];         // mul_pipe[0] receives the initial input
    wire [15:0] mul_input;             // Multiplier input (A * B)
    reg [15:0] mul_result;             // Multiplier output (final result from 5th stage)

    //========================================================
    // B Register Write
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            b_reg_internal <= 16'd0;
        end else if (b_we) begin
            b_reg_internal <= b_reg;
        end
    end

    //========================================================
    // A Register & Shift (Right Shift)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'd0;
        end else if (data_clear) begin
            a_reg <= 16'd0;
        end else if (en_shift_right) begin
            // Load a_in from the left into the current register
            a_reg <= a_in;
        end
    end

    // Output: Pass a_reg to the right neighbor
    assign a_shift_to_right = a_reg;

    //========================================================
    // 5-stage Multiply Pipeline
    //========================================================
    assign mul_input = a_reg * b_reg_internal; // In practice, consider synthesis constraints such as multi-cycle

    integer i;
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 5; i=i+1) begin
                mul_pipe[i] <= 16'd0;
            end
        end else if (data_clear) begin
            for (i = 0; i < 5; i=i+1) begin
                mul_pipe[i] <= 16'd0;
            end
        end else begin
            // Shift register structure
            mul_pipe[0] <= mul_input;       // Stage 1
            mul_pipe[1] <= mul_pipe[0];    // Stage 2
            mul_pipe[2] <= mul_pipe[1];    // Stage 3
            mul_pipe[3] <= mul_pipe[2];    // Stage 4
            mul_pipe[4] <= mul_pipe[3];    // Stage 5
        end
    end

    // Final stage of the multiplier result
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            mul_result <= 16'd0;
        end else if (data_clear) begin
            mul_result <= 16'd0;
        end else begin
            mul_result <= mul_pipe[4];
        end
    end

    //========================================================
    // partial_sum Register & Shift (Downward Shift)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            ps_reg <= 16'd0;
        end else if (data_clear) begin
            ps_reg <= 16'd0;
        end else if (en_shift_bottom) begin
            // Add ps_in from above and the current mul_result
            // ps_reg = current ps_reg + ps_in + mul_result, depending on requirements
            ps_reg <= ps_in + mul_result;
        end
    end

    // Output: Pass partial_sum to the lower neighbor
    assign partial_sum_to_bottom = ps_reg;

endmodule
