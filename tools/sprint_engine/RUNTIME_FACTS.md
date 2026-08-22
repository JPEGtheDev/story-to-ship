# Sprint Engine Runtime Facts

These are runtime facts the sprint engine's design builds on, verified by
direct measurement against the live runtime this engine runs on top of (not
assumed from documentation). Each fact below is stated in plain language and
followed by the verbatim evidence it rests on, quoted exactly as measured.

## Spec delivery: object or raw string

The engine's input channel can hand a spec to the runtime two different ways
-- as an already-parsed object, or as a raw JSON string that has not been
parsed yet -- and which one happens is not guaranteed to stay the same over
time. The engine must parse defensively for both.

Measured: passing a JSON object arrived at the running script already
stringified.

> Passing `args: {"payload": "..."}` (a JSON object with a 35,100-char total
> text) reached the script as `typeof args === 'string'` -- the raw JSON
> text, unparsed.

This is treated as harness-version behavior rather than a permanent
guarantee, so the trigger for re-checking it is a runtime-version change, not
routine suspicion:

> string delivery is harness-version behavior, so a runtime-version change
> triggers a cheap re-probe, not silent trust

## Carriage: byte-exact to 41,628 characters, ceiling unlocated

A spec (or any inline payload) carried through this channel arrived intact,
byte-for-byte, at every size actually measured, up to the largest size
measured. No corruption and no rejection were observed at any size tried.

The measurement below uses three internal labels: a "rung" is one step in an
increasing-size ladder of test payloads; the "wf_..." identifier names the
specific run that produced that rung's result; and "caller emission" --
which the parenthetical tag inside the quote below also names -- means the
limit that bounded how large the tested payloads got was the sending side's
own limit on how much text it could emit in one go, not any limit enforced
by the runtime itself.

> Measured maximum working size: 41,628 chars (rung 3, wf_791e813b). This is
> a FLOOR on the true ceiling, not the ceiling: no failure was ever observed,
> and the ladder stopped because caller emission (F3) -- not the runtime --
> bounded payload size.

So 41,628 characters is the highest point this repo has confirmed works, not
a discovered limit -- no failure was ever observed at any size tried, and no
ceiling above that point has been located.

## Injected dependencies only: no filesystem, no crypto inside a running script

The only capabilities a script the runtime executes has access to are the
ones the runtime injects into it directly -- it cannot read or write files
and cannot call into a crypto library on its own; both are absent from what
gets handed to the script.

> The workflow script computes sha256 IN-SCRIPT (pure-JS; scripts have no
> filesystem/crypto), returns {jsLength, sha256} plus a bounded agent echo
> probe

A pure-JavaScript sha256 implementation running inside the script (with no
crypto library available) was checked against a known-correct test vector
and matched:

> selfTest is sha256('abc') and is correct, so the in-runtime hash
> implementation is sound.

## Runtime script dialect

Scripts the runtime executes are written in a dialect that is neither plain
CommonJS nor plain ES modules: they open with an `export const meta` header,
and their body is allowed to use a bare top-level `return` statement --
something neither module system permits outside a function. Because of this,
running `node --check` against a script's body directly is not a valid way
to test whether the runtime will accept it as loadable; a different,
purpose-built check is needed for that.

The header, verbatim:

```js
export const meta = {
  name: 'e2-spec-runner',
  description: 'Minimal spec-interpreting runner: agent step -> gate step -> agent step',
  phases: [{ title: 'Run' }],
}
```

A bare top-level return, verbatim, from the same script's final line (not
inside any function):

```js
return { status, argsDelivery, trace, results, runError }
```

## By-path reads: agents can read and hash a file at an absolute path

A dispatched agent, given only an absolute file path, ran shell commands
against it and returned a digest that matched independently-computed ground
truth -- and this was confirmed at a large size (1 MiB), not just a small
one.

> driver: sha256sum -> 027ab5021c1b804d74ce217a436843f1def730ef363acc00963582c9ba3607c1, stat -c %s -> 1048576
> agent:  {"agentSha256":"027ab5021c1b804d74ce217a436843f1def730ef363acc00963582c9ba3607c1",
>          "agentBytes":1048576,
>          "agentCommand":"sha256sum .../e1b-payload.bin; stat -c %s .../e1b-payload.bin"}

Digest and byte count were identical between what the agent reported and
locally-computed ground truth, at the full 1 MiB the file actually was --
carried byte-exact by path.

## Output-token failure mode: an echo of prompt content, not a generated-output ceiling

An agent asked to copy a span of text out of a payload embedded in its own
prompt did not just fail -- it died against the runtime's output-token cap
while trying. The verbatim failure line:

> [echo-probe] failed: API Error: Claude's response exceeded the 32000 output
> token maximum.

This happened while the agent was asked to echo back roughly 14KB of
prompt-embedded payload text. It does NOT mean generated output is capped
anywhere near 14KB -- the agent was not generating new content near that
size, it was attempting to copy content that was already sitting in its
prompt, and it lost control of its own output length while trying to do
that. The failure is a property of asking an agent to echo large embedded
content, not a measurement of how much an agent can generate on its own.

## The spill-guard blind spot

The engine's oversized-output guard exists to catch a content field an agent
returns that is too large and should have spilled to a file instead. But a
violation large enough to die at the 32,000-output-token cap described above
never delivers a result to catch in the first place -- the dispatch just
comes back null.

The engine still halts safely in that case (a null result surfaces as a
failed or uncertain step, not a hang or a crash), but the trace records it as
an ordinary agent failure, not specifically as a caught guard violation --
so the count of guard violations the engine can report undercounts how often
this actually happens, because the worst violations never survive long
enough to be counted as violations.

## This repo's own runtime probe

Two further facts come from this repo's own probe workflow rather than from
the measurements quoted above; the full probe script and its result are
recorded in the sibling file `PROBE_RESULTS.md` in this same directory.

- **`parallel()` returns a positional array, not a labeled object.** Two
  branches run through `parallel()` came back as array indices `0` and `1`,
  not as named keys -- confirmed by one observed run.
- **A dispatched agent can create a directory and write a file.** An agent
  given an absolute path successfully ran `mkdir -p`, wrote a file, and an
  independent read-back (plus the launching session's own local hash)
  confirmed the file's contents matched what was intended -- confirmed by
  one observed run, at one file, in one environment.

Both are single observations, not stress-tested across multiple runs, sizes,
or environments.
