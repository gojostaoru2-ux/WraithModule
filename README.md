

## 1.1 What is this game?
Welcome to the Vox Engine. In this game, you do not fight with swords or guns. You fight with **Logic**.

You play as a hacker in a simulated world. Every entity, every player, and every movement is governed by data. You have been given a tool called **VoxC**—a programming language that lets you rewrite that data.

If you want to push an enemy away, you don't press a button. You write a script that tells the physics engine: *"Take that guy, and apply 5,000 units of force to the left."*

## 1.2 What is a Variable?
Imagine a cardboard box. You can write a name on the outside of the box, and you can put **one number** inside the box.

In programming, this is a **Variable**.

```c
var health = 100;
```
*   **var**: Tells the computer "I am making a new box."
*   **health**: The name on the box.
*   **=**: Puts something inside.
*   **100**: The number inside.
*   **;**: The period at the end of the sentence. "I am done with this line."

You can change what is in the box later:
```c
health = 50; // The box now holds 50.
health = health + 10; // The box now holds 60.
```

## 1.3 The Computer Reads Top-to-Bottom
The computer is very literal. It reads line 1, does it. Then line 2, does it.

**Example:**
```c
var x = 10;
x = 0;
x = 5;
```
At the end of this script, `x` is 5. The previous numbers are gone.

## 1.4 Decisions (If / Else)
Sometimes you want the computer to make a choice. We use `if` statements. Think of it like a question.

"**IF** my health is less than 10, **THEN** run away."

In Code:
```c
if (health < 10) {
    // This code ONLY runs if the check is true
    run_away();
}
```

## 1.5 Repetition (While Loops)
Computers are great at doing boring things over and over again. This is called a **Loop**.

"**WHILE** there are enemies nearby, **KEEP** attacking."

In Code:
```c
var enemies = 5;
while (enemies > 0) {
    attack();
    enemies = enemies - 1;
}
```
**Danger:** If you tell the computer `while (1 == 1)`, it will run forever because 1 always equals 1. This is called an **Infinite Loop**. The Vox Engine detects this and will shut down your script (Error: `MAX CYCLES`) to prevent the game from freezing.

---

# Module 2: A Crash Course in 3D Math
**"What is a Vector? What are Coordinates?"**

---

## 2.1 The World is a Grid (XYZ)
Imagine a flat sheet of graph paper. You have a center point `(0,0)`.
*   If you go **Right**, X gets bigger.
*   If you go **Up**, Y gets bigger.

Now, imagine the world is a box. We add a third direction: **Depth**.
*   **X**: Left (-) and Right (+)
*   **Y**: Up (+) and Down (-)
*   **Z**: Forward (-) and Backward (+)

This is called the **Cartesian Coordinate System**. Every object in the game is located at specific `(X, Y, Z)` coordinates.

## 2.2 What is a Vector?
A **Vector** is just a fancy name for those three numbers grouped together: `[X, Y, Z]`.

In VoxC, a Vector serves two purposes:
1.  **Position:** "Where am I?" -> `[10, 50, -20]` means I am 10 units right, 50 units up, and 20 units forward.
2.  **Direction/Force:** "Push me!" -> `[0, 100, 0]` means "Push me Up with 100 power."

## 2.3 Vector Math (The hard part)
VoxC does not do math for you. You have to do it manually.

**Problem:** You are at `A`. The enemy is at `B`. You want to know the direction **from A to B**.
**Solution:** `B - A`

```text
Enemy Position (B): [100, 0, 50]
Your Position  (A): [ 10, 0, 50]

Direction:
X = 100 - 10 = 90
Y =   0 -  0 = 0
Z =  50 - 50 = 0

Result: [90, 0, 0]
```
This tells us the enemy is 90 units to the **Right**.

## 2.4 Distance (Pythagoras)
How far away is the enemy?
The formula is: $a^2 + b^2 = c^2$.

In 3D: `Distance = SquareRoot( (x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2 )`

*Note: VoxC does not have a SquareRoot function yet. We usually just compare "Distance Squared" to avoid complex math.*

---

## 3.1 The Notebook Analogy
Variables (like `var x = 10`) are like sticky notes. You can stick them on your monitor. They are fast and easy to read.

But... you only have a few sticky notes. What if you need to remember a list of 500 enemies? Or a Vector with 3 numbers? You can't fit that on one sticky note.

You need a **Notebook**.
In computing, this Notebook is called **The Heap (RAM)**.

