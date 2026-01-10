
# VoxC Language Reference Manual

# Table of Contents

1.  **01. Introduction**
    *   What is VoxC?
    *   The Hacker's Philosophy
    *   System Architecture & Constraints
2.  **02. The Basics (CS 101)**
    *   Variables & Data Types
    *   The Semicolon Rule
    *   Logic & Flow Control
    *   Scope & Blocks
3.  **03. The Memory Model (Advanced)**
    *   The Heap & The Stack
    *   Pointers Explained
    *   Memory Layouts (Structs)
    *   Memory Safety & Leaks
4.  **04. 3D Mathematics & Physics**
    *   The Cartesian Grid (X, Y, Z)
    *   Vectors: Position vs. Direction
    *   Trigonometry (Angles & Aiming)
5.  **05. API Reference**
    *   System & I/O
    *   Memory Management
    *   Spatial Querying
    *   Physics & Movement
    *   Raycasting (Vision)
    *   World Manipulation
    *   Math Library
    *   Persistent Storage
6.  **06. Error Codes & Troubleshooting**

---

# 01. Introduction

## What is VoxC?
VoxC is a high-performance, imperative scripting language designed to manipulate the Vox Engine's simulated reality. Unlike standard game interactions (pressing buttons), VoxC allows you to rewrite the fundamental data governing entities, physics, and logic.

You are not a soldier; you are an architect. You do not fire a gun; you execute a function that applies 50,000 Newtons of force to an enemy's physics root.

## System Architecture
Your code does not run directly on the game server. It runs inside the **VoxVM** (Virtual Machine). This sandbox ensures fair play and server stability by enforcing strict resource limits.

### The "Triad" of Limitations
Every script you run is bound by three resources. If you exceed them, the Kernel kills your process.

1.  **Energy (Fuel):**
    *   Every operation costs energy. Math is cheap (1-2 units). Physics and Raycasts are expensive (100-250 units).
    *   **Max Energy:** 2500 Units.
    *   **Strategy:** You cannot spam commands. You must write efficient code.

2.  **Cycles (Time):**
    *   To prevent the server from freezing, scripts are limited to a specific number of instructions (operations).
    *   **Max Cycles:** 10,000 Operations.
    *   **Strategy:** Avoid infinite loops (e.g., `while(1==1)`).

3.  **Memory (RAM):**
    *   You are given a raw block of memory called the **Heap**.
    *   **Max Memory:** 4 Megabytes.
    *   **Strategy:** You must manually delete (`free`) data when you are done with it, or you will run out of RAM.

---

# 02. The Basics (CS 101)

If you have never coded before, start here.

## Variables & Data Types
Think of a **Variable** as a labeled cardboard box. You can put a number inside it.
In VoxC, everything is a number. We do not have "Text" or "Objects". Even coordinates are just numbers pointing to a place in memory.

**Syntax:**
```c
var health = 100;
var speed = 50.5;
```

**The Rules:**
1.  **Declaration:** You must use `var` to create a new box.
2.  **Assignment:** Use `=` to put a value inside.
3.  **Termination:** Every line must end with a semicolon `;`.

## Logic & Flow Control
Code normally runs from top to bottom. **Control Flow** lets you skip sections or repeat them.

### The "If" Statement
Asking a question. "If this is true, do that."
In VoxC, **0** is False. **Anything else** is True.

```c
var hp = 10;
if (hp < 20) {
    // This code runs because 10 is less than 20
    set_hp(self(), 100);
}
```

### The "While" Loop
Repeating an action. "While this is true, keep doing that."

```c
var i = 0;
while (i < 5) {
    print(i);
    i = i + 1; // IMPORTANT: Increase i, or the loop runs forever!
}
```

## Operators
*   `+` (Add), `-` (Subtract), `*` (Multiply), `/` (Divide)
*   `==` (Equals), `!=` (Not Equals)
*   `>` (Greater Than), `<` (Less Than)

---

# 03. The Memory Model (Advanced)

This is the barrier to entry. Understanding Memory is what separates "Script Kiddies" from "Hackers."

