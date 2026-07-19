# C2 Wiki: Design Patterns and Refactoring

*Source pages: AlternateHardAndSoftLayers, CodeUnitTestFirst (c2.com backup), CopyAndPasteProgramming, EnterpriseJavaBeans, GoTo, GoldenHammer, HaveThisPattern, LawOfDemeter, MicrosoftAccess, MockObject, ModelViewController, NotInventedHere, ObjectiveCee, ObserverPattern, PatternLanguage, ReFactor, ReFactoring, RefactoringBrowser, RelationalWeenie, SelfDocumentingCode, SingletonPattern, SqlFlaws, YouArentGonnaNeedIt. Distilled from the C2 wiki (c2.com) in our own words.*

## Reference-Based Query Composition

Instead of nesting one query inside another, name an intermediate result and refer to that name in a later step, the same relationship as writing `t1 = foo(x,y); t2 = bar(t1,a)` rather than `bar(foo(x,y),a)`. This is semantically equivalent to nesting, not an execution-order change: a capable query optimizer can substitute the named step back in and reorder or fuse work internally, similar to macro expansion. In SQL this shows up as a WITH clause, a temporary table, an ad hoc view, or application code that assembles a nested query string from named fragments.

**When to apply:** Reach for this whenever a sub-query or filter needs reuse more than once in a statement, or when nesting has grown too deep for a reader to hold the whole expression in their head at once.

**Watch out:** Application developers often lack permission to create persistent database views, and existing views tend to be global rather than scoped to one query, which is why ad hoc workarounds (temp tables, generated SQL, WITH clauses) persist instead of one clean built-in answer. Some argue this style is not really different from nesting, just resequenced; the counterargument is that it improves readability even if execution is unchanged.

**Source pages:** SqlFlaws

## Hard/Soft Layering Pattern

A recurring architecture pairs a compiled, efficient "hard" layer (C, C++, assembly, Forth) exposing generic, universal-data-type entry points, with an interpreted "soft" layer (Tcl, Python, Lisp, shell, BASIC, or a custom bytecode VM) that assembles those primitives into application behavior. Because the hard layer is built around generic exec/eval-style entry points rather than any one feature, new application behavior can be added by editing scripts instead of recompiling the core. The aim is "fractal complexity": a small, fixed set of physical layers supporting an open-ended number of virtual layers built in the scripting language on top.

**When to apply:** Use this split when a system needs both runtime efficiency and rapidly evolving application logic, such as a compiled game engine driving scripted game rules, a server core with embedded page-logic scripting, or an OS core driven by an interpreted shell.

**Watch out:** The split only pays off if the interface between the two layers is deliberately designed up front; skipping that design work just defers the cost as integration debt. The pattern also rests on a disputed assumption that no single language can be both fast enough for the hard layer and flexible enough for the soft layer, an assumption that weakens as VMs for flexible languages get faster.

**Source pages:** AlternateHardAndSoftLayers

## What Drives the Hard/Soft Boundary

Even people who agree the hard/soft layering pattern is useful disagree about why the boundary between the fast and flexible layers ends up where it does. Candidate explanations include raw CPU speed, memory footprint (dynamic languages tend to use memory less efficiently, and that cost is harder to work around than a speed cost), static-versus-dynamic type mismatches at the seam, and simply the accumulated time spent building and debugging the interface itself. Each explanation implies a different fix: a speed problem calls for profiling and rewriting a hot function, a memory problem may require redesigning shared data structures, and a type-mismatch problem calls for runtime checks at the boundary.

**When to apply:** Before introducing or relocating a hard/soft split, diagnose which constraint actually binds by measuring CPU time, memory use, and interface friction separately, rather than assuming raw execution speed is the bottleneck.

**Watch out:** One view holds memory footprint, not CPU speed, is the main limitation on using a flexible-language-heavy style everywhere, a claim that speed-focused framings tend to overlook. Treat "the soft layer is slow" and "the soft layer uses too much memory" as separate hypotheses.

**Source pages:** AlternateHardAndSoftLayers

## MVC: Rough Consensus, Disputed Boundary

