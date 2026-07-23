
# 5-Stage Pipelined RISC-V (RV32I) Processor Core

A 32-bit 5-stage pipelined processor core implementing a subset of the **RISC-V (RV32I)** Base Integer Instruction Set in **Verilog HDL**. Designed for synthesized target hardware platforms and verified via Xilinx Vivado.

The core features full dynamic hazard handling—managing data dependencies via EX/MEM forwarding paths, resolving load-use hazards through automatic NOP bubbling/stalls, and supporting control hazard flushes.

---

## 🛠️ Key Features & Architecture

* **Architecture:** 32-bit RISC-V (RV32I subset)
* **Pipeline Depth:** 5 Stages (`IF` -> `ID` -> `EX` -> `MEM` -> `WB`)
* **Hazard Resolution:**
  * **Data Forwarding Unit:** EX-to-EX and MEM-to-EX bypassing to eliminate RAW (Read-After-Write) data hazard stalls.
  * **Load-Use Hazard Unit:** Automatic 1-cycle pipeline freeze (stalling `IF`/`ID`) and NOP bubble insertion (`EX`) when consuming load data immediately.
  * **Control Hazard Handling:** Pipeline flush on taken branches/jumps.
* **Memory Interface:**
  * Separate Instruction Memory (`imem`) initialized via hex memory files (`program.mem`).
  * Byte/Word addressable Data Memory (`dmem`).
* **Toolchain Support:** Designed for Xilinx Vivado (Simulated & Tested using `xsim`).

---

## 📐 Pipeline Overview

[ IF Stage ]   ───>   [ ID Stage ]   ───>   [ EX Stage ]   ───>   [ MEM Stage ]   ───>   [ WB Stage ]
Program Counter        Reg File Read         ALU / Branch          Data RAM Read/        Reg File Write
& Instruction RAM      & Instruction Dec      Execution             Write                 Commit


### Supported Instructions
* **R-Type:** `add`, `sub`, `and`, `or`, `slt`
* **I-Type:** `addi`, `lw`
* **S-Type:** `sw`
* **U-Type:** `lui`
* **B-Type:** `beq`

---

## 📂 Repository File Breakdown

Below is a brief explanation of what each module and file in this repository does:

```text
├── hdl/
│   ├── riscv_top.v            # Top-level module connecting pipeline stages & hazard units
│   ├── pc.v                   # Program Counter register with stall support
│   ├── imem.v                 # Instruction Memory (loads program.mem)
│   ├── reg_file.v             # 32x32-bit Register File (x0 hardwired to 0)
│   ├── alu.v                  # Arithmetic Logic Unit
│   ├── dmem.v                 # Data Memory module
│   ├── hazard_unit.v          # Hazard Detection & Forwarding Logic Unit
│   └── control_unit.v         # Main Control Decoder
├── sim/
│   ├── tb_risc_top.v          # Self-checking testbench with cycle-by-cycle tracking
│   └── program.mem            # Hexadecimal machine code loaded at initialization
├── docs/                      # Diagrams and reports
└── README.md                  # Project Documentation
📄 Module Descriptions
1. Top & Pipeline Registers
riscv_top.v: The master module that instantiates all sub-modules, declares inter-stage pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB), and routes control signals, memory buses, and forwarding multiplexers across the core.

2. Fetch & Decode Stage Modules
pc.v: Holds the current 32-bit Program Counter (PC). Updates every clock cycle unless frozen by a stall signal from the hazard unit.

imem.v: Read-only Instruction Memory. Stores assembly machine code loaded from program.mem and outputs instructions based on the current PC.

control_unit.v: Decodes opcode/funct fields from the instruction and outputs control signals (RegWrite, ALUOp, MemRead, MemWrite, Branch, etc.) to drive execution.

reg_file.v: Dual-read, single-write register file containing 32 general-purpose 32-bit registers (x0–x31), with register x0 permanently hardwired to 0.

3. Execution & Memory Stage Modules
alu.v: Performs arithmetic and logical operations (ADD, SUB, AND, OR, SLT) based on inputs from the register file or forwarding multiplexers.

dmem.v: Read/Write Data Memory array. Stores values (sw) or reads memory data (lw) during the MEM stage.

4. Pipeline Management & Verification
hazard_unit.v: Monitors source and destination register numbers across pipeline stages. Controls forwarding selection signals (forward_a, forward_b) and asserts stall/flush flags (stall_F, stall_D, flush_E) on Load-Use or Branch hazards.

tb_risc_top.v: Testbench environment that generates the system clock/reset signals and logs real-time pipeline status into the Tcl console on every clock cycle.

program.mem: Hexadecimal text file containing compiled RISC-V machine code loaded into imem during simulation initialization.

🧪 Hazard Unit Logic & Verification
1. Data Forwarding (EX & MEM Bypassing)
When back-to-back arithmetic instructions depend on previous results (e.g., addi x1, x1, 913 followed by add x3, x1, x2), the Forwarding Unit detects matching destination (rd) and source (rs1/rs2) addresses, routing results directly to the ALU inputs before they are written to the Register File.

2. Load-Use Stall Sequence
When an instruction attempts to consume a register loaded by an immediately preceding lw instruction:

stall_F and stall_D assert high to freeze the Fetch and Decode stages.

flush_E asserts high, inserting a NOP (bubble) into the Execute stage.

The load completes in the MEM stage, data is forwarded, and execution safely resumes on the next clock cycle.

