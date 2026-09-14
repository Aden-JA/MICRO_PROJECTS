// ============================================================
//  Synchronous FIFO
//  Parameterizable depth and data width
//  N+1 pointer trick for full/empty detection
//  Separate read/write always blocks — simultaneous R/W safe
// ============================================================
module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   write_en,
    input  wire                   read_en,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output reg  [DATA_WIDTH-1:0]  data_out,
    output wire                   full,
    output wire                   empty
);

    // ----------------------------------------------------------
    // PTR_WIDTH auto-calculated — no manual setting ever needed
    // $clog2(16) = 4 → 5-bit pointers for 16-deep FIFO
    // ----------------------------------------------------------
    localparam PTR_WIDTH = $clog2(DEPTH);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // N+1 bit pointers
    // Extra MSB acts as lap counter — solves full vs empty ambiguity
    reg [PTR_WIDTH:0] wr_ptr;
    reg [PTR_WIDTH:0] rd_ptr;

    // ----------------------------------------------------------
    // Empty: all bits match (same lap, same slot)
    // Full:  MSBs differ (wr lapped rd), lower bits match
    // ----------------------------------------------------------
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[PTR_WIDTH]     != rd_ptr[PTR_WIDTH]) &&
                   (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);

    // ----------------------------------------------------------
    // Write logic — guarded by !full
    // ----------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            wr_ptr <= 0;
        else if (write_en && !full) begin
            mem[wr_ptr[PTR_WIDTH-1:0]] <= data_in;
            wr_ptr                     <= wr_ptr + 1;
        end
    end

    // ----------------------------------------------------------
    // Read logic — guarded by !empty
    // ----------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr   <= 0;
            data_out <= 0;
        end
        else if (read_en && !empty) begin
            data_out <= mem[rd_ptr[PTR_WIDTH-1:0]];
            rd_ptr   <= rd_ptr + 1;
        end
    end

endmodule

