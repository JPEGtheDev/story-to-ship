# requesting-code-review Rationale

Rationale moved out of SKILL.md. These sentences explain why a rule exists. They enforce nothing; the rules themselves stay in SKILL.md.

---

## Why a red CI or an incomplete PR description is not sent for review

Requesting review against a red CI or an incomplete PR description wastes the reviewer's time and erodes trust.

---

## Why agent review does not replace human review

**Agent review does NOT replace human review** -- it catches the mechanical issues so human review can focus on design and intent.

---

## Why every review request carries the commit SHA

This ensures:
1. The reviewer knows exactly what they are reviewing
2. Review comments are anchored to a specific state -- not a moving target
3. If the branch advances after review is requested, the SHA makes that visible

---

## Why a blanket LGTM is not coverage

It means the reviewer had no issues -- it does not mean they checked what you asked them to check.