## The Heap
Imagine a massive notebook with 4 million lines. Each line can hold one number (a byte).
This notebook is called **The Heap**.

When you create a Vector (3 numbers: X, Y, Z), you cannot hold it in a single variable. You must write it into the Notebook.

## Pointers
When you write data to the Heap, the system tells you the **Page Number** where you wrote it. This Page Number is called a **Pointer**.

```c
var my_vec = vec(0, 50, 0); 
```
In this example, `my_vec` is **NOT** the vector. `my_vec` is a number (e.g., `1040`).
*   At Address `1040`: You find **X**.
*   At Address `1048`: You find **Y**.
*   At Address `1056`: You find **Z**.

## Byte Alignment (The Rule of 8)
VoxC uses 64-bit precision. This means every number takes up **8 Bytes** of space.
When calculating memory offsets, you always move in steps of 8.

## Memory Layouts
Different data types look different in memory.

### 1. Vector3 (Size: 24 Bytes)
Used for Position and Velocity.
| Offset | Meaning |
| :--- | :--- |
| `pointer + 0` | X Coordinate |
| `pointer + 8` | Y Coordinate |
| `pointer + 16` | Z Coordinate |

### 2. Lists (Size: Dynamic)
Returned by scanning functions like `near()`.
| Offset | Meaning |
| :--- | :--- |
| `pointer + 0` | **Count** (Total items in list) |
| `pointer + 8` | Item 1 |
| `pointer + 16` | Item 2 |
| ... | ... |

### 3. RayResult (Size: 40 Bytes)
Returned by `ray()`.
| Offset | Meaning |
| :--- | :--- |
| `pointer + 0` | **Did Hit?** (1 = Yes, 0 = No) |
| `pointer + 8` | **Entity ID** (0 if wall) |
| `pointer + 16` | Normal X |
| `pointer + 24` | Normal Y |
| `pointer + 32` | Normal Z |

## Manual Memory Management
There is no garbage collector. If you call `vec()` 1,000 times inside a loop and never call `free()`, you will fill the 4MB heap and crash.

**Always clean up your mess:**
```c
var p = pos(self());
// ... use p ...
free(p); // Mark memory as reusable
```

---

# 04. 3D Mathematics & Physics

## The Cartesian Grid
The world is defined by three axes:
*   **X:** Left / Right
*   **Y:** Up / Down
*   **Z:** Forward / Backward

## Vectors: Position vs Direction
*   **Position Vector:** Describes a point in space (e.g., `[100, 50, 20]`).
*   **Direction Vector:** Describes a force or movement.
    *   To get the direction **from A to B**, the formula is **B - A**.

**Example:**
If I am at `10` and the Enemy is at `50`, the distance is `50 - 10 = 40`.
We apply this logic to X, Y, and Z separately.

## Trigonometry (Aiming)
How do you make a turret aim at a player? You need angles.
VoxC provides `atan2(y, x)` which converts coordinates into an Angle (Radians).

**Formula for Y-Rotation (Yaw):**
```c
var angle = atan2(target_z - my_z, target_x - my_x);
```

---

# 05. API Reference

## System & I/O

#### `self()`
*   **Returns:** `EntityID`
*   **Cost:** 5 Energy
*   **Description:** Returns your unique ID. Useful for checking "Is this target me?" before attacking.

#### `print(value)`
*   **Returns:** `0`
*   **Cost:** 0 Energy
*   **Description:** Prints a number to the F9 Developer Console. Use for debugging.

## Memory Management

#### `mem_read(ptr)`
*   **Returns:** `Number`
*   **Cost:** 1 Energy
*   **Description:** Reads the value at the specific memory address.

#### `mem_write(ptr, value)`
*   **Returns:** `0`
*   **Cost:** 1 Energy
*   **Description:** Writes a value to a specific memory address.

#### `free(ptr)`
*   **Returns:** `0`
*   **Cost:** 0 Energy
*   **Description:** Frees the memory block at the pointer.

## Spatial Querying

