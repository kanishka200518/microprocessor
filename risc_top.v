`timescale 1ns / 1ps

module riscv_top(
    input  clk,
    input  reset,
    output [31:0] write_data
);

    //========================================================================
    // 0. HAZARD & FORWARDING CONTROL WIRES
    //========================================================================
    wire [1:0] forward_a, forward_b;
    wire       stall_F, stall_D, flush_D, flush_E;

    //========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    //========================================================================
    wire [31:0] pc_next_F, pc_out_F, pc_plus4_F;
    wire [31:0] instr_F;
    wire [31:0] pc_target_E; // Fed back from Execute stage
    wire        pc_src_E;    // Fed back from Execute stage

    // PC Mux: Select next sequential instruction or branch target
    assign pc_next_F = pc_src_E ? pc_target_E : pc_plus4_F;

    // Program Counter Register (With Stall support)
    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .stall(stall_F), // Modify your pc.v to accept an active-high stall signal
        .pc_next(pc_next_F),
        .pc_out(pc_out_F)
    );

    imem imem_inst (
        .addr(pc_out_F),
        .instr(instr_F)
    );

    assign pc_plus4_F = pc_out_F + 4;

    //========================================================================
    // 2. IF/ID PIPELINE REGISTER
    //========================================================================
    reg [31:0] instr_D, pc_D, pc_plus4_D;

    always @(posedge clk or posedge reset) begin
        if (reset || flush_D) begin
            instr_D     <= 32'b0;
            pc_D        <= 32'b0;
            pc_plus4_D  <= 32'b0;
        end else if (!stall_D) begin
            instr_D     <= instr_F;
            pc_D        <= pc_out_F;
            pc_plus4_D  <= pc_plus4_F;
        end
    end

    //========================================================================
    // 3. INSTRUCTION DECODE (ID) STAGE
    //========================================================================
    wire [31:0] rd1_D, rd2_D, imm_ext_D;
    wire [4:0]  rs1_D = instr_D[19:15];
    wire [4:0]  rs2_D = instr_D[24:20];
    wire [4:0]  rd_D  = instr_D[11:7];
    
    // Control Unit Signals
    wire       reg_write_D, alu_src_D, mem_write_D, mem_read_D, result_src_D, branch_D;
    wire [1:0] alu_op_D;
    
    control_unit control_unit_inst (
        .opcode(instr_D[6:0]),
        .RegWrite(reg_write_D),
        .ALUSrc(alu_src_D),
        .MemWrite(mem_write_D),
        .MemRead(mem_read_D),
        .ResultSrc(result_src_D),
        .Branch(branch_D),
        .ALUOp(alu_op_D)
    );

    // Register File Writeback connections originate from WB stage
    wire        reg_write_W;
    wire [4:0]  rd_W;
    wire [31:0] result_W;

    reg_file reg_file_inst (
        .reset(reset),
        .clk(clk),
        .we(reg_write_W),
        .a1(rs1_D),
        .a2(rs2_D),
        .a3(rd_W),
        .wd3(result_W),
        .rd1(rd1_D),
        .rd2(rd2_D)
    );

    imm_gen imm_gen_inst (
        .instr(instr_D),
        .imm_ext(imm_ext_D)
    );

    //========================================================================
    // 4. ID/EX PIPELINE REGISTER
    //========================================================================
    reg        reg_write_E, alu_src_E, mem_write_E, mem_read_E, result_src_E, branch_E;
    reg [1:0]  alu_op_E;
    reg [31:0] rd1_E, rd2_E, pc_E, imm_ext_E, pc_plus4_E;
    reg [4:0]  rs1_E, rs2_E, rd_E;
    reg [2:0]  funct3_E;
    reg        funct7_bit_E;

    always @(posedge clk or posedge reset) begin
        if (reset || flush_E) begin
            reg_write_E  <= 1'b0; alu_src_E    <= 1'b0; mem_write_E  <= 1'b0;
            mem_read_E   <= 1'b0; result_src_E <= 1'b0; branch_E     <= 1'b0;
            alu_op_E     <= 2'b0; rd1_E        <= 32'b0; rd2_E       <= 32'b0;
            pc_E         <= 32'b0; imm_ext_E   <= 32'b0; pc_plus4_E  <= 32'b0;
            rs1_E        <= 5'b0;  rs2_E       <= 5'b0;  rd_E        <= 5'b0;
            funct3_E     <= 3'b0;  funct7_bit_E<= 1'b0;
        end else begin
            reg_write_E  <= reg_write_D;  alu_src_E    <= alu_src_D;
            mem_write_E  <= mem_write_D;  mem_read_E   <= mem_read_D;
            result_src_E <= result_src_D; branch_E     <= branch_D;
            alu_op_E     <= alu_op_D;     rd1_E        <= rd1_D;
            rd2_E        <= rd2_D;        pc_E         <= pc_D;
            imm_ext_E    <= imm_ext_D;    pc_plus4_E   <= pc_plus4_D;
            rs1_E        <= rs1_D;        rs2_E        <= rs2_D;
            rd_E         <= rd_D;
            funct3_E     <= instr_D[14:12];
            funct7_bit_E <= instr_D[30];
        end
    end

    //========================================================================
    // 5. EXECUTE (EX) STAGE
    //========================================================================
    wire [31:0] src_a_mux_out, src_b_forward_out, src_b_final;
    wire [31:0] alu_result_E;
    wire [3:0]  alu_control_E;
    wire        zero_E;
    
    wire [31:0] alu_result_M; // From memory stage pipeline registers

    // Forwarding Multiplexers for ALU Input A
    assign src_a_mux_out = (forward_a == 2'b10) ? alu_result_M :
                           (forward_a == 2'b01) ? result_W     : rd1_E;

    // Forwarding Multiplexers for ALU Input B (Before ALUSrc Mux)
    assign src_b_forward_out = (forward_b == 2'b10) ? alu_result_M :
                               (forward_b == 2'b01) ? result_W     : rd2_E;

    // ALU Src Mux: Choose register contents or sign-extended immediate
    assign src_b_final = alu_src_E ? imm_ext_E : src_b_forward_out;

    // ALU Decoder Logic
    assign alu_control_E = (alu_op_E == 2'b00) ? 4'b0010 : // Add (Loads/Stores)
                           (alu_op_E == 2'b01) ? 4'b0110 : // Sub (Branches)
                           ((funct3_E == 3'b000) && (funct7_bit_E == 1'b0)) ? 4'b0010 : // Add
                           ((funct3_E == 3'b000) && (funct7_bit_E == 1'b1)) ? 4'b0110 : // Sub
                           (funct3_E == 3'b111) ? 4'b0000 : // And
                           (funct3_E == 3'b110) ? 4'b0001 : // Or
                           4'b0010;

    alu alu_inst (
        .A(src_a_mux_out),
        .B(src_b_final),
        .ALUControl(alu_control_E),
        .Result(alu_result_E),
        .Zero(zero_E)
    );

    // Structural Target Adders
    assign pc_target_E = pc_E + imm_ext_E;
    assign pc_src_E    = branch_E && zero_E;

    //========================================================================
    // 6. EX/MEM PIPELINE REGISTER
    //========================================================================
    reg        reg_write_M, mem_write_M, mem_read_M, result_src_M;
    reg [31:0] write_data_M;
    reg [4:0]  rd_M;
    
    // Allocate shared dynamic forward reference wires
    reg [31:0] alu_result_reg_M;
    assign alu_result_M = alu_result_reg_M;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_M      <= 1'b0; mem_write_M <= 1'b0; mem_read_M <= 1'b0;
            result_src_M     <= 1'b0; alu_result_reg_M <= 32'b0; write_data_M  <= 32'b0;
            rd_M             <= 5'b0;
        end else begin
            reg_write_M      <= reg_write_E;
            mem_write_M     <= mem_write_E;
            mem_read_M      <= mem_read_E;
            result_src_M     <= result_src_E;
            alu_result_reg_M <= alu_result_E;
            write_data_M     <= src_b_forward_out; // Store forwarded register tracking values
            rd_M             <= rd_E;
        end
    end

    //========================================================================
    // 7. MEMORY (MEM) STAGE
    //========================================================================
    wire [31:0] read_data_M;

    dmem dmem_inst (
        .clk(clk),
        .we(mem_write_M),
        .addr(alu_result_M),
        .wd(write_data_M),
        .rd(read_data_M)
    );

    //========================================================================
    // 8. MEM/WB PIPELINE REGISTER
    //========================================================================
    reg        reg_write_W_reg, result_src_W;
    reg [31:0] alu_result_W, read_data_W;
    reg [4:0]  rd_W_reg;
    
    assign reg_write_W = reg_write_W_reg;
    assign rd_W        = rd_W_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_write_W_reg <= 1'b0;  result_src_W <= 1'b0;
            alu_result_W    <= 32'b0; read_data_W  <= 32'b0;
            rd_W_reg        <= 5'b0;
        end else begin
            reg_write_W_reg <= reg_write_M;
            result_src_W    <= result_src_M;
            alu_result_W    <= alu_result_M;
            read_data_W     <= read_data_M;
            rd_W_reg        <= rd_M;
        end
    end

    //========================================================================
    // 9. WRITEBACK (WB) STAGE
    //========================================================================
    assign result_W   = result_src_W ? read_data_W : alu_result_W;
    assign write_data = result_W; // Route pipeline tracing outwards

    //========================================================================
    // 10. FORWARDING UNIT LOGIC
    //========================================================================
    // Forwarding to Input A
    assign forward_a = ((reg_write_M) && (rd_M != 0) && (rd_M == rs1_E)) ? 2'b10 :
                       ((reg_write_W) && (rd_W != 0) && (rd_W == rs1_E)) ? 2'b01 : 2'b00;

    // Forwarding to Input B
    assign forward_b = ((reg_write_M) && (rd_M != 0) && (rd_M == rs2_E)) ? 2'b10 :
                       ((reg_write_W) && (rd_W != 0) && (rd_W == rs2_E)) ? 2'b01 : 2'b00;

    //========================================================================
    // 11. HAZARD DETECTION UNIT (Stalls & Flushes)
    //========================================================================
    wire lw_stall;
    
    // Detect a Raw Data Dependency immediately following a Load Word Instruction
    assign lw_stall = (result_src_E == 1'b1) && ((rd_E == rs1_D) || (rd_E == rs2_D));
    
    // Hardware actions based on hazard assessment
    assign stall_F = lw_stall;
    assign stall_D = lw_stall;
    assign flush_E = lw_stall || pc_src_E; // Flush execution if stalling or branching
    assign flush_D = pc_src_E;             // Flush decode stage on mispredicted jump

endmodule
