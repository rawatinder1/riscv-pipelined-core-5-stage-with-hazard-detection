
# riscv-pipelined-core-5-stage-with-hazard-detection

A complete 5-stage pipelined RISC-V RV32I processor written in Verilog.  
Supports **data forwarding**, **hazard detection**, **stalls**, and **flushes** for correct execution of dependent and control-flow instructions.

---

## 🧠 Features

✅ 5-stage pipeline: IF, ID, EX, MEM, WB  
✅ Data forwarding (EX → EX, MEM → EX)  
✅ Hazard detection unit (for LW→use stalls, etc.)  
✅ Branch resolution with pipeline flushing  
✅ Jumps and conditional branches (JAL, JALR, BEQ, BNE, etc.)  
✅ Load and store handling (LW, SW)  
✅ Modular Verilog design  
✅ Testbench with pass/fail reporting and register monitoring  