## 3.2 Allocation (Malloc)
The Notebook is huge (4 Million bytes). But you can't just write anywhere, or you might write over other notes.

You have to ask the Librarian (The Memory Manager) for space.
*   **You:** "I need space for a Vector (24 bytes)."
*   **Librarian:** "Okay, start writing at Page 1040."

In Code:
```c
var ptr = vec(0, 0, 0); // Asks for space. 'ptr' becomes 1040.
```
The variable `ptr` does **not** hold the vector. It holds the **Page Number** (Address) where the vector is stored. This is called a **Pointer**.

## 3.3 Reading from the Notebook
To read your vector, you go to the page number.

*   Page 1040: **X Value**
*   Page 1048: **Y Value** (Because X takes up 8 bytes)
*   Page 1056: **Z Value** (Because Y takes up 8 bytes)

In Code:
```c
var x_val = mem_read(ptr);
var y_val = mem_read(ptr + 8);  // Page 1040 + 8
var z_val = mem_read(ptr + 16); // Page 1040 + 16
```

## 3.4 The Danger (Memory Leaks)
If you ask the Librarian for a page, **no one else can use that page** until you give it back.

If you keep asking for pages inside a loop...
```c
while (i < 1000) {
    var p = vec(0,0,0); // Requesting a new page every millisecond!
}
```
... you will run out of pages. The Librarian will yell **"OUT OF MEMORY"** and your script will crash.

## 3.5 Cleaning Up (Free)
When you are done with a Vector or a List, give the page back.

```c
free(ptr); // "I am done with page 1040."
```

---

## 4.1 System Functions

### `self()`
*   **Description:** Asks "Who am I?"
*   **Returns:** A unique number ID representing you.
*   **Why use it?** When scanning for nearby players, you will find yourself. You need this ID to check "If the person I found is ME, don't attack."
*   **Example:**
    ```c
    var me = self();
    ```

---

## 4.2 Spatial Functions

### `pos(entity_id)`
*   **Description:** Asks the server "Where is this entity?"
*   **Returns:** A **Pointer** to a Vector3 in memory.
*   **Cost:** 50 Energy.
*   **Warning:** This creates new memory. You MUST `free()` it.
*   **Example:**
    ```c
    var my_pos = pos(me);
    var y = mem_read(my_pos + 8); // How high am I?
    free(my_pos); // Done with it.
    ```

### `near(position_ptr, radius)`
*   **Description:** The Radar. Scans a sphere around a point.
*   **Returns:** A **Pointer** to a List in memory.
*   **Cost:** 150 Energy (Expensive!).
*   **The List Format:**
    *   Offset 0: **Count** (How many people found).
    *   Offset 8: **ID 1**
    *   Offset 16: **ID 2**
    *   ...etc.
*   **Example:**
    ```c
    var my_pos = pos(me);
    var list = near(my_pos, 50); // Scan 50 studs around me
    var count = mem_read(list);  // How many?
    free(list);
    free(my_pos);
    ```

---

## 4.3 Creation Functions

### `vec(x, y, z)`
*   **Description:** Creates a Vector3 in memory manually.
*   **Returns:** A **Pointer**.
*   **Cost:** 20 Energy.
*   **Usage:** Used to create logic variables or force vectors.
*   **Example:**
    ```c
    // Create a vector pointing straight UP
    var up = vec(0, 500, 0);
    ```

---

## 4.4 Action Functions

### `force(entity_id, vector_ptr)`
*   **Description:** The "Yeet" function. Pushes an entity.
*   **Cost:** 250 Energy.
*   **Physics:** It applies a `BodyVelocity` for 0.2 seconds.
*   **Limits:** Max force is 100,000. You cannot launch someone to the moon (easily).
*   **Example:**
    ```c
    force(enemy_id, up_vector); // Goodbye enemy!
    ```

### `set_hp(entity_id, amount)`
*   **Description:** God mode. Changes health directly.
*   **Cost:** 400 Energy.
*   **Usage:** Heal yourself or execute enemies.
*   **Example:**
    ```c
    set_hp(me, 100); // Heal to full
    set_hp(enemy, 0); // Kill
    ```

---

## 4.5 Low Level Memory

### `mem_read(ptr)`
*   **Description:** Peeks at a specific memory address.
*   **Cost:** 1 Energy.

### `mem_write(ptr, value)`
*   **Description:** Writes to a specific memory address.
*   **Cost:** 1 Energy.
*   **Advanced:** You can use this to modify vectors returned by `pos()` without allocating new ones!