#### `pos(id)`
*   **Returns:** `Pointer` (Vector3 Struct)
*   **Cost:** 50 Energy
*   **Description:** Allocates 24 bytes and fills it with the target's position. Returns `0` if target doesn't exist.

#### `near(pos_ptr, radius)`
*   **Returns:** `Pointer` (List Struct)
*   **Cost:** 150 Energy
*   **Description:** Returns a list of all EntityIDs found within the radius.

## Physics & Movement

#### `vec(x, y, z)`
*   **Returns:** `Pointer` (Vector3 Struct)
*   **Cost:** 20 Energy
*   **Description:** Allocates a new vector in the heap.

#### `force(id, vec_ptr)`
*   **Returns:** `0`
*   **Cost:** 250 Energy
*   **Description:** Applies velocity to the target. Max force is capped at 100,000.

#### `set_hp(id, amount)`
*   **Returns:** `0`
*   **Cost:** 400 Energy
*   **Description:** Sets the Health of a humanoid. High cost prevents spamming.

## Raycasting (Vision)

#### `ray(origin_ptr, direction_ptr)`
*   **Returns:** `Pointer` (RayResult Struct)
*   **Cost:** 100 Energy
*   **Description:** Fires a raycast. Use this to check line-of-sight (Can I see the target? Is there a wall?). Returns `0` if nothing was hit.

## World Manipulation

#### `hack(id, property_id, value)`
*   **Returns:** `0`
*   **Cost:** 200 Energy
*   **Description:** Modifies rendering or collision properties.
    *   **Prop 1:** Transparency (1 = Invisible, 0 = Visible).

## Math Library
All standard math functions. Cost: 1-2 Energy.
*   `sin(rad)`, `cos(rad)`, `tan(rad)`
*   `sqrt(n)`
*   `atan2(y, x)`
*   `dist(dx, dy, dz)`: Returns 3D Magnitude $\sqrt{x^2+y^2+z^2}$

## Persistent Storage

#### `store(index, value)`
*   **Returns:** `0`
*   **Description:** Saves a number to a global slot (0-255). This data persists even after your script finishes running. Use this to save "State" (e.g., Toggling modes).

#### `load(index)`
*   **Returns:** `Number`
*   **Description:** Loads a number from a global slot.

---

# 06. Error Codes & Troubleshooting

| Error | Meaning | Solution |
| :--- | :--- | :--- |
| `OUT OF ENERGY` | Script used >2500 Energy. | Move `vec()` calls outside of loops. Scan less often. |
| `MAX CYCLES` | Script ran too long. | Check your `while` loops. Ensure variables increment. |
| `OUT OF MEMORY` | Heap is full. | You are leaking memory. Add `free()` calls. |
| `attempt to call nil` | Typo in function name. | Check spelling. `Pos` vs `pos`. |
| `arithmetic on string` | Bad Math. | You tried to add a String to a Number. |

---

### Example: The "Turret" Script
A fully functional Aim-bot script using the new Math and Memory features.

```c
// 1. Setup
var me = self();
var my_pos = pos(me);
var list = near(my_pos, 50); // Scan 50 studs
var count = mem_read(list);  // Get enemy count
var i = 0;

// Read my coords once to save energy
var mx = mem_read(my_pos);
var mz = mem_read(my_pos + 16);

while (i < count) {
    // 2. Get Target ID
    var ptr = list + 8 + (i * 8);
    var target = mem_read(ptr);
    
    if (target != me) {
        // 3. Get Target Position
        var t_pos = pos(target);
        var tx = mem_read(t_pos);
        var tz = mem_read(t_pos + 16);
        
        // 4. Calculate Angle (Trig)
        // atan2(deltaZ, deltaX)
        var angle = atan2(tz - mz, tx - mx);
        
        // 5. Output for debug
        print(angle);
        
        // 6. Push them away based on math
        // Simple directional force
        var dx = tx - mx;
        var dz = tz - mz;
        var f = vec(dx * 100, 500, dz * 100);
        
        force(target, f);
        
        // Cleanup Loop Memory
        free(t_pos);
        free(f);
    }
    i = i + 1;
}

// Cleanup Global Memory
free(list);
free(my_pos);
```
