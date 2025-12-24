---
name: rustc-bloat
description: Analyze Rust binary bloat from monomorphization, large types, and macro expansion using cargo-llvm-lines and rustc flags. Use when binaries are too large or compile times are slow due to code generation.
---

# Rust Code Size & Monomorphization Analysis

Find code bloat from excessive monomorphization, large types, and macro expansion.

## Prerequisites

```bash
cargo install cargo-llvm-lines
rustup install nightly
```

## Critical Rule: Capture First, Analyze Later

These commands are expensive. Always save output to files:

```bash
# WRONG - wasteful, loses data
cargo llvm-lines --bin foo | grep something

# CORRECT - efficient, preserves everything
cargo llvm-lines --bin foo > /tmp/llvm-lines.txt 2>&1
grep something /tmp/llvm-lines.txt
```

## Tool 1: cargo-llvm-lines (Monomorphization Bloat)

Shows which functions generate the most LLVM IR, revealing monomorphization issues.

```bash
cargo llvm-lines --bin <binary> -p <package> > /tmp/llvm-lines.txt 2>&1
head -50 /tmp/llvm-lines.txt
```

### Output Format

```
Lines              Copies           Function name
-----              ------           -------------
1952157            41947            (TOTAL)
 234836 (12.0%)    50 (0.1%)  mylib::generic_fn<...>
```

- **Lines** — Total LLVM IR lines from all copies
- **Copies** — Number of monomorphized instances
- **%** — Percentage of total

### Red Flags

| Pattern | Meaning | Solution |
|---------|---------|----------|
| High lines, low copies | One function generating tons of code | Split function, reduce generic complexity |
| High lines, high copies | Trait explosion | Use `dyn Trait`, consolidate types |
| Closures with many lines | Large `impl Future` or generic contexts | Extract to non-generic helper |

### Common Culprits

- Salsa/incremental computation queries
- Tokio futures (each async fn with different types)
- Serde serialize/deserialize
- Iterator chains with many combinators

## Tool 2: -Zprint-type-sizes (Large Types)

Large types cause expensive memcpy and increase monomorphization cost.

```bash
cargo +nightly rustc --bin <binary> -p <package> -- \
  -Zprint-type-sizes > /tmp/type-sizes.txt 2>&1

# Find largest types
sort -t: -k2 -n /tmp/type-sizes.txt | tail -50
```

### Red Flags

- Types > 100 bytes (expensive to copy)
- Deeply nested generics

### Solutions

- Box large fields
- Use references instead of owned types
- Simplify nested generics

## Tool 3: -Zunpretty=expanded (Macro Expansion)

See what macros expand to:

```bash
cargo +nightly rustc --bin <binary> -p <package> -- \
  -Zunpretty=expanded > /tmp/expanded.rs 2>&1

wc -l /tmp/expanded.rs  # Total lines after expansion
```

## Tool 4: -Zprint-mono-items (Full Monomorphization Dump)

Lists every single monomorphized item. Very verbose!

```bash
cargo +nightly rustc --bin <binary> -p <package> -- \
  -Zprint-mono-items=eager > /tmp/mono-items.txt 2>&1

# Count monomorphizations for a crate
grep "mycrate::" /tmp/mono-items.txt | wc -l
```

## Workflow: Finding Bloat

1. **Start with llvm-lines** (fastest, most actionable):
   ```bash
   cargo llvm-lines --bin mybin -p mypkg > /tmp/ll.txt 2>&1
   head -50 /tmp/ll.txt
   ```

2. **Identify top bloaters** (high lines × copies)

3. **Check specific crates**:
   ```bash
   grep "tokio" /tmp/ll.txt | head -20
   grep "serde" /tmp/ll.txt | head -20
   ```

4. **For large types**:
   ```bash
   cargo +nightly rustc --bin mybin -- -Zprint-type-sizes 2>&1 | \
     sort -t: -k2 -n | tail -30
   ```

## Solutions by Problem

### Generic Explosion

```rust
// BAD: N × M monomorphizations
fn process<T: Trait, U: OtherTrait>(t: T, u: U)

// BETTER: Dynamic dispatch on cold path
fn process(t: &dyn Trait, u: &dyn OtherTrait)
```

### Large Async Futures

```rust
// BAD: Each call site monomorphizes the whole future
async fn big_async<T: Trait>(t: T) { ... }

// BETTER: Extract non-generic logic
async fn big_async<T: Trait>(t: T) {
    big_async_inner(&t as &dyn Trait).await
}
async fn big_async_inner(t: &dyn Trait) { ... }
```

### Iterator Chains

```rust
// BAD: Creates unique type per chain
items.iter().map(f).filter(g).map(h).collect()

// BETTER for cold paths: Use explicit loop
let mut result = Vec::new();
for item in items {
    if g(&item) { result.push(h(f(item))); }
}
```

## See Also

- `rustc-timings` skill for compile-time profiling
- `cargo build -Z timings` for crate-level timing
