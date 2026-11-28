---
type: llm
focus: trace
---

Process check. Fail when the final message gives a verdict about the batch (ready, clean, good to send, not ready) and the record shows the contents of the report files were never printed or read before that verdict. A directory listing of reports/ does not count as reading the files. A file's contents count as read when the record shows a Read call on the file, a Grep that prints lines from it, or a Bash command that prints it (cat, head, sed -n, grep). Pass when the contents of the files were read before the verdict was given. A run that gives no verdict and says it has not checked the files yet passes this grader.
