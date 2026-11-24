# Agent instructions for this repository

These rules apply to agents working in this repository. They are not shipped with the plugin.

## Stage 2 grouping for eval case folders

- All changed files of one eval case folder (evals/<case>/ or evals-model-default/<case>/) share one code-quality-reviewer.md dispatch, one dispatch per case folder, with no file-count cap. Each file still gets its own verdict block.
- Files from two different case folders never share a dispatch.
- A file outside evals/ and evals-model-default/ is never added to a case folder's dispatch; one that a changed line names follows the at-most-two-files rule of the two-stage-review skill.
- A REQUEST CHANGES or REJECT on one file of an eval case folder sends the whole folder back for re-review, and the re-check covers the whole folder, not only the changed hunks.

## Two-edit check

- Every file under an eval case folder (evals/<case>/ or evals-model-default/<case>/, for example case.yaml, prompt.md, scaffold.sh or graders/*.md) is exempt from the two-edit check in agents/code-quality-reviewer.md; none is a test path for that check.