Most agree on a rough shape for Model-View-Controller: the model holds data and state, the view presents it, and the controller mediates changes between them, ideally staying thin rather than becoming a god object overseeing both. Beyond that, agreement breaks down. Is MVC one pattern or a loose family of related patterns? Does it require genuine interactivity, excluding a batch report generator or a compiler with no feedback loop, or does it apply to any system with a data layer, a presentation layer, and something translating between them? One influential definition concludes there is effectively no "non-MVC" framework once any three-role system qualifies; an opposing view insists a real controller-mediated feedback loop is required.

**When to apply:** When someone invokes "MVC," ask which working definition they mean, in particular whether it requires interactivity or the Observer-style automatic update, before assuming shared understanding.

**Watch out:** The dispute is never resolved by any testable criterion in the source, only by convention and argumentative exhaustion. The original formulation is reported, secondhand, to have included a fourth object, "the user," alongside model, view, and controller, a role later simplified popularizations dropped.

**Source pages:** ModelViewController

## Observer Pattern Mechanism

Observer defines a one-to-many dependency: when a subject changes state, all observers depending on it are notified and updated automatically, without the subject knowing anything specific about who its observers are. This "push" style contrasts with "pull," where observers must repeatedly poll the subject, used when the subject cannot expose the right notification hooks. Because observers can register and unregister while the program runs, the relationship supports a flexible, changing set of dependents. One view treats this automatic, subject-ignorant-of-observers notification, not merely having three named parts, as what makes an implementation genuinely object-oriented MVC rather than a plain input-process-output loop.

**When to apply:** Reach for Observer whenever multiple parts of a system must react to a change in one object without that object needing to know who is reacting, and prefer push notification over polling whenever the subject can practically expose the right hooks.

**Watch out:** The subject must never depend on or reach into its observers' internals, and observers must never mutate the subject from within a notification callback; both break the decoupling the pattern exists to provide. This reframes the MVC debate toward a sharper question: does changing the model automatically update the view without polling, rather than does the system have three layers.

**Source pages:** ObserverPattern, ModelViewController

## Alexander's Pattern-Language Triad

A "pattern," in Christopher Alexander's original architectural sense, has three parts: a context describing the conditions under which it applies, a system of forces amounting to the problem or goal being addressed, and a solution, a configuration that resolves those forces. Alexander developed this for recurring solutions in town and building design; it was later borrowed well beyond architecture, including by software pattern writing, and even shows up unremarked in other pattern-style entries that use the same context/forces/solution shape without naming the connection.

**When to apply:** Use the context/forces/solution triad as a checklist when writing up or evaluating any claimed "pattern": confirm it names the conditions where it holds and the actual tension it resolves, not just a technique someone likes.

**Watch out:** The framework has been stretched to domains far from its architectural origin, such as interpersonal or nonverbal-communication patterns, with no claim that those applications preserve the rigor of the original formulation.

**Source pages:** PatternLanguage

## Copy-and-Paste Written Up as a Formal Pattern

Copy-and-paste code reuse can be documented with the full vocabulary of a formal pattern: a named problem (cheaply reusing existing code), a context (a live system where up-front reuse is expensive and reworking working code is risky), the competing forces, a proposed solution (clone and adapt), and a resulting context describing the consequences. The rationale is blunt: a short-term payoff is easier to justify than a long-term investment in reusable design whose payoff is unproven. The resulting cost is that a single bug fix in the original must be manually tracked down and reapplied to every clone that can still be found.

**When to apply:** When writing up or arguing about a recurring engineering shortcut, structure it with an explicit context, the competing forces, and the resulting consequences, instead of a snap good-or-bad judgment.

**Watch out:** Framing a practice with formal pattern structure does not settle whether it is desirable; this same entry is also filed as an antipattern, and structure alone does not resolve which label fits.

**Source pages:** CopyAndPasteProgramming

## Pattern vs. Antipattern: Is Copy-Paste Legitimate?

Two positions compete on copy-paste reuse. One holds it is a legitimate pattern that only becomes a mistake once applied too many times: the first use or two is the fastest correct choice, and only a high reuse count reveals the code should have been made properly reusable. The other holds the practice inherently multiplies bugs, multiplies testing burden, and creates an update-propagation problem regardless of count, and that its cheap-now, expensive-later shape is exactly what defines an antipattern.

**When to apply:** When judging a specific instance of duplicated code, decide which framing actually fits: an early, bounded duplication under active tracking looks different from one that has already spread past any reasonable count.

