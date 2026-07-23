`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2026 01:51:12
// Design Name: 
// Module Name: tb_risc_top
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


module tb_risc_top();



    // Inputs
    reg clk;
    reg reset;

    // Outputs
    wire [31:0] write_data;

    // Instantiate the Unit Under Test (UUT)
    risc_top uut (
        .clk(clk),
        .reset(reset),
        .write_data(write_data)
    );

    // Clock generation (100MHz -> 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;

        // Hold reset for 20ns
        #20;
        reset = 0;

        // Run for 200ns to observe several instructions
        #400;

        // Finish simulation
        $stop;
    end

    // Monitor results in the Tcl Console
    initial begin
        $monitor("Time=%0t | PC=%h | Instr=%h | Result=%d", 
                 $time, uut.pc_out, uut.instr, write_data);
    end

endmodule
   
