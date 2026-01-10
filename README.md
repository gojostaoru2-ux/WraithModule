# VoxC Language Specification & Technical Reference

---

## Table of Contents
1.  **System Architecture**
    *   1.1 The Virtual Machine
    *   1.2 Resource Constraints (The Triad)
    *   1.3 Execution Pipeline
2.  **Memory Architecture**
    *   2.1 The Heap Model
    *   2.2 Data Representation (IEEE 754)
    *   2.3 Memory Layouts & Byte Alignment
    *   2.4 Pointer Arithmetic
    *   2.5 Memory Safety & Leaks
3.  **Language Syntax**
    *   3.1 Lexical Grammar
    *   3.2 Variables & Scope
    *   3.3 Control Flow
    *   3.4 Operators & Precedence
4.  **Standard Library (API)**
    *   4.1 System Input/Output
    *   4.2 Spatial Querying
    *   4.3 Physics Manipulation
    *   4.4 Direct Memory Access (DMA)
5.  **Advanced Mathematics Library**
    *   5.1 Implementing Distance
    *   5.2 Implementing Normalization
    *   5.3 Implementing Dot Product
6.  **Design Patterns & Optimization**
    *   6.1 The "Cache & Carry" Strategy
    *   6.2 The "Safe Scan" Protocol
7.  **Error Codes & Troubleshooting**

---

# 1. System Architecture

### 1.1 The Virtual Machine
VoxC does not run directly on the Roblox Lua engine. Instead, it is compiled into an Abstract Syntax Tree (AST) and executed by the **VoxVM**. This sandboxed environment ensures that user code remains isolated from critical server processes.

The VM operates on a **Fetch-Decode-Execute** cycle. It parses one statement at a time, resolves memory addresses, and executes the logic while deducting energy costs in real-time.

### 1.2 Resource Constraints (The Triad)
To simulate the limitations of embedded hacking devices, the VoxVM enforces three hard limits. Exceeding any of these results in an immediate `SIGKILL` (Script Termination).

| Resource | Limit | Description | Failure State |
| :--- | :--- | :--- | :--- |
| **Energy** | 2,000 Units | The "fuel" for execution. Heavy API calls drain this fast. | `OUT OF ENERGY` |
| **Cycles** | 10,000 Ops | The CPU time allowed. Prevents infinite loops/server freezing. | `MAX CYCLES EXCEEDED` |
| **Memory** | 4.0 MB | The Heap space available for dynamic allocation. | `OUT OF MEMORY` |

### 1.3 Execution Pipeline
1.  **Source:** Raw text input from the IDE.
2.  **Lexer:** Converts text into tokens (`ID`, `NUM`, `SYM`, `STR`).
3.  **Parser:** Validates grammar and builds the AST.
4.  **Linker:** Allocates static memory for variables (`var`).
5.  **Runtime:** Executes instructions.

---

# 2. Memory Architecture

This is the most critical subsystem of VoxC. Unlike high-level languages (Lua, Python), VoxC has **no Garbage Collection**. You are responsible for every byte.

### 2.1 The Heap Model
The Heap is a contiguous array of 4,194,304 bytes.
*   **Address Space:** `0x0000` to `0x400000`.
*   **Null Pointer:** `0`. Accessing address 0 is safe (returns 0) but usually indicates a logic error.
*   **Allocation Strategy:** The VM uses a linear allocator. `free()` marks blocks as reusable, but fragmentation can occur if you allocate/free in random orders.

### 2.2 Data Representation
VoxC is typeless. Every variable and memory slot holds a **64-bit Double-Precision Floating Point Number**.
*   **Integers:** Represented as Floats (e.g., `5.0`).
*   **Pointers:** Represented as Floats (e.g., `1024.0`).
*   **Booleans:** `1.0` is True, `0.0` is False.

### 2.3 Memory Layouts & Byte Alignment
When you allocate memory, you must understand how data is structured.

#### The Vector3 Structure (24 Bytes)
Used for Position, Velocity, and Raycasting.
```text
[ Pointer (Base) ]
|
+---Offset 0x00:  X Component (8 Bytes)
|
+---Offset 0x08:  Y Component (8 Bytes)
|
+---Offset 0x10:  Z Component (8 Bytes)
```

