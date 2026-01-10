# VoxC Technical Reference Manual

---

## 1. Introduction
VoxC is a high-level, imperative, C-style scripting language designed for the Vox Engine. It provides a layer of abstraction over the raw VoxASM bytecode, allowing for complex entity manipulation, memory management, and vector mathematics.

Unlike traditional Lua scripting, VoxC code is **compiled** and executed within a sandboxed Virtual Machine (VM). This VM enforces strict constraints on CPU cycles, memory usage, and "Energy" consumption to ensure server stability and gameplay balance.

### 1.1 Design Philosophy
*   **Safety:** No user script can crash the host server. Infinite loops are caught by the cycle limiter.
*   **Resource Management:** Every action has a cost. Efficient code is rewarded; wasteful code is terminated.
*   **Manual Memory:** There is no Garbage Collector. You malloc. You free. You control the heap.

---

## 2. The Memory Model

The Vox Engine provides a raw **4MB (4,194,304 bytes)** Heap for every execution context.

### 2.1 The Heap
The Heap is a contiguous array of bytes. When you declare a variable in VoxC, that variable usually lives in a virtual "register." However, complex data (Structs, Arrays, Vectors) must live in the Heap.

### 2.2 Pointers
VoxC uses **64-bit Floating Point** numbers for everything. When referencing data in the Heap, a variable holds a **Pointer** (an integer representing the memory index), not the data itself.

> **Warning:** Dereferencing a pointer that has not been allocated (Segfault) or has already been freed (Use-After-Free) will return `0` or garbage data. It will not crash the VM, but your logic will fail.

### 2.3 Data Structures
Because memory is raw, data structures follow strict byte alignments.

#### The Vector3 Structure (24 Bytes)
| Offset | Type | Description |
| :--- | :--- | :--- |
| `0x00` | Double (8b) | X Component |
| `0x08` | Double (8b) | Y Component |
| `0x10` | Double (8b) | Z Component |

#### The List Structure (Dynamic)
Lists returned by the API (e.g., `near()`) follow a length-prefixed format.

| Offset | Type | Description |
| :--- | :--- | :--- |
| `0x00` | Double (8b) | **Count** (N) |
| `0x08` | Double (8b) | Item[0] |
| `0x10` | Double (8b) | Item[1] |
| ... | ... | ... |
| `0x08 + (N * 8)` | Double (8b) | Item[N] |

---

## 3. Language Specification

### 3.1 Lexical Grammar
*   **Termination:** Statements must end with `;`.
*   **Blocks:** Scopes are defined by `{ ... }`.
*   **Comments:** `//` denotes a single-line comment.
*   **Case Sensitivity:** VoxC is case-sensitive. `Var` != `var`.

### 3.2 Variable Declaration
Variables are dynamically typed but implicitly treated as numbers.
```c
var speed = 100;      // Number
var ptr = 0x1040;     // Number (Pointer)
var id = self();      // Number (EntityID)
```

### 3.3 Control Flow

#### If / Else
Standard conditional branching. Non-zero values are treated as `TRUE`. Zero is `FALSE`.
```c
if (health < 10) {
    escape();
}
```

#### While Loops
Loops continue until the condition is 0.
> **Constraint:** The VM enforces a hard limit of 10,000 Cycles. A heavy loop will exhaust this limit instantly.

```c
var i = 0;
while (i < count) {
    // Logic
    i = i + 1;
}
```

---

## 4. Standard Library (API)

The Standard Library provides the interface between the VM and the Game World.

### 4.1 System Functions

#### `self()`
*   **Returns:** `EntityID`
*   **Cost:** 5 Energy
*   **Description:** Returns the unique unique integer identifier of the entity running the script.

#### `free(ptr)`
*   **Returns:** `0`
*   **Cost:** 0 Energy
*   **Description:** Marks the memory block at `ptr` as available. Failing to do this causes Memory Leaks.

### 4.2 Spatial Functions

#### `pos(id)`
*   **Returns:** `Pointer` (Vector3)
*   **Cost:** 50 Energy
*   **Description:** Allocates 24 bytes in the Heap and populates it with the World Position of the target Entity. Returns `0` if the entity does not exist.

#### `near(pos_ptr, radius)`
*   **Returns:** `Pointer` (List)
*   **Cost:** 150 Energy
*   **Description:** Performs a spatial query (Sphere Overlap) on the server. Allocates a list containing the IDs of all entities detected.
*   **Note:** This is an expensive operation. Do not call this inside a loop.

### 4.3 Physics Functions

#### `vec(x, y, z)`
*   **Returns:** `Pointer` (Vector3)
*   **Cost:** 20 Energy
*   **Description:** Helper function to `malloc(24)` and write X, Y, Z values immediately.

#### `force(id, vec_ptr)`
*   **Returns:** `0`
*   **Cost:** 250 Energy
*   **Description:** Applies an impulse (BodyVelocity) to the target entity. The velocity persists for 0.2 seconds before decaying.

### 4.4 Memory I/O

#### `mem_read(ptr)`
*   **Returns:** `Number`
*   **Cost:** 1 Energy
*   **Description:** Reads a 64-bit float from the specific Heap address.

#### `mem_write(ptr, value)`
*   **Returns:** `0`
*   **Cost:** 1 Energy
*   **Description:** writes a 64-bit float to the specific Heap address.

---

## 5. Optimization & Best Practices

The Vox Engine runs on a strict energy budget (2000 Units). Writing efficient code is required to execute complex logic.

### 5.1 Pointer Caching
**Bad Practice:**
```c
while (i < 10) {
    // Allocates 24 bytes (20 Energy) every single loop!
    // Total Cost: 200 Energy + 240 Bytes RAM
    force(target, vec(0, 50, 0)); 
}
```

**Good Practice:**
```c
// Allocates once. Total Cost: 20 Energy + 24 Bytes RAM.
var up_vector = vec(0, 50, 0); 

while (i < 10) {
    force(target, up_vector);
}
free(up_vector);
```

### 5.2 List Iteration
Iterating a list requires manual pointer arithmetic. This is the standard pattern:

```c
var list = near(pos(self()), 50);
var count = mem_read(list); // First 8 bytes is count
var i = 0;

while (i < count) {
    // Calculate address of current item
    // Base + Header(8) + (Index * 8)
    var offset = 8 + (i * 8);
    var current_ptr = list + offset;
    
    // Dereference to get ID
    var entity_id = mem_read(current_ptr);
    
    // Logic here...
    
    i = i + 1;
}
free(list);
```

---

## 6. Error Codes

| Error | Meaning | Solution |
| :--- | :--- | :--- |
| `OUT OF ENERGY` | The script exceeded 2000 Energy. | Reduce API calls or optimize loops. |
| `MAX CYCLES` | The script ran too long (10k ops). | Check for infinite `while` loops. |
| `OUT OF MEMORY` | The 4MB Heap is full. | Ensure you `free()` all vectors and lists. |
| `ATTEMPT TO CALL NIL` | Syntax Error. | Check for typos in function names. |

---

### NOTE ON ROBLOX LINKS
**Important:** You cannot put a direct link to a website inside a Roblox game (e.g., on a Sign or GUI) unless it is one of the approved sites (YouTube, Twitter/X, Discord, Twitch).

**How to give this to players:**
1.  Put this documentation in your **Discord Server**.
2.  Put a link to the Discord server on your **Game Page**.
3.  In the in-game GUI, simply say: **"For full documentation, join our Community Server (Link on Game Page)."**
