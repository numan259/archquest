# COMPUTER ARCHITECTURE — WEEK 8 SOURCE DOCUMENT
### Single-Cycle Limitations → Multi-Cycle Processors → Pipelining
*Extracted from annotated lecture slides (Patterson & Hennessy, LEGv8/ARMv8 + Harris & Harris ARM Edition). All handwritten notes transcribed verbatim as [PROF NOTE]. Source: 43-page annotated slide deck.*

---

# 1. WEEK OVERVIEW

**Topic title:** Processor Microarchitecture Performance — Why Single-Cycle Isn't Enough, Multi-Cycle Processors, and Pipelining

**Subtopics covered:**
1. Single-cycle processor recap and its fatal flaw (the critical path)
2. Why LDUR is the critical path instruction
3. Memory architecture requirement of single-cycle (separate instruction/data memories)
4. Multi-cycle processors — breaking instructions into steps
5. The 5 stages: Fetch, Decode, Execute, Memory, Writeback
6. Stage usage per instruction class (ADD, LDUR, STUR, CBZ)
7. Static vs. dynamic instructions (loop counting)
8. CPI (Cycles Per Instruction) for single-cycle vs. multi-cycle
9. Performance comparison via Execution Time (ET = CPI × #Instructions × Period)
10. Pipelining — the laundry analogy
11. Pipelined execution: resource utilization, no stage skipping
12. Quantitative timing comparison: single-cycle (3200 ps) vs. multi-cycle (3200 ps) vs. pipelined (1600 ps)

**Where this fits in the course narrative:**
- **What came before:** The single-cycle processor datapath (the same one Numan built in Verilog/Vivado for the course project) — PC, instruction memory, register file, ALU, data memory, control unit, sign extend. Week 8 opens by critiquing that design.
- **What this leads to:** Pipelining hazards (data hazards, control hazards, structural hazards), forwarding, stalling, and branch prediction. The closing slide ("can not skip a stage!") and the abstract pipeline view are the direct setup for hazard analysis.

**Textbook page references mentioned in slides:**
| Page ref | Slide page | Content |
|---|---|---|
| Pg. 285 | 38 | Instruction class timing table (P&H Fig 4.25) |
| Pg. 284 | 29 | Sequential laundry figure |
| Pg. 287 | 35 | Fig 4.26 — Single-cycle vs. pipelined execution |
| Pg. 298 | 21 | 5-stage datapath with stage boundaries |
| Pg. 310 | 37 | Fig 4.43/4.44 — Multi-clock-cycle pipeline diagram + single-clock-cycle slice |
| Pg. 427 | 36 | Fig 7.43 — Abstract view of pipeline in operation (Digital Design and Computer Architecture, ARM Edition — Harris & Harris) |

---

# 2. CONCEPT BREAKDOWN

---

## 2.1 Single-Cycle Processor (Recap & Critique)

**One-line definition:** A processor where every instruction — no matter how simple — completes in exactly one (long) clock cycle, so CPI = 1.

**Visual-first explanation:**
Picture one giant hallway that every instruction must walk through from end to end before the clock can tick again. A short errand (ADD) and a long errand (LDUR) both get the *same* time slot, and the slot must be long enough for the longest walk. The clock is a metronome set to the slowest walker.

**Exact details from the slides:**
- CPI = 1; all instructions finish in 1 cycle.
- The cycle period is set by the **critical path** — the longest-delay path through the hardware.
- Single-cycle processors are **not used today**.
- Requires **separate instruction memory and data memory** (to access both in the same cycle), but most real processors have a single external memory storing both — another strike against the design.

[PROF NOTE] "Single Cycle Processors are not used today. The CPI is 1 and all instructions finish in 1 cycle."
[PROF NOTE] "The cycle period is determined by the ~~Critical Path~~ (The path that needs the most time.)" — *"Critical Path" underlined in red wavy line*
[PROF NOTE] "Additionally to be able to access both instructions and data at the same time, Single Cycle Processors requires seperate memories for instructions & data. However most processors have a single external memory that stores both."

**Misconceptions / exam traps:**
- CPI = 1 sounds great but is misleading: the *cycle* is enormous. Low CPI ≠ fast processor.
- Trap: thinking the clock period is the *average* instruction delay. It's the *maximum* (critical path).
- Trap: forgetting the separate-memories requirement when asked "what are the disadvantages of single-cycle?"

---

## 2.2 Critical Path & Why LDUR Is the Longest

**One-line definition:** The critical path is the slowest signal route through the datapath in one cycle; in LEGv8 it belongs to LDUR because LDUR touches every major component.

**Visual-first explanation:**
Imagine the datapath as a subway map. Every instruction rides some route; LDUR rides the *full line*: it boards at instruction memory, stops at the register file, transfers through the ALU (to compute the address), rides all the way out to data memory, then comes *all the way back* to write into the register file. No other instruction makes the round trip.

**Exact details from the slides (page 2 hand-drawn datapath, red highlighted path):**
- Components in the drawing: **PC** (with mux m5 and +4 adder feeding it), **Instr. Mem** (64-bit address in, 32-bit instruction out), **Control Unit** (input = instruction bits [31:21]; outputs: m1, m2, m3, m4, m5, RWEn, DWEn, DREn, ALUop), **Reg. File** (read ports addressed by bits [9:5] and [20:16], write register from [4:0], write data port, RWEn), **Sign Extend** (selecting among bit fields [20:12], [23:5], [25:0] via mux m4), **ALU** (with ALUop and "iszero" output), **mux m2** (labeled 0: mem, 1: alu — actually feeding ALU operand selection), **mux m1** (labeled 0: regdata, 1: extdata), **Data Mem.** (DREn read enable, DWEn write enable), **Shift Left 2** (for branch target).
- The LDUR critical path is highlighted in red: Instr. Mem → Reg. File read → (Sign Extend → mux) → ALU → Data Mem. → back around to Reg. File write data.

[PROF NOTE] (red, page 2) "Critical Path (LDUR)" — *with the path traced in red highlighter through the hand-drawn datapath*
[PROF NOTE] (page 3) "Why LDUR is the longest? Because → reads data from register file → uses ALU for calculating address → reads data from data memory → writes back to the register file." (blue) "It passes through all stages/components"
[PROF NOTE] (page 4, red) "STUR ↳ does not write back to the register file. ADD/CBZ ↳ does not access memory. etc."

**The 10ns/160ns motivating example (page 5):**
- Assume ADD needs **10 ns**, LDUR needs **160 ns** (longest instruction → critical path is 160 ns).
- Clock period must be set to **160 ns** — if it were < 160, LDUR wouldn't complete.
- So ADD finishes in 10 ns but **waits 150 ns** doing nothing.

[PROF NOTE] "LDUR instruction needs 160ns ↳ longest instruction" / "critical path is 160ns → So we set the clock period to 160 ns. (if < 160 instruction wont complete)" / (blue) "So ADD finishes in 10ns but needs to wait 150 ns since the period is 160 ns. ↳ NOT GOOD ENOUGH!" — *"NOT GOOD ENOUGH!" in red caps*

**Misconceptions / exam traps:**
- Trap: "STUR also goes through memory, why isn't it the critical path?" — STUR *writes* memory but doesn't need the writeback hop to the register file afterward (700 ps vs 800 ps in the table later). The final register-write leg is what makes LDUR longest.
- Trap: assuming the clock can be set per-instruction in single-cycle. It can't — one fixed period for all.

---

## 2.3 Multi-Cycle Processors

**One-line definition:** A design that breaks each instruction into multiple short steps (one step per cycle), so simple instructions finish in fewer cycles than complex ones.

**Visual-first explanation:**
Instead of one giant hallway, chop the journey into rooms with doors. The clock now ticks once per *room*, not once per *journey*. An ADD walks through 4 rooms and exits; an LDUR walks through 5. Nobody waits around for the slowest traveler anymore — but each instruction still walks alone; only one instruction is in the building at a time.

**Exact details from the slides:**
- Steps an instruction can be broken into: read/write to memory, read/write to register file, use ALU.
- Different instructions use different numbers of steps, so simpler instructions complete faster.
- The clock period is now set by the **longest step** (memory), not the longest instruction.
- Step counts (multi-cycle): **ADD = 4 cycles** (F,D,E,W), **LDUR = 5 cycles** (F,D,E,M,W), **STUR = 4 cycles** (F,D,E,M), **CBZ = 3 cycles** (F,D,E).
- Because instructions take different cycle counts, **CPI ≠ 1**.

[PROF NOTE] (page 7) "~~Multi Cycle Processors~~ (red underlined title). Break an instruction into multiple steps. ✱ read/write to memory ✱ read/write to register file ✱ use ALU. Different instructions use different number of steps so simpler instructions can complete faster." (red) "No need to wait for the slowest instruction!!!"
[PROF NOTE] (page 10, single-cycle view of the stage chart, blue) "If the processor is a ~~single cycle~~ processor" / "each instruction is 1 cycle" / "1 clock cycle" (brace under all four instruction rows) / "→ period is measured by longest instruction (ldur)"
[PROF NOTE] (pages 11–12, multi-cycle view, green) "If the processor is a ~~multi cycle~~ processor" / "each step is 1 cycle" / "1 cycle" arrows under each stage column / "→ period is measured by longest step (memory)" / (red) "Different cycles for instructions. CPI ≠ 1" / *steps numbered ①②③④⑤ in red circles per instruction row*

**Misconceptions / exam traps:**
- Trap: multi-cycle is NOT automatically faster than single-cycle (proven on page 19 — see 2.7). The cycle count goes UP (e.g., 87 vs 23); you only win if the frequency increase outweighs the CPI increase.
- Trap: confusing multi-cycle with pipelining. Multi-cycle = one instruction at a time, in small steps. Pipelining = many instructions at once, one per stage.

---

## 2.4 The 5 Stages

**One-line definition:** Every instruction's journey decomposes into at most five stages — Fetch, Decode, Execute, Memory, Writeback.

**Visual-first explanation:**
Five stations on an assembly line, always in the same left-to-right order:

| # | Stage | What happens | Slide wording |
|---|---|---|---|
| 1 | **Fetch** | Read the instruction from memory | "got the instruction" |
| 2 | **Decode** | Read source operands from register file & produce control signals | "what is this instruction" |
| 3 | **Execute** | Computation with ALU | — |
| 4 | **Memory** | Read/write data memory | — |
| 5 | **Writeback** | Write to register file | — |

[PROF NOTE] (page 8) "5 Stages — Fetch: read the instruction from memory (blue: got the instruction). Decode: read the source operands from register file & produce control signals (blue: what is this instruction). Execute: computate with ALU. Memory: read/write data memory. Writeback: write to register file."
[PROF EMPHASIS] Page 8 includes a Mean Girls meme: **"STOP TRYING TO MAKE FETCH HAPPEN"** — the professor's joke anchor for remembering the Fetch stage.

**Stage usage by instruction (pages 9–12, "Steps for some instructions:" red underlined):**
- **ADD**: FETCH → DECODE → EXECUTE → WRITEBACK (skips Memory) — 4 steps
- **LDUR**: FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK — all 5 steps
- **STUR**: FETCH → DECODE → EXECUTE → MEMORY (skips Writeback) — 4 steps
- **CBZ**: FETCH → DECODE → EXECUTE (skips Memory and Writeback) — 3 steps

**Datapath mapping (page 21, textbook figure pg. 298):** The single-cycle datapath divided by dashed vertical lines into IF (instruction fetch), ID (instruction decode/register file read), EX (execute/address calculation), MEM (memory access), WB (write back) — professor labeled them in red handwriting: "Fetch, Decode, Execute, Memory, Writeback."
**Mapping from page 34:** Instruction fetch → Fetch; Reg → Decode; ALU → Execute; Data access → Memory; Reg → Writeback.

**Misconceptions / exam traps:**
- Trap: in the *multi-cycle* design, skipped stages are truly skipped (CBZ = 3 cycles). In the *pipelined* design, stages can NOT be skipped (see 2.9). This distinction is a classic exam question.
- Memorization aid: only LDUR uses all 5. STUR drops WB ("store doesn't come back"), ADD drops MEM, CBZ drops both.

---

## 2.5 Static vs. Dynamic Instructions

**One-line definition:** Static instructions = lines of code as written in memory; dynamic instructions = instructions actually executed at runtime (loops multiply them).

**Visual-first explanation:**
Static = the sheet music (7 bars on the page). Dynamic = the performance (the repeat sign makes you play some bars 5 times). The processor "hears" the performance, not the page.

**The running LEGv8 example (pages 13–19) — verbatim code:**
```
① addi  X9,  XZR, #0
② addi  X10, XZR, #5
③ addi  X20, XZR, #E
④ stur  X10, [X20, #0]
⑤ addi  X20, X20, #8
⑥ subi  X10, X10, #1
⑦ cbnz  X10, #-3
```
*(Note: "#E" is a hex immediate; XZR is the zero register.)*

**Static count (page 13):**
- The code has **7 instructions**. Each instruction is **32 bits (4 bytes)**, so the code takes **4 × 7 = 28 bytes** of memory space.
- The code has **7 static instructions** (red underlined).

**Dynamic count (pages 14–15):**
- `cbnz X10, #-3` loops back 3 instructions (to the `stur`), so the loop body = {stur, addi, subi, cbnz} = 4 instructions, numbered ③②① with "LOOPS BACK / go up 3 instructions" in blue.
- X10 starts at 5 and the loop runs while decrementing: initial part = 3 instructions, then the 4-instruction loop runs 5 times.
- **# of Dynamic Instructions = 3 + (4+4+4+4+4) = 3 + 5×4 = 23** — with X10 values written under each loop iteration: 4, 3, 2, 1, 0.

[PROF NOTE] (page 14, blue) "The code has 7 static instructions, however the processor is executing more than 7 instructions for this code. The instructions that are executed by the processor is called ~~dynamic instructions~~." (wavy underline)
[PROF NOTE] (page 15, blue) "If X10 = 7 initially, 3 + 7×4 = 31" / "Try to find an equation. → 3 + (X10 × 4)"

**Misconceptions / exam traps:**
- Trap: counting the loop as running 4 times instead of 5 (it runs until X10 hits 0: values 4,3,2,1,0 after each decrement = 5 passes starting from X10=5).
- Trap: forgetting the 3 initialization instructions in the total.
- The generalized equation **3 + (X10_initial × 4)** is the professor's explicit "find an equation" exercise — expect a variant with a different initial value on the exam.

---

## 2.6 CPI — Cycles Per Instruction

**One-line definition:** CPI = total cycles ÷ total *dynamic* instructions; single-cycle CPI = 1, multi-cycle CPI > 1 (here ≈ 3.78).

**Exact details from the slides:**
- **Single-cycle (page 16):** 23 dynamic instructions = **23 cycles**, **CPI = 1**. ("7 Static, 23 Dynamic Instructions" in red.)
- **Multi-cycle (page 17):** cycle counts per instruction (green): addi 4 cycles, stur 4 cycles, subi 4 cycles, cbnz 3 cycles. Total = 4+4+4 + 5×(4+4+4+3) = 12 + 5×15 = **87 cycles**. **CPI = 87 / 23 ≈ 3.78** — with a green arrow pointing at the 23: "dynamic ins."

[PROF NOTE] (page 17, green) "addi 4 cycle, stur 4 cycle, subi 4 cycle, cbnz 3 cycle" / "4+4+4+ 5×(4+4+4+3) = 87 cycles — loop" / "CPI = 87 / 23 ≅ 3.78" with arrow "dynamic ins."

**Misconceptions / exam traps:**
- Trap: dividing by static (7) instead of dynamic (23) instructions. The professor's arrow explicitly flags this.
- Trap: forgetting cbnz is only 3 cycles (no Memory, no Writeback) when summing the loop.

---

## 2.7 Performance Comparison (Execution Time)

**One-line definition:** Performance is compared via Execution Time = CPI × #Instructions × Clock Period; lower ET = faster; PerfA/PerfB = ETB/ETA.

**Visual-first explanation:**
Three dials multiply together: how many instructions, how many cycles each costs on average, how long each cycle lasts. Multi-cycle spins the CPI dial UP (bad) but the period dial DOWN (good). Which effect wins depends on the numbers — so you must *compute*, never assume.

**Exact details from the slides:**
- **Formula (page 18, red):** ET = CPI × #ofIns × Period. PerfA/PerfB = ETB/ETA (boxed: ETB in blue, ETA in green — note the inversion!).
- **Case 1 (page 18):** Multi-cycle processor A has frequency **5× faster** than single-cycle processor B.
  PerfA/PerfB = (1 × 23 × P) / (3.78 × 23 × P/5) — the 23s cancel (crossed out on the slide) — = **1.32 times faster** (A wins).
- **Case 2 (page 19):** Assume A has **3× freq instead of 5×**.
  PerfA/PerfB = **0.79** → **"B is faster!"** (red, double-underlined).

[PROF NOTE] (page 19, red) "Multi Cycle is not always faster, compare!" — *with emphatic exclamation mark*

**Misconceptions / exam traps:**
- Trap #1: PerfA/PerfB = ET**B**/ET**A** — execution time and performance are inverses. Students flip this constantly.
- Trap #2: instruction count cancels only because both processors run the same program (same 23 dynamic instructions).
- Trap #3: assuming multi-cycle always wins. The 3× case (0.79) is the professor's designed counterexample.

---

## 2.8 Pipelining — Concept & Laundry Analogy

**One-line definition:** Pipelining overlaps multiple instructions by letting each occupy a different stage simultaneously, like an assembly line — same latency per instruction, massively higher throughput.

**Visual-first explanation (the professor's laundry story, pages 23–33):**
Doing laundry has 4 steps: **wash → dry → fold → put away**. The slides build the joke step by step:
- STEP 1: ~~We~~ (The washing machine :p) are going to wash the clothes.
- STEP 2: ~~We~~ (The dryer :p) are going to dry the clothes.
- STEP 3: We are going to fold the clothes.
- STEP 4: Roommate is going to put the clothes away.

The punchline: each step uses a **different resource** (washer, dryer, you, roommate), so while load 1 is drying, load 2 can already be washing — "all can be done in parallel."

[PROF NOTE] (page 27, red) "all can be done in parallel" — brace over the four resource icons (washer, dryer, folded clothes, closet)
[PROF NOTE] (page 28, blue) "If 'We' needed to do all, then we needed to do them sequentially. ~~NEED SEPERATE RESOURCES!!~~" (underlined) — crossing out "washing machine/dryer/roommate" and writing "We" under each to show the sequential case. Side note: "In Single Cycle and multi cycle these steps were not done in parallel."
[PROF NOTE] (page 30) "But if I have seperate resources in each stage. (Instead of me swashing machine & dryer & roommate)" / (red) "Now we can do the loads in parallel."
[PROF NOTE] (page 31, red) Circle around the diagonal of simultaneous stages: "Utilization of resources 100% (No idle resource left)"

**The numbers (page 32):**
- **Not pipelined:** 4 loads × 4 steps each, sequential = **16 cycles** (red arrows: 4+4+4+4).
- **Pipelined:** first load takes 4 cycles, then each remaining load finishes 1 cycle later = 4+1+1+1 = **7 cycles**.

**Bridge to processors (page 33):** "Laundry Steps → Same goes with instruction steps" → FETCH | DECODE | EXECUTE | MEMORY | WRITEBACK.

**Pipelining motivation from hardware idleness (pages 20 & 22):** A 6-row diagram of LDUR's 5 stages across cycles 1–5, with exactly one stage highlighted green per cycle and the rest gray.
[PROF NOTE] (gray) "(Idle) not in use by hardware" → pointing at gray stages; (green) "in use by hardware" → pointing at the green stage.
[PROF NOTE] (page 22, red, scrawled with arrow at the idle stages) "lets use these too, why are they staying idle?" — *this is the motivating question for pipelining.*

**Textbook figures referenced:** sequential laundry pg. 284; Fig 4.26 single-cycle vs pipelined execution pg. 287 (LDUR X1,[X4,#100] / LDUR X2,[X4,#200] / LDUR X3,[X4,#400] shown both ways, with "1 cycle" arrows in blue for single-cycle and per-stage "1 cycle" arrows in red for pipelined).

**Misconceptions / exam traps:**
- Pipelining does NOT make one instruction faster (latency unchanged or slightly worse); it increases *throughput*.
- Pipelining requires **separate resources per stage** — exactly why the register file, ALU, and memories must not be shared between stages in the same cycle. (This foreshadows structural hazards.)
- Speedup for N tasks, S stages: not pipelined = N×S cycles; pipelined = S + (N−1) cycles. Check: 4 loads, 4 stages → 16 vs 7. ✓

---

## 2.9 Pipeline Rules — Cannot Skip a Stage

**One-line definition:** In a pipelined processor every instruction passes through all 5 stages in order, even stages it doesn't use, to keep the assembly line aligned.

**Visual-first explanation:**
The conveyor belt moves everything one station per tick. If ADD tried to skip the Memory station, it would crash into the instruction ahead of it. So ADD stands politely in the Memory station doing nothing for one cycle.

**Exact details from the slides (page 36, Fig 7.43, Harris & Harris pg. 427):**
- Legend: RF read (right-half shaded), RF write (left-half shaded), IM used, RF idle (unshaded).
- Instruction sequence shown: `LDUR R2,[R0,#40]`, `ADD R3,R9,R10`, `SUB R4,R1,R5`, `AND R5,R12,R13`, `STUR R6,[R1,#20]`, `ORR R7,R11,#42` — each starting one cycle after the previous, across cycles 1–10.

[PROF NOTE] (page 36, red) "Memory is not used by ADD (white) but we still show all of the stages of pipeline. ~~Can not skip a stage!~~" (underlined)

**Page 37 (Fig 4.43/4.44, pg. 310):** Five instructions (LDUR X10,[X1,#40]; SUB X11,X2,X3; ADD X12,X3,X4; LDUR X13,[X1,#48]; ADD X14,X5,X6) in a multiple-clock-cycle pipeline diagram across CC1–CC9; below it, the single-clock-cycle datapath snapshot at clock cycle 5 showing pipeline registers IF/ID, ID/EX, EX/MEM, MEM/WB — "a single-clock-cycle figure is a vertical slice through a multiple-clock-cycle diagram."

**Misconceptions / exam traps:**
- Trap: computing pipelined CBZ as 3 cycles. In the pipeline it still occupies all 5 stage slots.
- The register file trick (read in Decode, write in Writeback — shown as half-shaded RF in Fig 7.43) becomes critical for hazard questions later.

---

## 2.10 Quantitative Three-Way Comparison (The Timing Table)

**One-line definition:** With per-component delays, single-cycle ET = 3200 ps, multi-cycle ET = 3200 ps, pipelined ET = 1600 ps for the same 4-instruction dynamic mix.

**The timing table (pages 38–43, P&H pg. 285):**

| Instruction class | Instruction fetch | Register read | ALU operation | Data access | Register write | Total time |
|---|---|---|---|---|---|---|
| Load register (LDUR) | 200 ps | 100 ps | 200 ps | 200 ps | 100 ps | **800 ps** |
| Store register (STUR) | 200 ps | 100 ps | 200 ps | 200 ps | — | **700 ps** |
| R-format (ADD, SUB, AND, ORR) | 200 ps | 100 ps | 200 ps | — | 100 ps | **600 ps** |
| Branch (CBZ) | 200 ps | 100 ps | 200 ps | — | — | **500 ps** |

**Dynamic code for the exercise:** 1 LDUR, 1 STUR, 1 ADD, 1 CBZ. ("Lets say our ~~dynamic~~ code consists of…" — "dynamic" underlined in red.)

**① ET if single-cycle (page 39, blue):**
- LDUR → 800 ps (critical path) — *800 ps highlighted in the table.*
- Every instruction costs the critical path: 1 LDUR + 1 STUR + 1 ADD + 1 CBZ = 800+800+800+800 = **3200 ps**.

**② ET if multi-cycle (pages 40–41, green):**
- Cycle takes **200 ps** (longest step — fetch/ALU/data access columns highlighted green).
- LDUR 5 cycles + STUR 4 cycles + ADD 4 cycles + CBZ 3 cycles = **16 cycles**. 16 × 200 = **3200 ps**.
- *(Yes — identical to single-cycle here. The win only comes from frequency scaling, per 2.7.)*

**③ ET if pipelined (pages 42–43, orange):**
- Stage trace handwritten:
  ```
  ldur  F E D M W          ← (professor wrote F E D M W ordering loosely; canonical order F D E M W)
  stur    F E D M W
  add       F E D M W
  cbz         F E D M W
  ```
- 5 + 1 + 1 + 1 = **8 cycles**. 8 × 200 ps = **1600 ps** (underlined with a flourish).

**Misconceptions / exam traps:**
- The deliberate shock: single-cycle and multi-cycle tie at 3200 ps in this example. Multi-cycle's benefit appears only with the frequency argument; pipelining halves it outright.
- Pipelined cycle period = longest STAGE (200 ps), same as multi-cycle — pipelining wins on overlap, not on a faster clock.
- Formula to remember: pipelined cycles = stages + (instructions − 1) = 5 + (4−1) = 8.

---

# 3. VISUALIZATION SPEC

*Written as instructions to a Flutter developer. Suggested palette mirrors the professor's pen colors: red = emphasis/titles, blue = single-cycle, green = multi-cycle, orange = pipelined, gray = idle.*

## 3.1 "The Slow Hallway" — Single-Cycle Critical Path
- **Layout:** Simplified datapath as 6 rounded-rect nodes left→right: [Instr Mem] → [Reg File] → [ALU] → [Data Mem] → [Reg File (WB)] with a [Sign Extend] node below feeding the ALU. Connect with `CustomPainter` bezier wires.
- **Interaction:** Bottom bar with 4 instruction chips: ADD, LDUR, STUR, CBZ. User taps a chip.
- **Animation:** A glowing dot travels the instruction's route (≈300 ms per hop). Nodes light up amber while occupied. Nodes the instruction skips stay dim gray. After arrival, each traversed node shows its delay label (200/100/200/200/100 ps) and a running total counts up in a `TweenAnimationBuilder` to the instruction total (800/700/600/500).
- **State:** After all 4 chips tried, a red wavy underline (mimic prof's pen) appears under "Critical Path = LDUR 800 ps" and a clock face widget locks its period to 800 ps with the caption "everyone waits for the slowest."
- **Bonus beat:** Tap ADD after the lock — ADD's dot finishes at 600 ps, then an idle timer ticks the remaining 200 ps in red with the prof quote "NOT GOOD ENOUGH!"

## 3.2 Stage Cards — The 5 Stages
- **Layout:** 5 horizontally scrollable cards: FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK. Each card front = stage name + icon (📥 fetch, 🔍 decode, ⚙ execute, 💾 memory, ✍ writeback).
- **Interaction:** Tap to flip (`AnimatedSwitcher` with 3D Y-rotation). Back shows the one-line definition + prof's blue parenthetical ("got the instruction" / "what is this instruction").
- **Easter egg:** Long-press FETCH → show the "STOP TRYING TO MAKE FETCH HAPPEN" meme caption as a toast. Memory anchor, costs nothing.

## 3.3 Stage Ladder — Which Instruction Uses Which Stages
- **Layout:** 4 rows (ADD, LDUR, STUR, CBZ) × 5 columns (F, D, E, M, W) grid of cells. All cells start hollow.
- **Interaction:** Drag stage tokens from a tray into each row, OR tap cells to toggle. A "Check" button validates: ADD = F,D,E,W; LDUR = all 5; STUR = F,D,E,M; CBZ = F,D,E.
- **Feedback:** Correct cells fill green with a red circled step number (①②③…) exactly like the prof's annotation; wrong cells shake (`AnimationController` with `Curves.elasticIn`) and flash red.
- **Mode toggle (top-right):** "Single-cycle lens" (blue) draws ONE brace under each entire row labeled "1 clock cycle — period = longest instruction (LDUR)"; "Multi-cycle lens" (green) draws vertical column separators with "1 cycle" arrows per column and the caption "period = longest step (memory)". This directly reproduces slides 10–12.

## 3.4 Loop Counter — Static vs. Dynamic Instructions
- **Layout:** Left panel = the 7-line LEGv8 code in monospace, line numbers ①–⑦. Right panel = three live registers as flip-counters: X10, X20, X9, plus a "Dynamic count" odometer.
- **Interaction:** "Step" button executes one instruction: the current line highlights yellow, registers update, dynamic odometer +1. When `cbnz` fires, a curved blue arrow animates from line ⑦ up 3 lines to line ④ with the label "LOOPS BACK".
- **State changes:** X10 counts 5→4→3→2→1→0. When X10 hits 0, cbnz falls through, confetti, final odometer shows 23. Side card displays: static = 7 (gray, static), dynamic = 23 (blue, pulsing), memory = 28 bytes.
- **Challenge mode:** A slider sets initial X10 (1–9); user must predict the dynamic count before running; validates against 3 + X10×4.

## 3.5 CPI Duel — Single vs. Multi-Cycle
- **Layout:** Two vertical progress tracks side by side. Left (blue): "Single-cycle — 23 cycles, CPI = 1". Right (green): "Multi-cycle — 87 cycles, CPI = 3.78". Both fed by the same instruction stream scrolling at top.
- **Animation:** Tap "Run". Both tracks fill; the multi-cycle track ticks 4/4/4/3 per instruction with mini stage chips appearing per tick. End state shows ET formula cards: ET = CPI × #Ins × Period. A frequency slider (1×–6×) on the multi-cycle side recomputes PerfA/PerfB live: at 5× show "1.32× faster ✓" green; drag to 3× and it flips to "0.79 — B is faster!" in red with the prof quote "Multi Cycle is not always faster, compare!"
- **Key state variable:** `perfRatio = (1 * 23 * p) / (3.78 * 23 * p / freqMultiplier)`.

## 3.6 Laundry Pipeline — The Analogy Game
- **Layout:** 4 resource lanes stacked: 🫧 Washer, 🌀 Dryer, 👕 Folder (you), 🚪 Closet (roommate). A queue of 4 colored laundry baskets (blue/green/orange/purple — matching the prof's 1st–4th load colors) waits on the left. Timeline ruler along the top counts cycles.
- **Mode A — Sequential:** Baskets auto-run one at a time through all 4 lanes; cycle counter ends at 16. Gray "idle" badges appear on every unused resource each cycle.
- **Mode B — Pipelined:** Each tick, user taps "Advance" — every basket moves one lane right and a new basket enters Fetch...er, the Washer. Counter ends at 7. At the cycle where all 4 resources are busy, draw a red ellipse around the column (mimicking slide 31) with the caption "Utilization 100% — no idle resource left."
- **State machine:** `List<int> basketStage` (−1 = queued, 0–3 = lane, 4 = done); advance = increment all ≥0 if next lane free, admit new basket if lane 0 free.

## 3.7 Instruction Pipeline Visualizer (the core widget)
- **Layout:** Classic pipeline diagram: rows = instructions (user picks 3–6 from chips: LDUR, ADD, SUB, STUR, CBZ, ORR), columns = clock cycles CC1–CC10. Cells render stage abbreviations F/D/E/M/W.
- **Interaction:** "Next cycle" button (or scrub slider) advances a vertical highlight bar one column right. Each instruction's active stage cell fills its row color; completed cells dim; future cells hollow.
- **Critical rule enforcement:** ADD's Memory cell and CBZ's M/W cells render with a hatched pattern + tooltip on tap: "Memory not used by ADD but we can NOT skip a stage!" (prof quote verbatim).
- **Counters:** Live "cycles elapsed" and the formula chip "stages + (N−1)" that fills in numbers when run completes (e.g., 5 + 3 = 8).
- **Timing overlay toggle:** Switch from cycle-count to picoseconds: multiplies by 200 ps and shows the 1600 ps total for the 4-instruction set, side-by-side with ghost bars for single-cycle 3200 ps and multi-cycle 3200 ps.

## 3.8 Critical Path Tracer (datapath mini-game)
- **Layout:** Reproduce the hand-drawn style datapath of slide 2 (use a hand-drawn-look stroke style, `StrokeCap.round`, slight jitter): PC, +4, Instr Mem, Control Unit, Reg File, Sign Extend, muxes m1–m5, ALU, Data Mem, Shift Left 2.
- **Interaction:** Given "LDUR", user finger-traces the critical path by tapping components in order. Correct order: Instr Mem → Reg File → Sign Extend/mux → ALU → Data Mem → Reg File write. Path segments turn red highlighter (semi-transparent thick stroke) as on the slide.
- **Failure states:** Tapping Shift Left 2 or Control Unit as part of the path → gentle bounce + hint "control signals are produced in Decode but the DATA path is what we trace."

---

# 4. QUIZ BANK

```json
[
  {"q": "In a single-cycle processor, what determines the clock period?", "options": ["The average instruction delay", "The critical path (longest-delay path)", "The shortest instruction", "The number of static instructions"], "answer": 1, "difficulty": 1, "concept": "Critical Path", "explanation": "The clock period must be long enough for the slowest path through the hardware — the critical path. If the period were shorter, that instruction wouldn't complete."},

  {"q": "Why is LDUR the critical path instruction in the LEGv8 single-cycle datapath?", "options": ["It has the largest immediate field", "It uses the ALU twice", "It passes through ALL major components: register read, ALU, data memory, AND register writeback", "It is the most frequently executed instruction"], "answer": 2, "difficulty": 1, "concept": "Critical Path", "explanation": "LDUR reads the register file, uses the ALU to calculate the address, reads data memory, and writes back to the register file — no other instruction makes the full round trip. STUR skips writeback; ADD/CBZ skip memory."},

  {"q": "If ADD needs 10 ns and LDUR needs 160 ns in a single-cycle processor, how long does ADD effectively occupy the processor?", "options": ["10 ns", "150 ns", "160 ns", "170 ns"], "answer": 2, "difficulty": 1, "concept": "Single-Cycle Limitation", "explanation": "The clock period is fixed at 160 ns (the critical path). ADD finishes its work in 10 ns but the next instruction cannot start until the cycle ends — it waits 150 ns. As the professor wrote: NOT GOOD ENOUGH!"},

  {"q": "Which stage sequence does STUR use in a multi-cycle processor?", "options": ["Fetch, Decode, Execute, Writeback", "Fetch, Decode, Execute, Memory, Writeback", "Fetch, Decode, Execute, Memory", "Fetch, Decode, Execute"], "answer": 2, "difficulty": 1, "concept": "5 Stages", "explanation": "STUR writes TO memory but never writes a register, so it skips Writeback: F-D-E-M = 4 cycles. (LDUR uses all 5, ADD skips Memory, CBZ uses only 3.)"},

  {"q": "A program has 7 static instructions including a loop that executes its 4-instruction body 5 times after 3 setup instructions. How many dynamic instructions execute?", "options": ["7", "20", "23", "28"], "answer": 2, "difficulty": 2, "concept": "Static vs Dynamic Instructions", "explanation": "Dynamic = what the processor actually executes: 3 setup + 5×4 loop = 23. Static is just the 7 lines written in memory (28 bytes at 4 bytes each)."},

  {"q": "Using the lecture's equation, if X10 is initialized to 7 instead of 5, how many dynamic instructions execute?", "options": ["23", "28", "31", "35"], "answer": 2, "difficulty": 2, "concept": "Static vs Dynamic Instructions", "explanation": "The professor's equation: dynamic = 3 + (X10 × 4) = 3 + 7×4 = 31. The loop body of 4 instructions runs once per initial X10 value."},

  {"q": "TRACE: In the multi-cycle processor, the dynamic stream is addi, addi, addi, stur, addi, subi, cbnz (first loop pass). With addi=4, stur=4, subi=4, cbnz=3 cycles, what cycle count has elapsed when cbnz finishes its first execution?", "options": ["23", "24", "27", "28"], "answer": 2, "difficulty": 3, "concept": "Multi-Cycle CPI", "explanation": "4+4+4 (setup) + 4 (stur) + 4 (addi) + 4 (subi) + 3 (cbnz) = 27 cycles after one full loop pass. The full program reaches 87 cycles after all 5 passes: 12 + 5×15."},

  {"q": "What is the CPI of the multi-cycle processor for the example program (87 cycles, 23 dynamic instructions)?", "options": ["1", "3.78", "12.43", "87"], "answer": 1, "difficulty": 2, "concept": "Multi-Cycle CPI", "explanation": "CPI = total cycles ÷ DYNAMIC instructions = 87/23 ≈ 3.78. Classic trap: dividing by the 7 static instructions gives a wrong answer."},

  {"q": "Multi-cycle processor A has 5× the frequency of single-cycle processor B (CPI_A=3.78, CPI_B=1, same program). PerfA/PerfB = ?", "options": ["0.79 — B is faster", "1.0 — identical", "1.32 — A is faster", "5.0 — A is faster"], "answer": 2, "difficulty": 2, "concept": "Performance Comparison", "explanation": "PerfA/PerfB = ETB/ETA = (1×23×P)/(3.78×23×P/5) = 5/3.78 ≈ 1.32. Note the inversion: performance ratio = execution-time ratio flipped."},

  {"q": "Same comparison, but A's frequency advantage is only 3×. What happens?", "options": ["A is still 1.32× faster", "PerfA/PerfB ≈ 0.79, so B (single-cycle) is faster", "They tie exactly", "Cannot be determined"], "answer": 1, "difficulty": 2, "concept": "Performance Comparison", "explanation": "3/3.78 ≈ 0.79 < 1, so the single-cycle processor wins. The professor's verbatim warning: 'Multi Cycle is not always faster, compare!'"},

  {"q": "In the laundry analogy, what is the essential requirement for pipelining to work?", "options": ["Faster individual machines", "Separate resources for each stage", "Fewer loads of laundry", "A larger washing machine"], "answer": 1, "difficulty": 1, "concept": "Pipelining", "explanation": "If 'We' did every step, the steps must be sequential. With separate resources (washer, dryer, you, roommate), all stages run in parallel on different loads. NEED SEPERATE RESOURCES!! as the slide says."},

  {"q": "4 laundry loads, 4 stages, 1 cycle per stage. Cycles needed without and with pipelining?", "options": ["16 and 4", "16 and 7", "8 and 4", "16 and 8"], "answer": 1, "difficulty": 2, "concept": "Pipelining Speedup", "explanation": "Sequential: 4 loads × 4 stages = 16. Pipelined: first load takes 4, each of the remaining 3 finishes one cycle later: 4+1+1+1 = 7. General formula: stages + (N−1)."},

  {"q": "TRACE: Pipelined processor, instructions issued in order: LDUR, STUR, ADD, CBZ (one per cycle). During cycle 4, which stage is STUR in?", "options": ["Decode", "Execute", "Memory", "Writeback"], "answer": 2, "difficulty": 3, "concept": "Pipelined Execution", "explanation": "STUR enters Fetch at cycle 2. Cycle 2=F, 3=D, 4=E... wait, count again: cycle 2 Fetch, cycle 3 Decode, cycle 4 Execute. Answer: Execute. Build the grid row by row — each instruction starts one cycle after the previous."},

  {"q": "TRACE: Same stream (LDUR, STUR, ADD, CBZ), 200 ps per stage, 5-stage pipeline. Total execution time?", "options": ["3200 ps", "2000 ps", "1600 ps", "800 ps"], "answer": 2, "difficulty": 3, "concept": "Pipelined Timing", "explanation": "Cycles = 5 + (4−1) = 8. ET = 8 × 200 ps = 1600 ps. Compare: single-cycle = 4×800 = 3200 ps; multi-cycle = 16×200 = 3200 ps. Pipelining halves it."},

  {"q": "In the pipelined design, ADD does not need the Memory stage. What does it do during that cycle?", "options": ["Skips directly to Writeback", "Stalls the entire pipeline", "Passes through the Memory stage doing nothing — stages cannot be skipped", "Executes a second ALU operation"], "answer": 2, "difficulty": 2, "concept": "Pipeline Rules", "explanation": "Professor's note on Fig 7.43: 'Memory is not used by ADD but we still show all of the stages of pipeline. Can not skip a stage!' Skipping would collide with the instruction ahead."},

  {"q": "Why do single-cycle processors require separate instruction and data memories?", "options": ["To reduce cost", "Both must be accessed in the same single cycle", "Instructions are larger than data", "To support pipelining"], "answer": 1, "difficulty": 2, "concept": "Single-Cycle Limitation", "explanation": "A load instruction must fetch its own encoding AND access data memory within one cycle — impossible with one shared memory port. Yet most real processors have a single external memory storing both: another reason single-cycle isn't used today."}
]
```

---

# 5. FLASHCARDS

```json
[
  {"front": "Critical Path", "back": "The path through the datapath that needs the MOST time; it determines the clock period of a single-cycle processor. In LEGv8 it belongs to LDUR (800 ps).", "concept": "Single-Cycle"},
  {"front": "Why is LDUR the longest instruction?", "back": "It passes through ALL stages/components: reads register file → uses ALU to calculate address → reads data memory → writes back to register file.", "concept": "Critical Path"},
  {"front": "CPI", "back": "Cycles Per Instruction = total cycles ÷ DYNAMIC instruction count. Single-cycle: CPI = 1. Multi-cycle example: 87/23 ≈ 3.78.", "concept": "Performance"},
  {"front": "Static instructions", "back": "The instructions as written in memory. Example program: 7 static instructions × 4 bytes = 28 bytes of memory.", "concept": "Static vs Dynamic"},
  {"front": "Dynamic instructions", "back": "The instructions actually EXECUTED by the processor at runtime. Loops make dynamic > static: 3 + 5×4 = 23 in the lecture example. Equation: 3 + (X10 × 4).", "concept": "Static vs Dynamic"},
  {"front": "Fetch stage", "back": "Read the instruction from memory. ('Got the instruction.') Bonus: stop trying to make fetch happen.", "concept": "5 Stages"},
  {"front": "Decode stage", "back": "Read the source operands from the register file & produce control signals. ('What is this instruction?')", "concept": "5 Stages"},
  {"front": "Execute stage", "back": "Computation with the ALU (arithmetic, or address calculation for loads/stores).", "concept": "5 Stages"},
  {"front": "Memory stage", "back": "Read/write data memory. Used only by LDUR (read) and STUR (write).", "concept": "5 Stages"},
  {"front": "Writeback stage", "back": "Write the result to the register file. Used by LDUR and R-format; NOT by STUR or CBZ.", "concept": "5 Stages"},
  {"front": "Stages used by ADD", "back": "Fetch, Decode, Execute, Writeback — skips Memory. 4 cycles in multi-cycle.", "concept": "Stage Usage"},
  {"front": "Stages used by LDUR", "back": "All five: Fetch, Decode, Execute, Memory, Writeback. 5 cycles in multi-cycle — the only instruction using every stage.", "concept": "Stage Usage"},
  {"front": "Stages used by STUR", "back": "Fetch, Decode, Execute, Memory — skips Writeback (stores don't write registers). 4 cycles in multi-cycle.", "concept": "Stage Usage"},
  {"front": "Stages used by CBZ", "back": "Fetch, Decode, Execute only — no memory access, no register write. 3 cycles in multi-cycle.", "concept": "Stage Usage"},
  {"front": "Multi-cycle processor", "back": "Breaks each instruction into steps (1 step = 1 cycle). Simpler instructions finish faster — no need to wait for the slowest instruction! Period = longest STEP (memory, 200 ps), not longest instruction.", "concept": "Multi-Cycle"},
  {"front": "Execution Time formula", "back": "ET = CPI × #Instructions × Clock Period. To compare: PerfA/PerfB = ETB/ETA (note the inversion!).", "concept": "Performance"},
  {"front": "Is multi-cycle always faster than single-cycle?", "back": "NO — 'Multi Cycle is not always faster, compare!' At 5× frequency it wins (1.32×); at 3× it loses (0.79). Always compute ET.", "concept": "Performance"},
  {"front": "Pipelining", "back": "Overlapping instruction execution: each stage works on a DIFFERENT instruction simultaneously, like a laundry line (wash/dry/fold/put away). Requires separate resources per stage.", "concept": "Pipelining"},
  {"front": "Pipelining cycle formula", "back": "Cycles = #stages + (#instructions − 1). E.g., 4 loads × 4 stages: sequential 16 cycles, pipelined 4+3 = 7 cycles.", "concept": "Pipelining"},
  {"front": "Can a pipelined instruction skip a stage it doesn't use?", "back": "NO — 'Can not skip a stage!' ADD passes idly through Memory to keep the pipeline aligned. (Unlike multi-cycle, where stages are truly skipped.)", "concept": "Pipeline Rules"},
  {"front": "Single-cycle vs multi-cycle vs pipelined ET (1 LDUR, 1 STUR, 1 ADD, 1 CBZ; 200 ps stages)", "back": "Single-cycle: 4×800 = 3200 ps. Multi-cycle: 16 cycles × 200 = 3200 ps. Pipelined: 8 cycles × 200 = 1600 ps.", "concept": "Timing Comparison"},
  {"front": "Why do single-cycle CPUs need separate instruction & data memories?", "back": "Both must be accessed in the same cycle (fetch + load/store). Real processors usually have ONE external memory for both — a key reason single-cycle isn't used today.", "concept": "Single-Cycle"},
  {"front": "Instruction class timings (P&H pg. 285)", "back": "LDUR 800 ps, STUR 700 ps, R-format 600 ps, CBZ 500 ps. Components: fetch 200, reg read 100, ALU 200, data access 200, reg write 100.", "concept": "Timing Comparison"},
  {"front": "100% resource utilization", "back": "In a full pipeline, every stage's hardware is busy every cycle — 'No idle resource left.' This is the whole motivation: 'lets use these too, why are they staying idle?'", "concept": "Pipelining"}
]
```

---

# 6. BOSS BATTLE — "The Processor Trial"

**Scenario:** You are the chief architect. A client hands you this LEGv8 program and three candidate processors. Survive all 6 stages to ship the chip.

```
addi  X9,  XZR, #0
addi  X10, XZR, #3     ← note: X10 starts at 3, NOT 5!
addi  X20, XZR, #E
stur  X10, [X20, #0]
addi  X20, X20, #8
subi  X10, X10, #1
cbnz  X10, #-3
```
Per-stage delays: fetch 200 ps, reg read 100 ps, ALU 200 ps, data access 200 ps, reg write 100 ps. Multi-cycle step counts: addi 4, stur 4, subi 4, cbnz 3.

**STAGE 1 — Count the armies.** How many static and dynamic instructions?
> **Answer:** Static = 7. Dynamic = 3 + (X10 × 4) = 3 + 3×4 = **15**.
> **Explanation:** The loop body {stur, addi, subi, cbnz} runs once per initial X10 value (X10 counts 2, 1, 0 after each decrement = 3 passes). Setup = 3 instructions.

**STAGE 2 — The single-cycle gate.** What is the clock period of the single-cycle processor, and its total ET for this program?
> **Answer:** Period = **800 ps** (LDUR-class critical path applies even though the program's longest instruction is stur at 700 ps — the HARDWARE is built for the worst case, LDUR). ET = 15 × 800 = **12,000 ps**.
> **Explanation:** The period is fixed by the slowest instruction the hardware supports, not the slowest in this particular program. CPI = 1, so ET = 1 × 15 × 800.
> **Trap:** Using 700 ps because the program contains no LDUR. The clock can't change per program!

**STAGE 3 — The multi-cycle gauntlet.** Total cycles and CPI on the multi-cycle processor?
> **Answer:** Cycle period = 200 ps (longest step). Cycles = 4+4+4 (setup) + 3 × (4+4+4+3) (loop) = 12 + 45 = **57 cycles**. CPI = 57/15 = **3.8**. ET = 57 × 200 = **11,400 ps**.
> **Explanation:** Same structure as the lecture's 87-cycle example, scaled to 3 loop passes. Divide by dynamic (15), never static (7).

**STAGE 4 — The duel.** The multi-cycle chip runs at 3.5× the single-cycle frequency. Which is faster, and by how much?
> **Answer:** PerfMC/PerfSC = ETSC/ETMC = (1 × 15 × P) / (3.8 × 15 × P/3.5) = 3.5/3.8 ≈ **0.92 — the single-cycle processor is faster!**
> **Explanation:** The frequency boost (3.5×) doesn't cover the CPI penalty (3.8×). Exactly the professor's warning: "Multi Cycle is not always faster, compare!"

**STAGE 5 — The pipeline ascension.** A 5-stage pipelined processor (200 ps/stage) runs the first loop pass's 7-instruction dynamic prefix (addi, addi, addi, stur, addi, subi, cbnz). Ignoring hazards, how many cycles and how many picoseconds?
> **Answer:** Cycles = 5 + (7−1) = **11 cycles** = 11 × 200 = **2,200 ps**.
> **Explanation:** First instruction needs all 5 stages; each subsequent one finishes one cycle later. And remember: addi flows through the Memory stage doing nothing — can not skip a stage!

**STAGE 6 — Final boss: full program on the pipeline.** All 15 dynamic instructions, ignoring hazards. Cycles, ET, and speedup vs. single-cycle?
> **Answer:** Cycles = 5 + (15−1) = **19 cycles** = 19 × 200 = **3,800 ps**. Speedup vs single-cycle = 12,000/3,800 ≈ **3.16×**. (vs multi-cycle: 11,400/3,800 = 3.0×.)
> **Explanation:** Pipelining wins not with a faster clock (same 200 ps as multi-cycle) but with overlap — up to 5 instructions in flight at once, approaching the ideal where utilization of resources is 100%, no idle resource left.
> **Victory condition:** The realistic caveat — a real pipeline would face hazards from cbnz (a branch!) and back-to-back register dependencies. That is next week's boss.

---

# 7. CONNECTIONS

**Backward links:**
- **← Single-cycle datapath (course project):** The hand-drawn datapath on slide 2 is the same architecture as Numan's Verilog/Vivado LEGv8 single-cycle CPU — the control signals (RWEn, DWEn, DREn, ALUop, muxes m1–m5) map one-to-one to that project's modules. Week 8 explains *why* that design is pedagogical, not practical.
- **← ISA & instruction encoding:** The 32-bit/4-byte instruction size from earlier weeks powers the static-size calculation (7 × 4 = 28 bytes); the bit-field slices [31:21], [9:5], [20:16], [4:0], [20:12], [23:5], [25:0] in the datapath come straight from LEGv8 instruction formats.
- **← Performance equations:** ET = CPI × IC × Period generalizes the Iron Law of performance introduced with benchmarks/Amdahl discussions.

**Forward links:**
- **→ Pipeline hazards (next):** The abstract pipeline view (Fig 7.43) with its half-shaded register file (write-left/read-right) is the exact diagram used to spot **data hazards**: SUB R4,R1,R5 reading a register that LDUR hasn't written back yet. "Can not skip a stage" becomes "sometimes you must STALL a stage."
- **→ Control hazards & branch prediction:** cbnz in the loop example is fetched before the processor knows whether it's taken — the seed of branch prediction (1-bit/2-bit predictors). The "LOOPS BACK" arrow is literally a future control hazard.
- **→ Structural hazards:** "NEED SEPERATE RESOURCES!!" — when two pipeline stages want the same hardware in the same cycle (one shared memory!), the pipeline stalls. The single-cycle separate-memory requirement returns as the I-cache/D-cache split.
- **→ Caches/memory hierarchy:** The 200 ps "data access" being the longest stage foreshadows why memory speed dominates processor design.
- **→ Superscalar/parallelism:** Laundry-in-parallel scales beyond one pipeline: multiple washers = multiple issue. Also conceptually adjacent to Numan's interest in parallel/neuromorphic computation — SNNs are in a sense extreme pipelines of spikes.

---

# UNREADABLE PAGES

**None.** All 43 pages were extracted. Pages 1–7 and 13–14 contained handwriting-only content that required visual extraction (transcribed above); pages 9–12 and 20/22 were progressive animation builds of the same diagrams — all annotation states captured. The hand-drawn datapath on page 2 is fully described in §2.2 but is worth keeping as a reference image for the Critical Path Tracer mini-game (§3.8).