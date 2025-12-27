# Never Use block_on

## The Rule

**NEVER use `block_on`, `block_in_place`, or any sync-over-async pattern.**

This includes:
- `futures::executor::block_on()`
- `tokio::runtime::Runtime::block_on()`
- `tokio::task::block_in_place()`
- `std::thread::spawn` + channel to bridge sync/async
- Any clever trick to call async code from sync code

## Why It's Forbidden

### Reason 1: Deadlock (The Obvious One)

With a single-threaded runtime (like `current_thread`):

```
You're in sync code on Thread A
    ↓
You call block_on(some_future)
    ↓
Thread A blocks, waiting for some_future to complete
    ↓
some_future needs the runtime to make progress
    ↓
The runtime runs on Thread A
    ↓
Thread A is blocked
    ↓
DEADLOCK - nothing can ever make progress
```

This isn't theoretical. This happens. Every time.

### Reason 2: Deadlock (The Sneaky One)

Even with a multi-threaded runtime, you can deadlock:

```
Task A holds Lock X, awaits something
    ↓
Task B needs Lock X, calls block_on(get_lock_x)
    ↓
Task B blocks its thread waiting for Lock X
    ↓
Task A is scheduled on that same thread
    ↓
Task A can't run because the thread is blocked
    ↓
Lock X is never released
    ↓
DEADLOCK
```

### Reason 3: The RPC Session Problem

In rapace cells:

```
Cell receives RPC request
    ↓
Handler calls block_on(host_client.get_data())
    ↓
Thread blocks waiting for RPC response
    ↓
RPC response arrives on the same runtime
    ↓
Runtime can't process it - thread is blocked
    ↓
DEADLOCK
```

The RPC session MUST be driven by the runtime. Block the runtime, kill the session.

### Reason 4: It's A Lie

`block_on` pretends you can have sync code call async code. You can't. The entire point of async is cooperative multitasking - yielding control so other tasks can run. `block_on` says "I refuse to yield, I will hold this thread hostage until I get what I want."

That's not cooperation. That's a deadlock waiting to happen.

### Reason 5: It Defeats The Purpose

Even when `block_on` doesn't deadlock, it:
- Holds a thread hostage (wastes resources)
- Prevents other tasks from running (kills throughput)
- Creates hidden blocking points (makes debugging hell)
- Spreads through the codebase like cancer (sync callers need sync callees)

## The Correct Solution

**Make the sync code async.**

If you have:
```rust
// WRONG
fn sync_function() {
    let result = block_on(async_operation());
}
```

The answer is:
```rust
// RIGHT
async fn now_async_function() {
    let result = async_operation().await;
}
```

"But my trait is sync!" → Make the trait async.
"But that's a lot of changes!" → Yes. Do them.
"But it's just this one place!" → No. Fix the architecture.

## Real World Example: Gingembre

Gingembre had sync traits:
```rust
trait DataResolver {
    fn resolve(&self, path: &DataPath) -> Option<Value>;  // sync!
}
```

The temptation: use `block_on` in the cell to call async RPC.

The reality: deadlock on first render.

The solution: make gingembre async:
```rust
trait DataResolver {
    async fn resolve(&self, path: &DataPath) -> Option<Value>;  // async!
}
```

Yes, this means making `Evaluator` async, `Renderer` async, `Engine` async. That's the correct solution.

## Mnemonics To Remember

1. **"block_on blocks everything"** - You're not just blocking your code, you're blocking the runtime.

2. **"One thread, one deadlock"** - Single-threaded runtime + block_on = guaranteed deadlock.

3. **"Async is contagious, blocking is infectious"** - Async spreads up the call stack (good). Blocking spreads deadlocks through your system (bad).

4. **"If you need block_on, your architecture is wrong"** - It's a symptom, not a solution.

5. **"The runtime can't save you if you're choking it"** - block_on is hands around the runtime's throat.

## What To Do Instead

1. **Accept that async is viral** - If something deep in the stack needs to be async, everything above it becomes async too. This is correct.

2. **Design for async from the start** - Traits that might need I/O should be async.

3. **Use proper async boundaries** - spawn_blocking for CPU work, async for I/O.

4. **When in doubt, make it async** - You can always call async code from async code. You cannot safely call async code from sync code.

## The Promise

If you ever find yourself reaching for `block_on`:

1. STOP
2. Ask: "Why is this code sync when it needs async?"
3. Make it async
4. Propagate async up the call stack as needed
5. Ship code that doesn't deadlock

There are no shortcuts. There is only async, all the way down.
