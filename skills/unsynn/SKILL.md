---
name: unsynn
description: Write Rust proc macros using unsynn instead of syn. This skill should be used when creating or modifying procedural macros. Unsynn is a lightweight grammar-based parser that avoids syn's 15-20s compile time overhead.
---

# Unsynn: Syn-Free Proc Macros

## Overview

`unsynn` is a lightweight, macro-based parser generator for writing Rust procedural macros without the `syn` dependency. It generates recursive descent parsers from grammar specifications.

## When to Use This Skill

- Writing new proc macros
- Refactoring existing proc macros to remove syn
- Understanding how bearcove proc macros work

## Dependencies

```toml
[dependencies]
unsynn = "0.3"
proc-macro2 = "1"
quote = "1"
```

## Core Concepts

### 1. Keywords

Define Rust keywords and custom keywords:

```rust
use unsynn::*;

keyword! {
    pub KPub = "pub";
    pub KAsync = "async";
    pub KFn = "fn";
    pub KStruct = "struct";
    pub KEnum = "enum";
    pub KImpl = "impl";
    pub KFor = "for";
    pub KWhere = "where";
    pub KMut = "mut";
    pub KRef = "ref";
    pub KSelf = "self";
    pub KSelfType = "Self";
}
```

### 2. Grammar Structures

Define grammar using the `unsynn!` macro:

```rust
unsynn! {
    pub struct FnSignature {
        pub attributes: Option<Many<Attribute>>,
        pub vis: Option<KPub>,
        pub async_kw: Option<KAsync>,
        pub fn_kw: KFn,
        pub name: Ident,
        pub generics: Option<GenericParams>,
        pub params: ParenthesisGroup,
        pub return_type: Option<ReturnType>,
        pub where_clause: Option<WhereClause>,
        pub body: BraceGroup,
    }

    pub struct GenericParams {
        pub lt: Lt,
        pub params: VerbatimUntil<Gt>,
        pub gt: Gt,
    }

    pub struct ReturnType {
        pub arrow: RArrow,
        pub ty: VerbatimUntil<Either<BraceGroup, KWhere>>,
    }

    pub struct WhereClause {
        pub where_kw: KWhere,
        pub bounds: VerbatimUntil<BraceGroup>,
    }
}
```

### 3. Parsing

```rust
use proc_macro2::TokenStream;
use unsynn::ToTokenIter;

fn parse_function(input: TokenStream) -> Result<FnSignature, String> {
    let mut iter = input.to_token_iter();
    iter.parse()
}
```

## Type Reference

### Combinators

| Type | Description | Example |
|------|-------------|---------|
| `Option<T>` | Zero or one T | `Option<KAsync>` for optional `async` |
| `Many<T>` | Zero or more T | `Many<Attribute>` for `#[...]` attributes |
| `Cons<A, B>` | Sequence A then B | `Cons<KFn, Ident>` for `fn name` |
| `Cons<A, B, C>` | Sequence A, B, C | Works with up to 12 items |
| `Either<A, B>` | Choice: A or B | `Either<KPub, KCrate>` |
| `Except<T>` | Any token except T | `Except<Semi>` for non-semicolon |

### Token Collectors

| Type | Description | Use Case |
|------|-------------|----------|
| `VerbatimUntil<T>` | Collect tokens until T | Capturing type expressions |
| `VerbatimUntilEnd` | Collect until end | Rest of input |

### Delimited Groups

| Type | Description |
|------|-------------|
| `ParenthesisGroup` | `(...)` |
| `BraceGroup` | `{...}` |
| `BracketGroup` | `[...]` |

### Punctuation

| Type | Symbol |
|------|--------|
| `Lt` | `<` |
| `Gt` | `>` |
| `Semi` | `;` |
| `Colon` | `:` |
| `Comma` | `,` |
| `RArrow` | `->` |
| `FatArrow` | `=>` |
| `PathSep` | `::` |

### Literals and Identifiers

| Type | Description |
|------|-------------|
| `Ident` | Identifier |
| `Literal` | Any literal |
| `LiteralString` | String literal |
| `LiteralInt` | Integer literal |

### Collections

| Type | Description |
|------|-------------|
| `CommaDelimitedVec<T>` | `T, T, T` (trailing comma ok) |
| `CommaDelimited<T>` | `T, T, T` (no trailing) |

## Patterns

### Pattern 1: Parsing Struct Definitions

