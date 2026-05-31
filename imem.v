`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2026 23:59:42
// Design Name: 
// Module Name: imem
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


module imem(
    input  [31:0] addr,
    output [31:0] instr
);
    // Adjust depth based on how much code you are writing (64 words = 256 bytes)
    reg [31:0] rom [0:63]; 

    initial begin
        // Vivado will look for this file in the project folder
        $readmemh("program.mem", rom);
    end

    // Word-aligned access: dividing address by 4
    assign instr = rom[addr[31:2]]; 
endmodule

  
