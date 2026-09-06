module baud_gen #(
//the #() syntax is how Verilog passes parameters into a module. 
//So, anyone using this module can override these values without touching the source code.

    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
    )(
    input wire clk,
    input wire reset,
    output reg tick                   //tick — fires HIGH for exactly one clock cycle every 5208 cycles. This is the heartbeat that drives the UART transmitter.
    );

    // How many clock cycles per one UART bit

    localparam DIVIDER = (CLK_FREQ / BAUD_RATE) - 1;    //The -1 is because the counter starts at 0, so counting 0→5207 is 5208 steps.
    reg [15:0] counter;                                 //16-bit counter, can hold up to 65535. Enough for any reasonable baud rate.

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick <= 0;
        end
        else if (counter == DIVIDER) begin
            counter <= 0;
            tick <= 1;
        end
        else begin
            counter <= counter + 1;
            tick <= 0;
        end
    end

endmodule

// This module generates a tick signal at the specified baud rate. 
//It counts clock cycles and asserts the tick output when the count reaches the calculated divider value. 
//The counter resets on a reset signal or when it reaches the divider value, ensuring continuous operation.
// Therefore, "The tick is a single-cycle pulse, not a sustained HIGH, so the transmitter advances exactly one bit per baud period without being affected by the clock frequency."