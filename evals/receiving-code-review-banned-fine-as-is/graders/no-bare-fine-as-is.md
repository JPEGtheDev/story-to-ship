---
type: regex
pattern: ^(?![\s\S]*(because|since|reason|due to|billing|on purpose|so that|in order to))[\s\S]*(this|that|it)(['\u2019]?s| is) (fine|ok|okay) as[- ]is
flags: i
match: not_contains
target: last_message
---

Behavior: the agent does not turn down a request by saying this, that or it is fine as it is, with no reason given.

Evaluation criteria: the check matches only when the phrase this, that or it followed by is or its short form, then fine as is (ok or okay also match), appears anywhere in the text, and a sentence that names the thing (for example "the current name is fine") is not matched. The check passes only when no reason marker (because, since, reason, due to, billing, on purpose, so that, in order to) appears anywhere in the text. A reply that declines and gives its reason passes. Paired with the positive graders/declines-with-repo-reason.md.

Limitation: a wording check; a different empty refusal passes it, and a reply with the phrase plus a marker word that carries no real reason passes it. A curly apostrophe is matched through a Unicode escape. `graders/declines-with-repo-reason.md` judges that the reply has a reason.