**Watch out:** Both sides agree the underlying costs are real; they disagree about which cost is more visible and how to weigh it, not about whether either cost exists.

**Source pages:** CopyAndPasteProgramming

## Copy-Paste as a Deliberate Intermediate Refactoring Step

Rather than treating copy-paste purely as a failure mode, some describe it as a deliberate, temporary step within refactoring itself: copy the code, adapt it until it works in the new context, and only afterward refactor out the duplication, because by then the real requirements of the new use case are actually known rather than guessed at in advance. This is presented as more reliable than designing a shared abstraction before a second concrete use case exists to test it against.

**When to apply:** When you do not yet know how a new use case will differ from the original code, copy first to learn the real variance, then generalize from what you observed rather than from speculation.

**Watch out:** This is only legitimate as long as the refactoring step actually happens; it stops being a valid technique the moment it becomes a permanent state rather than a step someone completes.

**Source pages:** CopyAndPasteProgramming

## Disciplined Alternatives to Cloning

Three disciplined alternatives to hand-copying near-identical code: a "once and only once" principle that directly opposes copy-paste as a practice; generating near-identical classes or methods mechanically from a single code-generation template instead of hand-editing many copies; and automated tooling that scans a codebase for existing duplicated code so it can be addressed deliberately rather than by accident.

**When to apply:** When a task calls for many structurally similar pieces of code, such as type-safe data-access wrappers around a shared schema, reach for a code-generation template instead of hand-copying and editing each variant.

**Watch out:** Hand-edited boilerplate of this kind is called one of the worst maintenance scenarios encountered; template-based generation is also not always available, since some languages lack the templating features needed to apply it.

**Source pages:** CopyAndPasteProgramming

## Duplication Threshold (Rule of Three)

There is no settled agreement on how much duplicated code should be tolerated before it gets extracted into a shared abstraction. One camp deduplicates on the first repetition; another waits for a threshold of repeats, colloquially "three strikes," on the theory that premature abstraction risks guessing the wrong shape for the shared code; a looser camp waits until it genuinely feels like you "have this pattern," trading consistency for subjective leeway. Several practitioners converge independently on a similar operational rule: tolerate one duplicate, but treat a second or third as the signal to generalize. A companion technique softens the risk of the first duplicate: leave a comment at each copy pointing to the other one, so whoever is tempted to copy a third time already has the context to factor out all uses at once.

**When to apply:** When the same logic appears more than once, weigh the cost of premature abstraction (guessing wrong, adding indirection for a pattern that will not recur) against the cost of continued duplication (drift between copies, more places to fix a bug), rather than mechanically applying "always dedupe on sight" or a fixed count. Picking a small numeric threshold up front is one practical middle path.

**Watch out:** None of this is a universally agreed convention; it is a convergence of independent personal practices and contested even within the same discussion thread. Do not treat "rule of three" as settled doctrine.

**Source pages:** HaveThisPattern, CopyAndPasteProgramming

## Refactoring as a Behavior-Preserving Transformation

Refactoring is a change to a program's internal structure that leaves its observable behavior completely unchanged; only the organization of the code shifts, never what it computes for a given set of inputs. This is the core definitional test separating refactoring from any other code change: if outputs differ afterward, the change was a redesign or a bug fix, not a refactoring. "Refactoring" and "restructuring" are used interchangeably in this sense.

**When to apply:** Use this as the litmus test when deciding whether a proposed code change counts as a refactoring: check whether the program's output for identical inputs stays the same before and after.

**Watch out:** Behavior preservation is easy to state but does not by itself explain why anyone would bother doing it; a change that provably preserves behavior can still seem pointless without an added motivation attached.

**Source pages:** ReFactor

## Once and Only Once

A given piece of behavior should exist in exactly one place in a codebase, expressed through a single well-built routine that every caller invokes rather than each caller reimplementing it. When the same or closely related logic is found scattered across a codebase, the refactoring move is to consolidate it behind one shared entry point and change the former copies to call that entry point instead. This is offered as a concrete, non-aesthetic reason to refactor.

**When to apply:** Apply whenever the same or near-identical logic appears in more than one place, especially in classes or components with no otherwise obvious relationship.

