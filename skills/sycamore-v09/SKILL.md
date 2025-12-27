---
name: sycamore-v09
description: Build reactive web applications with Sycamore 0.9, a fine-grained reactive UI framework for Rust and WebAssembly. Use this skill when working with Sycamore components, signals, views, async resources, routing, or converting from other frameworks like Dioxus.
---

# Sycamore 0.9

Build reactive web applications using Sycamore 0.9, a fine-grained reactive UI framework for Rust that compiles to WebAssembly.

## When to Use This Skill

Use this skill when:
- Building Sycamore 0.9 web applications from scratch
- Converting code from other frameworks (Dioxus, Yew, etc.) to Sycamore
- Debugging Sycamore reactivity or component issues
- Understanding Sycamore's view DSL syntax
- Working with signals, effects, and reactive state
- Implementing components, props, and composition patterns
- Using async resources and suspense
- Setting up routing with sycamore-router
- Implementing contexts for shared state

## Sycamore Overview

Sycamore is a fine-grained reactive library for Rust and WebAssembly. Unlike virtual DOM frameworks, Sycamore uses signals for fine-grained reactivity - when a signal changes, only the specific DOM nodes that depend on it are updated.

### Key Concepts

**Signals**: Reactive state containers that notify dependents when they change
- Created with `create_signal(initial_value)`
- Read with `.get()` or `.get_untracked()`
- Update with `.set(new_value)` or `.update(|x| ...)`

**Views**: Declarative UI templates using the `view!` macro
- Written in a JSX-like syntax
- Automatically subscribe to signals
- Update DOM surgically when signals change

**Components**: Reusable UI functions marked with `#[component]`
- Accept props as function parameters
- Return `View` (or `View<G>` with generic rendering backend)
- Can be nested and composed

**Effects**: Side effects that run when dependencies change
- Created with `create_effect()`
- Automatically track signal dependencies
- Re-run when any tracked signal changes

## Basic Component Patterns

### Simple Component

```rust
use sycamore::prelude::*;

#[component]
fn MyComponent() -> View {
    let count = create_signal(0);

    view! {
        div {
            p { "Count: " (count.get()) }
            button(on:click=move |_| count.set(*count.get() + 1)) {
                "Increment"
            }
        }
    }
}
```

### Component with Props

```rust
#[component]
fn Greeting(name: String) -> View {
    view! {
        h1 { "Hello, " (name) "!" }
    }
}

// Usage:
view! {
    Greeting(name="World".to_string())
}
```

### Component with Generic Renderer

For libraries or reusable components that work across different rendering backends:

```rust
use sycamore::web::Html;

#[component]
fn GenericComponent<G: Html>() -> View<G> {
    view! {
        div { "Works on web" }
    }
}
```

For most applications, omit `<G: Html>` and just return `View`.

## Signals and Reactivity

### Creating and Reading Signals

```rust
// Create a signal
let count = create_signal(42);

// Read (tracked - creates reactive dependency)
let value = count.get();  // Returns ReadSignal - deref to get value
let value = *count.get(); // Get the actual value

// Read untracked (no reactive dependency)
let value = count.get_untracked();
```

### Updating Signals

```rust
// Set new value
count.set(100);

// Update based on current value
count.update(|x| *x += 1);

// Or with closure
count.set(*count.get() + 1);
```

### Derived State with Memos

```rust
let name = create_signal("Alice".to_string());

// Computed value that updates when name changes
let greeting = create_memo(move || {
    format!("Hello, {}!", name.get())
});

view! {
    p { (greeting.get()) }
}
```

### Effects for Side Effects

```rust
let count = create_signal(0);

create_effect(move || {
    // Runs whenever count changes (tracks the .get() call)
    tracing::info!("Count is now: {}", count.get());
});
```

## Async Resources and Suspense

**See `references/next/guide/resources-and-suspense.md` for complete details.**

### Creating Resources

Resources handle async data fetching with built-in loading states:

```rust
use sycamore::prelude::*;
use sycamore::web::create_isomorphic_resource;

async fn fetch_user(id: u32) -> User {
    // HTTP request or async operation
    reqwest::get(format!("/api/users/{}", id))
        .await
        .unwrap()
        .json()
        .await
        .unwrap()
}

// Create resource - runs on both client and server
let user = create_isomorphic_resource(move || fetch_user(123));

// For client-only data fetching
let user = create_client_resource(move || fetch_user(123));
```

### Resources with Dependencies

Resources can reactively refresh when signals change:

```rust
let user_id = create_signal(123);

// Resource depends on user_id signal
let user = create_client_resource(on(user_id, move || async move {
    fetch_user(*user_id.get()).await
}));

// When user_id changes, resource automatically refetches
```

