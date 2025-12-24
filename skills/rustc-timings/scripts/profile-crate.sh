#!/bin/bash
# Profile a Rust crate's compile time and analyze with DuckDB
#
# Usage: ./profile-crate.sh <package> [binary]
#
# Examples:
#   ./profile-crate.sh my-crate
#   ./profile-crate.sh my-crate my-binary
#
# Requires: nightly rust, crox, summarize, duckdb

set -euo pipefail

PACKAGE="${1:?Usage: $0 <package> [binary]}"
BINARY="${2:-$PACKAGE}"
PROFILE_DIR="/tmp/rustc-profile-$$"

echo "=== Profiling $PACKAGE (binary: $BINARY) ==="
echo "Output dir: $PROFILE_DIR"
echo

# Check prerequisites
for cmd in crox summarize duckdb; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found"
        echo "Install with:"
        echo "  cargo install --git https://github.com/rust-lang/measureme crox summarize"
        echo "  brew install duckdb  # or apt install duckdb"
        exit 1
    fi
done

# Clean and profile
echo "=== Step 1: Clean package ==="
cargo +nightly clean -p "$PACKAGE"

echo
echo "=== Step 2: Build with self-profiling ==="
mkdir -p "$PROFILE_DIR"
RUSTFLAGS="-Zself-profile=$PROFILE_DIR" cargo +nightly build -p "$PACKAGE" --bin "$BINARY" 2>&1

# Find the profile data
PROFILE_DATA=$(find "$PROFILE_DIR" -name "*.mm_profdata" | head -1)
if [[ -z "$PROFILE_DATA" ]]; then
    echo "ERROR: No profile data found in $PROFILE_DIR"
    exit 1
fi
PROFILE_BASE="${PROFILE_DATA%.mm_profdata}"

echo
echo "=== Step 3: Generate summary ==="
summarize summarize "$PROFILE_BASE" | head -50

echo
echo "=== Step 4: Convert to Chrome format ==="
cd "$PROFILE_DIR"
crox "$(basename "$PROFILE_BASE")"

CHROME_JSON="$PROFILE_DIR/chrome_profiler.json"
if [[ ! -f "$CHROME_JSON" ]]; then
    echo "ERROR: chrome_profiler.json not created"
    exit 1
fi

echo
echo "=== Step 5: DuckDB Analysis ==="

echo
echo "--- Top 20 by total time ---"
duckdb -c "
SELECT
    name,
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as count,
    ROUND(100.0 * SUM(dur) / (SELECT SUM(dur) FROM read_json('$CHROME_JSON')), 1) as pct
FROM read_json('$CHROME_JSON')
WHERE dur IS NOT NULL
GROUP BY name
ORDER BY SUM(dur) DESC
LIMIT 20
"

echo
echo "--- Query events (trait resolution, type checking) ---"
duckdb -c "
SELECT
    name,
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as invocations
FROM read_json('$CHROME_JSON')
WHERE dur IS NOT NULL AND cat = 'Query'
GROUP BY name
ORDER BY SUM(dur) DESC
LIMIT 15
"

echo
echo "--- Monomorphization check ---"
duckdb -c "
SELECT
    ROUND(SUM(dur) / 1e6, 2) as seconds,
    COUNT(*) as instances,
    CASE WHEN COUNT(*) > 30000 THEN '⚠️  EXCESSIVE' ELSE '✓ OK' END as status
FROM read_json('$CHROME_JSON')
WHERE name = 'items_of_instance' AND dur IS NOT NULL
"

echo
echo "--- LLVM backend ---"
duckdb -c "
SELECT name, ROUND(SUM(dur) / 1e6, 2) as seconds
FROM read_json('$CHROME_JSON')
WHERE dur IS NOT NULL AND name LIKE 'LLVM%'
GROUP BY name ORDER BY SUM(dur) DESC
LIMIT 10
"

echo
echo "=== Done ==="
echo "Profile data: $PROFILE_DIR"
echo "Chrome JSON:  $CHROME_JSON"
echo
echo "View in browser: chrome://tracing (load $CHROME_JSON)"