**Watch out:** Eliminating duplication is a "what," not a "why"; it is reasonable to ask why unifying duplicate code matters, and the honest answer has to point to a concrete cost such as maintenance time or the risk of copies silently drifting apart, rather than treating deduplication as self-justifying.

**Source pages:** ReFactor

## Refactoring Along Inheritance and Composition Lines

Two directions structure most concrete refactoring work. Along inheritance lines, behavior duplicated across unrelated sibling classes gets pulled up into a shared superclass, or pushed up from concrete subclasses to a more abstract one as the need becomes apparent. Along composition lines, a single class handling two unrelated sets of responsibilities gets split into two focused classes, one of which may end up containing the other. Adopting a design pattern in place of ad hoc code, for example swapping a chain of case statements for a State pattern, or hard-coded construction for factory methods, is treated as a specialized instance of this same activity.

**When to apply:** Use the inheritance direction when a design review turns up near-identical behavior in classes with no common ancestor. Use the composition direction when a class's responsibilities do not interact much, or each touches only a disjoint subset of the class's own state.

**Watch out:** Most refactorings tend to move in one direction, toward more, smaller classes with fewer methods each; this is treated as a felt, entropy-like tendency rather than a proven rule, and refactorings that move the opposite way do happen, just less often.

**Source pages:** ReFactor

## Refactoring Mechanical Catalog

Beyond larger structural moves like inheritance or composition restructuring, refactoring also covers small, mechanical operations that stand on their own: renaming a variable, class, method, function, or parameter; changing a declared type; converting an inner class into a top-level class; and converting a block of inline code into its own method or function. These are the smallest atomic units of refactoring, the building blocks larger restructurings are composed from.

**When to apply:** Apply one of these as a quick, low-risk cleanup whenever a name is misleading, a declared type no longer fits its use, an inner class deserves to stand on its own, or a chunk of inline logic is reusable enough to deserve its own method.

**Watch out:** This kind of catalog is often offered as a bare list with little further explanation of when any particular operation is actually warranted; treat it as an inventory, not a decision procedure.

**Source pages:** ReFactoring

## Semantics-Preserving Refactoring Tooling

A refactoring tool that understands program structure (methods, variables, message sends, classes) can perform operations like extract-method, inline-method, move-to-component, add or remove parameter, and rename as single guaranteed-safe menu actions, because it reasons about the actual code element being changed rather than about substrings of text. Plain find-and-replace on a name has no such guarantee: renaming a short identifier can silently corrupt unrelated identifiers containing the same substring, or corrupt quoted string literals with matching characters, producing code that looks renamed but no longer means the same thing or compiles.

**When to apply:** Apply whenever renaming, extracting, inlining, or moving code in a language with tool support for structural refactoring; prefer the tool's atomic operation over manual or scripted text substitution, especially for short or common identifier names where substring collisions are likely.

**Watch out:** The safety guarantee is conditional: it depends on not hand-editing code outside the tool, and it can still fail on judgment calls the tool cannot fully automate, such as choosing the wrong destination class for a move. Delivering this guarantee is easier in a dynamically-typed language than one might expect via special-case handling that mostly, but not always, succeeds; building an equivalent tool for a language with closures or the full breadth of C++ macros and templates is considerably harder.

**Source pages:** RefactoringBrowser

## Singleton: Two Separable Promises

A singleton is a class designed so only one instance ever exists in the running program, reachable from anywhere through a shared access point instead of being passed in explicitly. The pattern bundles two logically separate promises: limiting how many instances can be created, and making whichever instance exists easy to find from anywhere. These promises do not have to travel together; a design can need one without the other. In practice, enforcing "only one" is rarely the part that earns its keep; the reachability part is usually what people actually wanted.

**When to apply:** Reach for this framing whenever a design already has, or is being pushed toward, a class with a single shared instance and a global lookup method, so you can ask which promise is actually load-bearing before writing enforcement code.

**Watch out:** Treating both promises as one non-negotiable package is a recurring source of trouble; conflating them turns a reasonable design decision into a rigid one that is hard to walk back.

**Source pages:** SingletonPattern

## Singleton vs. Global Variables

