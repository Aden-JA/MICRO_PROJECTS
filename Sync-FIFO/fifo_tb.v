// ============================================================
//  Synchronous FIFO Testbench
//
//  Drive strategy: set inputs AFTER posedge — DUT captures
//  them at the NEXT posedge. This gives maximum setup time
//  (almost one full clock period) and zero race conditions.
//
//  Example for one write:
//    @(posedge clk);  write_en=1; data_in=X;  // set AFTER posedge N
//    @(posedge clk);  write_en=0;              // DUT captures at posedge N+1
//
//  Tests:
//    TEST 1 — Write 8, read 8, verify order
//    TEST 2 — Fill to FULL, check flag
//    TEST 5 — Overflow attempt (write when full)
//    TEST 3 — Empty completely, check flag
//    TEST 6 — Underflow attempt (read when empty)
//    TEST 4 — Simultaneous read and write
// ============================================================
`timescale 1ns/1ps

module fifo_tb;

    // ----------------------------------------------------------
    // Parameters
    // ----------------------------------------------------------
    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 16;

    // ----------------------------------------------------------
    // Signals
    // ----------------------------------------------------------
    reg                   clk;
    reg                   reset;
    reg                   write_en;
    reg                   read_en;
    reg  [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire                  full;
    wire                  empty;

    // ----------------------------------------------------------
    // Instantiate DUT
    // ----------------------------------------------------------
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .read_en(read_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // ----------------------------------------------------------
    // Clock: 50 MHz — 20 ns period
    // ----------------------------------------------------------
    initial clk = 0;
    always  #10 clk = ~clk;

    // ----------------------------------------------------------
    // VCD dump for GTKWave
    // ----------------------------------------------------------
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
    end

    // ----------------------------------------------------------
    // Loop variable and read capture register
    // ----------------------------------------------------------
    integer i;
    reg [DATA_WIDTH-1:0] rd_val;

    // ----------------------------------------------------------
    // Main stimulus
    // ----------------------------------------------------------
    initial begin

        // --- Initialize all signals before first clock ---
        write_en = 0;
        read_en  = 0;
        data_in  = 0;
        reset    = 1;

        // Hold reset for 4 cycles then release
        repeat(4) @(posedge clk);
        @(posedge clk); reset = 0;
        repeat(3) @(posedge clk);   // settle

        $display("=========================================");
        $display("      FIFO VERIFICATION TESTBENCH       ");
        $display("  DEPTH=%0d | DATA_WIDTH=%0d bits       ", DEPTH, DATA_WIDTH);
        $display("=========================================");

        // ==================================================
        // TEST 1 — Write 8 bytes, read back, verify order
        // ==================================================
        $display("\n[TEST 1] Write 8 bytes, read back — verify FIFO order");

        // Write 8 bytes: 0, 10, 20, 30, 40, 50, 60, 70
        // Pattern: set write_en+data AFTER each posedge
        //          DUT captures at the NEXT posedge
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            write_en = 1;
            data_in  = i * 10;
        end
        @(posedge clk); write_en = 0; // last write captured here, now clear
        repeat(2) @(posedge clk);     // idle

        // Read back 8 bytes and verify each value
        // read_en goes HIGH after posedge, captured at next posedge
        // data_out valid 1ns after that posedge
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk); read_en = 1;   // set after posedge N
            @(posedge clk); read_en = 0;   // DUT reads at posedge N+1
            #1;
            rd_val = data_out;
            $display("  READ[%0d] = %3d  (expected %3d)  %s",
                      i, rd_val, i*10,
                      (rd_val == i*10) ? "PASS" : "FAIL");
        end
        repeat(2) @(posedge clk);

        // ==================================================
        // TEST 2 — Fill completely to FULL
        // ==================================================
        $display("\n[TEST 2] Fill FIFO to FULL (%0d bytes)", DEPTH);

        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            write_en = 1;
            data_in  = i;
        end
        @(posedge clk); write_en = 0;
        repeat(2) @(posedge clk); #1;

        $display("  full  = %b  (expected 1)  %s",
                  full,  (full  == 1) ? "PASS" : "FAIL");
        $display("  empty = %b  (expected 0)  %s",
                  empty, (empty == 0) ? "PASS" : "FAIL");

        // ==================================================
        // TEST 5 — Overflow: write when FULL
        // ==================================================
        $display("\n[TEST 5] Overflow attempt — write when FULL");

        @(posedge clk); write_en = 1; data_in = 8'hFF;
        @(posedge clk); write_en = 0;    // DUT sees write_en=1 but !full=0 → blocked
        repeat(2) @(posedge clk); #1;

        $display("  full still = %b  (expected 1)  %s",
                  full, (full == 1) ? "PASS" : "FAIL");

        // ==================================================
        // TEST 3 — Empty completely
        // ==================================================
        $display("\n[TEST 3] Empty FIFO completely (%0d reads)", DEPTH);

        // Burst reads — read_en stays HIGH across consecutive posedges
        // No read at the first posedge (read_en just set), 16 reads follow
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk);
            read_en = 1;
        end
        @(posedge clk); read_en = 0;   // 16th read captured here, then clear
        repeat(2) @(posedge clk); #1;

        $display("  empty = %b  (expected 1)  %s",
                  empty, (empty == 1) ? "PASS" : "FAIL");
        $display("  full  = %b  (expected 0)  %s",
                  full,  (full  == 0) ? "PASS" : "FAIL");

        // ==================================================
        // TEST 6 — Underflow: read when EMPTY
        // ==================================================
        $display("\n[TEST 6] Underflow attempt — read when EMPTY");

        @(posedge clk); read_en = 1;
        @(posedge clk); read_en = 0;    // DUT sees read_en=1 but !empty=0 → blocked
        repeat(2) @(posedge clk); #1;

        $display("  empty still = %b  (expected 1)  %s",
                  empty, (empty == 1) ? "PASS" : "FAIL");

        // ==================================================
        // TEST 4 — Simultaneous read and write
        // ==================================================
        $display("\n[TEST 4] Simultaneous read and write");

        // Prime the FIFO with 0xAA
        @(posedge clk); write_en = 1; data_in = 8'hAA;
        @(posedge clk); write_en = 0;
        repeat(2) @(posedge clk);

        // Assert write_en AND read_en simultaneously
        // At the next posedge:
        //   WRITE 0xBB into mem[wr_ptr]
        //   READ  0xAA from mem[rd_ptr] → data_out
        @(posedge clk);
        write_en = 1; data_in = 8'hBB;
        read_en  = 1;
        @(posedge clk);
        write_en = 0; read_en = 0;
        #1;
        $display("  Simultaneous: data_out=0x%h  (expected 0xaa)  %s",
                  data_out, (data_out == 8'hAA) ? "PASS" : "FAIL");

        repeat(2) @(posedge clk);

        // Read 0xBB to confirm it was written
        @(posedge clk); read_en = 1;
        @(posedge clk); read_en = 0; #1;
        $display("  Follow-up:    data_out=0x%h  (expected 0xbb)  %s",
                  data_out, (data_out == 8'hBB) ? "PASS" : "FAIL");

        repeat(3) @(posedge clk);

        $display("\n=========================================");
        $display("         VERIFICATION COMPLETE          ");
        $display("=========================================\n");
        $finish;

    end

endmodule
