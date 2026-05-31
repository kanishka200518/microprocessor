`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2026 16:54:47
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module alu(
    input  [31:0] A, B,
    input  [3:0]  ALUControl,
    output reg [31:0] Result,
    output        Zero
);
    always @(*) begin
        case (ALUControl)
            4'b0000: Result = A & B;                // AND
            4'b0001: Result = A | B;                // OR
            4'b0010: Result = A + B;                // ADD
            4'b0110: Result = A - B;                // SUB
            4'b0111: Result = (A < B) ? 32'd1 : 32'd0; // SLT (Set Less Than)
            4'b1100: Result = ~(A | B);             // NOR
            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0);
endmodule
   