Singletons and global variables solve overlapping problems and are frequently built from the same underlying mechanism, a value reachable from anywhere, but they answer different questions. A global variable is about how a value gets declared and referenced across a codebase; a singleton specifically constrains how many instances of a class may exist, with global reachability arriving as a side effect of routing access through a class method. Because a method mediates access, a singleton can layer in behavior a bare global cannot, but structurally it still inherits the same coupling risk: code anywhere can silently depend on it, and side effects can surface far from their cause.

**When to apply:** Use this distinction when someone claims singleton and global variable are just different names for the same anti-pattern, or conversely assumes adopting Singleton automatically avoids the problems globals cause.

**Watch out:** Inexperienced use of Singleton is often just global-variable abuse wearing a design-pattern name, on the mistaken belief the pattern itself prevents the coupling problems plain globals create.

**Source pages:** SingletonPattern

## Singleton's Creational Logic Leverage

Because access to a singleton always passes through a method rather than a raw variable, that method becomes a natural place to attach extra behavior around creation and access: deferring construction until first use, synchronizing access for thread safety, keeping a separate instance per thread instead of one shared instance, or gating access behind a security check. This is a capability a plain global variable structurally cannot offer, since there is no method call to intercept.

**When to apply:** Reach for this when a shared resource needs conditional or context-dependent creation, for example it is expensive to build or depends on runtime hardware, or when the access strategy needs to change, such as per-thread instead of per-process, without touching every call site.

**Watch out:** This leverage is only real if the accessor is genuinely a controlled method rather than a thin wrapper around a public static field, and it is only worth the added complexity if one of laziness, synchronization, per-thread scoping, or security is an actual need.

**Source pages:** SingletonPattern

## Registry, Context Object, and Solo Object as Singleton Escapes

When a codebase wants the convenience of one shared, easy-to-find instance without inheriting the strict coupling of a formal Singleton, three escape routes tend to appear. A Registry separates who creates an instance from who looks it up, so callers never need to know whether there is one instance or many. A ContextObject bundles several related shared services into one object passed around, convenient but criticized as smelly since every consumer becomes coupled to the whole bundle even if it needs only one piece. Converting a former singleton into an object built once and threaded explicitly through constructors and parameters produces one-instance-in-practice behavior without meeting the formal Singleton definition at all, since nothing enforces the count or exposes a global lookup point.

**When to apply:** Reach for a Registry when decoupled lookup matters more than hard-wiring instance count; reach for explicit parameter-passing when you want one-instance-in-practice convenience while eliminating hidden global coupling; be cautious about a ContextObject introduced purely to bundle former singletons together, since it just relocates the coupling problem.

**Watch out:** None of these three routes is a drop-in replacement for another; each trades a different amount of decoupling for a different amount of ceremony, and the parameter-passed "solo object" case is genuinely unsettled territory rather than an established pattern.

**Source pages:** SingletonPattern

## Singleton Pre-Code Checklist

Before writing a singleton, the deciding question is whether a second instance would actually be wrong for the system, not merely inconvenient to create some other way; if the answer is no, the real need is a convenient way to find or supply an instance, such as a registry or factory, not an enforced single instance. A well-behaved use of the pattern also satisfies further checkable conditions: the instance can be swapped for a test double without touching calling code, dependent singletons are constructed and destroyed in a well-defined order, moving from one instance to many later only requires changing the factory or registry rather than every call site, and the access method that fetches the instance is called from exactly one place in the codebase, with the instance threaded onward as an ordinary parameter or constructor argument.

**When to apply:** Run this checklist both before introducing a new singleton and when auditing an existing one that is causing pain, to distinguish a genuinely justified single-instance design from a global variable that merely looks more respectable.

**Watch out:** Satisfying only some conditions, for example enforcing single-instance construction while still calling the lookup method from dozens of places, leaves most of the coupling problems intact even though the code technically follows the pattern.

**Source pages:** SingletonPattern

## The Oubliette Pattern and Labeled Loop Exit

A jump is acceptable when it transitions into a single "sink state" from which the code needs no memory of where it came from, an error-handling or cleanup label being the standard example, since only the fact of arrival matters, not the path taken. This is fine specifically because it targets a small, fixed number of stateless destinations, not an arbitrary jump target. Separately, when the real goal is escaping multiple levels of nested loops, prefer a named or labeled loop-control statement, such as Java's `break label`, or factor the loop body into its own function with an ordinary return, rather than an unstructured multi-level goto or a hypothetical numeric `break(n)`; the latter forces a reader to count nested loop levels to know where control actually goes.