### `free(ptr)`
*   **Description:** Releases memory.
*   **Cost:** 0 Energy.

---

## Tutorial 1: The "Kill Aura"
**Goal:** Automatically kill anyone who gets too close.

**Step 1: Setup Variables**
We need to know who we are and where we are.
```c
var me = self();
var p = pos(me);
```

**Step 2: Scan the area**
Look for people within 20 studs.
```c
var radius = 20;
var list = near(p, radius);
```

**Step 3: How many people?**
Read the first number in the list.
```c
var count = mem_read(list);
```

**Step 4: The Loop**
We need to check every single person in that list.
```c
var i = 0;
while (i < count) {
    // LOGIC GOES HERE
    i = i + 1;
}
```

**Step 5: Get the ID**
This is the math part.
List structure: `[Count] [ID0] [ID1] [ID2]`
*   At `i=0`, we want the number at offset 8.
*   At `i=1`, we want the number at offset 16.
*   Formula: `8 + (i * 8)`.

```c
    var offset = 8 + (i * 8);
    var id_ptr = list + offset;
    var target_id = mem_read(id_ptr);
```

**Step 6: Kill them (safely)**
Don't kill yourself!
```c
    if (target_id != me) {
        set_hp(target_id, 0);
    }
```

**Step 7: Clean Up**
If we don't free the memory, our game crashes after a few seconds.
```c
free(list);
free(p);
```

---

## Tutorial 2: The "Repulsor" (Advanced Math)
**Goal:** Push enemies away based on where they are standing.

This requires Vector Subtraction.
`Force = EnemyPosition - MyPosition`.

```c
var me = self();
var my_pos = pos(me);
var list = near(my_pos, 30);
var count = mem_read(list);
var i = 0;

// Read my coordinates once to save energy
var mx = mem_read(my_pos);
var my = mem_read(my_pos + 8);
var mz = mem_read(my_pos + 16);

while (i < count) {
    var ptr = list + 8 + (i * 8);
    var target = mem_read(ptr);
    
    if (target != me) {
        // Get their position
        var t_pos = pos(target);
        
        // Read their coordinates
        var tx = mem_read(t_pos);
        var ty = mem_read(t_pos + 8);
        var tz = mem_read(t_pos + 16);
        
        // CALCULATE DIRECTION: Target - Me
        var dx = tx - mx;
        var dz = tz - mz;
        
        // Amplify force (Multiply by 500)
        var fx = dx * 500;
        var fz = dz * 500;
        
        // Create the Force Vector
        // We push them UP (5000) and Away (fx, fz)
        var force_vec = vec(fx, 5000, fz);
        
        force(target, force_vec);
        
        // Free loop memory
        free(t_pos);
        free(force_vec);
    }
    i = i + 1;
}

// Cleanup global memory
free(list);
free(my_pos);
```

---

## 6.1 The Energy Grid
You have **2000 Energy**.
*   `set_hp` costs 400. You can only use it **5 times** before your battery dies.
*   `force` costs 250. You can use it **8 times**.

## 6.2 Optimization Strategies

**Strategy A: Dont Allocate inside Loops**
*   **Bad:** Calling `vec(0,50,0)` inside a loop. You pay 20 Energy every single time.
*   **Good:** Call `vec` *before* the loop. Save the pointer. Use the pointer inside the loop. Pay 20 Energy once.

**Strategy B: Don't scan too often**
*   `near()` is expensive (150 Energy).
*   If you are fighting one person, get their ID once and save it. Don't scan for them every frame.

## 6.3 The Cycle Limit
To prevent the server from freezing, VoxC stops any script that runs more than **10,000 instructions**.
*   Be careful with `while` loops.
*   If you write `while (1 == 1) {}`, your script will die instantly.

---

| Error Message | Translation | Fix |
| :--- | :--- | :--- |
| `OUT OF ENERGY` | You used too many expensive functions. | Use fewer `force`/`near` calls. Move allocations outside loops. |
| `OUT OF MEMORY` | The Heap (4MB) is full. | You forgot to `free()` your pointers. |
| `MAX CYCLES` | The code ran for too long. | Check your `while` loops. Are you increasing `i`? |
| `attempt to call nil` | You typed a function name wrong. | Check spelling. `Pos` vs `pos`. |
| `arithmetic on string` | You tried to do math on text. | VoxC doesn't support strings in variables. |
