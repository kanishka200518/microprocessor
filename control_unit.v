`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2026 23:21:16
// Design Name: 
// Module Name: control_unit
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



module control_unit(
    input  [6:0] opcode,
    output reg   RegWrite,
    output reg   ALUSrc,
    output reg   MemWrite,
    output reg   MemRead,
    output reg   ResultSrc, // 0 for ALU, 1 for Memory
    output reg   Branch,
    output reg [1:0] ALUOp
);
    always @(*) begin
        // Default values
        RegWrite  = 0; ALUSrc = 0; MemWrite = 0; 
        MemRead   = 0; ResultSrc = 0; Branch = 0; ALUOp = 2'b00;

        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                RegWrite = 1; ALUSrc = 1; ALUOp = 2'b10;
            end
            7'b0000011: begin // Load
                RegWrite = 1; ALUSrc = 1; MemRead = 1; ResultSrc = 1;
            end
            7'b0100011: begin // Store
                ALUSrc = 1; MemWrite = 1;
            end
            7'b1100011: begin // Branch (BEQ)
                Branch = 1; ALUOp = 2'b01;
            end
        endcase
    end
endmodule
   
