---
type: regex
pattern: ^(?![\s\S]*(because|since|reason|due to|billing|on purpose|so that|in order to))[\s\S]*(this|that|it)(['\u2019]?s| is) (fine|ok|okay) as[- ]is
flags: i
match: not_contains
target: last_message
---

Behavior: the final message does not use the it-is-fine-as-is phrase while giving no reason. The pattern matches only when the phrase appears anywhere in the text (with or without a lead-in such as a name or "I think") and no reason marker (because, since, reason, due to, billing, on purpose, so that, in order to) appears anywhere in the text. A reply that declines and gives its reason passes. Paired with the positive `graders/declines-with-repo-reason.md`.

Limitation: a wording check; a different empty refusal passes it, and a reply with the phrase plus a marker word that carries no real reason passes it. A curly apostrophe is matched through a Unicode escape. `graders/declines-with-repo-reason.md` judges that the reply has a reason.
