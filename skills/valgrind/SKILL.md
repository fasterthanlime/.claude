---
name: valgrind
description: Debug memory errors and profile performance using valgrind and callgrind. Use for crashes, memory corruption, leaks, or instruction-level profiling on Linux.
---

# Valgrind: Memory Debugging & Profiling

Debug crashes, memory corruption, leaks, and profile at instruction level.

## Prerequisites

```bash
# Linux
sudo apt install valgrind kcachegrind

# macOS (limited support)
brew install valgrind qcachegrind
```

## Memory Debugging

### Quick Leak Check

```bash
valgrind --leak-check=full --show-leak-kinds=all \
  --errors-for-leak-kinds=definite,indirect \
  --error-exitcode=1 \
  ./target/debug/mybin
```

### With Nextest

```bash
# Run specific test under valgrind
valgrind --leak-check=full --error-exitcode=1 \
  $(cargo nextest list --list-type binaries-only -p mypkg | grep test_name) \
  test_name --nocapture
```

Or configure a nextest profile (see `nextest-scripts` skill).

### Track Uninitialized Values

```bash
valgrind --track-origins=yes ./target/debug/mybin
```

## Profiling with Callgrind

### Basic Profiling

```bash
valgrind --tool=callgrind \
  --callgrind-out-file=callgrind.out \
  ./target/debug/mybin

callgrind_annotate callgrind.out
```

### With Cache Simulation

```bash
valgrind --tool=callgrind \
  --cache-sim=yes --branch-sim=yes \
  --callgrind-out-file=callgrind.out \
  ./target/debug/mybin
```

### Analyze Output

```bash
# Top functions by instruction count
callgrind_annotate --auto=yes --threshold=1 callgrind.out

# Focus on specific module
callgrind_annotate --include='mymodule::' callgrind.out

# Compare before/after
callgrind_annotate --diff callgrind.old.out callgrind.new.out
```

### GUI Analysis

```bash
kcachegrind callgrind.out   # Linux
qcachegrind callgrind.out   # macOS
```

## Interpreting Output

### Memory Error Example

```
==12345== Invalid read of size 8
==12345==    at 0x123456: mymod::parse (parse.rs:42)
==12345==    by 0x234567: mymod::run (lib.rs:123)
==12345==  Address 0x789abc is 0 bytes after a block of size 16 alloc'd
```

Translation: Reading 8 bytes past end of 16-byte allocation at parse.rs:42.

### Leak Example

```
==12345== 128 bytes in 1 blocks are definitely lost
==12345==    at 0x123456: malloc
==12345==    by 0x234567: Box::new (boxed.rs:123)
==12345==    by 0x345678: setup (jit.rs:456)
```

Translation: 128 bytes allocated in `setup` never freed.

### Callgrind Metrics

```
Ir     — Instructions executed (main optimization target)
I1mr   — L1 instruction cache misses
Dr/Dw  — Data reads/writes
D1mr   — L1 data cache misses (poor locality)
DLmr   — Last-level cache misses (very expensive)
```

## Common Workflows

### Debug a Crash

```bash
valgrind ./target/debug/mybin
# Read output for "Invalid read/write" with exact location
```

### Find Memory Leak

```bash
valgrind --leak-check=full --show-leak-kinds=definite \
  ./target/debug/mybin
```

### Profile Hot Path

```bash
# 1. Profile
valgrind --tool=callgrind --callgrind-out-file=before.out \
  ./target/debug/mybin

# 2. Make changes

# 3. Re-profile
valgrind --tool=callgrind --callgrind-out-file=after.out \
  ./target/debug/mybin

# 4. Compare
callgrind_annotate --diff before.out after.out
```

### Heap Corruption

For subtle heap corruption, use DHAT:

```bash
valgrind --tool=dhat ./target/debug/mybin
```

## Tips

### Profile Release with Debug Symbols

```toml
# Cargo.toml
[profile.release]
debug = true
```

```bash
valgrind --tool=callgrind ./target/release/mybin
```

### Reproducible Profiling

Disable ASLR for consistent results:

```bash
setarch $(uname -m) -R valgrind --tool=callgrind ./target/debug/mybin
```

### Single-Threaded Profiling

For cleaner callgrind data:

```bash
# With nextest
cargo nextest run --test-threads=1 ...

# Or set in test
#[test]
fn my_test() { ... }  // runs single-threaded by default
```

## Flags Reference

### Valgrind (Memory)

```
--leak-check=full          Detailed leak info
--show-leak-kinds=all      Show all leak types
--track-origins=yes        Track uninitialized values (slower)
--error-exitcode=1         Exit 1 on errors (for CI)
--log-file=valgrind.log    Save output to file
```

### Callgrind (Profiling)

```
--callgrind-out-file=FILE  Output file
--cache-sim=yes            Simulate cache
--branch-sim=yes           Simulate branches
--collect-jumps=yes        Collect jump info
--compress-strings=yes     Smaller output files
```

## Troubleshooting

### "unrecognized instruction"

Update valgrind or use:
```bash
valgrind --vex-iropt-register-updates=allregs-at-mem-access ...
```

### Output is huge

```bash
valgrind --tool=callgrind --compress-strings=yes --compress-pos=yes ...
```

### Can't open in GUI

Check file isn't corrupted:
```bash
callgrind_annotate callgrind.out | head
```

## See Also

- `nextest-scripts` skill for valgrind integration
- `cranelift-debugging` skill for JIT-specific debugging
