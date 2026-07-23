`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.04.2026 23:23:37
// Design Name: 
// Module Name: reg_file
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


module reg_file(
    input         clk,
    input         we,
    input  [4:0]  a1, a2, a3,
    input  [31:0] wd3,
    output [31:0] rd1, rd2
);
    reg [31:0] rf [31:0];

    // Synchronous write
    always @(posedge clk) begin
        if (we && a3 != 5'b0) // x0 is hardwired to 0
            rf[a3] <= wd3;
    end

    // Asynchronous read
     assign rd1 = (a1 == 5'b0) ?32'b0 : (we && a1==a3)?wd3:rf[a1];
    assign rd2 = (a2 == 5'b0) ?32'b0 : (we && a2==a3)?wd3:rf[a2];
endmodule
   