```rust
unsynn! {
    pub struct StructDef {
        pub attributes: Option<Many<Attribute>>,
        pub vis: Option<KPub>,
        pub struct_kw: KStruct,
        pub name: Ident,
        pub generics: Option<GenericParams>,
        pub body: Either<StructBody, Semi>,
    }

    pub struct StructBody {
        pub brace: BraceGroup,
    }
}
```

### Pattern 2: Parsing Trait Impl Blocks

```rust
unsynn! {
    pub struct ImplBlock {
        pub impl_kw: KImpl,
        pub generics: Option<GenericParams>,
        pub trait_path: Option<TraitPath>,
        pub self_ty: VerbatimUntil<Either<KWhere, BraceGroup>>,
        pub where_clause: Option<WhereClause>,
        pub body: BraceGroup,
    }

    pub struct TraitPath {
        pub path: VerbatimUntil<KFor>,
        pub for_kw: KFor,
    }
}
```

### Pattern 3: Extracting and Transforming

```rust
impl FnSignature {
    pub fn into_parts(self) -> (TokenStream, Ident, TokenStream, TokenStream) {
        let vis = self.vis.map(|v| v.to_token_stream()).unwrap_or_default();
        let name = self.name;
        let params = self.params.to_token_stream();
        let body = self.body.to_token_stream();
        (vis, name, params, body)
    }
}
```

### Pattern 4: Generating Output with quote

```rust
use quote::quote;

fn transform_fn(sig: FnSignature) -> TokenStream {
    let name = &sig.name;
    let params = &sig.params;
    let body = &sig.body;

    quote! {
        fn #name #params {
            println!("entering {}", stringify!(#name));
            #body
        }
    }
}
```

## Real-World Example: Attribute Macro

```rust
use proc_macro::TokenStream;
use proc_macro2::TokenStream as TokenStream2;
use quote::quote;
use unsynn::*;

keyword! {
    KAsync = "async";
    KFn = "fn";
}

unsynn! {
    struct AsyncFn {
        async_kw: KAsync,
        fn_kw: KFn,
        name: Ident,
        params: ParenthesisGroup,
        ret: Option<ReturnType>,
        body: BraceGroup,
    }

    struct ReturnType {
        arrow: RArrow,
        ty: VerbatimUntil<BraceGroup>,
    }
}

#[proc_macro_attribute]
pub fn my_async(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = TokenStream2::from(item);
    let mut iter = input.to_token_iter();

    let func: AsyncFn = match iter.parse() {
        Ok(f) => f,
        Err(e) => return quote! { compile_error!(#e); }.into(),
    };

    let name = &func.name;
    let params = &func.params;
    let body = &func.body;
    let ret = func.ret.map(|r| {
        let ty = &r.ty;
        quote! { -> #ty }
    });

    quote! {
        fn #name #params #ret {
            let rt = tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .unwrap();
            rt.block_on(async #body)
        }
    }.into()
}
```

## Simple Token Walking Alternative

For very simple macros, direct token manipulation works without even unsynn:

```rust
use proc_macro::{TokenStream, TokenTree};

#[proc_macro_attribute]
pub fn simple(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let tokens: Vec<TokenTree> = item.into_iter().collect();

    // Find fn keyword
    let fn_pos = tokens.iter().position(|tt| {
        matches!(tt, TokenTree::Ident(id) if id.to_string() == "fn")
    }).expect("expected fn");

    // Function name is next ident after fn
    let name = match &tokens[fn_pos + 1] {
        TokenTree::Ident(id) => id.to_string(),
        _ => panic!("expected function name"),
    };

    // Continue parsing...
    item // or transform and return
}
```

## Reference Implementations

| Project | Location | Description |
|---------|----------|-------------|
| picante-macros | `~/bearcove/picante/crates/picante-macros/` | Query system macros |
| rapace-macros | `~/bearcove/rapace/crates/rapace-macros/` | RPC service macros |
| facet-macros-impl | `~/bearcove/facet/facet-macros-impl/` | Reflection macros |
| tokio-test-lite | `~/bearcove/tokio-test-lite/` | Simple token walking |

## Tips

1. **Start simple** - Use `VerbatimUntil` to capture complex expressions you don't need to parse
2. **Test incrementally** - Parse one piece at a time
3. **Use Option liberally** - Many syntax elements are optional
4. **Leverage quote** - Don't build token streams manually
5. **Check picante-macros** - Best reference for complex unsynn usage
