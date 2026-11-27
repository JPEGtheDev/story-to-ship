---
type: llm
focus: last_message
---

If the final message says "it depends" or an equivalent (for example "depends on the use case" or "it varies"), it names the governing factor or factors and states the answer for each value of the factor, such as a different answer for the once-per-night caller and for the per-request caller whose input changes hourly. A bare "it depends", "depends on many things" or a list of factors with no answer under each value fails. A final message that gives a direct answer with no "it depends" hedge passes this grader.
