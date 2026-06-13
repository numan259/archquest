COMPUTER ARCHITECTURE — WEEK 7: THE PROCESSOR (Single-Cycle LEGv8 Datapath & Control)

Source: 70 annotated lecture slides (Patterson & Hennessy, LEGv8/ARMv8 edition, Chapter 4)
Extraction: Complete — all slides, handwritten notes, and emphasis marks transcribed.
Color key used by professor: RED = headings/key terms/new datapath elements being added · BLACK = main explanation text · BLUE = control signals & meta-commentary · GREEN = side remarks, alternative design choices, the isZero flag.


1. WEEK OVERVIEW

Topic title: The Processor — Building a Single-Cycle LEGv8 Datapath and its Control Unit

Subtopics covered (in lecture order):


Processor = Datapath + Control (definitions)
The stored-program execution loop (fetch → decode/execute → PC update → repeat)
Von Neumann vs. Harvard architecture (memory/bus organization)
Single-cycle processor concept and its timing limitation
The 7 hardware components: Instruction Memory, PC, Adder, Register File, ALU, Data Memory, Sign Extend Unit
Instruction formats used: R-format, D-format, CB-format, B-format (bit-field slicing)
Incremental datapath construction, one instruction at a time: add, sub, and, orr, ldur, stur, cbz, b
The five multiplexers (M1–M5) and the Shift-Left-2 / branch adder
The Control Table (filling control-signal rows per instruction, don't-cares)
The Control Unit (opcode + isZero in → 9 signal groups out)
Verilog implementation sketches of the ALU and the Control Unit


Where this fits in the course narrative:


What came before: ISA weeks (LEGv8 instruction formats R/D/CB/B, registers X0–X31, byte vs. word addressing) and digital-logic foundations (muxes, edge-triggered registers, adders). The lecture explicitly reuses the R/D/CB/B field layouts and assumes you know what a mux and a clocked register are.
What it leads to: Pipelining (the single-cycle "clock limited by slowest instruction" weakness is the direct motivation), hazards and branch handling, and the Verilog single-cycle CPU project (slides 69–70 literally start the Verilog implementation — this matches the LEGv8 Verilog/Vivado project).


Textbook page references handwritten on slides:


pg. 264 — Instruction memory (slide 10)
pg. 265 — Fetch datapath, FIGURE 4.6 (slide 13); Register File (slides 15, 16, 17)
pg. 267 — Data memory (slide 20)
FIGURE 4.6 caption transcribed verbatim (slide 13): "A portion of the datapath used for fetching instructions and incrementing the program counter. The fetched instruction is used by other parts of the datapath."



2. CONCEPT BREAKDOWN


2.1 The Processor = Datapath + Control

One-line definition: A processor is the combination of a datapath (the roads data travels on) and control (the traffic director choosing which road is used).

Visual-first explanation: Picture a city. The datapath is the entire road network — every street between the register file, the memory, the ALU. The control is the set of traffic lights and signposts deciding, for each instruction, which streets are open and which direction traffic flows. Same roads every cycle; different light pattern per instruction.

Exact slide details: Slide 1 shows the P&H "Computer" illustration with Control marked ② and Datapath marked ① inside the Processor block, next to Memory, Input, Output.

[PROF NOTE] "Processor is formed by the combination of: ① Datapath — The path that data flows. (From registers, memory, instructions etc.) ② Control — Decides which datapath will be used."

Misconceptions / exam traps:


Control does not move data; it only selects. If asked "which part computes X1+X2?" the answer is the datapath (ALU), even though control chose the add operation.
"Datapath" is singular hardware reused by every instruction — not a separate path built per instruction.



2.2 The Stored-Program Execution Loop

One-line definition: The processor endlessly repeats: fetch an instruction from memory, decode & execute it, update the PC to point at the next instruction.

Visual-first explanation: Imagine a librarian (the CPU) with a bookmark (PC). Loop forever: go to the bookmarked shelf slot, take the card (fetch), read what the card says to do (decode: "what is it doing?"), do it (execute), then move the bookmark forward (PC update). A big arrow on the slide loops from the bottom back to the top, labeled "Repeat."

Exact slide details (slide 2, transcribed):


"Instructions in a stored program are retrieved from memory." — retrieved is double-underlined in red with [PROF NOTE] "Fetched" written above it.
"The instruction gets decoded and executed by the hardware." — red arrow pointing to [PROF NOTE] "what is it doing?"
"Program Counter gets updated for the next instruction."
A red arc connects the last line back to the first, labeled [PROF NOTE] Repeat.


Misconceptions / exam traps:


"Retrieved" and "fetched" are the same thing — the prof flags this vocabulary equivalence explicitly.
The PC update is part of every instruction, not only branches.



2.3 Von Neumann vs. Harvard Architecture

One-line definition: Von Neumann stores program and data in one shared memory (one bus); Harvard stores them in separate memories with separate buses.

Visual-first explanation: Von Neumann = one warehouse with a single driveway: instruction trucks and data trucks must take turns (queueing = the bottleneck). Harvard = two warehouses, each with its own driveway: an instruction truck and a data truck can drive simultaneously, and the two driveways don't even need to be the same width.

Exact slide details:


Slide 3: "In terms of instruction allocation in memory, there are two types of approach. ① Von Neumann Architecture — Single memory (The program and the data are stored in the same memory). ② Harward Architecture [sic — professor's spelling] — Seperate memories [sic] (The program and the data are stored in different memory space)."
Slide 4 (Von Neumann diagram): CPU (blue box) ↔ Main Memory (green box). One-directional Address Bus (CPU → Memory), bidirectional Data Bus. [PROF NOTE] "Bus: Communication system that transfers data." Red note on the data bus: "Both instruction & data uses this bus." with arrow to [PROF NOTE] "Von Neumann bottleneck".
Slide 5 (Harvard diagram): Instruction Memory ↔ CPU ↔ Data Memory, each side with its own Address Bus + Data Bus. [PROF NOTE] (red, top): "They don't need to be identical, can have different widths." [PROF NOTE] (red, right): "They use different buses."
Slide 6 comparison: ① Von Neumann — "Same bus → CANT access instruction and data at the same time." (CANT in red). Red note: "Operating system does arrangements so that the programs do not overwrite each other." "* Control unit is less costly." ② Harvard — "Different bus → CAN access instruction and data at the same time." (CAN in red). [PROF NOTE — blue, double-arrow emphasis] "We are going to use Harvard!"


Misconceptions / exam traps:


The address bus is one-way (CPU→memory); the data bus is two-way. Students often draw both bidirectional.
"Less costly control unit" is a Von Neumann advantage — easy to misattribute to Harvard.
The single-cycle design requires Harvard-style separate instruction/data memories (see 2.13) — a favorite exam "why?" question.



2.4 Single-Cycle Processor

One-line definition: A processor design where every instruction completes in exactly one clock cycle, so the clock period must fit the slowest instruction.

Visual-first explanation: Imagine a metronome where every tick must be long enough for the slowest dancer (the load instruction, which travels the longest route: PC → instr mem → registers → ALU → data memory → back to registers). Fast dancers (add) finish early and wait; the tick can never be shortened below the slow dancer's routine.

Exact slide details (slide 7): "Our implementation will be a Single Cycle Processor. ↳ Executes an instruction in 1 cycle. The cycle period is limited by the slowest instruction."
Slide 29: "Priorly we said that our design will be a Single Cycle Processor, this also means that no datapath resource can be used more than once per instruction. So we need to duplicate if we need more." (last sentence in red)
Slide 30: "Since the processor operates in one cycle and can not use a single memory for two different address access within that cycle, we will use seperate memories for data and instructions." (seperate double-underlined in red)

Misconceptions / exam traps:


CPI = 1 for single-cycle, but that does NOT mean it's fast — the cycle itself is long. Performance trap question.
"No resource reused per instruction" is why there are two adders (PC+4 adder, branch adder) plus the ALU, and two memories. If you see duplicated hardware, this rule is the reason.



2.5 Edge-Triggered State Elements

One-line definition: All state-holding components (PC, register file, memories) update on the clock edge.

Exact slide details (slide 8): "Let's check the needed components... [PROF NOTE] PS: They are edge triggered." with a drawing of a box with clk →▷ (the triangle clock-input symbol).
Slide 32 [PROF NOTE]: clk "(will not show since it makes the design too complicated but they are edge triggered)" — the clock wire is drawn once into PC and Instr. Mem. and then omitted from later diagrams.

Misconceptions / exam traps: The clock is invisible in most datapath diagrams but is always there. The ▷ triangle on PC/memories in slides 32+ is the clock input.


2.6 Component ① Instruction Memory

One-line definition: Read-only-during-execution storage that takes an instruction's address as input and outputs that instruction.

Visual-first explanation: A vending machine for instructions: type a slot number (address) in, the 32-bit instruction drops out. No write port — programs aren't modified while running.

Exact slide details (slide 10, textbook pg. 264): Block with input "Instruction address", output "Instruction". "Stores the instructions." [PROF NOTE — blue]: "give the desired instruction's address as input" (left arrow), "get the instruction as output" (right arrow).


2.7 Component ② Program Counter (PC)

One-line definition: A register that stores the address of the instruction being processed.

Visual-first explanation: The bookmark. One small box labeled PC, an arrow in (next address) and an arrow out (current address). It is a register — 64 bits wide in LEGv8 — clocked like everything else.

Exact slide details (slide 11): "PC Register stores the address of processed instruction."

Misconceptions / exam traps: PC holds an address, never the instruction itself.


2.8 Component ③ Adder

One-line definition: A fixed-function arithmetic block that always adds its two inputs (used for PC+4 and branch targets).

Visual-first explanation: The trapezoid-with-a-notch shape ("Add / Sum"). The professor jokes it "looks like pants ☺" [PROF NOTE, slide 12 — with a picture of orange pants pasted next to the symbol]. An alternative hand-drawn chevron >+ symbol is shown: [PROF NOTE] "Also shown as this."

Exact slide details (slide 12): "We need an adder to calculate the next instruction's address."
Slide 13 (FIGURE 4.6, pg. 265): PC → Instruction memory (Read address → Instruction out); PC also → Add, second Add input is constant 4, Add output loops back to PC. [PROF NOTE — blue] "PC += 4". The constant 4 is circled in red: [PROF NOTE] "32 bits (1 instruction size = next instruction)".

Misconceptions / exam traps:


Why 4? Because one instruction = 32 bits = 4 bytes, and LEGv8 instruction memory is byte-addressed. (Contrast with branch offsets, which count words — see 2.16.)
The Adder is NOT the ALU: adders are dedicated, un-selectable; the ALU has an operation-select input.



2.9 Component ④ Register File

One-line definition: The component storing the 32 general-purpose registers (X0–X31), with two read ports and one write port.

Visual-first explanation: A cabinet of 32 numbered drawers. Three small 5-bit "dials" on the front: which drawer to read (×2: Read register 1, Read register 2) and which drawer to write (Write register). Two output chutes (Read data 1, Read data 2), one input slot (Write Data), and one master switch: RegWrite — writing only happens when this enable is ON.

Exact slide details:


Slide 14: "We need to access registers. ADD X0, X1, X2 → [PROF NOTE — red] X0 = X1 + X2. Access data of X1 & X2. Write data to X0. The 32 general purpose registers (X0–X31) are stored in a component called Register File."
Slide 15 (pg. 265): port diagram — Read register 1 (5 bits), Read register 2 (5 bits), Write register (5 bits), Write Data (data input), Read data 1, Read data 2 (data outputs), RegWrite (blue, bottom). [PROF NOTE — green] "Give the register numbers as input (0–31)". [PROF NOTE — blue] "control to enable write".
Slide 16 (read walkthrough): [PROF NOTE — red] "If we only want to read a register value → give the value [register number] → read data" out of Read data 1; RegWrite arrow: "select as disabled".
Slide 17 (write walkthrough): [PROF NOTE — red] "If we want to write to a register → give the number (to Write register), give the data (to Write Data), enable (RegWrite)."


Why 5 bits? 2⁵ = 32 registers. This number appears on every port slash.

Misconceptions / exam traps:


Reads need NO enable signal (they're combinational, always happening); only the write needs RegWrite=1. Classic trap: "what must RegWrite be for STUR?" → 0.
Two read ports exist because R-format instructions read two sources simultaneously (single cycle = no taking turns).



2.10 Component ⑤ ALU (Arithmetic Logic Unit)

One-line definition: The selectable compute block that performs add/sub/and/orr on two 64-bit inputs, also outputting a Zero flag.

Visual-first explanation: The pants-shaped block again, but with a control dial on top: "ALU operation" (4-bit in the textbook figure; 2-bit ALUop in the prof's own design). Feed it two 64-bit values; the dial picks which math happens; outputs "ALU result" plus a side LED labeled Zero/isZero that lights when the checked value is zero.

Exact slide details:


Slide 18: "We need to do arithmetic operations so we need an ⑤ Arithmetic Logic Unit (ALU)". Diagram shows 4-bit "ALU operation" input (blue). [PROF NOTE — blue] "select which operation to calculate (add, sub etc.)".
Slide 24: the textbook ALU symbol with a grey "Zero" output appears: [PROF NOTE — red] "updated the ALU to check if 0."
Slide 48 [PROF NOTE — green]: "I will update the ALU to out a zero flag if the input is 0. (I'll use data2 because I already have [4:0] muxed to address2) → (if data2 == 0, zero flag = 1)". The flag is labeled isZero (green) on the ALU in all later diagrams.
Final ALU spec (slide 69 Verilog): inputs data1, data2 (each 64 bits), ALUop (2 bits); outputs result (64 bits), isZero. Encodings: 00 = add, 01 = sub, 10 = and, 11 = orr.


Misconceptions / exam traps:


In the professor's design, isZero checks data2 directly (the register value routed to the ALU's second input), NOT the ALU result. This differs from the textbook (where Zero flags the ALU result of a subtraction). The prof's CBZ therefore needs no subtraction — ALUop is don't-care (XX) for CBZ.
ALUop is 2 bits in this design (4 ops), even though the textbook drawing shows a 4-bit ALU operation field.



2.11 Component ⑥ Data Memory

One-line definition: The memory holding program data, with separate read and write enables (MemRead/MemWrite — later renamed DREn/DWEn).

Visual-first explanation: A storage warehouse with one address keypad, one inbound conveyor (Write data), one outbound conveyor (Read data), and two switches on the roof: MemWrite (enable writing) and MemRead (enable reading). Both off = warehouse ignored this cycle.

Exact slide details:


Slides 20–22 (pg. 267): "We need to access to data so we need a ⑥ Data Memory." Ports: Address, Write data (inputs); Read data (output); MemWrite (top, blue), MemRead (bottom, blue). [PROF NOTE — blue] "controls to enable read or write mode."
Slide 21 read walkthrough [PROF NOTE — red]: "give the address to read from" → Address; "get the data" ← Read data; "enable" → MemRead.
Slide 22 write walkthrough [PROF NOTE — red]: "give the address to write to", "give the data to write to" → Write data; "enable ↳ MemWrite".
In the combined datapath (slides 44+), the enables are renamed DREn (Data Read Enable) and DWEn (Data Write Enable), and the data input port is labeled Data.


Misconceptions / exam traps:


Unlike the register file (read always on), data memory reads ALSO need an enable. Asymmetry trap.
Only LDUR sets DREn=1; only STUR sets DWEn=1; every other instruction has both at 0 — and you may NOT write X (don't care) for these enables (see 2.18).



2.12 Component ⑦ Sign Extend Unit

One-line definition: Stretches a short signed immediate (e.g., the 9-bit D-format offset) to the full 64-bit register width by replicating the sign bit.

Visual-first explanation: A rubber-band stretcher: a 9-bit value enters, gets stretched to 64 bits, and the leftmost (sign) bit's color is painted across all the new bits — so negative stays negative.

Exact slide details (slide 23): "We also need a ⑦ Sign Extend Unit. The D format has 9 bit offset. The ALU we already have, has input ports of 64 bits. (Registers are 64 bits). We don't want to use an additional ALU unit." Hand-drawn: 9 →[Sign Extend]→ 64 feeding the ALU's lower input, whose other input is 64. Slide 28 shows the textbook oval "Sign-extend" symbol with a 64 output.

Misconceptions / exam traps:


The motivation is reuse: rather than a second narrow ALU, extend the immediate and reuse the existing 64-bit ALU.
After slide 49 the sign-extend input is muxed (M4) between THREE widths: [20:12] (9-bit D offset), [23:5] (19-bit CB offset), [25:0] (26-bit B offset). All extend to 64.



2.13 Instruction Formats & Bit Slices (as used in the build)

One-line definition: Fixed bit-field layouts that tell the datapath which wires carry register numbers, opcodes, and offsets.

Exact field tables shown on slides:


R-format (slide 33, printed table): opcode [31:21] | Rm [20:16] | shamt [15:10] | Rn [9:5] | Rd [4:0]
Worked example (red): add X0, X1, X2 → opcode=[31:21], X0=[4:0], X1=[9:5], X2=[20:16].
D-format (slide 42, printed table): opcode [31:21] | DT_address [20:12] | op [11:10] | Rn [9:5] | Rt [4:0]
Worked example (red): LDUR X0, [X1, #off] → X0=[4:0], X1=[9:5], off=[20:12] → sign extend → "X1+(off)".
CB-format (slide 47, printed table): Opcode [31:24] | COND_BR_address [23:5] | Rt [4:0]
Worked example (red): cbz X0, #off → X0=[4:0], off=[23:5]. Semantics: "if zero PC += off<<2 else PC += 4".
B-format (slide 50, printed table): opcode [31:26] | BR_address [25:0]
Worked example (red): B #off → off=[25:0]. Semantics: "PC += off << 2".


Misconceptions / exam traps:


In R-format, the destination Rd is the LOWEST bits [4:0] — written first in assembly but last in the encoding. Most common slicing error.
The CB offset is 19 bits ([23:5]); the prof wrote "19 bits → relative to branch instruction address → PC + sign extend(#offset)" on slides 24–25.
The instruction word is 32 bits, but registers/addresses are 64 bits — the [9:5] etc. slices are 5-bit register numbers, not data.



2.14 Load & Store Semantics (LDUR / STUR)

One-line definition: LDUR copies memory→register; STUR copies register→memory; both compute the address as base register + sign-extended offset.

Exact slide details (slide 19, transcribed):


Ⓐ LDUR X1, [X2, #off] → [PROF NOTE — red] "we need to read the value of X2, access X2+off in memory, write result to X1."
Ⓑ STUR X1, [X2, #off] → [PROF NOTE — red] "we need to read the value of X2 and X1, access X2+off in memory, write X1's value to memory."
"So we need the register file and ALU to add." (the ALU computes base+offset)


Misconceptions / exam traps:


STUR reads TWO registers (base X2 AND data X1) but writes none. LDUR reads one and writes one. Drives the M3/RWEn control values.
The ALU performs add (ALUop=00) for both LDUR and STUR — it's computing the address, not the data.



2.15 Conditional & Unconditional Branches (CBZ / B)

One-line definition: CBZ jumps by a sign-extended, word-scaled offset if a register equals zero (else falls through to PC+4); B always jumps.

Exact slide details:


Slide 24: "Branches: CBZ X1, offset" — offset marked 19 bits, [PROF NOTE — red] "relative to branch instruction address ⇓ PC + sign extend(#offset)"; "is zero?" annotation under X1; ALU "updated... to check if 0."
Slide 26: "CBZ branches conditionally. So it may branch PC = PC + (off<<2) ← [PROF NOTE — red] 'branch is taken' — or it may not branch PC = PC + 4 ← 'branch is not taken'."
Slide 27: "B branches unconditionally. PC = PC + (off << 2)"


Misconceptions / exam traps:


Branch target is relative to the branch instruction's own address (current PC), not PC+4 in this course's formulation. Use the formulas exactly as given: taken → PC = PC + (off<<2).
"Taken / not taken" vocabulary introduced here is the foundation for branch prediction later.



2.16 The "<<2" Word-Offset Rule (Shift Left 2)

One-line definition: LEGv8 branch offsets count words (instructions), so the hardware multiplies the offset by 4 — implemented for free by gluing "00" onto the right.

Visual-first explanation: The offset says "jump 3 instructions", but addresses count bytes, and each instruction is 4 bytes. So shift left by 2 (×4). Since shifting a constant amount left just appends zeros, no real shifter circuit is needed — just wire the bits over and tie the bottom two to 0.

Exact slide details (slide 25, [PROF NOTE — red flag symbol]): "LEGv8 branch operations: <<2 to make word offset! We are counting words not bytes! Some ISAs count bytes. ↳ Because of this we need a shifter, but we can simply concatenate '00' to the right."
A dedicated Shift Left 2 box appears in the datapath from slide 49 onward, feeding the branch adder.

Misconceptions / exam traps:


PC+4 uses bytes (+4 bytes); branch offsets use words (<<2 converts words→bytes). Mixing these up is the #1 numeric error in branch-target calculations.
"Concatenate 00" = shift-left-2 for this fixed case; no barrel shifter required.



2.17 The Incremental Datapath Build (slides 31–51) — the five muxes

One-line definition: The full datapath emerges by adding hardware instruction-by-instruction; every point where two sources compete for one input gets a multiplexer (M1–M5).

Build sequence with exact details:


Fetch stage (slides 31–32): "① We need to fetch the instructions sequentially." Adder(+4) → PC → (64-bit address) → Instr. Mem. → 32-bit Ins output. Clock shown once then omitted [PROF NOTE on clk, see 2.5].
add (slides 33–35): "② Implement the instructions one by one: add, sub, and, orr, ldur, stur, cbz, b." Wire instruction slices into the register file: [9:5] → read1, [20:16] → read2, [4:0] → write1; data1 & data2 → adder(+); result → write data. Write enable labeled WEn (blue; later RWEn).
sub (slides 36–37): "bit format same as add." The bare adder is upgraded to an ALU with blue "op select — 0: add, 1: sub".
and (slides 38–39): op select widens to 2 bits: "00: add, 01: sub, 10: and".
orr (slides 40–41): "11: orr". (Bit format still same as add.)
ldur (slides 42–44): D-format. New red hardware: Sign Extend (fed by [20:12]) and Data Mem. (REn/WEn). Two muxes appear (blue labels):

M1 — ALU's 2nd input: "0: regdata, 1: extdata".
M2 — register write-back source: "0: mem, 1: alu".



stur (slides 45–46): "Same bits as ldur." Red wire: register data2 → Data Mem 'Data' input. New mux M3 on the register file's 2nd read-address: selects [20:16] or [4:0] (so STUR can read the Rt register through read2). [PROF NOTE — green]: "You can wire the [4:0] to read2 as well. I chose read2." [Meaning: the design choice was to mux [4:0] into the read2 address port.]
cbz (slides 47–49): CB format. ALU gains green isZero output (logic per 2.10). New red hardware (slide 49): Shift Left 2 box and a second branch adder computing PC + (off<<2). Two more muxes:

M4 — Sign Extend input select: [20:12] vs [23:5].
M5 — PC source select: PC+4 vs branch-adder output.



b (slides 50–51): B format, "PC += off<<2". M4 gains a third input [25:0] (M4 becomes a 2-bit-select, 3-input mux). M5 is forced to the branch side.


Misconceptions / exam traps:


Each mux exists because of a specific instruction pair conflict: M1 (R-type vs D-type ALU operand), M2 (LDUR vs R-type write-back), M3 (R-type Rm vs store/branch Rt), M4 (three offset widths), M5 (sequential vs branch PC). Knowing which instruction forced which mux is prime exam material.
There are three adding units total in the final design: PC+4 adder, branch adder, and the ALU — a direct consequence of "no resource reused in one cycle" (2.4).



2.18 The Control Table

One-line definition: A truth table mapping each instruction to the values of all 9 control signal groups: M1, M2, M3, M4, M5, RWEn, DWEn, DREn, ALUop.

Exact slide details:


Slide 52: "The Datapath ✓ } Processor / The Control ↳ To create the control unit we will first fill a table called the control table."
Slide 53: "✱ Show the instructions and the select bits for those instructions. (select bits from muxes, enables, ALU etc.)"
Slide 55: "Check where we need to use the Selection Bits. And name them. (no duplicate names, for clarity)" — every mux/enable circled in red on the datapath; names (blue): M1–M5, RWEn (register write), DWEn (data-mem write), DREn (data-mem read), ALUop.
Slide 58 [PROF NOTE — blue]: "You can use don't care (X) for MUXs, but not for disable/enable signals (RWEn, DREn, DWEn)."
Slide 57 [PROF NOTE — blue]: "Fill the table according to the instructions, such as: If I'm doing add operation which bits should I select from ALUop."


THE COMPLETE CONTROL TABLE (slides 59–67, transcribed exactly):

InstructionM1M2M3M4M5RWEnDWEnDREnALUopAdd010XX010000Sub010XX010001And010XX010010Orr010XX010011Ldur10X00010100Stur1X100001000cbz0X1010/1 (= isZero)000XXbXXX101000XX

Signal meaning legend (from [PROF NOTE]s, slides 59–66):


M1: 0 → use reg. data; 1 → use extend data (ALU 2nd operand)
M2: 1 → ALU data; 0 → memory data (register write-back source)
M3: 0 → use inst [20:16]; 1 → use inst [4:0] (read-register-2 address)
M4: 00 → [20:12] (D), 01 → [23:5] (CB), 10 → [25:0] (B); XX → not used
M5: 0 → PC += 4; 1 → branch target (PC + off<<2)
RWEn: 1 → write register file enabled; 0 → disabled
DWEn: 1 → data-memory write enabled; 0 → disabled
DREn: 1 → data-memory read enabled; 0 → disabled
ALUop: 00 add, 01 sub, 10 and, 11 orr; XX → ALU result unused
cbz M5 cell is highlighted green and written "0/1": [PROF NOTE — green, slide 65] "branch not taken ←0 / 1→ branch taken ... check isZero flag from ALU. isZero→1 ⇒ ①, isZero→0 ⇒ ⓪."


Misconceptions / exam traps:


X is permitted ONLY on mux selects, never on the three enables — writing X under RWEn/DWEn/DREn loses points and could corrupt state in real hardware.
LDUR's ALUop is 00 (add) even though it's a "load" — the ALU is doing address arithmetic.
cbz's M5 is the only data-dependent control value in the table (depends on isZero at runtime).
STUR: RWEn=0 but DWEn=1; LDUR: the mirror image. Swapping these two rows is the most common table error.



2.19 The Control Unit

One-line definition: A combinational block that reads the 11-bit opcode (instruction bits [31:21]) plus the isZero flag and outputs all nine control signal groups.

Visual-first explanation: A decoder box: opcode goes in the left; nine labeled wires fan out the right (M1, M2, M3, M4, M5, RWEn, DWEn, DREn, ALUop). A thin green wire (isZero) sneaks in from the ALU — used only to decide cbz's M5.

Exact slide details:


Slide 67: red Control Unit box; input opcode; green input iszero; outputs M1–M5, RWEn, DWEn, DREn, ALUop. [PROF NOTE — blue] "Checks opcode and selects the outputs accordingly." / "checks the iszero flag".
Slide 68: the complete final datapath — Control Unit wired in red on top; instruction bits [31:21] feed its opcode input; green isZero wire runs from ALU back to the Control Unit; all nine signals fan out to their circled destinations.
Slide 70 (Verilog header): input [10:0] opcode — confirming the opcode is 11 bits wide.


Misconceptions / exam traps:


The control unit input is [31:21] (11 bits) even for CB/B formats whose true opcodes are shorter ([31:24], [31:26]) — the prof's simplified design just feeds the top 11 bits.
isZero flows ALU → Control Unit → M5. The mux is not driven by the ALU directly.



2.20 Verilog: ALU module (slide 69, transcribed verbatim)

[PROF NOTE — blue]: "You can implement all of the components and wire them to each other."

verilogmodule ALU (
  input  [63:0] data1, data2,
  input  [1:0]  ALUop,
  output reg    iszero,
  output reg [63:0] result);

  always @* begin
    if (data2 == 0)
      iszero = 1;
    else iszero = 0;
    case (ALUop)
      2'b00: result = data1 + data2;
      2'b01: result = data1 - data2;
      2'b10: result = data1 & data2;
      2'b11: result = data1 | data2;
    endcase
  end
endmodule

Diagram: data1 (64), data2 (64) in; result (64), isZero (green) out; ALUop (2) below.


2.21 Verilog: Control Unit module (slide 70, transcribed verbatim)

verilogmodule Control_Unit (
  input  [10:0] opcode,
  input  iszero,
  output reg M1, M2, M3, M4, M5,
             RWEn, DWEn, DREn,
  output [1:0] reg ALUop);   // as written on slide

  localparam ADD = 11'b10001011000;   // [PROF NOTE - blue] "opcodes"
  // ⋮ (other opcodes elided on slide)

  always @* begin
    case (opcode)
      ADD: begin
        M1 = 0; M2 = 1;  // .....
      end
      // ⋮
      CBZ: begin
        M1 = 0; M3 = 1; M4 = 2'b01;
        M5 = iszero;     // ...
      end
      // ...
    endcase
  end
endmodule

[PROF NOTE — green]: "(Checks iszero as well" — the green iszero wire enters the block diagram at bottom-left. The 11-bit opcode bus is marked 11 / on the diagram.
Detail to notice: M5 = iszero; is the single line that implements conditional branching — the table's "0/1" cell in code form. (Also note M4 is assigned a 2-bit value 2'b01, consistent with the 3-input M4 mux.)


3. VISUALIZATION SPEC (Flutter animation/interaction instructions per concept)

3.1 Processor = Datapath + Control

City-map metaphor screen. Draw 4 rounded rectangles: RegisterFile (left), ALU (center), DataMemory (right), InstructionMemory (top). Connect with grey road-like paths (8px stroke). A floating "Control" traffic-light icon sits above. User taps an instruction chip (add / ldur) at the bottom: the roads used by that instruction animate to blue (AnimatedContainer color tween, 400ms) while unused roads dim to 20% opacity, and the traffic light "switches" (rotation tween). Caption updates: "Control decided WHICH path. Data flows ON the path."

3.2 Fetch–Decode–Execute Loop

Three stacked cards: FETCH, DECODE/EXECUTE, PC UPDATE, with a curved arrow from card 3 back to card 1 labeled "Repeat". A bookmark icon (PC) shows a hex address. Each tap of a "Tick clock" FAB advances a glowing highlight ring to the next card; on the third tap the PC value increments by 4 (AnimatedSwitcher on the text) and a small instruction card flies from a memory column into the FETCH card. Loop infinitely. State: step = tapCount % 3, pc = 0x40 + 4*floor(tapCount/3).

3.3 Von Neumann vs Harvard

Split screen toggle (SegmentedButton: "Von Neumann" / "Harvard"). Von Neumann: one green Memory box, one blue CPU box, ONE bidirectional data-bus line; spawn two dot streams (orange = instruction, purple = data) that must take turns — animate them queueing (the second stream pauses, a red "BOTTLENECK" badge pulses at the bus). Harvard: two green memory boxes flanking the CPU, two independent buses; both dot streams flow simultaneously, badge shows green "PARALLEL". A tappable info chip on each bus: tapping the address bus shows a one-way arrow; data bus shows two-way arrows.

3.4 Single-Cycle Clock Limitation

Horizontal timeline = one clock period (a long rounded bar). Below it, 4 instruction sprites with progress bars of different lengths: add (40%), orr (40%), stur (75%), ldur (100% — the longest). User drags a "clock period" handle leftward to shorten the cycle: when the period becomes shorter than the ldur bar, the ldur sprite flashes red and a "WRONG RESULT — cycle must fit slowest instruction" toast appears, snapping the handle back. Label: "Cycle period is limited by the SLOWEST instruction (ldur)."

3.5 Instruction Memory

Vending-machine widget: a column of 8 address slots (0x00…0x1C) each containing a 32-bit instruction chip. A numeric keypad (or slider) sets "Instruction address"; pressing GO animates the matching chip sliding out of the right side into an "Instruction" tray. No write controls visible — greyed-out padlock icon communicates read-only.

3.6 Program Counter

A single register box labeled PC with a 64-bit hex value, clock triangle ▷ at the bottom-left. Two ghost arrows: in (next address) and out (current address). Tap "clock edge" button: the value at the input visually latches into the box (scale-bounce animation), and the old value fades out the output side. Toggle switch "input = PC+4 / branch target" prepares the M5 concept.

3.7 Adder

The pants-shaped polygon (CustomPainter: trapezoid with a notch on the input side). Two input wires with editable number fields; output shows the live sum. Easter egg per the prof's joke: long-press the adder and a tiny pants emoji 👖 pops with the caption "looks like pants ☺". A second button morphs the symbol into the alternate chevron >+ drawing ("Also shown as this").

3.8 Register File

Cabinet of 32 drawer rows (ListView, X0–X31, each showing a 64-bit value). Left edge: three 5-bit dial widgets (Read reg 1, Read reg 2, Write reg — render as 5 toggleable bits with decimal preview). Right edge: two output trays (Read data 1/2). Bottom: RegWrite toggle (blue). Interactions: setting a read dial instantly highlights that drawer and copies its value to the tray (no enable needed — show "reads are always on" tooltip). Pressing "clock edge" with RegWrite=ON slides the Write-Data value into the selected drawer (drawer flashes green); with RegWrite=OFF the write bounces off (shake animation + red flash).

3.9 ALU

Pants shape with a 2-bit ALUop dial on top (4 positions: 00 add, 01 sub, 10 and, 11 orr). Two 64-bit input fields (data1, data2). Output panel: result + an LED labeled isZero. The LED logic must follow the prof's design: it lights green when data2 == 0 regardless of ALUop (tooltip: "this design checks data2, not the result!"). Changing the dial re-computes the result with a 200ms count-up animation.

3.10 Data Memory

Warehouse grid of 16 cells (addresses 0x00–0x78 step 8). Controls: Address field, WriteData field, two roof switches DREn / DWEn. With DREn=1, tapping GO highlights the addressed cell and pipes its value to the Read-data tray; with DREn=0 the tray shows "—" (disabled grey). With DWEn=1 + clock edge, WriteData slides into the cell. If both enables are 0, the whole warehouse dims (opacity 0.4) with caption "ignored this cycle".

3.11 Sign Extend Unit

A 9-bit binary editor row on the left. An animated stretch: on tap, the 9 bits slide right into positions [8:0] of a 64-bit row, and the leftmost bit's color floods cells [63:9] (staggered 15ms fill animation). Toggle the sign bit to watch the flood color flip (blue=0, red=1) and the decimal readout change (e.g., 111111111₂ stays −1). M4 extension mode: a dropdown switches input width 9 ([20:12]) / 19 ([23:5]) / 26 ([25:0]).

3.12 Instruction Format Slicer

A 32-cell bit ribbon (indices 31…0). Selecting an instruction from a dropdown (add X0,X1,X2, ldur X0,[X1,#8], cbz X0,#12, b #100) recolors contiguous spans per format (R: opcode[31:21] red, Rm[20:16] orange, shamt[15:10] grey, Rn[9:5] green, Rd[4:0] blue; D/CB/B analogous with their tables). Tapping a span pops a label: field name, bit range, decimal value, and which datapath port it feeds (e.g., "[9:5] → Read register 1"). Drag-quiz mode: field labels are shuffled below and must be dropped onto the right span.

3.13 Incremental Datapath Builder (core screen of the week)

Interactive canvas reproducing slides 31–51. Stage stepper with 9 stages: Fetch → add → sub → and → orr → ldur → stur → cbz → b. Each "Next" press drops the new hardware onto the canvas with a red-outline entrance animation matching the prof's red pen: stage1 PC+adder+InstrMem; stage2 RegisterFile wiring [9:5]/[20:16]/[4:0]; stage3 ALU replaces adder + 1-bit op select; stage4–5 op select grows to 2 bits (badge shows the growing legend 00/01/10/11); stage6 SignExtend + DataMem + mux M1 + mux M2; stage7 M3 + data2→Data wire; stage8 isZero (green LED) + ShiftLeft2 + branch adder + M4 + M5; stage9 M4 third input [25:0]. Every mux is a tappable trapezoid showing its select legend (e.g., M2: "0:mem / 1:alu"). "Run instruction" mode: pick any of the 8 instructions; an animated pulse traverses exactly the active wires, muxes snap to their table values, inactive blocks dim.

3.14 Shift-Left-2 Mini-Widget

A 19-bit offset value in cells; pressing "<<2" slides all bits two cells left and two grey "0" cells pop in on the right with caption: "concatenate '00' — no shifter circuit needed. Words → bytes (×4)." A counter shows offset 3 (words) becoming 12 (bytes).

3.15 Control Table Trainer

The exact 8×9 table from slides 59–67 rendered as an editable grid. Per-row play: selecting a row dims the datapath thumbnail above and lights the relevant wires. Fill-in mode: cells start blank; user taps a cell and picks from {0, 1, X, 00, 01, 10, 11, XX, 0/1}; validation rule engine enforces the prof's rule — entering X under RWEn/DWEn/DREn is ALWAYS marked wrong with the toast "Don't-care is for muxes only, never enables!" The cbz/M5 cell is special: it renders as a green split cell "0/1" and tapping it opens a mini isZero simulator (set register value → watch M5 flip).

3.16 Control Unit Decoder

A red Control Unit box. Left input: an 11-bit opcode strip (and a thin green isZero wire from below). Right: nine output pins with live values. User picks an instruction chip; the 11-bit opcode pattern types itself into the input (typewriter animation), then each output pin flips to its table value sequentially (80ms stagger). Toggle the green isZero switch while cbz is loaded to watch ONLY the M5 pin flip 0↔1 ("the one runtime-dependent signal").

3.17 Verilog Peek Panels

Two read-only code cards (syntax highlighted) for ALU and Control_Unit exactly as transcribed in §2.20/2.21. Tapping case (ALUop) lines highlights the matching dial position in the ALU widget; tapping M5 = iszero; flashes the M5 mux in the datapath canvas. Caption: "You can implement all of the components and wire them to each other."


4. QUIZ BANK (JSON)

json[
  {"q": "According to the lecture, a processor is formed by the combination of which two parts?", "options": ["Datapath and Control", "ALU and Memory", "Registers and Cache", "Fetch unit and Decode unit"], "answer": 0, "difficulty": 1, "concept": "Processor = Datapath + Control", "explanation": "Slide 1: ① Datapath — the path that data flows (registers, memory, instructions etc.); ② Control — decides which datapath will be used."},
  {"q": "In the professor's notes, what one-word synonym is written above 'retrieved' for getting an instruction from memory?", "options": ["Fetched", "Loaded", "Decoded", "Dispatched"], "answer": 0, "difficulty": 1, "concept": "Fetch-decode-execute loop", "explanation": "The prof double-underlined 'retrieved' and wrote 'Fetched' — they mean the same thing."},
  {"q": "Why can't a Von Neumann machine access an instruction and data at the same time?", "options": ["They share the same bus and memory", "The ALU is busy", "The PC blocks the data bus", "Instructions are wider than data"], "answer": 0, "difficulty": 1, "concept": "Von Neumann vs Harvard", "explanation": "Same bus → CANT access instruction and data at the same time (slide 6). This queueing is the Von Neumann bottleneck."},
  {"q": "Which advantage belongs to the VON NEUMANN architecture in the lecture notes?", "options": ["Control unit is less costly", "Buses can have different widths", "Instruction and data access in parallel", "Separate memories prevent overwrites"], "answer": 0, "difficulty": 2, "concept": "Von Neumann vs Harvard", "explanation": "Slide 6 lists '* Control unit is less costly' under Von Neumann. The other three describe Harvard. (Trap: the course design itself uses Harvard.)"},
  {"q": "In the single-cycle design, what limits the clock cycle period?", "options": ["The slowest instruction", "The fastest instruction", "The number of registers", "The opcode width"], "answer": 0, "difficulty": 1, "concept": "Single-cycle processor", "explanation": "Slide 7: 'The cycle period is limited by the slowest instruction' — every instruction must fit in one cycle, so the longest path (ldur) sets the period."},
  {"q": "Why does the single-cycle design need SEPARATE instruction and data memories?", "options": ["One memory can't serve two different address accesses in the same cycle", "Instructions are encrypted", "Data memory is faster technology", "The PC can only address 32 bits"], "answer": 0, "difficulty": 2, "concept": "Single-cycle + Harvard", "explanation": "Slide 30: the processor operates in one cycle and cannot use a single memory for two different address accesses within that cycle — also why no datapath resource is reused per instruction (slide 29)."},
  {"q": "The constant '4' wired into the PC adder represents what?", "options": ["One 32-bit instruction = 4 bytes", "Four registers read per cycle", "The 4-bit ALU operation field", "Four pipeline stages"], "answer": 0, "difficulty": 1, "concept": "PC += 4", "explanation": "Slide 13 circles the 4: '32 bits (1 instruction size = next instruction)' — instruction memory is byte-addressed, so the next instruction is 4 bytes ahead."},
  {"q": "Why are the register-number inputs of the Register File exactly 5 bits wide?", "options": ["2^5 = 32 registers (X0–X31)", "Registers are 5 bytes", "The opcode leaves only 5 bits", "5 bits match the ALUop width"], "answer": 0, "difficulty": 1, "concept": "Register File", "explanation": "32 general-purpose registers X0–X31 need ⌈log2(32)⌉ = 5 selection bits per port."},
  {"q": "For the instruction add X0, X1, X2, which bit slice carries the DESTINATION register X0?", "options": ["[4:0]", "[9:5]", "[20:16]", "[31:21]"], "answer": 0, "difficulty": 2, "concept": "R-format slicing", "explanation": "R-format: opcode[31:21], Rm[20:16]=X2, Rn[9:5]=X1, Rd[4:0]=X0. The destination is written FIRST in assembly but lives in the LOWEST bits."},
  {"q": "In this course's ALU design (slide 48 & Verilog), the isZero flag is set when…", "options": ["the data2 input equals 0", "the ALU result equals 0", "the subtraction overflows", "ALUop = 00"], "answer": 0, "difficulty": 3, "concept": "isZero flag", "explanation": "Prof note: 'I will update the ALU to out a zero flag if the input is 0… (if data2==0, zero flag=1)'. The Verilog checks data2, not the result — different from the textbook's result-based Zero."},
  {"q": "TRACE: The instruction LDUR X5, [X3, #16] executes. Read the control signals for the write-back mux M2 and the memory enables.", "options": ["M2=0 (mem data), DREn=1, DWEn=0", "M2=1 (alu data), DREn=1, DWEn=0", "M2=0 (mem data), DREn=0, DWEn=1", "M2=X, DREn=1, DWEn=1"], "answer": 0, "difficulty": 2, "concept": "Control table — Ldur", "explanation": "Ldur row: M1=1, M2=0, M3=X, M4=00, M5=0, RWEn=1, DWEn=0, DREn=1, ALUop=00. Memory data is written back (M2=0) and only the read enable is on."},
  {"q": "TRACE: PC = 0x0040 and the instruction is CBZ X9, #6 with X9 = 0. What is the next PC?", "options": ["0x0058", "0x0044", "0x0046", "0x0064"], "answer": 0, "difficulty": 3, "concept": "Branch target arithmetic", "explanation": "X9==0 → isZero=1 → M5=1 → branch taken: PC = PC + (off<<2) = 0x40 + (6×4) = 0x40 + 24 = 0x58. If X9≠0 it would be PC+4 = 0x44."},
  {"q": "TRACE: For STUR X2, [X7, #8], which value reaches the Data Memory's 'Data' input, and through which register-file port is X2 read?", "options": ["X2's value, via read2 with M3=1 selecting bits [4:0]", "X7's value, via read1 with M3=0", "The sign-extended 8, via M1", "The ALU result, via M2"], "answer": 0, "difficulty": 3, "concept": "STUR datapath", "explanation": "Stur row: M3=1 routes instruction bits [4:0] (Rt=X2) into the read-register-2 port; data2 is wired to Data Mem's Data input. The prof's green note: 'You can wire the [4:0] to read2 as well. I chose read2.'"},
  {"q": "Which control signals may NEVER be filled with a don't-care (X) in the control table?", "options": ["RWEn, DWEn, DREn", "M1 and M2", "M4 and ALUop", "M5 only"], "answer": 0, "difficulty": 2, "concept": "Control table rules", "explanation": "Slide 58: 'You can use don't care (X) for MUXs, but not for disable/enable signals (RWEn, DREn, DWEn)' — a floating enable could corrupt registers or memory."},
  {"q": "TRACE: An unknown instruction drives M4=10 and M5=1, with RWEn=DWEn=DREn=0 and ALUop=XX. Which instruction is it?", "options": ["b", "cbz", "ldur", "orr"], "answer": 0, "difficulty": 3, "concept": "Control table — reverse lookup", "explanation": "M4=10 selects the [25:0] B-format offset and M5=1 unconditionally takes the branch adder; nothing is written or read → b. (cbz uses M4=01 and M5=isZero.)"},
  {"q": "In the Control_Unit Verilog, which single assignment implements the conditional behavior of cbz?", "options": ["M5 = iszero;", "M4 = 2'b01;", "RWEn = 0;", "result = data1 - data2;"], "answer": 0, "difficulty": 2, "concept": "Control Unit Verilog", "explanation": "Slide 70: in the CBZ case, M5 = iszero; routes the runtime flag straight onto the PC-source mux select — the table's '0/1' cell in code."}
]


5. FLASHCARDS (JSON)

json[
  {"front": "Datapath", "back": "The path that data flows (from registers, memory, instructions etc.) — the hardware roads of the processor.", "concept": "Processor basics"},
  {"front": "Control", "back": "The part of the processor that decides which datapath will be used for each instruction.", "concept": "Processor basics"},
  {"front": "Fetched / Retrieved", "back": "Getting an instruction from memory at the address in the PC — first step of every cycle; loop = fetch → decode/execute → PC update → repeat.", "concept": "Execution loop"},
  {"front": "Von Neumann architecture", "back": "Program and data in the SAME memory, sharing one bus → can't access instruction and data simultaneously (Von Neumann bottleneck); control unit is less costly; OS keeps programs from overwriting each other.", "concept": "Memory architecture"},
  {"front": "Harvard architecture", "back": "Program and data in SEPARATE memories with separate buses (which may have different widths) → instruction and data access can happen at the same time. Used in this course's design.", "concept": "Memory architecture"},
  {"front": "Bus", "back": "Communication system that transfers data. Address bus: one-way CPU→memory. Data bus: bidirectional.", "concept": "Memory architecture"},
  {"front": "Single Cycle Processor", "back": "Executes one instruction per clock cycle; cycle period is limited by the SLOWEST instruction; no datapath resource may be used more than once per instruction (duplicate hardware instead).", "concept": "Single-cycle design"},
  {"front": "Program Counter (PC)", "back": "Register storing the address of the processed instruction; updated every cycle to PC+4 or a branch target.", "concept": "Components"},
  {"front": "Instruction Memory", "back": "Stores the instructions. Input: instruction address. Output: the instruction. (pg. 264)", "concept": "Components"},
  {"front": "Why PC += 4?", "back": "One instruction is 32 bits = 4 bytes; memory is byte-addressed, so the next sequential instruction is 4 bytes ahead. (pg. 265, Fig 4.6)", "concept": "Fetch"},
  {"front": "Register File", "back": "Holds the 32 general-purpose registers X0–X31. Ports: Read register 1/2 and Write register (5 bits each), Write Data in, Read data 1/2 out, RegWrite enable. Reads need no enable; writes need RegWrite=1. (pg. 265)", "concept": "Components"},
  {"front": "ALU (this design)", "back": "64-bit compute unit. ALUop: 00=add, 01=sub, 10=and, 11=orr. Outputs result + isZero flag, where isZero=1 when data2==0 (checks the INPUT, not the result).", "concept": "Components"},
  {"front": "Data Memory", "back": "Holds program data. Ports: Address, Write data (Data), Read data; enables DREn (read) and DWEn (write) — both must be explicitly 0 or 1, never X. (pg. 267)", "concept": "Components"},
  {"front": "Sign Extend Unit", "back": "Stretches a short signed immediate (9-bit D offset, 19-bit CB offset, or 26-bit B offset, selected by mux M4) to 64 bits so the existing 64-bit ALU can be reused.", "concept": "Components"},
  {"front": "R-format fields", "back": "opcode[31:21] | Rm[20:16] | shamt[15:10] | Rn[9:5] | Rd[4:0]. add X0,X1,X2 → Rd=X0 in [4:0], Rn=X1 in [9:5], Rm=X2 in [20:16].", "concept": "Instruction formats"},
  {"front": "D-format fields", "back": "opcode[31:21] | DT_address[20:12] | op[11:10] | Rn[9:5] | Rt[4:0]. Used by LDUR/STUR; address = Rn + sign_extend(offset).", "concept": "Instruction formats"},
  {"front": "CB-format fields", "back": "Opcode[31:24] | COND_BR_address[23:5] (19 bits) | Rt[4:0]. cbz: if register==0 then PC += off<<2 else PC += 4.", "concept": "Instruction formats"},
  {"front": "B-format fields", "back": "opcode[31:26] | BR_address[25:0] (26 bits). b: PC += off<<2, unconditionally.", "concept": "Instruction formats"},
  {"front": "Why shift branch offsets left by 2?", "back": "LEGv8 branch offsets count WORDS, addresses count BYTES (some ISAs count bytes). <<2 multiplies by 4 — implemented by simply concatenating '00' on the right, no shifter circuit needed.", "concept": "Branches"},
  {"front": "Branch taken vs not taken (cbz)", "back": "Taken: PC = PC + (off<<2). Not taken: PC = PC + 4. Selected by mux M5, driven by the isZero flag.", "concept": "Branches"},
  {"front": "Mux M1", "back": "ALU second-operand select: 0 = register data (read data 2), 1 = sign-extended data. R-types use 0; ldur/stur use 1.", "concept": "Control signals"},
  {"front": "Mux M2", "back": "Register write-back source: 0 = memory data, 1 = ALU data. ldur uses 0; R-types use 1.", "concept": "Control signals"},
  {"front": "Mux M3", "back": "Read-register-2 address select: 0 = instruction [20:16] (Rm), 1 = instruction [4:0] (Rt). stur and cbz use 1 to read the Rt register.", "concept": "Control signals"},
  {"front": "Mux M4", "back": "Sign-extend input select: 00 = [20:12] (D format), 01 = [23:5] (CB), 10 = [25:0] (B). XX when no immediate is used.", "concept": "Control signals"},
  {"front": "Mux M5", "back": "PC source select: 0 = PC+4, 1 = branch target (PC + off<<2). For cbz it equals the runtime isZero flag; for b it is always 1.", "concept": "Control signals"},
  {"front": "RWEn / DWEn / DREn", "back": "Register-write, data-memory-write, data-memory-read enables. NEVER don't-care. R-types & ldur: RWEn=1. stur: DWEn=1 only. ldur: DREn=1 only.", "concept": "Control signals"},
  {"front": "Control table row: Add", "back": "M1=0, M2=1, M3=0, M4=XX, M5=0, RWEn=1, DWEn=0, DREn=0, ALUop=00 (sub/and/orr identical except ALUop 01/10/11).", "concept": "Control table"},
  {"front": "Control table row: Ldur", "back": "M1=1, M2=0, M3=X, M4=00, M5=0, RWEn=1, DWEn=0, DREn=1, ALUop=00 (ALU adds base+offset).", "concept": "Control table"},
  {"front": "Control table row: Stur", "back": "M1=1, M2=X, M3=1, M4=00, M5=0, RWEn=0, DWEn=1, DREn=0, ALUop=00.", "concept": "Control table"},
  {"front": "Control table row: cbz", "back": "M1=0, M2=X, M3=1, M4=01, M5=0/1 (= isZero), RWEn=0, DWEn=0, DREn=0, ALUop=XX.", "concept": "Control table"},
  {"front": "Control table row: b", "back": "M1=X, M2=X, M3=X, M4=10, M5=1, RWEn=0, DWEn=0, DREn=0, ALUop=XX.", "concept": "Control table"},
  {"front": "Control Unit", "back": "Combinational block: inputs = 11-bit opcode (instruction bits [31:21]) + isZero flag; outputs = M1–M5, RWEn, DWEn, DREn, ALUop. 'Checks opcode and selects the outputs accordingly.'", "concept": "Control unit"},
  {"front": "Edge-triggered", "back": "All state elements (PC, register file, memories) update on the clock edge (▷ symbol). The clk wire is omitted from diagrams 'since it makes the design too complicated, but they are edge triggered.'", "concept": "Timing"},
  {"front": "Verilog: M5 = iszero;", "back": "The single Control_Unit line that implements conditional branching for CBZ — the PC-source mux follows the ALU's zero flag at runtime.", "concept": "Verilog"}
]


6. BOSS BATTLE — "Resurrect the Single-Cycle CPU"

Scenario: The lab's LEGv8 single-cycle CPU lost its control ROM. The next instruction sitting in memory at PC = 0x0100 is LDUR X5, [X3, #24], and the one after it is CBZ X5, #5. Register X3 = 0x2000; data memory address 0x2018 contains the value 0. Rebuild the behavior stage by stage.

Stage 1 — Slice the instruction. Which bit fields of LDUR X5, [X3, #24] carry X5, X3, and 24?
✅ Answer: D-format → X5 = Rt = bits [4:0]; X3 = Rn = bits [9:5]; 24 = DT_address = bits [20:12].
Explanation: D-format: opcode[31:21] | DT_address[20:12] | op[11:10] | Rn[9:5] | Rt[4:0].

Stage 2 — Compute the memory address. What does the ALU output, and which control values make that happen (M1, ALUop)?
✅ Answer: M1 = 1 (use sign-extended data), ALUop = 00 (add) → ALU result = X3 + sign_extend(24) = 0x2000 + 0x18 = 0x2018.
Explanation: Loads use the ALU for ADDRESS arithmetic; M4 = 00 routes [20:12] into the sign extender first.

Stage 3 — Finish the LDUR control row. Fill M2, M3, M5, RWEn, DWEn, DREn.
✅ Answer: M2 = 0 (write back memory data), M3 = X, M5 = 0 (PC+4), RWEn = 1, DWEn = 0, DREn = 1.
Explanation: Memory is read (DREn=1) at 0x2018, the value 0 travels through M2=0 into register X5 on the clock edge (RWEn=1). Enables may never be X.

Stage 4 — Update the PC after LDUR. What is the new PC?
✅ Answer: M5 = 0 → PC = 0x0100 + 4 = 0x0104.
Explanation: Non-branch instructions always take the PC+4 adder path.

Stage 5 — Now CBZ X5, #5 executes at PC = 0x0104. What is isZero, and why — in THIS design specifically?
✅ Answer: X5 was just loaded with 0. M3 = 1 routes [4:0] (X5) to read-register-2; the ALU checks data2 == 0 directly (not a subtraction result) → isZero = 1.
Explanation: The prof's green note: "if data2 == 0, zero flag = 1" — ALUop is XX because the result is unused.

Stage 6 — Final PC. Compute the branch target.
✅ Answer: isZero = 1 → M5 = 1 → PC = PC + (off << 2) = 0x0104 + (5 × 4) = 0x0104 + 20 = 0x0118.
Explanation: The offset counts words; Shift-Left-2 concatenates "00" to convert to bytes. Full cbz row: M1=0, M2=X, M3=1, M4=01, M5=1(taken), RWEn=0, DWEn=0, DREn=0, ALUop=XX.

Victory condition: All six stages correct → "Control ROM rebuilt. CPU lives!"


7. CONNECTIONS


→ Pipelining (next major topic): The single-cycle weakness stated on slide 7 — "the cycle period is limited by the slowest instruction" — is the exact motivation for pipelining, which splits this week's datapath into fetch/decode/execute/memory/write-back stages. Every mux and signal named this week (M5/PCSrc especially) reappears as pipeline-stage hardware.
→ Branch prediction & hazards: "Branch taken / not taken" vocabulary (slide 26) and the runtime-dependent M5 = isZero signal are precisely what makes control hazards hard in pipelines — you can't know M5 until the ALU finishes.
← ISA weeks: The R/D/CB/B field tables are reused verbatim; this week shows WHY the encoding was designed that way (e.g., Rn always at [9:5] lets read-register-1 be wired directly with no mux).
← Digital logic: Muxes, edge-triggered registers, and adders from earlier weeks are the building blocks; the Control Unit is just a big combinational decoder (case statement).
→ Verilog CPU project: Slides 69–70 hand you the ALU and Control_Unit module skeletons — the project extends this by implementing all 7 components and "wiring them to each other."
→ Memory hierarchy (later weeks): The Harvard split (separate instruction/data memories) foreshadows split L1 I-cache / D-cache in real CPUs — modern machines are Von Neumann at main memory but Harvard at the cache level.
→ Performance chapter: Single-cycle CPI = 1 but with a long clock period — the CPU-time = IC × CPI × Tc equation explains why this design loses to multicycle/pipelined designs despite "1 cycle per instruction."



UNREADABLE PAGES

None — all 70 pages were legible and fully transcribed.
(Note: page 31 contains only the red headline "① We need to fetch the instructions sequentially" with the rest of the slide intentionally blank — it is the build-up frame for page 32. Pages 16–17, 21–22, 34–51 and 56–66 are progressive overlays of the same diagram; every unique annotation from each overlay is captured above.)