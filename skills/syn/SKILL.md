---
name: syn
description: Avoid syn dependency in Rust projects. This skill should be used when adding dependencies, writing proc macros, or when syn appears in the dependency tree. Provides alternatives for serde_derive, clap_derive, tokio-macros, futures-macro.
---

# Syn Avoidance

## Overview

The `syn` crate adds 15-20 seconds to compile times. This skill documents how to avoid it entirely using alternatives developed in the bearcove ecosystem.

**Core principle:** For every syn-dependent crate, there's a syn-free alternative. Avoiding syn is a sport!

## When to Use This Skill

- Before adding any dependency that might pull in syn
- When writing proc macros (use the `unsynn` skill)
- When cargo tree shows syn in the dependency tree
- When optimizing compile times

## Quick Reference: Replacements

| syn-dependent | syn-free alternative |
|---------------|---------------------|
| `serde` + `serde_derive` | `facet` (see facet skill) |
| `serde_json` | `facet-json` |
| `clap` + `clap_derive` | `facet-args` |
| `#[tokio::test]` | `tokio-test-lite` or manual runtime |
| `#[tokio::main]` | Manual runtime builder |
| `select!` / `join!` | `StreamExt` combinators |
| `syn` (for proc macros) | `unsynn` (see unsynn skill) |
| `axum` (default features) | `axum` with `default-features = false` |

## Detailed Replacements

### 1. Serialization: serde_derive → facet

**See the `facet` skill for complete details.**

Quick mapping:
```toml
# Instead of:
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# Use:
facet = { git = "https://github.com/facet-rs/facet", branch = "main" }
facet-json = { git = "https://github.com/facet-rs/facet", branch = "main" }
```

```rust
// Instead of:
#[derive(Serialize, Deserialize)]
struct Foo { ... }

// Use:
#[derive(Facet)]
struct Foo { ... }
```

### 2. CLI Parsing: clap_derive → facet-args

```toml
# Instead of:
clap = { version = "4", features = ["derive"] }

# Use:
facet-args = { git = "https://github.com/facet-rs/facet", branch = "main" }
```

```rust
// Instead of:
#[derive(Parser)]
struct Args {
    #[arg(short, long)]
    verbose: bool,
}
let args = Args::parse();

// Use:
#[derive(Facet)]
struct Args {
    /// Enable verbose output
    verbose: bool,
}
let args = facet_args::parse::<Args>(std::env::args())?;
```

### 3. Async Tests: tokio-macros → tokio-test-lite

```toml
[dev-dependencies]
tokio-test-lite = "0.2"
```

```rust
// Instead of:
#[tokio::test]
async fn test_something() {
    // ...
}

// Use:
#[tokio_test_lite::test]
async fn test_something() {
    // ...
}
```

### 4. Async Main: tokio-macros → Manual Runtime

```rust
// Instead of:
#[tokio::main]
async fn main() {
    run_server().await;
}

// Use:
fn main() {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap();
    rt.block_on(async_main());
}

async fn async_main() {
    run_server().await;
}
```

For single-threaded runtime:
```rust
fn main() {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap();
    rt.block_on(async_main());
}
```

### 5. Futures Macros: select!/join! → Combinators

```rust
// Instead of:
use futures::select;
select! {
    result = future1.fuse() => handle1(result),
    result = future2.fuse() => handle2(result),
}

// Use tokio::select! (if tokio is already in tree) or:
use futures::future::select;
match select(future1, future2).await {
    Either::Left((result, _)) => handle1(result),
    Either::Right((result, _)) => handle2(result),
}

// Or for streams, use StreamExt combinators:
use futures::stream::StreamExt;
while let Some(item) = stream.next().await {
    // handle item
}
```

### 6. Axum: Disable tokio Feature

```toml
# Instead of:
axum = "0.8"

# Use:
axum = { version = "0.8", default-features = false, features = [
    "form", "http1", "json", "matched-path", "original-uri",
    "query", "tower-log", "tracing"
] }
```

Note: This disables `axum::serve`. Use `rapace-axum-serve` or implement your own serve loop with hyper-util.

### 7. Proc Macros: syn → unsynn

**See the `unsynn` skill for complete details.**

Use `unsynn` for writing procedural macros without syn's compile time overhead.

## Checking for syn in Dependencies

**See the `cargo-tree` skill for full details.**

The critical command pattern for investigating syn:

```bash
cargo tree -i syn -e normal -e features
```

Key flags:
- `-i syn` - Invert tree to show what depends on syn
- `-e normal` - Show normal dependencies
- `-e features` - **CRITICAL**: Show which features activate syn

Without `-e features`, you won't see *why* syn is being pulled in.

Example investigations:
```bash
# What pulls in syn?
cargo tree -i syn -e normal -e features

# What pulls in tokio-macros?
cargo tree -i tokio-macros -e normal -e features

# What features does tokio have enabled?
cargo tree -i tokio -e normal -e features
```

## Common Pitfalls

### 1. Transitive Dependencies

Many crates pull in syn transitively. Always check with `cargo tree -i syn`.

### 2. Default Features

Many crates enable syn-dependent features by default:
```toml
# BAD - pulls in tokio-macros
tokio = { version = "1", features = ["macros"] }

# GOOD - no macros
tokio = { version = "1", features = ["rt", "sync", "time"] }
```

### 3. tracing Default Features

```toml
# BAD - pulls in tracing-attributes which uses syn
tracing = "0.1"

# GOOD
tracing = { version = "0.1", default-features = false, features = ["std"] }
```

### 4. Dev Dependencies Matter Too

Don't forget `[dev-dependencies]` - they affect compile times during development.

## Philosophy

Avoiding syn isn't just about compile times - it's about:
1. **Simplicity** - Token stream manipulation is often simpler than full AST parsing
2. **Compile times** - 15-20 seconds saved per clean build
3. **Understanding** - Forces you to understand what you actually need
4. **Fun** - It's a sport! Finding syn-free alternatives is satisfying

When tempted to reach for a syn-dependent crate, ask: "What's the syn-free way?"
