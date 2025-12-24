---
name: nextest-scripts
description: Configure cargo-nextest wrapper and setup scripts for test instrumentation. Use when integrating valgrind, memory limits, profiling, or custom test environments with nextest.
---

# Nextest Wrapper & Setup Scripts

Configure `cargo nextest` with wrapper scripts (valgrind, resource limits) and setup scripts (fixtures, services).

## Configuration File

Create `.config/nextest.toml` in your project root.

## Wrapper Scripts

Wrapper scripts wrap test binary execution. Use for instrumentation, resource limits, or debugging.

### Basic Wrapper

```toml
# .config/nextest.toml

[scripts.wrapper.my-wrapper]
command = 'path/to/wrapper.sh'

[profile.instrumented]
run-wrapper = 'my-wrapper'
```

Usage:
```bash
cargo nextest run --profile instrumented
```

### Valgrind Integration

```toml
[scripts.wrapper.valgrind]
command = 'valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=definite,indirect --error-exitcode=1'

[profile.valgrind]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'valgrind'
```

Usage:
```bash
cargo nextest run --profile valgrind -p mypkg test_name
```

### Memory Limits (systemd-run)

```toml
[scripts.wrapper.limited]
command = 'systemd-run --user --scope -p MemoryMax=512M -p MemorySwapMax=0'

[profile.limited]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'limited'
```

### Custom Wrapper Script

Create `scripts/test-wrapper.sh`:
```bash
#!/bin/bash
set -e

# Environment setup
export MY_VAR=value

# Optional: resource limits
if [[ -n "$MEMORY_LIMIT" ]]; then
    exec systemd-run --user --scope -p MemoryMax="$MEMORY_LIMIT" "$@"
else
    exec "$@"
fi
```

```toml
[scripts.wrapper.custom]
command = 'scripts/test-wrapper.sh'

[profile.custom]
run-wrapper = 'custom'
```

### Callgrind Profiling

```toml
[scripts.wrapper.callgrind]
command = 'valgrind --tool=callgrind --callgrind-out-file=callgrind.out'

[profile.callgrind]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'callgrind'
test-threads = 1  # Single thread for clean profiling
```

## Setup Scripts

Setup scripts run **before** tests. Use for starting services, creating fixtures, or environment prep.

### Basic Setup

```toml
[scripts.setup.start-db]
command = 'scripts/start-test-db.sh'

[profile.integration]
setup = ['start-db']
```

### Setup with Arguments

```toml
[scripts.setup.setup-env]
command = 'scripts/setup.sh'

[profile.dev]
setup = ['setup-env']
```

### Multiple Setup Scripts

```toml
[scripts.setup.start-db]
command = 'docker compose up -d postgres'

[scripts.setup.wait-db]
command = 'scripts/wait-for-postgres.sh'

[scripts.setup.seed-db]
command = 'scripts/seed-test-data.sh'

[profile.integration]
setup = ['start-db', 'wait-db', 'seed-db']
```

## Profile Configuration

### Full Example

```toml
# .config/nextest.toml

# Wrapper scripts
[scripts.wrapper.valgrind]
command = 'valgrind --leak-check=full --error-exitcode=1'

[scripts.wrapper.limited]
command = 'systemd-run --user --scope -p MemoryMax=1G'

# Setup scripts
[scripts.setup.prepare]
command = 'scripts/prepare-tests.sh'

# Default profile (always applied)
[profile.default]
retries = 0
fail-fast = true

# CI profile
[profile.ci]
retries = 2
fail-fast = false
test-threads = 4

# Debug profile with valgrind
[profile.valgrind]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'valgrind'
test-threads = 1
slow-timeout = { period = "60s" }

# Integration tests with setup
[profile.integration]
setup = ['prepare']
test-threads = 1

# Memory-limited tests
[profile.limited]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'limited'
```

## Platform-Specific Configuration

### Linux Only

```toml
[profile.valgrind]
platform = 'cfg(target_os = "linux")'
run-wrapper = 'valgrind'
```

### macOS Only

```toml
[profile.macos-debug]
platform = 'cfg(target_os = "macos")'
# macOS-specific settings
```

### Combine Conditions

```toml
[profile.linux-x86]
platform = 'cfg(all(target_os = "linux", target_arch = "x86_64"))'
```

## Environment Variables

### In Wrapper Scripts

Wrappers receive the test command as arguments. Use `"$@"` to pass through:

```bash
#!/bin/bash
export MY_VAR=value
exec "$@"
```

### In nextest.toml

```toml
[profile.default.env]
MY_VAR = "value"
RUST_BACKTRACE = "1"
```

## Useful Patterns

### Conditional Wrapper via Environment

```bash
#!/bin/bash
# scripts/maybe-valgrind.sh
if [[ "$USE_VALGRIND" == "1" ]]; then
    exec valgrind --leak-check=full "$@"
else
    exec "$@"
fi
```

```bash
USE_VALGRIND=1 cargo nextest run --profile custom
```

### Timeout Wrapper

```bash
#!/bin/bash
# scripts/with-timeout.sh
exec timeout ${TEST_TIMEOUT:-60} "$@"
```

### Retry on Flaky Tests

```toml
[profile.flaky]
retries = 3
retry-delay = { delay = "1s", backoff = "exponential" }
```

## Debugging

### List Available Profiles

```bash
cargo nextest list --profile valgrind
```

### Show Effective Configuration

```bash
cargo nextest show-config test
cargo nextest show-config test --profile valgrind
```

### Verbose Wrapper Execution

Add `-v` to see what's being executed:

```bash
cargo nextest run -v --profile valgrind test_name
```

## Common Issues

### Wrapper Not Found

Ensure script is executable and in PATH or use absolute/relative path:

```toml
[scripts.wrapper.my-wrapper]
command = './scripts/wrapper.sh'  # Relative to project root
```

### Slow Tests Timeout

Increase timeout for instrumented tests:

```toml
[profile.valgrind]
slow-timeout = { period = "120s", terminate-after = 2 }
```

### Tests Fail Under Wrapper

Test with wrapper manually first:

```bash
valgrind ./target/debug/deps/mytest-abc123 test_name --nocapture
```

## See Also

- [nextest docs: Wrapper scripts](https://nexte.st/docs/configuration/wrapper-scripts/)
- [nextest docs: Setup scripts](https://nexte.st/docs/configuration/setup-scripts/)
- `valgrind` skill for memory debugging
- `systemd-run` skill for resource limits
