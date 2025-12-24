---
name: facet
description: Facet is a serde replacement for Rust using reflection. Use this skill when working with serialization, deserialization, CLI parsing, or any task where you'd normally use serde. Provides crate mappings (serde_json → facet-json, clap → facet-args, etc.) and usage patterns.
---

# Facet - Rust Reflection & Serialization

Facet (<https://facet.rs>) is a reflection-based alternative to serde for Rust. Instead of `Serialize`/`Deserialize` traits, types derive `Facet` which provides a `SHAPE` associated const with full type introspection.

## Derive Macro

```rust
// Instead of:
use serde::{Serialize, Deserialize};
#[derive(Serialize, Deserialize)]
struct Foo { ... }

// Use:
use facet::Facet;
#[derive(Facet)]
struct Foo { ... }
```

## Crate Mapping

| Traditional Crate | Facet Equivalent | Notes |
|-------------------|------------------|-------|
| `serde` | `facet` | Core derive macro |
| `serde_json` | `facet-json` | JSON (de)serialization |
| `toml` / `serde_toml` | `facet-toml` | TOML (de)serialization |
| `serde_yaml` | `facet-yaml` | YAML (de)serialization |
| `clap` | `facet-args` | CLI argument parsing |
| `rmp-serde` / msgpack | `facet-msgpack` | MessagePack (de)serialization |
| `postcard` | `facet-postcard` | Binary format for embedded/no_std |
| `quick-xml` / `serde_xml_rs` | `facet-xml` | XML (de)serialization |
| `kdl` | `facet-kdl` | KDL format support |
| `csv` | `facet-csv` | CSV (de)serialization |
| `serde_urlencoded` | `facet-urlencoded` | URL-encoded form data (deser only) |
| `rasn` / asn1 | `facet-asn1` | ASN.1 (serialization only) |
| `xdr-codec` | `facet-xdr` | XDR (serialization only) |

## Web Framework Integration

| Framework | Facet Crate | Replaces |
|-----------|-------------|----------|
| Axum | `facet-axum` | `axum::Json`, `axum::Form` |

`facet-axum` provides extractors and responses. Enable features for each format:
```toml
[dependencies]
facet-axum = { version = "0.33", features = ["json", "form", "yaml", "toml", "xml", "kdl", "msgpack", "postcard"] }
```

## Utility Crates

| Crate | Purpose |
|-------|---------|
| `facet-reflect` | Build/inspect values dynamically via `Peek` and `Poke` |
| `facet-value` | Dynamic value type (like `serde_json::Value`) |
| `facet-pretty` | Pretty-print any Facet type |
| `facet-diff` | Diff two Facet values |
| `facet-assert` | Pretty assertions (no `PartialEq` required) |

## Typical Cargo.toml

```toml
[dependencies]
facet = "0.33"
facet-json = "0.33"  # If you need JSON
facet-toml = "0.33"  # If you need TOML
# etc.
```

## Feature Flags (on `facet` crate)

Common features to enable for third-party type support:
- `uuid` - `uuid::Uuid`
- `ulid` - `ulid::Ulid`
- `chrono` - chrono date/time types
- `time` - time crate types
- `jiff02` - jiff date/time types
- `bytes` - `bytes::Bytes` / `BytesMut`
- `camino` - `Utf8Path` / `Utf8PathBuf`
- `url` - `url::Url`
- `ordered-float` - ordered float types
- `indexmap` - `IndexMap` / `IndexSet`
- `net` - network types (`SocketAddr`, `IpAddr`, etc.)
- `nonzero` - `NonZero<T>` types

## Code Examples

### JSON serialization
```rust
use facet::Facet;
use facet_json::{to_string, from_str};

#[derive(Facet)]
struct Config {
    name: String,
    count: u32,
}

let config = Config { name: "test".into(), count: 42 };
let json = to_string(&config);
let parsed: Config = from_str(&json)?;
```

### CLI argument parsing
```rust
use facet::Facet;
use facet_args::from_slice;

#[derive(Facet)]
struct Args {
    /// Input file path
    #[facet(positional)]
    input: String,

    /// Enable verbose output
    #[facet(short = 'v')]
    verbose: bool,
}

let args: Args = from_slice(&std::env::args().collect::<Vec<_>>())?;
```

### Axum handlers
```rust
use facet::Facet;
use facet_axum::FacetJson;

#[derive(Facet)]
struct Request { id: u64 }

#[derive(Facet)]
struct Response { message: String }

async fn handler(FacetJson(req): FacetJson<Request>) -> FacetJson<Response> {
    FacetJson(Response { message: format!("Got id {}", req.id) })
}
```

## Extended Ecosystem (External)

- `facet-v8` - V8 JavaScript engine integration
- `facet-openapi` - OpenAPI schema generation
- `facet_generate` - Generate types for Java/Swift/TypeScript

## Reference

- Website: <https://facet.rs>
- Repository: <https://github.com/facet-rs/facet>
- Local copy: `~/bearcove/facet`