#### The Dynamic List Structure (8 + N*8 Bytes)
Returned by `near()`.
```text
[ Pointer (Base) ]
|
+---Offset 0x00:  Count (Number of items, e.g., 2)
|
+---Offset 0x08:  EntityID_1 (8 Bytes)
|
+---Offset 0x10:  EntityID_2 (8 Bytes)
|
...
```

### 2.4 Pointer Arithmetic
To traverse a list, you cannot simply use `list[i]`. You must calculate the raw memory address.

**Formula:**
$$Address = Base + HeaderSize + (Index \times ElementSize)$$

**In VoxC:**
```c
// Assuming 'list' is a pointer to a List Structure
// Accessing index 'i'
var ptr = list + 8 + (i * 8);
var value = mem_read(ptr);
```

### 2.5 Memory Safety & Leaks
**The Golden Rule:** For every `malloc/vec/near/pos`, there must be a `free`.

**Memory Leak Example (Catastrophic):**
```c
while (i < 100) {
    // This allocates 24 bytes every loop iteration.
    // The previous 24 bytes are lost forever in the heap (Leaked).
    // After enough iterations, the VM crashes.
    force(target, vec(0, 10, 0)); 
    i = i + 1;
}
```

**Memory Safe Example:**
```c
// Allocation outside the loop
var up = vec(0, 10, 0); 
while (i < 100) {
    force(target, up);
    i = i + 1;
}
// Deallocation
free(up); 
```

---

# 3. Language Syntax

### 3.1 Lexical Grammar
*   **Identifiers:** Must start with a letter. Can contain `_` and numbers.
*   **Literals:** Numbers (`10`, `0.5`, `-50`), Hex (`0xFF`), Strings (`"Health"`).
*   **Strings:** Only permitted in specific API calls (`set_hp`). You cannot assign a string to a variable (e.g., `var x = "hello"` is invalid).

### 3.2 Variables & Scope
Variables are declared with `var`.
```c
var energy = 100;
var target = 0;
```
*   **Cost:** Declaring or assigning a variable costs **2 Energy**.
*   **Scope:** Variables declared inside a block (`{}`) remain in memory until the script finishes.

### 3.3 Control Flow

#### If / Else
Logic gates based on numeric truth (Non-zero = True).
```c
if (target != me) {
    // Attack
}
```

#### While Loops
Repeats code block.
```c
while (energy > 0) {
    // Work
}
```

### 3.4 Operators & Precedence
(Ordered High to Low)
1.  `()` (Parentheses)
2.  `*`, `/` (Multiplication, Division)
3.  `+`, `-` (Addition, Subtraction)
4.  `>`, `<`, `==`, `!=` (Comparison)

---

# 4. Standard Library (API)

### 4.1 System Input/Output

#### `self()`
*   **Signature:** `self() -> EntityID`
*   **Energy Cost:** 5
*   **Description:** Returns the Integer ID of the entity running the script. Essential for ensuring you don't attack yourself.

### 4.2 Spatial Querying

#### `pos(id)`
*   **Signature:** `pos(EntityID) -> Pointer`
*   **Energy Cost:** 50
*   **Returns:** A pointer to a new 24-byte Vector3 in the Heap.
*   **Failure:** Returns `0` if the entity is invalid or dead.
*   **Memory Note:** You **must** `free()` this pointer.

#### `near(pos_ptr, radius)`
*   **Signature:** `near(Pointer, Number) -> Pointer`
*   **Energy Cost:** 150
*   **Returns:** A pointer to a List Structure in the Heap.
*   **Description:** Performs a spatial sphere-check on the server.
*   **Memory Note:** You **must** `free()` this pointer. The list size depends on how many entities are found.

### 4.3 Physics Manipulation

#### `vec(x, y, z)`
*   **Signature:** `vec(Number, Number, Number) -> Pointer`
*   **Energy Cost:** 20
*   **Description:** Allocates 24 bytes and writes the 3 numbers provided.

#### `force(id, vec_ptr)`
*   **Signature:** `force(EntityID, Pointer) -> 0`
*   **Energy Cost:** 250
*   **Description:** Applies a `BodyVelocity` to the target's RootPart.
*   **Behavior:** Velocity is applied instantaneously and decays over 0.2 seconds.
*   **Limits:** Max force is clamped to `100,000` units to prevent physics engine crashes.

#### `set_hp(id, amount)`
*   **Signature:** `set_hp(EntityID, Number) -> 0`
*   **Energy Cost:** 400
*   **Description:** Directly modifies the `Humanoid.Health` property.
*   **Usage:** Can be used to Heal (amount > current) or Damage (amount < current).