### Displaying Resource Data

Resources are `Signal<Option<T>>`:

```rust
view! {
    (if let Some(user) = user.get_clone() {
        view! {
            h1 { (user.name) }
            p { (user.email) }
        }
    } else {
        view! {
            p { "Loading..." }
        }
    })
}
```

### Suspense Component

Automatically shows fallback while async data loads:

```rust
view! {
    Suspense(fallback=move || view! {
        div(class="spinner") { "Loading..." }
    }) {
        UserProfile {}  // Component that uses resources
    }
}
```

Any resource accessed under a `Suspense` boundary will trigger the fallback.

### Transition Component

Like `Suspense`, but keeps showing old content while new data loads (smoother UX):

```rust
view! {
    Transition(fallback=move || view! { /* Optional loading indicator */ }) {
        UserProfile {}  // Won't flicker when data refetches
    }
}
```

## Routing with sycamore-router

**See `references/next/router.md` for complete details.**

### Setup

Add to `Cargo.toml`:

```toml
sycamore-router = "0.9.2"
```

### Defining Routes

Routes are defined as an enum with derive macros:

```rust
use sycamore_router::{Route, Router, HistoryIntegration};

#[derive(Route, Clone)]
enum AppRoutes {
    #[to("/")]
    Index,
    #[to("/about")]
    About,
    #[to("/users/<id>")]
    User { id: u32 },
    #[to("/blog/<year>/<month>/<slug>")]
    BlogPost {
        year: u32,
        month: u32,
        slug: String
    },
    #[not_found]
    NotFound,
}
```

**Important**:
- Each route needs `#[to("/path")]` attribute
- Dynamic parameters use `<name>` syntax and must match struct fields
- Must have exactly one `#[not_found]` route for 404s

### Using the Router

```rust
#[component]
fn App() -> View {
    view! {
        Router(
            integration=HistoryIntegration::new(),
            view=move |route: &ReadSignal<AppRoutes>| {
                match route.get().as_ref() {
                    AppRoutes::Index => view! { HomePage {} },
                    AppRoutes::About => view! { AboutPage {} },
                    AppRoutes::User { id } => view! { UserPage(id=*id) },
                    AppRoutes::BlogPost { year, month, slug } => {
                        view! { BlogPost(year=*year, month=*month, slug=slug.clone()) }
                    }
                    AppRoutes::NotFound => view! { NotFoundPage {} },
                }
            },
        )
    }
}
```

### Navigation

Use regular anchor tags - the router intercepts them automatically:

```rust
view! {
    nav {
        a(href="/") { "Home" }
        a(href="/about") { "About" }
        a(href="/users/123") { "User 123" }
    }
}
```

### Programmatic Navigation

```rust
use sycamore_router::navigate;

button(on:click=|_| navigate("/about")) {
    "Go to About"
}
```

### Getting Current Route

```rust
use sycamore_router::use_route;

#[component]
fn SomeComponent() -> View {
    let route = use_route::<AppRoutes>();

    // Access current route
    let current_path = match route.get().as_ref() {
        AppRoutes::Index => "/",
        AppRoutes::About => "/about",
        // ...
    };

    view! { /* ... */ }
}
```

## Contexts for Shared State

**See `references/next/guide/contexts.md` for complete details.**

Contexts let you share data between components without prop drilling.

### Defining a Context

Use the newtype idiom with a signal wrapper:

```rust
#[derive(Clone, Copy, PartialEq, Eq)]
struct DarkMode(Signal<bool>);

impl DarkMode {
    fn is_enabled(self) -> bool {
        *self.0.get()
    }

    fn toggle(self) {
        self.0.set(!*self.0.get());
    }
}
```

### Providing Context

Make the context available to child components:

```rust
#[component]
fn App() -> View {
    let dark_mode = DarkMode(create_signal(false));
    provide_context(dark_mode);

    view! {
        ThemeToggle {}
        Content {}
    }
}
```

### Using Context

Access the context in nested components:

```rust
#[component]
fn ThemeToggle() -> View {
    let dark_mode = use_context::<DarkMode>();

    view! {
        button(on:click=move |_| dark_mode.toggle()) {
            (if dark_mode.is_enabled() { "☀️ Light" } else { "🌙 Dark" })
        }
    }
}
```

**Important**: Contexts are not reactive by themselves. Wrap them in signals for reactivity.

## View DSL Syntax

**See `references/next/guide/view-dsl.md` for complete details.**

### Elements and Attributes

```rust
view! {
    // Basic element
    div { "Hello" }

    // With attributes
    div(class="container", id="main") {
        "Content"
    }

    // Dynamic attributes
    div(class=format!("item {}", if active { "active" } else { "" })) {
        "Item"
    }
}
```

