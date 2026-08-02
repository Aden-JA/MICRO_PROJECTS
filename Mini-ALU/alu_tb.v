`timescale 1ns/1ps

module alu_tb;

    reg [3:0] A;
    reg [3:0] B;
    reg [2:0] opcode;
    wire [3:0] result;
    wire zero;

    // Connect testbench to ALU module
    alu uut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .result(result),
        .zero(zero)
    );

    // Waveform dump for GTKWave
    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
    end

    initial begin
        $display("=== Mini ALU Testbench ===");
        $display("Op    A    B    Result  Zero");

        // ADD: 5 + 3 = 8
        A = 4'd5; B = 4'd3; opcode = 3'b000; #10;
        $display("ADD   %0d    %0d    %0d       %b", A, B, result, zero);

        // SUB: 5 - 3 = 2
        A = 4'd5; B = 4'd3; opcode = 3'b001; #10;
        $display("SUB   %0d    %0d    %0d       %b", A, B, result, zero);

        // SUB producing zero: 4 - 4 = 0
        A = 4'd4; B = 4'd4; opcode = 3'b001; #10;
        $display("SUB   %0d    %0d    %0d       %b", A, B, result, zero);

        // AND: 1100 & 1010 = 1000
        A = 4'b1100; B = 4'b1010; opcode = 3'b010; #10;
        $display("AND   %b  %b  %b    %b", A, B, result, zero);

        // OR: 1100 | 1010 = 1110
        A = 4'b1100; B = 4'b1010; opcode = 3'b011; #10;
        $display("OR    %b  %b  %b    %b", A, B, result, zero);

        // XOR: 1100 ^ 1010 = 0110
        A = 4'b1100; B = 4'b1010; opcode = 3'b100; #10;
        $display("XOR   %b  %b  %b    %b", A, B, result, zero);

        // NOT: ~0101 = 1010
        A = 4'b0101; B = 4'b0000; opcode = 3'b101; #10;
        $display("NOT   %b  ----  %b    %b", A, result, zero);

        // LEFT SHIFT: 0011 << 1 = 0110
        A = 4'b0011; B = 4'b0000; opcode = 3'b110; #10;
        $display("LSH   %b  ----  %b    %b", A, result, zero);

        // RIGHT SHIFT: 0110 >> 1 = 0011
        A = 4'b0110; B = 4'b0000; opcode = 3'b111; #10;
        $display("RSH   %b  ----  %b    %b", A, result, zero);

        $display("=== Simulation Complete ===");
        $finish;
    end

endmodule

// 4'd5 means 4-bit decimal 5. The d specifies decimal.
// #10 means wait 10 nanoseconds before next test — gives time for outputs to settle.
// %0d prints decimal, %b prints binary — we use both depending on what makes the result clearest
