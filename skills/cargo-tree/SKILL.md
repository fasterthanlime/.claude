---
name: cargo-tree
description: Analyze Rust dependency trees to understand why dependencies are included and which features are being activated. Use when investigating dependency issues, unwanted dependencies (like syn), feature activation sources, or compile-time bloat.
---

# Cargo Tree

## Overview

Investigate Rust dependency trees to understand dependency relationships and feature activation. This skill provides patterns for using `cargo tree` effectively, especially for troubleshooting dependency issues and understanding feature propagation.

## When to Use This Skill

Use `cargo tree` analysis when:
- Investigating why a dependency is included in the build
- Finding which crate activates a specific feature (e.g., why `tokio/macros` is enabled)
- Identifying sources of compile-time bloat (e.g., `syn` dependencies)
- Understanding duplicate dependencies
- Debugging dependency version conflicts

## Core Patterns

### Pattern 1: Finding Why a Dependency Exists

To find what depends on a specific crate:

```bash
cargo tree -i <crate-name> -e normal
```

**Example:** Find what depends on `tokio-macros`:
```bash
cargo tree -i tokio-macros -e normal
```

**Key flags:**
- `-i, --invert <SPEC>`: Invert the tree to show reverse dependencies (what depends on this)
- `-e, --edges <KINDS>`: Specify dependency types to display

### Pattern 2: Understanding Feature Activation (CRITICAL)

To understand **why a feature is activated**, always include `-e features`:

```bash
cargo tree -i <crate-name> -e normal -e features
```

**Example:** Find why `tokio` has the `macros` feature enabled:
```bash
cargo tree -i tokio -e normal -e features
```

**Why this matters:** Without `-e features`, `cargo tree` won't show which features are being activated by dependents. This is essential for understanding feature propagation - if you want to know why `tokio/macros` is enabled, you must use `-e features`.

**Edge types available:**
- `features` - Show feature dependencies (CRITICAL for feature investigation)
- `normal` - Normal dependencies
- `build` - Build dependencies
- `dev` - Dev dependencies
- `all` - All dependency types
- `no-normal`, `no-build`, `no-dev`, `no-proc-macro` - Exclusion filters

### Pattern 3: Formatted Output for Analysis

To see both package names and activated features:

```bash
cargo tree -i <crate-name> -e normal -e features --format "{p} {f}"
```

**Format placeholders:**
- `{p}` - Package name and version (default)
- `{f}` - Comma-separated list of activated features
- `{l}` - Package license

**Example:**
```bash
cargo tree -i tokio -e normal -e features --format "{p} {f}"
```

This shows each package AND which features are active, making feature propagation visible.

### Pattern 4: Finding Duplicate Dependencies

```bash
cargo tree --duplicates
```

Shows only dependencies that appear in multiple versions. Useful for identifying version conflicts.

## Handling Large Output

**IMPORTANT:** `cargo tree` output can be extremely large (hundreds or thousands of lines), especially for workspaces with many crates.

### Use a Subagent for Analysis

When running `cargo tree` commands, use a subagent to handle and interpret the output:

```
Use the Task tool with subagent_type='general-purpose' to:
1. Run the cargo tree command
2. Analyze the output
3. Summarize findings
```

**Why:** Subagents can process large output without overwhelming the main conversation context.

**Example task prompt:**
```
Run `cargo tree -i tokio-macros -e normal -e features` and analyze which crates
are pulling in tokio-macros. Identify the root causes and summarize findings.
```

### Limiting Output Directly

Alternative approaches for manageable output:

```bash
# Limit tree depth
cargo tree -i <crate> -e normal -e features --depth 3

# Focus on specific package
cargo tree -p <package-name> -i <dependency> -e normal -e features

# Prune specific packages from display
cargo tree -i <crate> -e normal -e features --prune <package-to-hide>
```

## Common Workflows

### Workflow 1: Removing an Unwanted Dependency (e.g., syn)

**Goal:** Eliminate `syn` from the dependency tree to improve compile times.

**Steps:**
1. Find what depends on the target crate:
   ```bash
   cargo tree -i syn -e normal -e features
   ```

2. Analyze output (via subagent) to identify:
   - Direct dependents of `syn`
   - Which features pull in proc-macro crates
   - Root causes in your `Cargo.toml` files

3. For each dependent:
   - If it's a direct dependency with an optional feature, disable that feature
   - If it's a transitive dependency, trace back to find the root cause
   - Remove or replace the root dependency if possible

4. Verify the change:
   ```bash
   cargo tree -i syn -e normal -e features
   ```
   Should return "error: package 'syn' not found" if successful.

### Workflow 2: Understanding Feature Propagation

**Goal:** Find why a specific feature is activated when you didn't enable it directly.

**Steps:**
1. Check which features are active on the crate:
   ```bash
   cargo tree --format "{p} {f}" | grep <crate-name>
   ```

2. Find the full dependency chain with features:
   ```bash
   cargo tree -i <crate-name> -e normal -e features --format "{p} {f}"
   ```

3. Analyze (via subagent) to identify:
   - Which dependent activated the feature
   - The complete activation chain
   - Whether it's from a workspace dependency or package-specific dependency

4. Fix by:
   - Disabling the feature in the root cause's `Cargo.toml`
   - Using `default-features = false` if appropriate
   - Splitting dependencies between different package scopes if needed

### Workflow 3: Workspace-Wide Analysis

For multi-crate workspaces:

```bash
cargo tree --workspace -i <crate> -e normal -e features
```

The `--workspace` flag shows the dependency tree for all workspace members, helping identify which workspace packages contribute to a dependency.

## Key Principles

1. **Always include `-e features`** when investigating feature-related issues
2. **Use subagents** for commands that might produce large output
3. **Combine `-e normal -e features`** to see both dependency structure and feature activation
4. **Use `--format "{p} {f}"`** to make features visible in the output
5. **Invert with `-i`** to trace reverse dependencies (what depends on X)

## Additional Useful Flags

- `--no-dedupe` - Show all occurrences of shared dependencies (normally deduplicated)
- `--prefix <PREFIX>` - Change indentation style (`depth`, `indent`, `none`)
- `--charset <CHARSET>` - Use `ascii` for compatibility in logs
- `--target <TRIPLE>` - Filter dependencies for specific target platform
- `--locked` - Require Cargo.lock to be up to date
