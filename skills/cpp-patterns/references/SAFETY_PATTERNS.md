# C++ Safety Patterns Reference

Source: Ward Cunningham's C2 wiki audit -- C++-specific patterns for resource safety, object identity, and structural hazards.

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

Objects passed by value must be fully independent copies -- no aliasing between source and destination. Requirements:
- Copy constructor produces an object equivalent to the original
- Assignment operator produces an object equivalent to the original
- Neither the copy nor the original affects the other after copying

For OpenGL resource handles: value semantics implies cloning the resource or using reference counting -- not sharing the raw integer handle.

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

Singletons are globals with extra syntax. They break dependency injection, make mocking impossible, and cause test interference when tests share state. Any class that "only needs one instance" MUST instead receive that instance through its constructor or a factory parameter.

Replacing a singleton:
1. Extract an interface for the singleton's behavior
2. Pass an instance through constructors (dependency injection)
3. Create one instance at startup in `main()` or the top-level factory

This restores testability and removes hidden coupling.

---

## Speculative Inheritance Hazard

See the `oop-principles` skill -- Speculative Hierarchy Anti-Pattern -- for the hierarchy design rule.

C++-specific note: Curiously Recurring Template Pattern (CRTP)-based template hierarchies compound the hazard -- they add compile-time complexity and harder debugging on top of the structural debt. Resist CRTP-style base classes until three or more real, concrete variants are actively in use.

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

Polymorphic objects cannot be safely passed across process boundaries via shared memory. A vtable pointer is a memory address in the originating process's address space -- it does not exist in another process's memory space.

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
std::weak_ptr<TextureCache> weakCache = cache;
if (auto s = weakCache.lock()) { s->update(); }
```

Use `std::weak_ptr` instead of raw pointers for non-owning references to managed objects.

---

## No Exceptions in Destructor

Destructors must not throw. Throwing from a destructor during stack unwinding (when another exception is already active) calls `std::terminate` and kills the process.

If a destructor contains code that can fail:
1. Wrap it in `try/catch`
2. Log the error -- do not re-throw
3. Complete the cleanup regardless

For RAII resource types (GL buffer handles, texture handles, shader programs), this is a critical correctness constraint -- the resource must be released even if the release encounters an error. Source: C2 Wiki "BewareOfExceptionsInTheDestructor".

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

This prevents subclasses from bypassing the algorithm skeleton (pre/post hooks always fire) while still allowing step customization. Use NVI (Non-Virtual Interface). Do not make public methods virtual. Source: C2 Wiki "TemplateMethodPattern".

---

## Command-Query Separation in OpenGL Code

A method either returns a value (Query) or changes state (Command) -- not both.

In OpenGL code:
- **Commands** (state-changing): `glBindVertexArray`, `glUseProgram`, `glBufferData` -- no return value expected
- **Queries** (state-reading): `glGetIntegerv`, `glGetError`, shader uniform lookups -- no side effects expected

Mixing them in a single function (e.g., bind-and-return-previous-binding) requires extra caution and explicit documentation of the side effect. When a method must return a value AND change state, document the side effect at the declaration site, not just the implementation. Source: C2 Wiki "CommandQuerySeparation".

---

## Fail Fast

Terminate immediately on encountering irrecoverable state corruption rather than allowing corrupt state to propagate. The purpose is to prevent damage and generation of incorrect output -- not to maintain availability.

C++ implementation:
- `assert(condition)` for invariants that must hold in debug builds
- `std::terminate()` for unrecoverable runtime state corruption
- Structured logging before termination: record the failing condition, the last known good state, and the call context

Distinguish: fail-fast on process state corruption; graceful handling on recoverable input data errors. Do not use `std::terminate` as a catch-all for bad input.

See also: the `systematic-debugging` skill (Fail Fast section) for the general principle. Source: C2 Wiki "FailFast".

---

## strncpy Does Not Guarantee NUL Termination

Replacing `strcpy` with `strncpy` looks like a complete buffer-overflow fix, but it only closes half the gap. `strncpy` halts copying once it reaches the given length, yet nothing in its contract forces the destination to end in a NUL byte, and nothing guarantees a well-formed string was produced at all -- depending on the source length relative to the bound, `strncpy` can leave the buffer unterminated or copy fewer meaningful bytes than the caller expects.

The pattern that closes the gap: after `strncpy(dst, src, n)`, terminate the buffer explicitly.

```c
strncpy(dst, src, n);
dst[n - 1] = 0;  // force termination -- strncpy does not do this for you
```

Checking the copied length or return value works as an alternative to blind termination. Either way, the call to `strncpy` by itself is not the safety mechanism -- the follow-up step is.

Why the gap exists: C's string-handling library was built without automatic bounds or termination checking. That omission is the same speed-over-safety tradeoff woven through the rest of the standard library, not a `strncpy`-specific oversight.

Watch out: how sufficient the fix above actually is remains disputed. One camp holds that `dst[n - 1] = 0` fully closes the issue and no further checking is needed. Another camp considers `strncpy` itself buggy or badly named, and pushes for a proper string-handling library or explicit length checks instead of patching around `strncpy`'s behavior. Treat `strncpy` plus manual termination as a partial safety mechanism, not a settled one.

Source: C2 Wiki "CeeLanguage".

---

## Implementation-Defined and Undefined Behavior Limit What Source Alone Reveals

The strongest form of the claim "source code is the design" holds that everything about intended behavior lives in the source. C breaks that claim directly: some constructs are implementation-defined, unspecified, or fully undefined, so reading the source -- no matter how carefully -- cannot tell you what a given construct actually does on a given compiler and platform. Only a comment at the call site or an external specification can supply that information, and most code carries neither.

Two concrete constructs illustrate the gap:
- The expression `x = x++;` -- its outcome depends on compiler behavior, not on anything fixed by the language standard.
- Memory-mapped IPv4 header structures that type an address field as `unsigned long` -- an assumption of 32-bit width that no standard guarantees on every platform.

When code depends on implementation-defined, unspecified, or undefined behavior, an explicit comment or a separate specification records the assumption being made. Without that record, the source cannot convey which behavior class applies, or what happens once the assumption stops holding.

Watch out: it is easy to mistake "this compiler produced a result without warning" for "this behavior is well-defined." That confusion holds until a compiler upgrade or a platform change produces a different result. Reading the code that ran correctly yesterday does not substitute for knowing what the language's actual guarantees are.

Source: C2 Wiki "TheSourceCodeIsTheDesign".

---

## Related Skills

- `cpp-safety` -- iron law: every resource is owned by a scope-bound guard; destructors never throw
- `cpp-patterns` -- broader C++ idiom reference
- `oop-principles` -- structural design before implementation choices
