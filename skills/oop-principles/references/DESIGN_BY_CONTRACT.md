# Design by Contract

Source: Ward Cunningham's C2 wiki audit -- Design by Contract as a discipline for stating and
enforcing the obligations a method and its callers owe each other.

This file covers the runtime discipline of contracts already in force between a method and its
caller. It is not about testing multiple implementations of an interface against shared
invariants -- see `contract-testing` for that (behavior-across-implementations fixtures).

---

## The Contract Triad

Every method makes a deal with the code that calls it, whether or not anyone writes that deal
down. Design by Contract gives that deal three checkable parts:

- **Precondition** -- what must already be true when the method is entered. Satisfying it is
  the caller's obligation.
- **Postcondition** -- what the method guarantees will be true when it returns. Satisfying it
  is the method's own obligation.
- **Class invariant** -- a condition that must hold both before and after every public call on
  an instance, for the lifetime of that instance.

Choosing not to write these down is not choosing to have no deal -- it is choosing to leave the
deal unstated. An unstated contract can still be violated; it is just harder to notice when it
is.

```
function withdraw(account, amount):
  // precondition: amount > 0 and amount <= account.balance -- caller's obligation
  // postcondition: account.balance decreases by exactly amount -- method's obligation
  // invariant: account.balance >= 0 always holds between public calls
  ...
```

---

## Caller vs. Callee: Who Owns the Check

If a precondition is stated explicitly, satisfying it belongs entirely to the caller. A
violated precondition is therefore a bug in the caller, not in the method that was called.

The practical consequence: by default, a method should not re-verify a condition its own
contract already assigns to the caller. If every method in a call stack re-checks what its
caller already checked, the result is clutter and repeated error-handling that adds no real
safety -- only the illusion of it.

This does not settle the question in every case, and it should not be flattened into "never
double-check." A method whose precondition failure would leave shared or persistent state
inconsistent -- not just return a wrong value to one caller -- has a real reason to re-check
anyway. Consider a bank-account `withdraw()` method: its precondition already says "amount must
not exceed balance," so by the default rule the caller owns that check. But a badly-behaved
caller that skips the check can corrupt the account's stored balance for every future caller,
not just itself. In that situation the cost of a bad caller corrupting shared state can outweigh
the cost of one redundant check, which is why `withdraw()` is the standard example of a method
that reasonably re-verifies its own precondition even though the contract assigns that check to
the caller.

Treat the two positions as both live, not as a solved rule:

- **Trust the contract by default.** Do not cascade the same validation down every layer of a
  call stack; assign each condition to exactly one side and hold it there.
- **Re-check where the alternative is corrupted shared state.** When a violated precondition
  would leave data that other callers depend on in a broken condition, the redundancy is
  cheaper than the failure mode it prevents.

Deciding which case a given method falls into is a design judgment made per method, not a
blanket policy applied to a whole codebase.

---

## Contracts as Documentation and as an Open/Closed Boundary

A contract can be recorded as a plain comment or made executable as a runtime assertion.
Comments are cheap but can silently drift out of sync with the code they describe, the same way
any comment can. An executable assertion catches a violation at the moment and place it actually
happens, rather than leaving the gap to surface later as a confusing downstream symptom.

Contracts also give the Open/Closed Principle something concrete to stand on. Whatever a
contract states is closed against modification without breaking callers; whatever it leaves
unstated is open to change freely inside the implementation. Under this view, a change can only
break something in one of three ways:

1. Some code fails to live up to its own contractual obligations.
2. Some code depends on behavior the contract never actually promised.
3. The contract itself is changed.

This only works if the contract is well-scoped. A contract that promises too much locks the
implementation down and blocks legitimate future changes or subclassing. A contract that
promises too little fails to protect callers from implementation changes that really do break
them. Writing a contract that promises exactly what callers need -- no more, no less -- is a
hard design problem in its own right, not a mechanical exercise.

---

## Contracts and Liskov Substitution

When an override replaces a base method, its contract may only move in one direction:

- The precondition may only **weaken** -- an override must keep accepting everything the base
  method accepted, and may open its acceptance further, but may never turn away an input the
  base allowed.
- The postcondition may only **strengthen** -- an override must keep every guarantee the base
  made, and may add stronger guarantees on top, but may never deliver less than the base did.

This is the same substitutability guarantee the Liskov Substitution Principle describes in the
abstract, made concrete and checkable: whatever the contract commits to becomes the one boundary
substitution is never allowed to cross, while anything the contract leaves unstated is free to
differ between base and override. If an override instead narrows what it accepts or delivers
less than its base promised, code that was written and tested only against the base type can
fail the moment a subtype instance is substituted in -- without a single line of that calling
code ever being touched.

This is consistent with the oop-principles gate: a derived class that "only adds methods" can
still violate substitutability if any override tightens a precondition or weakens a
postcondition -- adding a method is not automatically safe, and every override needs the
weaken-precondition / strengthen-postcondition check applied to it individually.

In a language with native contract support, a base class's contract is inherited automatically
by every descendant. In most languages, nothing enforces this at compile time -- verifying that
an override only weakens preconditions and strengthens postconditions is a manual discipline for
whoever reviews the override, not something the toolchain checks.

---

## Practical Limits of Contracts

Contracts are a useful discipline, not a clean, universally safe one:

- **Side effects can corrupt the check itself.** A contract expression that calls another
  method to read a value can only be trusted if that call leaves no side effects behind --
  evaluating the contract must not itself change anything. In most object-oriented languages,
  ordinary method calls can mutate state, so a naively written contract check can change the
  very state it was meant to verify.
- **Reentrancy, concurrency, and distribution weaken the guarantee.** A precondition or
  invariant is checked at one moment, but the operation it guards runs afterward. Under
  reentrancy, concurrent execution, or a distributed call, the condition that held at check time
  is not guaranteed to still hold when the guarded operation actually executes.
- **Nothing in the tooling enforces side-effect-free contracts**, even in languages built
  around contracts natively. Writing a contract expression that does not itself mutate state is
  a matter of author discipline and reviewer attention, not a compiler guarantee.
- **Whether contracts would have caught bugs like Y2K is a live, unresolved dispute.** One
  position: writing preconditions and postconditions forces a fragile, undocumented assumption
  -- such as representing a year with only two digits -- out into the open, where it becomes
  visible before it breaks anything. The opposing position: a contract only gets written for a
  condition someone already suspects might break, so if nobody yet suspects a given assumption
  is fragile, no contract exists to catch it until after it has already failed. Treat both
  positions as live, not as a solved rule, the same way the caller/callee trust question earlier
  in this file stays open, and treat "contracts would have caught this" as a claim to check
  against the specific bug, not a general guarantee.

---

## Related Skills

- `oop-principles` -- parent; Liskov Substitution gate applies the weaken-precondition /
  strengthen-postcondition rule to every override
- `contract-testing` -- sibling; verifies that every implementation of an interface honors its
  contract, rather than governing runtime responsibility between one caller and one callee
