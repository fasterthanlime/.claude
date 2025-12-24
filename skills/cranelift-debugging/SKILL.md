---
name: cranelift-debugging
description: Debug JIT-compiled code from Cranelift. Use when debugging crashes, memory corruption, or calling convention issues in dynamically generated code. Covers cdb.exe (Windows), lldb/gdb with SIGSEGV handlers (Unix), and disassembly analysis.
---

# Debugging Cranelift JIT Code

Debug crashes and memory corruption in dynamically generated code. Miri can't help here — the code doesn't exist at compile time.

## Why JIT Debugging is Different

- **No source maps** — JIT code has no debug info
- **No symbols** — Function names are just addresses
- **Miri doesn't work** — It only sees Rust code, not generated machine code
- **Calling conventions matter** — Wrong ABI corrupts callee-saved registers

## Windows: CDB/WinDbg

### Finding the Test Binary

```bash
cargo nextest list | grep -B5 my_test_name
# Shows: bin: C:\path\to\test-abc123.exe
```

### Running Under Debugger

```bash
cdb ./target/debug/deps/test-abc123.exe my_test_name --nocapture
```

### Essential Commands

| Command | Description |
|---------|-------------|
| `g` | Run until crash/breakpoint |
| `sxe av` | Break on access violation |
| `r` | Show all registers |
| `k` | Stack trace |
| `u` | Disassemble at current instruction |
| `u <addr>` | Disassemble at address |
| `ub <addr>` | Disassemble backwards |
| `dd/dq <addr>` | Display memory (dword/qword) |
| `ln <addr>` | Find nearest symbol |
| `bp <addr>` | Set breakpoint |

### Quick Workflow

```
sxe av          # Break on access violation
g               # Run
r               # Check registers after crash
k               # Stack trace
u               # Disassemble crash location
```

### Windows x64 Calling Convention

| Registers | Purpose |
|-----------|---------|
| RCX, RDX, R8, R9 | First 4 arguments |
| RAX | Return value (if ≤8 bytes) |
| R12-R15, RBX, RBP, RSI, RDI | **Callee-saved** |

**If R12-R15 are corrupted after a call → wrong calling convention in JIT.**

### Windows ABI Gotchas

#### Struct Returns: The Hidden First Parameter

**Critical difference from System V:**

On System V (Linux/macOS), small structs can be returned in RAX + RDX:
```rust
struct Result { pos: u64, err: u32 }  // 12 bytes, fits in RAX+RDX on System V
```

On Windows x64, structs > 8 bytes **cannot** use register pairs. Instead:
- Caller allocates return buffer on stack
- **Hidden first parameter** (RCX) points to this buffer
- All other arguments shift by one position!

```
// What you think happens:
fn helper(input: *const u8, len: usize) -> Result
//        RCX              RDX

// What Windows actually does:
fn helper(ret_buf: *mut Result, input: *const u8, len: usize) -> *mut Result
//        RCX (hidden!)        RDX              R8
```

**Symptom**: Arguments are "shifted" — `len` gets interpreted as `input`, causing wild pointer access.

