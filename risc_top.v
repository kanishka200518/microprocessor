`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2026 01:33:48
// Design Name: 
// Module Name: risc_top
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



module risc_top(
    input  clk,
    input  reset,
    output [31:0] write_data // Connect to LEDs/OLED for hardware debug
);

    // --- Internal Signal Busses ---
    wire [31:0] pc_out, pc_next, pc_plus4, pc_target;
    wire [31:0] instr;
    wire [31:0] rd1, rd2, imm_ext, alu_result, read_data, result;
    wire [3:0]  alu_control;
    wire [1:0]  alu_op;
    wire        reg_write, alu_src, mem_write, mem_read, result_src, branch, zero;

    // --- 1. FETCH STAGE ---
    pc pc_unit  (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    imem imem_unit (
        .addr(pc_out),
        .instr(instr)
    );

    assign pc_plus4 = pc_out + 4;

    // --- 2. DECODE STAGE ---
    control_unit cu (
        .opcode(instr[6:0]),
        .RegWrite(reg_write),
        .ALUSrc(alu_src),
        .MemWrite(mem_write),
        .MemRead(mem_read),
        .ResultSrc(result_src),
        .Branch(branch),
        .ALUOp(alu_op)
    );

    // Mini ALU Decoder logic (converts ALUOp + funct bits to ALUControl)
    assign alu_control = (alu_op == 2'b00) ? 4'b0010 : // Add (Load/Store)
                         (alu_op == 2'b01) ? 4'b0110 : // Subtract (Branch)
                         ((instr[14:12] == 3'b000) && (instr[31:25] == 7'b0000000)) ? 4'b0010 : // Add
                         ((instr[14:12] == 3'b000) && (instr[31:25] == 7'b0100000)) ? 4'b0110 : // Sub
                         ((instr[14:12] == 3'b111)) ? 4'b0000 : // And
                         ((instr[14:12] == 3'b110)) ? 4'b0001 : // Or
                         4'b0010; // Default Add

    reg_file rf (
        .clk(clk),
        .we(reg_write),
        .a1(instr[19:15]),
        .a2(instr[24:20]),
        .a3(instr[11:7]),
        .wd3(result),
        .rd1(rd1),
        .rd2(rd2)
    );

    imm_gen ig (
        .instr(instr),
        .imm_ext(imm_ext)
    );

    // --- 3. EXECUTE STAGE ---
    wire [31:0] src_b = alu_src ? imm_ext : rd2;
    
    alu alu_unit (
        .A(rd1),
        .B(src_b),
        .ALUControl(alu_control),
        .Result(alu_result),
        .Zero(zero)
    );

    // --- 4. MEMORY & WRITEBACK STAGE ---
    // Note: If you haven't made a data_mem.v yet, we'll bypass it for now
    assign read_data = 32'b0; 
    assign result = result_src ? read_data : alu_result;

    // PC Source Mux (Next PC logic)
    assign pc_target = pc_out + imm_ext;
    assign pc_next = (branch && zero) ? pc_target : pc_plus4;

    // Output for Hardware Debugging
    assign write_data = result;

endmodule
  