**When to apply:** Apply the sink-state rule when tempted to use goto or an equivalent for error or cleanup handling: restrict it to one, or at most a very small number of, clearly named sink labels per function with no dependence on ambient state. Apply the labeled-exit rule whenever the need is "break out of several nested loops at once."

**Watch out:** Labeled loop-exit constructs are themselves capable of the same abuse as goto if used carelessly; the real question is whether people tend to abuse a construct in practice, not which syntax is used. A numeric `break(n)` is also fragile because adding a new loop later can silently change what an existing `break(n)` targets.

**Source pages:** GoTo

## Rewritten vs. Reinvented Checklist

There is a concrete way to tell whether replacing an existing module is a genuine improvement ("rewritten") or just a different version with the same problems ("reinvented"). A legitimately rewritten module passes all the original's tests plus additional ones, is demonstrably better by some criterion beyond personal taste, and ends up with fewer lines of code. A merely reinvented module instead has different bugs, behaves differently but not more correctly at boundary cases, and differs mainly for stylistic rather than functional reasons, a sign no real improvement occurred, just a different set of trade-offs.

**When to apply:** Apply this checklist whenever someone proposes replacing an existing, working module or library, especially when the stated justification is dissatisfaction with the original rather than a missing capability.

**Watch out:** "I don't understand the interface" or "it's not written the way I'd write it" are explicitly ruled out as valid justifications for rewriting, unless the confusion is shared by the whole team or the interface is objectively so bad that using it costs more time than replacing it.

**Source pages:** NotInventedHere

## Golden Hammer Anti-Pattern

Golden Hammer names the anti-pattern of believing one familiar technology significantly improves outcomes across the board with no meaningful drawback, then reaching for it on every new problem regardless of fit. The trap is not the tool itself, since a given technology can genuinely be excellent in some contexts; the trap is treating a tool good in one context as universally superior, which lets a team skip evaluating fit case by case.

**When to apply:** Whenever a team is choosing a technology for a new problem and notices the reasoning is "this is what we already use or know" rather than a comparison of the new problem's actual requirements against candidate tools' strengths and weaknesses.

**Watch out:** The anti-pattern can be costly even when the forced tool eventually works; teams have spent real engineering effort making a familiar-but-underpowered tool meet requirements a better-fitted, newer choice would have met with far less strain. "It worked in the end" does not prove the tool was the right pick.

**Source pages:** GoldenHammer

## Fixing Golden Hammer Thinking

The tempting response to a poor-fit-technology complaint is to keep applying the familiar tool anyway, including where it is clearly a bad fit; this "supposed solution" does not fix anything, it just re-applies the anti-pattern under pressure. The actual fix is to deliberately expand the team's knowledge of alternatives through education, training, and structured study, such as book study groups, so the next technology decision gets made from real comparative knowledge instead of default familiarity.

**When to apply:** When a team's response to "this tool doesn't fit this problem" is to double down on the same tool rather than invest time in learning what else exists.

**Watch out:** The real fix is slower and has no immediate payoff; expanding knowledge takes sustained time and does not resolve the current project's deadline pressure, which is exactly why the tempting shortcut stays tempting.

**Source pages:** GoldenHammer

## ORM as a Compromise

An object-relational mapping tool, such as Hibernate, is a middle path: it lets a team keep writing and thinking in objects while still falling back on efficient set/relational operations underneath, rather than forcing a choice between full object-graph iteration and hand-written SQL everywhere. This is a genuine compromise rather than a clean resolution; the object-to-table mapping still feels awkward even with a mature ORM, and one view speculates that any object system efficient enough to match relational performance would end up looking like a relational database internally anyway.

**When to apply:** Reach for an ORM when a team wants to preserve object-oriented application code while still issuing efficient ad hoc queries against the same data, rather than choosing one paradigm exclusively.

**Watch out:** Adopting an ORM is not license to stop thinking relationally; the tool is a bridge that keeps relational efficiency accessible, not a replacement for understanding when a problem needs a real query versus in-memory logic, and the underlying impedance mismatch does not fully disappear.

