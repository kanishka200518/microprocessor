`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2026 17:27:14
// Design Name: 
// Module Name: imm_gen
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



module imm_gen(
    input  [31:0] instr,
    output reg [31:0] imm_ext
);
    always @(*) begin
        case (instr[6:0])
            7'b0010011: imm_ext = {{20{instr[31]}}, instr[31:20]}; // I-type (addi, etc)
            7'b0000011: imm_ext = {{20{instr[31]}}, instr[31:20]}; // I-type (load)
            7'b0100011: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type (store)
            7'b1100011: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type (branch)
            default:    imm_ext = 32'b0;
        endcase
    end
endmodule
  