**Real-world example** (facet-rs/facet#1366):
```
JIT expected:  RAX = new_pos, EDX = error
Windows did:   RCX = return buffer (hidden), args shifted
Result:        len (small number) read as input pointer → access violation
```

**Solution**: Return values that fit in a single register:
```rust
// BAD: Struct return, ABI differs across platforms
fn skip_value(input: *const u8, len: usize) -> SkipResult { ... }

// GOOD: Single isize fits in RAX everywhere
fn skip_value(input: *const u8, len: usize) -> isize {
    // >= 0: success (new position)
    // < 0: error code
}
```

#### Other Windows ABI Oddities

| Issue | Windows x64 | System V |
|-------|-------------|----------|
| Struct return (>8 bytes) | Hidden RCX pointer | RAX + RDX |
| Shadow space | 32 bytes required | Not required |
| Float args | XMM0-XMM3 | XMM0-XMM7 |
| Varargs | All in integer regs | Mixed |

#### Historical ABIs (32-bit, rare but exist)

| ABI | Args | Cleanup | Notes |
|-----|------|---------|-------|
| cdecl | Stack R→L | Caller | C default |
| stdcall | Stack R→L | Callee | Win32 API |
| fastcall | ECX, EDX, stack | Callee | Older optimization |
| thiscall | ECX = this, stack | Callee | MSVC C++ |

Modern 64-bit code uses Windows x64 ABI (fastcall-like) or System V.

### Checking ABI Violations

```
bp <before_call>    # Set breakpoint before suspicious call
g                   # Run to breakpoint
r r12 r13 r14 r15   # Note values
p                   # Step over call
r r12 r13 r14 r15   # Check if corrupted
```

### Page Heap (Heap Corruption)

```bash
# Enable detailed heap checking
gflags /p /enable mytest.exe

# Run under debugger
cdb mytest.exe ...

# Disable when done
gflags /p /disable mytest.exe
```

## Unix: LLDB/GDB with SIGSEGV Handler

### SIGSEGV Handler Pattern

Add to your test to catch the crash and pause for debugger attachment:

```rust
#[cfg(unix)]
fn install_crash_handler() {
    use std::sync::atomic::{AtomicBool, Ordering};
    static CAUGHT: AtomicBool = AtomicBool::new(false);

    extern "C" fn handler(sig: libc::c_int) {
        if CAUGHT.swap(true, Ordering::SeqCst) {
            std::process::abort();
        }
        eprintln!("\n!!! SIGNAL {} - attach debugger to PID {} !!!", sig, std::process::id());
        eprintln!("lldb -p {}", std::process::id());
        eprintln!("Press Enter to continue (will crash)...");
        let mut buf = [0u8; 1];
        let _ = std::io::Read::read(&mut std::io::stdin(), &mut buf);
    }

    unsafe {
        libc::signal(libc::SIGSEGV, handler as usize);
        libc::signal(libc::SIGBUS, handler as usize);
    }
}

#[test]
fn my_jit_test() {
    install_crash_handler();
    // ... test code ...
}
```

### Attaching LLDB

When test prints the PID:

```bash
lldb -p <pid>
```

Then in lldb:

```
bt                    # Backtrace
register read         # All registers
register read rax rbx # Specific registers
di -p                 # Disassemble at PC
di -s <addr> -c 20    # Disassemble 20 instructions from addr
memory read <addr>    # Read memory
```

### Attaching GDB

```bash
gdb -p <pid>
```

Then:

```
bt                    # Backtrace
info registers        # All registers
x/20i $pc             # Disassemble 20 instructions
x/8gx <addr>          # Examine 8 qwords at addr
```

### System V AMD64 Calling Convention (Linux/macOS)

| Registers | Purpose |
|-----------|---------|
| RDI, RSI, RDX, RCX, R8, R9 | First 6 arguments |
| RAX | Return value |
| RBX, RBP, R12-R15 | **Callee-saved** |

**If RBX or R12-R15 corrupted after call → wrong ABI in JIT.**

## Disassembly Analysis

### Identifying JIT vs Rust Code

- **JIT code**: Random-looking addresses in heap (0x7f..., 0x1...)
- **Rust code**: Addresses with symbols (`mylib::func+0x42`)

```
# LLDB: Find nearest symbol
image lookup -a <address>

# GDB: Same
info symbol <address>

# CDB: Same
ln <address>
```

### Reading JIT Disassembly

Common patterns:

```asm
; Function prologue (if any)
push rbp
mov rbp, rsp
sub rsp, 0x20

; Helper call
mov rdi, <arg1>      ; First arg (System V)
mov rsi, <arg2>      ; Second arg
call <helper_addr>

; Function epilogue
add rsp, 0x20
pop rbp
ret
```

### Red Flags

| Pattern | Problem |
|---------|---------|
| `call` without saving callee-saved regs | ABI violation |
| Misaligned stack at `call` | Stack must be 16-byte aligned |
| Wrong argument registers | Windows vs System V mixup |
| No prologue/epilogue | Missing frame setup |

## Common Issues

### Struct Return ABI Mismatch (Windows)

**Symptom**: Arguments seem "shifted" — pointer args contain small integers, length args are wild pointers

**Cause**: Returning struct >8 bytes. Windows inserts hidden first parameter, shifting all args.

**Debug**:
```
# Check RCX at call entry — is it a stack pointer (return buffer)?
# Check RDX — does it contain what you expected in RCX?
```

**Fix**: Return single register-sized value. Encode multiple values as tagged integer:
```rust
// >= 0: success value
// < 0: error code
fn helper(...) -> isize
```

### Callee-Saved Register Clobbering

**Symptom**: Crash after returning from helper function

**Cause**: JIT uses R12-R15/RBX without saving them

**Fix**: Emit proper prologue saving registers, or mark helpers as clobber-all

### Stack Misalignment

**Symptom**: Crash in called function, often in SSE instructions

**Cause**: Stack not 16-byte aligned at `call`

**Fix**: Adjust stack in prologue: `sub rsp, 8` if needed

### Wrong Calling Convention

**Symptom**: Arguments have garbage values in helper

**Cause**: Using wrong register order (Windows vs System V)

**Debug**:
```
# Break at call site, check arg registers
# Windows: rcx, rdx, r8, r9
# System V: rdi, rsi, rdx, rcx, r8, r9
```

### Use-After-Free in JIT Buffer

**Symptom**: Crash executing garbage instructions

**Cause**: JIT buffer was deallocated while still in use

**Debug**: Check if crash address is in valid JIT region

## Workflow: Debug a JIT Crash

1. **Reproduce with handler** (Unix) or **debugger** (Windows)

2. **Get crash location**:
   ```
   # Address where crash happened
   # Is it in JIT region or Rust helper?
   ```

3. **Check registers**:
   ```
   # Are callee-saved registers sane?
   # Is RSP aligned?
   ```

4. **Disassemble around crash**:
   ```
   # What instruction failed?
   # What were the operands?
   ```

5. **Trace back to JIT generation**:
   ```
   # Find what Cranelift IR produced this
   # Check calling convention flags
   ```

## See Also

- `valgrind` skill for memory debugging (where supported)
- Cranelift IR debugging: `CRANELIFT_DBG=1` env var
- Capstone for offline disassembly
