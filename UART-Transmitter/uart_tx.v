module uart_tx #(                             // #(parameter ...) — this is parameterized module syntax.
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600,
    parameter PARITY = 0,
    parameter STOP_BITS = 1
    )(
    input wire     clk,
    input wire     reset,
    input wire     send,
    input wire [7:0] data,
    output reg     tx,
    output reg     tx_busy,
    output reg     tx_done
    );

// State encoding 

    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam DATA = 3'd2;
    localparam PAR = 3'd3;
    localparam STOP1 = 3'd4;
    localparam STOP2 = 3'd5;

// Internal registers 

    reg [2:0] state;       // 3-bit register storing current FSM state. 3 bits because we have 6 states
    reg [7:0] shift_reg;   // holds the byte being transmitted. Bits get shifted out one by one during DATA state
    reg [2:0] bit_count;   // counts how many bits have been sent (0 to 7)
    reg       parity_bit;  // accumulates XOR of all data bits to calculate parity
    
    wire       baud_tick;   // wire that connects to the baud generator's tick output

// Instantiate baud rate generator

    baud_gen #(
        .CLK_FREQ(CLK_FREQ),    // passes the parameter from the outer module down into the inner module
        .BAUD_RATE(BAUD_RATE)
    ) baud_inst (
        .clk(clk),
        .reset(reset),
        .tick(baud_tick)
    );

// Main FSM

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            tx         <= 1;
            tx_busy    <= 0;
            tx_done    <= 0;
            bit_count  <= 0;
            shift_reg  <= 0;
            parity_bit <= 0;
        end
        else begin
            tx_done <=0;      // default: done is LOW unless explicitly set

            case (state)
                
                IDLE: begin
                    tx      <= 1;    // line HIGH when idle
                    tx_busy <= 0;
                    if (send) begin     // transmission triggered
                        shift_reg  <= data;
                        parity_bit <= ^data;    // XOR all bits = parity
                        tx_busy    <= 1;
                        state      <= START;
                    end
                end
                START: begin
                if (baud_tick) begin
                    tx    <= 0;      // pull line LOW = start bit
                    state <= DATA;
                end
            end

            DATA: begin
                if (baud_tick) begin
                    tx        <= shift_reg[0];    // send LSB first
                    shift_reg <= shift_reg >> 1;  // shift right
                    bit_count <= bit_count + 1;
                    if (bit_count == 7) begin     // all 8 bits sent
                        bit_count <= 0;
                        if (PARITY != 0)
                            state <= PARITY;
                        else
                            state <= STOP1;
                    end
                end
            end

            PAR: begin
                if (baud_tick) begin
                    if (PARITY == 1)
                        tx <= parity_bit;      // even parity
                    else
                        tx <= ~parity_bit;     // odd parity
                    state <= STOP1;
                end
            end

            STOP1: begin
                if (baud_tick) begin
                    tx <= 1;                   // stop bit = HIGH
                    if (STOP_BITS == 2)
                        state <= STOP2;
                    else begin
                        tx_done <= 1;          // single pulse
                        tx_busy <= 0;
                        state   <= IDLE;
                    end
                end
            end

            STOP2: begin
                if (baud_tick) begin
                    tx      <= 1;
                    tx_done <= 1;
                    tx_busy <= 0;
                    state   <= IDLE;
                end
            end

        endcase
    end
end

endmodule
                