### Event Handlers

```rust
view! {
    button(on:click=move |_| {
        // Handle click
    }) { "Click me" }

    input(on:input=move |e: web_sys::Event| {
        let target = e.target().unwrap();
        let input = target.unchecked_into::<web_sys::HtmlInputElement>();
        let value = input.value();
        // Use value
    })
}
```

### Interpolation

```rust
let name = create_signal("Alice".to_string());
let count = create_signal(42);

view! {
    // Text interpolation
    p { "Hello, " (name.get()) "!" }

    // Expression interpolation
    p { "Count: " (count.get()) }

    // Complex expressions
    p { "Double: " (count.get() * 2) }
}
```

### Conditional Rendering

```rust
let show = create_signal(true);

view! {
    (if *show.get() {
        view! { p { "Visible" } }
    } else {
        view! { p { "Hidden" } }
    })
}
```

### List Rendering

```rust
let items = create_signal(vec!["Apple", "Banana", "Cherry"]);

view! {
    ul {
        Keyed(
            iterable=items,
            view=|item| view! {
                li { (item) }
            },
            key=|item| item.to_string(),
        )
    }
}
```

**Important**: Always use `Keyed` for dynamic lists - provides efficient updates.

### Two-Way Data Binding

```rust
let text = create_signal(String::new());

view! {
    input(bind:value=text, placeholder="Type here...")
    p { "You typed: " (text.get()) }
}
```

## Other Important Concepts

### Node References

**See `references/next/guide/node-ref.md` for details.**

Get direct DOM element access:

```rust
let input_ref = create_node_ref();

view! {
    input(ref=input_ref)
    button(on:click=move |_| {
        if let Some(input) = input_ref.get::<DomNode>() {
            // Access DOM element
            input.unchecked_into::<web_sys::HtmlInputElement>().focus();
        }
    }) { "Focus Input" }
}
```

### JavaScript Interop

**See `references/next/guide/js-interop.md` for details.**

Call JavaScript from Rust using `wasm-bindgen`:

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

log("Hello from Rust!");
```

### Tweened Values

**See `references/next/guide/tweened.md` for details.**

Animated transitions between values:

```rust
use sycamore::easing;

let value = create_signal(0.0);
let tweened = create_tweened_signal(value.get(), Duration::from_millis(500), easing::quad_out);

// When value changes, tweened animates to new value
value.set(100.0);
```

## Documentation Structure

The skill includes the complete official Sycamore 0.9 documentation in `references/next/`:

### Essential Guides

- **`introduction/`**: Getting started tutorials
  - `your-first-app.md` - Hello world
  - `adding-state.md` - Signals and reactivity basics
  - `rendering-lists.md` - List rendering patterns
  - `todo-app.md` - Complete todo app tutorial

- **`guide/`**: Core concepts
  - `view-dsl.md` - Complete view syntax reference
  - `data-binding.md` - Two-way binding patterns
  - `resources-and-suspense.md` - Async data fetching
  - `contexts.md` - Shared state management
  - `node-ref.md` - DOM element access
  - `js-interop.md` - JavaScript integration
  - `tweened.md` - Animated values
  - `view-builder.md` - Alternative view API
  - `attribute-passthrough.md` - Forwarding attributes

### Ecosystem Features

- **`router.md`**: Complete routing guide
- **`server-side-rendering.md`**: SSR setup and usage

### Reference Materials

- **`reference.md`**: API documentation
- **`faq.md`**: Common questions
- **`troubleshooting.md`**: Debugging help
- **`contributing/roadmap.md`**: Future plans

### Loading Documentation

Load relevant documentation as needed:

```bash
# For basics
Read references/next/introduction/your-first-app.md

# For specific features
Read references/next/guide/resources-and-suspense.md
Read references/next/router.md
Read references/next/guide/contexts.md

