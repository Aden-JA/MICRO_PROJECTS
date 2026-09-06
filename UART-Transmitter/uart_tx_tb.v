`timescale 1ns/1ps

module uart_tx_tb;

    // Parameters matching the design
    parameter CLK_FREQ  = 50_000_000;
    parameter BAUD_RATE = 9600;
    parameter BAUD_PERIOD = 1_000_000_000 / BAUD_RATE; // in ns

    // Testbench signals
    reg        clk;
    reg        reset;
    reg        send;
    reg  [7:0] data;
    wire       tx;
    wire       tx_busy;
    wire       tx_done;

    // Instantiate UART transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .PARITY(0),
        .STOP_BITS(1)
    ) uut (
        .clk(clk),
        .reset(reset),
        .send(send),
        .data(data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // Clock generation - 50MHz = 20ns period
    initial clk = 0;
    always #10 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);
    end

    // Task to send one byte and wait for completion
    task send_byte;
        input [7:0] byte_to_send;
        begin
            @(posedge clk);
            data <= byte_to_send;
            send <= 1;
            @(posedge clk);
            send <= 0;
            // Wait for transmission to complete
            @(posedge tx_done);
            #(BAUD_PERIOD);
        end
    endtask

    // Main test
    initial begin
        $display("=== UART Transmitter Testbench ===");
        $display("CLK: %0d Hz | BAUD: %0d | Period: %0d ns",
                  CLK_FREQ, BAUD_RATE, BAUD_PERIOD);

        // Initialize
        reset = 1;
        send  = 0;
        data  = 0;
        #100;
        reset = 0;
        #100;

        // Send "HELLO" in ASCII
        $display("\nSending: H E L L O");
        $display("---------------------------");

        send_byte(8'h48); $display("Sent: H (0x48)");
        send_byte(8'h45); $display("Sent: E (0x45)");
        send_byte(8'h4C); $display("Sent: L (0x4C)");
        send_byte(8'h4C); $display("Sent: L (0x4C)");
        send_byte(8'h4F); $display("Sent: O (0x4F)");

        // Edge cases
        $display("\nEdge Cases:");
        $display("---------------------------");
        send_byte(8'h00); $display("Sent: 0x00 (all zeros)");
        send_byte(8'hFF); $display("Sent: 0xFF (all ones)");
        send_byte(8'hAA); $display("Sent: 0xAA (alternating)");

        $display("\n=== Simulation Complete ===");
        $finish;
    end

endmodule
