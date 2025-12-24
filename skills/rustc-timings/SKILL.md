---
name: rustc-timings
description: Profile Rust compilation to find slow builds. Use when compile times are unacceptable, to identify trait resolution bottlenecks, excessive monomorphization, or LLVM backend issues.
---

# Rust Compile Time Profiling

Profile rustc to identify why builds are slow: trait resolution, monomorphization, LLVM codegen, etc.

## Prerequisites

```bash
# Nightly for -Z flags
rustup install nightly

# measureme tools for processing profiling data
cargo install --git https://github.com/rust-lang/measureme crox summarize

# DuckDB for analysis
brew install duckdb  # or apt install duckdb
```

## Workflow

### 1. Generate Profiling Data

```bash
# Clean the target crate first
cargo +nightly clean -p <crate-name>

# Build with self-profiling
RUSTFLAGS="-Zself-profile=/tmp/profile" \
  cargo +nightly build --bin <binary> -p <crate>
```

This creates `.mm_profdata` files in `/tmp/profile/`.

### 2. Quick Summary

```bash
summarize summarize /tmp/profile/<binary>-<pid>
```

Key metrics to look for:
- **LLVM_module_codegen_emit_obj** — LLVM code generation
- **LLVM_module_optimize** — LLVM optimization passes
- **items_of_instance** — Monomorphization (>30k is excessive)
- **codegen_select_candidate** — Trait resolution during codegen
- **type_op_prove_predicate** — Proving trait bounds
- **typeck** — Type checking
- **mir_borrowck** — Borrow checking

### 3. Convert to Chrome Format

```bash
cd /tmp/profile && crox <binary>-<pid>
```

Creates `chrome_profiler.json` (~10x larger than .mm_profdata).

### 4. Analyze with DuckDB

#### Overall Time Distribution

```bash
duckdb -c "
SELECT
    name,
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as count,
    ROUND(100.0 * SUM(dur) / (SELECT SUM(dur) FROM read_json('/tmp/profile/chrome_profiler.json')), 1) as pct
FROM read_json('/tmp/profile/chrome_profiler.json')
WHERE dur IS NOT NULL
GROUP BY name
ORDER BY SUM(dur) DESC
LIMIT 30
"
```

#### Query Events Only (Trait Resolution, Type Checking)

```bash
duckdb -c "
SELECT
    name,
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as invocations,
    ROUND(MAX(dur) / 1e6, 3) as max_sec
FROM read_json('/tmp/profile/chrome_profiler.json')
WHERE dur IS NOT NULL AND cat = 'Query'
GROUP BY name
ORDER BY SUM(dur) DESC
LIMIT 30
"
```

#### Monomorphization Check

```bash
duckdb -c "
SELECT
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as instances
FROM read_json('/tmp/profile/chrome_profiler.json')
WHERE name = 'items_of_instance' AND dur IS NOT NULL
"
```

If `instances` > 30,000 → trait/generic explosion.

#### LLVM Backend Breakdown

```bash
duckdb -c "
SELECT name, ROUND(SUM(dur) / 1e6, 2) as seconds, COUNT(*) as count
FROM read_json('/tmp/profile/chrome_profiler.json')
WHERE dur IS NOT NULL AND name LIKE 'LLVM%'
GROUP BY name ORDER BY SUM(dur) DESC
"
```

#### Time by Category

```bash
duckdb -c "
SELECT cat, ROUND(SUM(dur) / 1e6, 2) as seconds, COUNT(*) as events
FROM read_json('/tmp/profile/chrome_profiler.json')
WHERE dur IS NOT NULL
GROUP BY cat ORDER BY SUM(dur) DESC
"
```

### 5. Visual Analysis (Optional)

Open `chrome://tracing` in Chrome and load `chrome_profiler.json` for a timeline view.

## Interpreting Results

### LLVM Backend Dominates (>60%)

Symptoms: `LLVM_module_codegen_emit_obj`, `LLVM_module_optimize`, `LLVM_lto_optimize` are top

Solutions:
- Reduce `opt-level` in dev profile
- Use `lto = "thin"` instead of `"fat"`
- Increase `codegen-units` (trades runtime perf for compile time)
- Split large crates

### High Monomorphization

Symptoms: `items_of_instance` has >30k invocations

Solutions:
- Use `dyn Trait` instead of generics where possible
- Consolidate similar types
- Check for unintended trait bound combinatorics
- See `rustc-bloat` skill for deeper analysis

### Trait Resolution Issues

Symptoms: `codegen_select_candidate`, `type_op_prove_predicate` taking >2s combined

Solutions:
- Simplify where clauses
- Avoid deeply nested generic bounds
- Check for trait coherence issues

### Type Checking Slow

Symptoms: `typeck`, `mir_borrowck` taking >3s combined

Solutions:
- Split large functions
- Simplify type signatures
- Reduce nested generics

## Chrome Profiler JSON Schema

For custom queries, the JSON contains:
- `name` — Activity or query name
- `cat` — Category ("Query", "GenericActivity", etc.)
- `ph` — Phase ("X" = complete event)
- `ts` — Timestamp (μs)
- `dur` — Duration (μs)
- `pid`, `tid` — Process and thread IDs

## Notes

- Profile data files are large (~200MB .mm_profdata, ~700MB chrome_profiler.json)
- Profile in dev mode first (release masks some issues)
- Focus on the specific slow crate, not entire workspace
- Use `cargo +nightly build -Z timings` for crate-level overview
