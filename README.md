# microprocessor
Here is a complete, professional, and production-ready `README.md` for your GitHub repository. It clearly highlights your design choices, provides an in-depth breakdown of how each component works, and tracks the data flow through your verified architecture.

---

# 32-Bit Single-Cycle RISC-V (RV32I) Processor Core

A hardware-level implementation of a 32-bit single-cycle RISC-V processor core based on the base integer instruction set (**RV32I**). Developed using **Verilog HDL** and fully simulated, debugged, and verified using **Xilinx Vivado**.

The architecture executes core arithmetic/logic (R-type), immediate operations (I-type), and program control flow (B-type) instructions within a single clock cycle by utilizing a cleanly partitioned, structural top-level design.

---

## 🏛️ Architectural Overview & Dataflow

The processor is engineered as a monolithic single-cycle execution datapath. In a single clock period, an instruction is fetched from memory, decoded, its operands are gathered from the register file or immediate generator, processed by the ALU, and the resulting state is committed back to the architecture.

```
       +---------+     +---------+     +-------------+
       |   PC    | --> |  IMEM   | --> | Control Unit|
       +---------+     +---------+     +-------------+
            |               |                 |
            v               v                 v
     +--------------+  +---------+     +-------------+     +---------+
  +> | Next PC Mux  |  | RegFile | --> |     ALU     | --> |  DMEM   | --+
  |  +--------------+  +---------+     +-------------+     +---------+   |
  |         ^               |                 ^                  |       |
  |         |               v                 |                  v       |
  +---------+---------------X-----------------+------------------X-------+
                                Writeback Data / Muxes

```

---

## 🛠️ Detailed Component Functionality

### 1. Program Counter (`pc.v`)

* **Role:** The execution pointer of the processor.
* **Working:** A 32-bit synchronous register that holds the address of the current instruction. On every rising edge of the clock (`posedge clk`), it updates its internal state to the address presented at its input port (`pc_next`). When the `reset` line is asserted high, it asynchronously flushes its value back to `32'h00000000`, forcing the system to reboot from the beginning of the application software binary.

### 2. Instruction Memory (`imem.v`)

* **Role:** Read-only storage for the application machine code.
* **Working:** Modeled as a byte-addressable memory array initializing machine code instructions via hex files using the `$readmemh` system directive. It accepts the 32-bit address from the PC and outputs a 32-bit wide instruction word (`instr`) asynchronously. Because instructions are word-aligned (4 bytes), the lower two bits of the address are safely truncated or bypassed during internal index lookups.

### 3. Control Unit (`control_unit.v`)

* **Role:** The brain of the CPU; decodes instructions into hardware control signals.
* **Working:** Parses the lowest 7 bits of the instruction (`instr[6:0]`), which contain the RISC-V Opcode. Based on a combinatorial case matrix, it dynamically drives control lines across the chip:
* `RegWrite`: Enables or disables writing back to the Register File.
* `ALUSrc`: Toggles the second input of the ALU between Register Data 2 (`rd2`) and the Sign-Extended Immediate Value.
* `MemWrite` / `MemRead`: Interfaces with Data Memory boundaries.
* `ResultSrc`: Selects whether ALU math or RAM read data goes back to the destination register.
* `ALUOp`: Outputs a multi-bit operational classification code to the execution block.



### 4. Register File (`reg_file.v`)

* **Role:** High-speed internal storage architecture containing 32 independent, 32-bit registers.
* **Working:** Features dual asynchronous read ports (`a1`, `a2`) and a single synchronous write port (`a3`). It translates source fields (`instr[19:15]` and `instr[24:20]`) into instant data bus outputs. On the rising edge of the clock, if `we` (write-enable) is active, it commits the writeback data (`wd3`) to address `a3`.
* *Critical Architecture Rule:* Register `x0` is structurally hardwired to `32'b0` through conditional logic. Any attempt to write to `x0` is ignored, and reading it always yields zero, eliminating uninitialized data noise.



### 5. Immediate Generator (`imm_gen.v`)

* **Role:** Extracts and reformats scrambled literal values embedded inside instructions.
* **Working:** Unlike older architectures, RISC-V distributes immediate bits across different zones of an instruction word to keep register source pins fixed. This unit captures those disjointed chunks, shifts them into a uniform sequence, and sign-extends the highest bit (bit 31) out to a full 32-bit signed integer (`imm_ext`), making it safe for immediate math or branch target calculations.

### 6. Arithmetic Logic Unit (`alu.v`)

* **Role:** The core computational mathematical engine.
* **Working:** Accepts two 32-bit data inputs (`A` and `B`) and a 4-bit operational selection code (`ALUControl`). It performs high-speed combinations asynchronously:
* `4'b0010` $\rightarrow$ Signed Addition (`A + B`)
* `4'b0110` $\rightarrow$ Signed Subtraction (`A - B`)
* `4'b0000` $\rightarrow$ Bitwise AND
* `4'b0001` $\rightarrow$ Bitwise OR
* It generates a Boolean `Zero` flag output which evaluates to `1` if the computation result equals exactly 0, serving as the core evaluation trigger for branch conditions.



### 7. Data Memory (`dmem.v`)

* **Role:** Read/Write RAM boundary for volatile program variables.
* **Working:** Implemented as a word-aligned volatile memory block. When `MemWrite` is triggered, data from register `rd2` is committed directly to the memory index computed by the ALU result on the rising clock edge. Reading happens continuously and asynchronously based on the address index, supplying data to the final writeback multiplexer.

---

## 💻 Simulation and Verification

The system was simulated using the testbench component `tb_risc_top.v` to monitor execution accuracy under behavioral evaluation loops.

### Step-by-Step Execution Verification:

A test vector binary file (`program.mem`) containing standard mathematical configurations was successfully loaded. During execution, individual signal tracking verified flawless operation:

1. **Instruction 1 (`addi x1, x0, 5`):** The Immediate Generator expanded `5`. The ALU calculated `0 + 5`, and the writeback routine cleanly populated Register `[1]` with `00000005`.
2. **Instruction 2 (`addi x2, x0, 10`):** The immediate block parsed `10` ($A$ in Hex). The writeback logic captured the result and committed `0000000a` directly into Register `[2]`.
3. **Instruction 3 (`add x3, x1, x2`):** The control unit deactivated `ALUSrc` to draw operands straight from the register file ports. The ALU pulled `5` and `10` from registers `[1]` and `[2]`, computing an arithmetic sum of `15`. Register `[3]` updated cleanly to `0000000f`.

### Simulation Waveform Capture

Uninitialized registers start in a safe state and update exactly on the active clock boundaries, demonstrating zero propagation leakage, missing drivers, or unhandled high-impedance conditions.

---