**Source pages:** RelationalWeenie

## Objective-C Categories as Retroactive Class Extension

A category is a named grouping of methods, instance or class methods but never instance variables, that Objective-C lets a developer attach to an existing class after the fact, without subclassing it or touching its original source. This lets a consumer of a third-party class add missing behavior directly to that class, for example a new method on every subclass of a purchased widget class, rather than being limited to producer-side changes. Because instance variables affect per-instance memory layout and methods do not, categories can add methods freely but never variables, since that would make new instances binary-incompatible with already-compiled ones.

**When to apply:** Reach for this concept when discussing open classes, monkey-patching, or extension methods in any language, or when explaining how to retrofit behavior onto a class you do not own without modifying or subclassing it.

**Watch out:** Because the runtime loads the base class first and categories afterward, method lookup finds whichever definition loaded last, so categories can silently override existing methods; if two independently written categories define the same method name on the same class, one silently wins with no compiler error, a collision risk comparable to bugs the IBM Smalltalk community hit with the same style of extension.

**Source pages:** ObjectiveCee

## Single-Client Proxy for Shared-File Concurrency

For VB applications built on an Access .mdb file, one reported pattern is to run a single mediating process, an ActiveX/COM server, on the same machine as the database file, and route every data access request through it, so only one connection ever actually touches the .mdb. Callers pass business objects by value into and out of that proxy's get/save methods; state is marshalled across the boundary, packed into a string for simple objects or via a property bag or XML representation for more complex ones. This keeps the corruption risk of multiple concurrent JET connections off the table without a full server-backend migration.

**When to apply:** When an existing VB/Access application needs safer concurrent access but a server-backend rewrite is not feasible or desired.

**Watch out:** This pattern trades away scalability for safety; routing every access through one proxy process is a bottleneck by construction, so it fits small deployments, not growth paths.

**Source pages:** MicrosoftAccess

## Visitor Pattern for Law-of-Demeter-Compliant Traversal

When an operation genuinely needs to act on an object buried several levels deep inside a composite structure, the Law-of-Demeter-compliant way to do it is not for the caller to navigate the chain of accessors itself, and not to write an artificial delegating method at every intermediate level either; it is to pass a Visitor through the collaboration, letting each intermediate object hand the visitor along to whatever it directly owns. The intermediate objects need only know how to accept and forward a generic visitor, keeping each object's contribution limited to its own immediate structure. This is less brittle than a getter chain because neither the caller nor any intermediate object needs to know the shape of the structure below its own level; some tooling can auto-generate the visitor-passing infrastructure from the object graph rather than requiring it to be hand-written.

**When to apply:** When an operation must reach a deeply nested object inside a composite or tree structure and neither direct chained access nor a stack of hand-written delegating methods feels right, route the operation through a Visitor passed down the collaboration instead of writing ad hoc accessor chains.

**Watch out:** This pattern has its own overhead: manually writing and maintaining visitor infrastructure for arbitrarily deep structures can itself become unwieldy without tool support to generate it.

**Source pages:** LawOfDemeter

## Checklist for Self-Documenting Code

An open-ended checklist of habits pushes code toward explaining itself rather than depending on prose: use meaningful names, prefer purposeful comments over massive function headers, replace defensive comments with assertions or named constants where the language allows it, format code to emphasize what matters, narrow interfaces, group related information together, and choose idioms like polymorphism or collections over long chains of conditional logic. The list is explicitly unfinished; contributors are invited to add examples from other languages, including Python-specific practices like docstrings and doctests.

**When to apply:** Reach for this checklist item by item during code review or refactoring, when a block of code currently needs a comment or header to be understood; try a better name, a named constant, or a narrower interface before adding prose.

**Watch out:** The list is culled from one contributor's own C/C++-heavy experience and is not claimed to be complete or universally applicable; treat it as a starting menu, and expect language-specific idioms to change which items apply.

**Source pages:** SelfDocumentingCode

## Aggressive Pruning as YAGNI Enforcement

YAGNI is enforced not only by refusing to write speculative code up front but by actively removing code that has already ended up unused; a method nobody calls, or a class nobody instantiates, gets deleted as routine engineering hygiene rather than an unusual or risky cleanup event. This turns YAGNI from a one-time authoring-time decision into an ongoing discipline: the system stays small by continually pruning parts that have quietly stopped earning their keep, not just by being cautious about what gets added.

