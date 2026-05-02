# C++ Safety Patterns Reference

Source: Ward Cunningham's C2 wiki audit — C++-specific patterns for resource safety, object identity, and structural hazards.

---

## Zitface Pattern (Pimpl + NullObject)

Combines pointer-to-implementation with a static null object for safe default state:

```cpp
class Animal {
    struct Impl {
        virtual void speak() = 0;
        virtual Impl* clone() const = 0;
        virtual ~Impl() = default;
    };
    struct NullImpl : Impl {
        void speak() override {}
        NullImpl* clone() const override { return &instance(); }
        static NullImpl& instance() { static NullImpl n; return n; }
    };

    Impl* impl;
public:
    Animal() : impl(&NullImpl::instance()) {}
    Animal(const Animal& o) : impl(o.impl == &NullImpl::instance() ? &NullImpl::instance() : o.impl->clone()) {}
    ~Animal() { if (impl != &NullImpl::instance()) delete impl; }
    void speak() { impl->speak(); }
};
```

Benefits: transparent polymorphism, safe default state, no explicit null checks at call sites. Applicable to OpenGL context wrappers and optional feature flags where "no implementation" is a valid state.

---

## Value Semantics

Objects passed by value must be fully independent copies — no aliasing between source and destination. Requirements:
- Copy constructor produces an object equivalent to the original
- Assignment operator produces an object equivalent to the original
- Neither the copy nor the original affects the other after copying

For OpenGL resource handles: value semantics implies cloning the resource or using reference counting — not sharing the raw integer handle.

---

## Virtual Static Idiom (C-style Callback Adapter)

Bridges C-style `void*` callbacks (SDL3 event handlers, OpenGL debug callbacks) with C++ virtual dispatch:

```cpp
class EventHandler {
    static void staticCallback(void* userdata, SDL_Event* e) {
        static_cast<EventHandler*>(userdata)->onEvent(e);
    }
    virtual void onEvent(SDL_Event* e) = 0;
public:
    void* callbackPtr() { return this; }
    SDL_EventFilter filter() { return staticCallback; }
};
```

The static wrapper holds the this-pointer in `userdata`; the virtual method provides the polymorphic dispatch.

---

## Singleton Avoidance (Simpleton Pattern)

Singletons are globals with extra syntax. They break dependency injection, make mocking impossible, and cause test interference when tests share state. Any class that "only needs one instance" should instead receive that instance through its constructor or a factory parameter.

Replacing a singleton:
1. Extract an interface for the singleton's behavior
2. Pass an instance through constructors (dependency injection)
3. Create one instance at startup in `main()` or the top-level factory

This restores testability and removes hidden coupling.

---

## Speculative Inheritance Hazard

See the `oop-principles` skill — Speculative Hierarchy Anti-Pattern — for the hierarchy design rule.

C++-specific note: CRTP-based template hierarchies compound the hazard — they add compile-time complexity and harder debugging on top of the structural debt. Resist CRTP-style base classes until three or more real, concrete variants are actively in use.

---

## Two-Phase Composite for GL State Safety

When executing multiple GL operations that can fail, validate the entire sequence before executing any of it:

```cpp
bool validateAll(const std::vector<GLCommand*>& cmds) {
    return std::all_of(cmds.begin(), cmds.end(),
        [](auto* c) { return c->validate(); });  // side-effect-free
}
void executeAll(const std::vector<GLCommand*>& cmds) {
    for (auto* c : cmds) c->execute();
}
```

`validate()` must not modify GL state. If any validation fails, no execution begins. Prevents partial-state corruption mid-sequence.

---

## Virtual Functions and Shared Memory Hazard

Polymorphic objects cannot be safely passed across process boundaries via shared memory. A vtable pointer is a memory address in the originating process's address space — it does not exist in another process's memory space.

Workarounds: serialize state to a plain-data structure, reconstruct on the other side. Never pass `IOpenGLContext*` through IPC.

---

## Writing Equality Operators

`operator==` must satisfy: reflexivity, symmetry, transitivity, and consistency. In inheritance hierarchies, `instanceof`-style checking breaks symmetry when a derived object compares to a base object.

Safe pattern: compare `typeid(*this) == typeid(other)` for strict type equality, then compare members. Derived types that extend equality must override the operator.

---

## Weak Reference Pattern

A `WeakPointer<T>` holds a non-owning reference that returns `nullptr` if the target has been destroyed. Use to break circular ownership between observer and observable:

```cpp
// Observable holds strong ref; observer holds weak ref
std::weak_ptr<ParticleSystem> weakSystem = system;
if (auto s = weakSystem.lock()) { s->update(); }
```

Prefer `std::weak_ptr` over raw pointers for non-owning references to managed objects.

---

## No Exceptions in Destructor

Destructors must not throw. Throwing from a destructor during stack unwinding (when another exception is already active) calls `std::terminate` and kills the process.

If a destructor contains code that can fail:
1. Wrap it in `try/catch`
2. Log the error — do not re-throw
3. Complete the cleanup regardless

For RAII resource types (GL buffer handles, texture handles, shader programs), this is a critical correctness constraint — the resource must be released even if the release encounters an error. Source: C2 Wiki "BewareOfExceptionsInTheDestructor".

---

## Non-Virtual Interface (Template Method in C++)

The Template Method pattern in C++ is implemented via the Non-Virtual Interface idiom:
- The **public method** is non-virtual: it defines the algorithm skeleton
- The **virtual methods** it calls are protected: they define the overridable steps

```cpp
class Renderer {
public:
    void render() {           // non-virtual: skeleton
        preRender();
        doRender();           // virtual: step subclasses override
        postRender();
    }
protected:
    virtual void doRender() = 0;
    virtual void preRender() {}
    virtual void postRender() {}
};
```

This prevents subclasses from bypassing the algorithm skeleton (pre/post hooks always fire) while still allowing step customization. Prefer NVI over making public methods virtual. Source: C2 Wiki "TemplateMethodPattern".

---

## Command-Query Separation in OpenGL Code

A method either returns a value (Query) or changes state (Command) — not both.

In OpenGL code:
- **Commands** (state-changing): `glBindVertexArray`, `glUseProgram`, `glBufferData` — no return value expected
- **Queries** (state-reading): `glGetIntegerv`, `glGetError`, shader uniform lookups — no side effects expected

Mixing them in a single function (e.g., bind-and-return-previous-binding) requires extra caution and explicit documentation of the side effect. When a method must return a value AND change state, document the side effect at the declaration site, not just the implementation. Source: C2 Wiki "CommandQuerySeparation".

---

## Fail Fast

Terminate immediately on encountering irrecoverable state corruption rather than allowing corrupt state to propagate. The purpose is to prevent damage and generation of incorrect output — not to maintain availability.

C++ implementation:
- `assert(condition)` for invariants that must hold in debug builds
- `std::terminate()` for unrecoverable runtime state corruption
- Structured logging before termination: record the failing condition, the last known good state, and the call context

Distinguish: fail-fast on process state corruption; graceful handling on recoverable input data errors. Do not use `std::terminate` as a catch-all for bad input.

See also: `systematic-debugging/references/DEBUGGING_TACTICS.md — Fail Fast` for the general principle. Source: C2 Wiki "FailFast".

---

## Related Skills

- `cpp-safety` — iron law: every resource is owned by a scope-bound guard; destructors never throw
- `cpp-patterns` — broader C++ idiom reference
- `oop-principles` — structural design before implementation choices
