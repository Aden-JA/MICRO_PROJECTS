module alu (
    input [3:0] A,                         // 4 bit input (0-15)
    input [3:0] B,                         // another 4 bit input (0-15)
    input [2:0] opcode,                    // 3 bit opcode
    output reg [3:0] result,               // 4 bit output
    output wire zero                       // zero flag
    );

    // Combinational logic for ALU operations
    always @(*) begin
        case (opcode)
            3'b000: result = A + B;        // Addition
            3'b001: result = A - B;        // Subtraction
            3'b010: result = A & B;        // Bitwise AND
            3'b011: result = A | B;        // Bitwise OR
            3'b100: result = A ^ B;        // Bitwise XOR
            3'b101: result = ~A;           // Bitwise NOT (on A)
            3'b110: result = A << 1;       // Left shift A by 1
            3'b111: result = A >> 1;       // Right shift A by 1
            default: result = 4'b0000;     // Default case
        endcase
    end

    // Zero flag logic
    assign zero = (result == 4'b0000) ? 1:0;

endmodule