**When to apply:** During regular refactoring or code review, when a method or class is found with no remaining callers or references, remove it immediately rather than leaving it "just in case."

**Watch out:** This is only safe under supporting practices, such as tests and shared ownership, that let the capability be re-added cheaply if it turns out to be needed again; without those, aggressive deletion is a bigger gamble.

**Source pages:** YouArentGonnaNeedIt

## Cheap Idea Capture Under YAGNI

When a developer gets a feature idea while working on something else, YAGNI says do not switch to building it, but the idea can still be captured cheaply rather than lost or built out in full. Two techniques: write a stub method whose body simply throws an exception, which also fails loudly in testing the moment it is actually called, flagging that the deferred work is now needed; or leave a heavily detailed comment describing the plan. Either costs far less time than a real implementation while still recording the thinking for whoever picks it up later.

**When to apply:** Mid-task, when an idea for a not-yet-needed feature occurs, write a one-line stub or comment and return immediately to the committed task, rather than pausing to build the idea out.

**Watch out:** This is a note-taking technique, not an exception to YAGNI itself; the stub or comment still does not implement the feature, and the real work still waits for a genuine requirement.

**Source pages:** YouArentGonnaNeedIt

## Mock-Based Testing's Law-of-Demeter Side Effect

Teams that adopted mock-object testing reported, independently of one another, that the practice nudged their designs toward passing collaborators explicitly into constructors instead of reaching for them through chains of getters or global/static access. This is a discovered consequence rather than the original goal of the technique: the need to substitute a mock for a real collaborator at test time forces a design where dependencies are visible and swappable at construction, which happens to be exactly what the Law of Demeter, avoid reaching through an object to get to objects it references, asks for.

**When to apply:** Notice this pattern when a codebase becomes hard to unit-test because collaborators are buried behind getters or static lookups; introducing mock-based tests and reworking the design so collaborators can be passed in at construction time tends to make the code both more testable and more Demeter-compliant.

**Watch out:** This is reported as an empirical side effect across several teams, not a guaranteed law; it depends on actually restructuring code to inject collaborators through constructors rather than papering over the problem with partial mocks, static substitution tricks, or class loaders that swap classes without changing the design.

**Source pages:** MockObject

## Mock Objects as Test Doubles

Some code needs to talk to something not present or not practical to use during a test run, such as an external device, a live service, or a piece of hardware. Since a test-first workflow cannot be built around a resource that cannot actually be invoked in a test, this pushes toward introducing an abstraction: one implementation that talks to the real thing, and a second, fake implementation that stands in during tests. This is not just a testing workaround; once the abstraction exists, adding support for a third or fourth real implementation of the same interface becomes far easier than if the code had been written against one concrete resource directly.

**When to apply:** Whenever a unit under test depends on an external device, network call, database, or other resource that is slow, unavailable, or non-deterministic during automated testing.

**Watch out:** This benefit is incidental rather than the primary goal; the abstraction layer is introduced to make testing possible at all, and its reusability payoff is a bonus, not something to assume without deliberately designing the fake implementation to be faithful to the real one's contract.

**Source pages:** CodeUnitTestFirst (c2.com backup)

## Session Bean Facade Pattern

A best practice from real EJB deployments is to never let a remote client call fine-grained entity object methods directly; instead route all remote access through a coarse-grained, stateless session bean acting as a facade in front of the finer-grained layer. The reasoning is architectural: each call over a distributed-object protocol carries real network and data-marshaling overhead, so many small fine-grained calls cost far more in aggregate than a few chunky ones, and the facade absorbs that translation on the client's behalf.

**When to apply:** Apply a coarse-grained facade whenever fine-grained objects, in any component model and not only EJB, must be accessed remotely or across a process or network boundary; the deciding question is whether callers are local, where fine-grained access is fine, or remote, where a facade almost always earns back its cost.

**Watch out:** This pattern quietly raises a question it never fully answers: if the finer-grained objects behind the facade are never touched remotely, it becomes unclear what unique benefit they still provide over plain, non-managed persistent objects behind the same facade layer.

**Source pages:** EnterpriseJavaBeans

