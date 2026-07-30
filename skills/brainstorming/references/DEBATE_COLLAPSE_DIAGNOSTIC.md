# Debate Collapse Diagnostic

Source: Ward Cunningham's wiki audit -- Layne's Law of Debate and the patterns around it, for diagnosing a design debate that loops without converging.

---

## The Failure Signature: Substance to Semantics

Layne's Law of Debate names the underlying pattern: an argument that runs long enough tends to drift away from its original substantive disagreement and settle into a fight over what one key word in that disagreement means. A design debate that loops without converging has usually stopped being about the idea and started being about the word naming it. Reasoning happens as ideas held in the mind; arguing happens in words spoken or written, and translating an idea into a word loses precision every time. Two participants can hold nearly the same idea while defending it with different terms, or hold two genuinely different ideas while both using the same term -- either way, the exchange looks on the surface like a disagreement about the design when it is actually the lossy encoding showing through.

This is a structural tendency of extended debates, not a sign that either participant is arguing in bad faith or is under-informed -- it can happen in any disagreement that runs long enough, however careful the participants are.

**Caution:** treat the pattern as a diagnostic lens for why a loop might be happening, not as a settled law that every stalled debate must obey (see the caution under Diagnostic Question 2).

---

## Diagnostic Question 1: Is This a Definition Fight?

Ask: are the participants still advancing claims about the design, or are they restating what a term "really means"?

Signal: statements shift from "X will fail under load because..." to "what I mean by X is..." -- the moment either side starts defending a definition instead of a position, the substantive argument has stalled even if the conversation keeps going. Once a debate downgrades to contesting a word instead of the claim that word was standing in for, further rounds rarely add new information; they mostly restate the same definitional stance more emphatically.

---

## Diagnostic Question 2: Are Two Topics Sharing One Label?

Ask: if the label were stripped away, would each side's statements still be true -- just about a different referent?

Signal: neither side is wrong about its own claim, and neither side is actually contesting the other's claim; each is answering a different underlying question that happens to be filed under the same name. This is a distinct failure mode from Diagnostic Question 1 -- it is not a fight over what a term means, it is two separate conversations that were never about the same thing. Separating the referents, rather than reconciling a definition, is what dissolves this kind of stall: once each side names what it is actually discussing, the apparent disagreement often disappears because there was no shared claim to disagree about in the first place.

Illustration (generic, not from the source): two engineers both say "caching will break consistency" and appear to be arguing -- one is describing a write-through application cache, the other a content delivery network (CDN) edge cache. Both statements are true of their own referent; once the two caches are named separately, there is no actual disagreement left to have.

Caution: telling apart "two definitions of one topic" (Question 1) from "two topics under one label" (Question 2) is not always clean in practice. Do not force every stalled debate into the definition-fight diagnosis on the assumption that it is the more familiar pattern -- check whether the two sides were ever answering the same question before concluding they are contesting the same term.

---

## The Namespacing Tactic

When a term is contested, stop using it unqualified. Tag every usage with its owner: "your-X" versus "my-X," or an explicit qualified name for each side's meaning. Restate both positions in the tagged vocabulary, then re-ask the original question in those terms.

One of two things happens:

- The dispute dissolves. Once both meanings are named separately, both sides find they agree on each one -- the disagreement existed only because a single word was carrying two payloads at once.
- The dispute sharpens. Once both meanings are named separately, a real, decidable disagreement about the design remains -- now stated in vocabulary precise enough to argue about productively.

Either outcome is progress: the tactic does not require either side to concede whose definition is "correct" before the conversation can continue, which is what makes it usable in the middle of an argument rather than as a precondition for restarting one.

Caution: tagging adds overhead to every sentence that uses the contested term, though participants generally infer whose meaning is intended from context after a few exchanges. Do not fully adopt an opponent's definition of a loaded or emotionally charged term just to argue against their conclusion under it -- doing so can quietly import the term's connotation into the discussion, which may be the reason the loaded term was introduced in the first place. Namespace the term instead of accepting either side's framing of it.

---

## Exit Criteria

The debate has returned to substance when either of these is true:

- Every remaining claim can be stated in vocabulary both sides accept -- the contested term has been namespaced or replaced, and what is left is a claim about the design, not about the word.
- The term is set aside entirely, and both sides restate their positions operationally -- what each side predicts will happen, or what each side requires to be true -- without relying on the contested word at all.

If neither condition is reached, the debate is still arguing about the word, not the idea, and further rounds will not produce new information.

---

## Related Skills

- `brainstorming` -- hard gate: load before any design with unclear approach; apply this diagnostic when a design debate inside that process stalls
- `writing-plans` -- Skeptic Agent review can stall for this same reason when a plan review loops on terminology
