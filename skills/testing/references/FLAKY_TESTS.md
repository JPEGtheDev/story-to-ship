# Flaky Tests

Load this reference when a test passed and failed on the same commit, or when you are deciding whether to retry, skip or quarantine a test. The rules say what counts as a flake, why retries are banned, and how to fix the cause.

---

## Definition

A test is flaky when it passes and fails on the same commit and setup with no change.

A run killed by the machine or the network (for example a runner shut down, or a package install timed out) is an infrastructure failure, not a flaky test.

---

## Retries

No automatic retries in the test runner or CI; a retry hides the flake.

- An infrastructure failure gets one fresh run, started by hand by a person or an agent and never by a retry setting; an identical second failure is real.

---

## Handling a Flake

- Open an issue with both run links (the failing and the passing run) the day a flake is seen.
- Fix a flake by removing the nondeterminism: pass the clock in, seed randomness, have each test create what it needs, reset shared state, wait on a condition and never a fixed sleep.
- Skipping, disabling or quarantining a flaky test to get green needs the repository owner's sign-off and an open issue.

---

## Random and Property-Based Tests

- A random or property-based test prints its seed when it fails (the seed the test itself drew, when its framework has no seed option), and the failing seed becomes a fixed regression case.
