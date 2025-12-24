---
name: systemd-run
description: Limit memory and CPU for tests using systemd-run on Linux. Use when testing memory limits, reproducing OOM conditions, or preventing runaway tests from consuming all resources.
---

# Resource Limits with systemd-run

Run commands with strict memory/CPU limits using systemd's cgroup integration.

## Prerequisites

- Linux with systemd
- User must have permissions for transient units (usually works out of the box)

## Basic Usage

### Memory Limit

```bash
# Limit to 512MB RAM
systemd-run --user --scope -p MemoryMax=512M \
  cargo nextest run -p mypkg my_test

# Limit to 1GB RAM
systemd-run --user --scope -p MemoryMax=1G \
  ./target/debug/mybin
```

### Memory + Swap Limit

```bash
# 512MB RAM, no swap
systemd-run --user --scope \
  -p MemoryMax=512M \
  -p MemorySwapMax=0 \
  cargo nextest run -p mypkg my_test
```

### CPU Limit

```bash
# Limit to 50% of one CPU
systemd-run --user --scope -p CPUQuota=50% \
  cargo nextest run -p mypkg my_test

# Limit to 2 CPUs worth
systemd-run --user --scope -p CPUQuota=200% \
  ./target/debug/mybin
```

### Combined Limits

```bash
systemd-run --user --scope \
  -p MemoryMax=1G \
  -p MemorySwapMax=0 \
  -p CPUQuota=100% \
  cargo nextest run -p mypkg my_test
```

## Common Use Cases

### Reproduce OOM Conditions

```bash
# Force OOM at 256MB to test error handling
systemd-run --user --scope -p MemoryMax=256M \
  cargo nextest run -p mypkg test_large_input
```

### Prevent Runaway Tests

```bash
# Kill test if it exceeds 2GB
systemd-run --user --scope -p MemoryMax=2G \
  cargo nextest run --no-fail-fast
```

### Simulate CI Resource Limits

```bash
# Match typical CI runner limits
systemd-run --user --scope \
  -p MemoryMax=4G \
  -p CPUQuota=200% \
  cargo build --release
```

### Test Memory-Constrained Environments

```bash
# Simulate embedded or container with 64MB
systemd-run --user --scope \
  -p MemoryMax=64M \
  -p MemorySwapMax=0 \
  ./target/release/embedded-app
```

## Properties Reference

### Memory

| Property | Description | Example |
|----------|-------------|---------|
| `MemoryMax` | Hard memory limit | `512M`, `1G` |
| `MemorySwapMax` | Swap limit (0 = no swap) | `0`, `256M` |
| `MemoryHigh` | Soft limit (throttle, don't kill) | `1G` |
| `MemoryLow` | Memory protection (won't reclaim below) | `256M` |

### CPU

| Property | Description | Example |
|----------|-------------|---------|
| `CPUQuota` | CPU time limit (100% = 1 core) | `50%`, `200%` |
| `CPUWeight` | Relative CPU priority (1-10000) | `100` |
| `AllowedCPUs` | Pin to specific CPUs | `0-1` |

### I/O

| Property | Description | Example |
|----------|-------------|---------|
| `IOWeight` | Relative I/O priority (1-10000) | `100` |
| `IOReadBandwidthMax` | Read bandwidth limit | `/dev/sda 10M` |
| `IOWriteBandwidthMax` | Write bandwidth limit | `/dev/sda 5M` |

### Timeouts

| Property | Description | Example |
|----------|-------------|---------|
| `RuntimeMaxSec` | Kill after duration | `300` (5 min) |

## Integration with Nextest

### Wrapper Script

Create `scripts/limited-run.sh`:

```bash
#!/bin/bash
exec systemd-run --user --scope \
  -p MemoryMax=${MEMORY_LIMIT:-2G} \
  -p MemorySwapMax=0 \
  "$@"
```

Configure in `.config/nextest.toml`:

```toml
[scripts.wrapper.limited]
command = 'scripts/limited-run.sh'

[profile.limited]
run-wrapper = 'limited'
```

Use:

```bash
MEMORY_LIMIT=512M cargo nextest run --profile limited
```

## Checking Status

### View Resource Usage

```bash
# While running, in another terminal:
systemctl --user status
systemd-cgtop --user
```

### Check if OOM Killed

```bash
# Check dmesg for OOM messages
dmesg | grep -i oom | tail -5

# Or journal
journalctl --user -u 'run-*' --since "5 minutes ago"
```

## Troubleshooting

### "Failed to create scope"

You may need to enable lingering:
```bash
loginctl enable-linger $USER
```

### "No such property"

Your systemd version may not support all properties. Check:
```bash
systemctl --version
man systemd.resource-control
```

### Can't Set Memory Below ~10MB

systemd has minimums. For extreme limits, use:
```bash
# Direct cgroup manipulation (needs root or delegation)
cgcreate -g memory:mytest
echo 8388608 > /sys/fs/cgroup/memory/mytest/memory.limit_in_bytes
cgexec -g memory:mytest ./mybin
```

## Alternatives

### ulimit (per-process, less reliable)

```bash
# Soft limit 512MB, hard limit 1GB
ulimit -Sv 524288 -Hv 1048576
./mybin
```

Caveats: Only limits virtual memory, child processes can exceed.

### Docker (heavier)

```bash
docker run --memory=512m --memory-swap=512m myimage
```

### firejail (sandboxing + limits)

```bash
firejail --rlimit-as=512m ./mybin
```

## See Also

- `man systemd-run`
- `man systemd.resource-control`
- `nextest-scripts` skill for wrapper integration