### 4.4 Direct Memory Access (DMA)

#### `mem_read(ptr)`
*   **Signature:** `mem_read(Pointer) -> Number`
*   **Energy Cost:** 1
*   **Description:** Returns the value stored at the specific byte offset.

#### `mem_write(ptr, value)`
*   **Signature:** `mem_write(Pointer, Number) -> 0`
*   **Energy Cost:** 1
*   **Description:** Overwrites the value at the specific byte offset.
*   **Warning:** Writing to random addresses can corrupt your own variables or vectors.

#### `free(ptr)`
*   **Signature:** `free(Pointer) -> 0`
*   **Energy Cost:** 0
*   **Description:** Notifies the Memory Manager that the block at `ptr` is no longer needed.

---

# 5. Advanced Mathematics Library

VoxC does not include a math library (`Math.sqrt`, `Vector3.new`, etc.). You must implement vector math manually using raw memory operations.

### 5.1 Implementing Distance
Calculating the distance between two entities.
Formula: $\sqrt{(x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2}$

*Note: VoxC does not currently support `sqrt`. We rely on distance comparisons using Distance Squared to avoid expensive square root operations.*

```c
// Input: Two Position Pointers (p1, p2)
var x1 = mem_read(p1);
var y1 = mem_read(p1 + 8);
var z1 = mem_read(p1 + 16);

var x2 = mem_read(p2);
var y2 = mem_read(p2 + 8);
var z2 = mem_read(p2 + 16);

var dx = x2 - x1;
var dy = y2 - y1;
var dz = z2 - z1;

// Distance Squared
var dist_sq = (dx*dx) + (dy*dy) + (dz*dz);

if (dist_sq < 900) { 
    // Distance is less than 30 (30*30 = 900)
}
```

### 5.2 Implementing Vector Normalization
To launch an enemy *away* from you, you need a Normalized Direction Vector.
Since we lack `sqrt`, we approximate or use fixed values.

**Simple Direction (Non-Normalized):**
```c
var diff_x = target_x - my_x;
var diff_z = target_z - my_z;

// Apply raw difference as force (Stronger if further away)
force(target, vec(diff_x * 100, 50, diff_z * 100));
```

### 5.3 Implementing "Upward Launch"
Simple vector addition logic to modify a position vector into a force vector.

```c
var p = pos(target); // Get [X, Y, Z]
// We want [0, 5000, 0]
// We don't care about their position, we just want a force vector.
// So we allocate a NEW vector.

var launch = vec(0, 5000, 0);
force(target, launch);
free(launch);
free(p); // Don't forget to free the position we grabbed!
```

---

# 6. Design Patterns & Optimization

### 6.1 The "Cache & Carry" Strategy
API calls are the most expensive operations. Never call an API inside a loop if the result doesn't change.

**Inefficient Code (Cost: 2000+ Energy):**
```c
// Logic: Push 10 enemies up
var i = 0;
while (i < 10) {
    // 250 Energy for force
    // 20 Energy for vec allocation
    // Total per loop: 270. 
    // 10 Loops = 2700 Energy. CRASH.
    force(target, vec(0, 50, 0)); 
}
```

**Optimized Code (Cost: ~250 Energy):**
```c
var up = vec(0, 50, 0); // 20 Energy
var i = 0;
while (i < 10) {
    force(target, up); // 250 Energy
    // Note: This still hits energy limits quickly.
    // You can only force ~7 entities per script execution.
}
free(up);
```

### 6.2 The "Safe Scan" Protocol
Always verify data before using it.
1.  Check if `near()` returned a valid pointer (not 0).
2.  Check if `count` is greater than 0.
3.  Check if `target` is not `self()`.

---

# 7. Error Codes

| Error Message | Cause |
| :--- | :--- |
| `Line X: OUT OF ENERGY` | Your script consumed >2000 energy. Optimization required. |
| `Line X: OUT OF MEMORY` | Heap >4MB. You are leaking memory (missing `free`). |
| `Line X: MAX CYCLES` | Infinite loop detected. Check your `while` conditions. |
| `Line X: attempt to perform arithmetic` | You tried to add a number to a non-existent variable. |
| `Line X: missing method '...'` | Typo in function name (e.g., `Pos` instead of `pos`). |