# For debugging
Read references/next/troubleshooting.md
Read references/next/faq.md
```

## Migration from Dioxus

When converting Dioxus code to Sycamore:

1. **Update imports**:
   ```rust
   // Before (Dioxus)
   use dioxus::prelude::*;

   // After (Sycamore)
   use sycamore::prelude::*;
   ```

2. **Change view macro**:
   ```rust
   // Before
   rsx! { div { "Hello" } }

   // After
   view! { div { "Hello" } }
   ```

3. **Convert state**:
   ```rust
   // Before
   let mut count = use_state(|| 0);
   count.set(5);

   // After
   let count = create_signal(0);
   count.set(5);
   ```

4. **Update component signatures**:
   ```rust
   // Before
   #[component]
   fn MyComponent(cx: Scope) -> Element { /* ... */ }

   // After
   #[component]
   fn MyComponent() -> View { /* ... */ }
   ```

5. **Convert props**:
   ```rust
   // Before (Dioxus)
   #[component]
   fn Greeting(cx: Scope, name: String) -> Element { /* ... */ }

   // After (Sycamore)
   #[component]
   fn Greeting(name: String) -> View { /* ... */ }
   ```

6. **Update event handlers**:
   ```rust
   // Before
   onclick: move |_| { /* ... */ }

   // After
   on:click=move |_| { /* ... */ }
   ```

7. **Replace context hooks**:
   ```rust
   // Before
   use_context_provider(|| state);
   let state = use_context::<State>();

   // After
   provide_context(state);
   let state = use_context::<State>();
   ```

## Common Patterns

### App State Management

```rust
#[derive(Clone)]
struct AppState {
    user: Signal<Option<User>>,
    theme: Signal<Theme>,
}

#[component]
fn App() -> View {
    let state = AppState {
        user: create_signal(None),
        theme: create_signal(Theme::Light),
    };
    provide_context(state);

    view! {
        Router(/* ... */)
    }
}
```

### Form Handling

```rust
#[component]
fn LoginForm() -> View {
    let email = create_signal(String::new());
    let password = create_signal(String::new());

    let submit = move |_| {
        let email_val = (*email.get()).clone();
        let password_val = (*password.get()).clone();
        // Handle submission
    };

    view! {
        form(on:submit=submit) {
            input(bind:value=email, type="email", placeholder="Email")
            input(bind:value=password, type="password", placeholder="Password")
            button(type="submit") { "Log In" }
        }
    }
}
```

### Loading States with Suspense

```rust
#[component]
fn DataView() -> View {
    let data = create_isomorphic_resource(|| fetch_data());

    view! {
        Suspense(fallback=move || view! {
            div(class="loading") {
                "Loading data..."
            }
        }) {
            (if let Some(data) = data.get_clone() {
                view! {
                    DisplayData(data=data)
                }
            } else {
                view! {}
            })
        }
    }
}
```

## Best Practices

1. **Use `Keyed` for all dynamic lists**: Essential for efficient updates and correct behavior
2. **Wrap contexts in signals**: Make them reactive by wrapping in `Signal<T>`
3. **Use memos for expensive computations**: Avoid recalculating derived values
4. **Prefer `Transition` for data refetches**: Better UX than `Suspense` for updates
5. **Use `on(signal, ...)` for resource dependencies**: Explicit dependency tracking for async operations
6. **Keep components small**: Break complex UIs into focused, reusable components
7. **Load documentation as needed**: Reference files are comprehensive - load specific topics

## Common Issues and Solutions

### "cannot find trait `Html` in this scope"

```rust
// Add import
use sycamore::web::Html;

// Then use in component
#[component]
fn MyComponent<G: Html>() -> View<G> { /* ... */ }
```

For most apps, omit the generic and just return `View`.

### Signal reactivity not working

Ensure you're using `.get()` (tracked) not `.get_untracked()`:

```rust
// Reactive - establishes dependency
let value = signal.get();

// Not reactive - no dependency tracking
let value = signal.get_untracked();
```

### Router not intercepting links

Ensure you're using the `HistoryIntegration`:

```rust
Router(
    integration=HistoryIntegration::new(),  // ← Important
    view=|route| { /* ... */ }
)
```

### Resource not triggering Suspense

The resource must be read under the `Suspense` boundary:

```rust
// Wrong - resource read outside Suspense
let data = resource.get();
view! {
    Suspense(fallback=|| view! { "Loading" }) {
        (data)  // Already read, won't trigger suspense
    }
}

// Right - resource read inside Suspense
view! {
    Suspense(fallback=|| view! { "Loading" }) {
        (resource.get())  // Read inside boundary
    }
}
```

## Quick Start

```bash
# Add dependencies
cargo add sycamore@0.9
cargo add sycamore-router@0.9.2  # If using routing

# Build for WASM
cargo build --target wasm32-unknown-unknown

# Or use wasm-pack
wasm-pack build --target web
```

## When to Load Documentation

Load specific documentation files when:
- **Getting started**: `references/next/introduction/your-first-app.md`
- **Learning routing**: `references/next/router.md`
- **Async data fetching**: `references/next/guide/resources-and-suspense.md`
- **Shared state patterns**: `references/next/guide/contexts.md`
- **View syntax questions**: `references/next/guide/view-dsl.md`
- **Debugging issues**: `references/next/troubleshooting.md`
- **Framework comparison questions**: `references/next/faq.md`

The documentation is comprehensive - load specific files only when needed to conserve context.
