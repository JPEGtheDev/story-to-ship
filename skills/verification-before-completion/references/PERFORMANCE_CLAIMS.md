# Performance and Cost Claims Checklist

Apply this to any speed, memory, token-spend, or cost number, any before and after figure, and any A/B comparison, including measurements of agent runs.

---

## Before the Run

Complete all three steps before the first measured run:

- WRITE the claim you expect to make: one sentence with the direction and the size (for example, "B is about 1.3x faster than A on the same input").
- READ the measurement script and confirm exactly what it times. A timer that wraps setup, teardown, or a cache warm-up measures those too.
- CHECK machine and system load. Stop other heavy work, and record the load before and after the runs.

A claim written after the numbers are in is not a prediction. It is a rationalization.

---

## The Seven Questions

Answer every question before reporting a number. A question you cannot answer makes the result inconclusive.

1. Why not double? Name the limiter (the resource or step that caps the number) from a profile or from counters, not from reading the code. (For example, a sampling profiler or a hardware counter reader; or a tool-call count from the run log.)
2. Was each side tuned the way it runs for real? Build both sides with the same settings used in production, and do not give only one side a warm cache or a debug flag.
3. Does the number break a physical limit? Compare it with the bandwidth, the number of cores, and the share of total time the changed piece took. A whole-task time saving larger than that share cannot come from the change, so it is a measurement error.
4. Did it error? Count the failed runs and check that each output is correct, not only that the process exited 0.
5. Does it reproduce? Run at least 5 runs per side, alternated (A, B, A, B, ...). Report the median and the range. A gap smaller than the spread is no difference.
6. Does it matter end to end? Measure the whole task the user waits for, not only the changed function.
7. Did the work actually happen inside the timed region? Check the output, a log, or a counter that proves the expected work ran while the timer was running.

---

## Runs

- A comparison MUST have at least 5 alternated runs per side. Fewer runs make it inconclusive.
- A single number with no comparison still states its run count.
- The one-run exception applies only to a ballpark the owner explicitly requested. Report it as "ballpark, 1 run", with the range marked not applicable, the limiter named if known and otherwise "limiter not identified", and never as a result. Still answer questions 4 and 7. The claim is still written before the run.

---

## Report

Lead with the verdict: faster, slower, no measurable difference, or inconclusive. Then give one number with its unit, the run count, the range, and the limiter.

Worked lines:

- "Faster: 1.3x median, 5 runs per side, range 1.2-1.4, limiter: tool-call count from counters."
- "No measurable difference: 41,200 vs 42,000 tokens median, 5 runs per side, ranges overlap, limiter: context size per call."

A limiter is required for cost numbers too. For token spend, name what drives the count, such as tool calls or context size.

---

## Inconclusive

Write "inconclusive" and name the gap when any of these holds:

- the limiter is not identified
- a side was not tuned the way it runs for real
- errors or "did it happen" were not checked
- fewer than 5 alternated runs per side were made

Example: "30% faster, 5 runs, limiter unknown" is reported as "inconclusive: limiter not identified".

---

## Examples Are Illustrations

Any tool named in this file (for example, a sampling profiler, a hardware counter reader, or a token usage log) is an illustration only. The checklist works with whatever the project's platform provides.

---

## Related

For the control-and-treatment rule that sits beside the alternated-runs rule, see `RESEARCH_GATE.md`.
