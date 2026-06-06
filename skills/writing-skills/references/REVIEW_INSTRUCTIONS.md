# Review Instructions

How to conduct a skill review. The criteria for each checklist item are in the reference
sections injected above this document. Apply them exactly.

---

## Step 1 -- Pre-Checks

Run before any element checks:

```bash
wc -l "{{SKILL_PATH}}"
wc -c "{{SKILL_PATH}}"
head -6 "{{SKILL_PATH}}"
ls "$(dirname "{{SKILL_PATH}}")/references/" 2>/dev/null || echo "No references/ directory"
```

Record all output. Apply size limits from SIZE_AND_COMPRESSION. Apply frontmatter rules
from SKILL_ANATOMY_ELEMENTS Element 1. Note every file found in `references/` -- each will
be reviewed in Step 4.

---

## Step 2 -- SKILL.md Checklist

Run every item. Mark [+] (pass) or [-] (fail) with file:line evidence. Criteria for each
item are in the reference sections above.

- [ ] **Frontmatter** -- `name:` and `description: Use when...` present, valid, under 200 characters?
- [ ] **Size** -- apply three levels from SIZE_AND_COMPRESSION: (1) at or under Target = OK; (2) above Target but at or under Ideal max = SIZE ALERT (note it, not a NEEDS WORK blocker); (3) above Ideal max = NEEDS WORK (compression required before shipping)?
- [ ] **Iron Law block** -- backtick-wrapped; ALL CAPS rule; `YOU MUST`; `No exceptions.`; all INSIDE the backtick block?
- [ ] **Iron Law letter/spirit line** -- "Violating the letter of this rule is violating the spirit of this rule." present?
- [ ] **Announcement** -- explicit exact wording present, not implied?
- [ ] **Gate Function** -- `## BEFORE PROCEEDING` with numbered conditions and [+]/[-] branches?
- [ ] **Rationalization Prevention** -- table with >=5 rows, specific excuses and specific counters?
- [ ] **Red Flags->STOP** -- section with >=5 trigger thoughts, each with a concrete action?
- [ ] **No weak language** -- run: `grep -n "should\|prefer\|consider\|try to\|might be worth\|could potentially" "{{SKILL_PATH}}"` -- any hit in a rule body is a FAIL?
- [ ] **Acronym Rule** -- all terms spelled out on first use per VOICE_AUTHORITY_RULES?
- [ ] **No absolute paths** -- no literal `/home/`, `/usr/`, `/root/` or machine-specific prefixes?
- [ ] **No cross-skill file path refs** -- other skills referenced by name in prose only, not by `../other-skill/references/FILE.md` paths?
- [ ] **Skill-specific content** -- no generic placeholder-only examples?
- [ ] **Related skill cross-reference** -- at least one related skill named?
- [ ] **Domain language** -- matches skill scope; no wrong-platform commands or terminology?
- [ ] **Enforcement co-location** -- every banned phrase or prohibited action has its safe substitute in SKILL.md, not behind a references/ pointer?

[+] All pass -> proceed to Step 3
[-] Any unmet -> record every failing item; continue through all steps before filing verdict

---

## Step 3 -- Qualitative Assessment

Read the skill again and answer:

**1. Gating effectiveness**
- Does the Iron Law stop the most common failure mode for this domain?
- Does the BEFORE PROCEEDING gate ask the right questions or rubber-stamp most cases?
- Would an agent under pressure to move fast rationalize past this skill?

**2. Alexandrian form gaps**
- Does each major rule state when it applies and when it does NOT?
- Does each rule explain the tension it resolves?
- Identify up to 3 bare imperatives without context/forces. Suggest how to expand them.

**3. Rationalization table quality**
- Are the excuses realistic things agents actually say?
- Are the counters specific, not just "don't do that"?
- Flag any row where the counter could itself be rationalized around.

**4. Improvement suggestions**
List 1-5 concrete, actionable suggestions. Each must name the specific section or line,
state the problem, and provide example replacement text or a clear direction.
Do not suggest padding or structural bloat.

---

## Step 4 -- Reference File Review

Read and review every file listed in `references/` during Step 1. If there is no
`references/` directory, write "No references/ directory" and proceed to Step 5.

For each reference file, run:

```bash
wc -c "<file>"
grep -n "should\|prefer\|consider\|try to\|might be worth\|could potentially" "<file>"
grep -n "/home/\|/usr/\|/root/" "<file>"
grep -n "\.\./[a-z].*references/" "<file>"
```

Apply this checklist per file (anatomy elements do not apply to reference files):

- [ ] **No weak language** -- grep hit in a rule body is a FAIL
- [ ] **Acronym Rule** -- all terms spelled out on first use
- [ ] **No absolute paths** -- no `/home/`, `/usr/`, `/root/` literals
- [ ] **No cross-skill file path refs** -- no `../other-skill/references/FILE.md` patterns
- [ ] **Content matches SKILL.md pointer** -- file contains what SKILL.md says it contains
- [ ] **Size** -- no hard limit for reference files; flag as SIZE ALERT if > 8,000 chars (~2,000 tokens)

Reference file issues that trigger NEEDS WORK on the overall verdict:
- Weak language in rule bodies
- Absolute paths
- Cross-skill file path references
- Content that contradicts or is absent from what SKILL.md says it contains

Size alerts on reference files are informational only -- not a NEEDS WORK trigger.

---

## Step 5 -- Red Flags Gate

Check before filing the verdict. Any hit here means re-examine the finding and correct
the verdict if needed before returning.

- "It has most of the required elements" -- count every element. Partial is FAIL.
- "The Iron Law is present but mild" -- `YOU MUST` and `No exceptions.` must be INSIDE the backtick block.
- "4 rows is close enough" -- 4 is a FAIL. >=5 is the rule.
- "The announcement is implied" -- implied is a FAIL. Must be an explicit line.
- "I'll note issues but still give PASS" -- no PASS with open issues.
- "The path is just an example" -- any machine-specific absolute path is a FAIL.
- "The gate function exists under a different heading" -- must be `## BEFORE PROCEEDING`.
- "`YOU MUST` and `No exceptions.` are in prose, not the block" -- prose-only is a FAIL.
- "The skill is long but comprehensive" -- SIZE ALERT if above Target; NEEDS WORK if above Ideal max. Content quality does not override size limits.
- "The description explains what the skill does" -- must start "Use when...".
- "`should` is just writing style" -- soft language in rule bodies is a FAIL.
- "The acronym is obvious" -- spell it out. No exceptions.
- "The safe substitute is in references/ but the ban is inline" -- enforcement separation. Ban and safe alternative must be in the same file. If a vocabulary gate says 'use process language' and the process language list is only in references/, that is a FAIL on Enforcement co-location.

---

## Return Format

Return findings in EXACTLY this structure:

```markdown
## Skill Review: [skill-name]

### Size and Frontmatter
- Lines: [N] | Bytes: [N] | Size status: OK / SIZE ALERT (above target, within ideal max) / OVER IDEAL MAX (compression required)
- Frontmatter: [+]/[-] -- [note any missing or malformed fields]

### Gate Elements
| Element | Present | Quality | Notes |
|---------|---------|---------|-------|
| Iron Law | [+]/[-] | Strong/Weak | file:line -- [quote key phrase] |
| Iron Law hard language in block | [+]/[-] | In block / Prose only | file:line |
| Iron Law letter/spirit line | [+]/[-] | Present/Absent | file:line |
| Announcement | [+]/[-] | Clear/Vague | file:line |
| Gate Function | [+]/[-] | Present/Absent | file:line |
| Rationalization Table | [+]/[-] | N rows | file:line |
| Red Flags->STOP | [+]/[-] | N items | file:line |

### Checklist
| Item | Result | Evidence |
|------|--------|----------|
| Frontmatter name + description | [+]/[-] | file:line |
| Size within limits | [+]/[-] | [N lines, N bytes] |
| Iron Law hard language in block | [+]/[-] | file:line |
| Iron Law letter/spirit line | [+]/[-] | file:line |
| Announcement explicit | [+]/[-] | file:line |
| Gate Function BEFORE PROCEEDING | [+]/[-] | file:line |
| Rationalization >=5 rows | [+]/[-] | file:line |
| Red Flags >=5 items | [+]/[-] | file:line |
| No weak language | [+]/[-] | grep output or "no instances found" |
| Acronym Rule | [+]/[-] | file:line or "no issues found" |
| No absolute paths | [+]/[-] | grep output or "no issues found" |
| No cross-skill path refs | [+]/[-] | grep output or file:line |
| Skill-specific content | [+]/[-] | file:line |
| Related skill cross-reference | [+]/[-] | file:line |
| Domain language match | [+]/[-] | file:line or "no issues found" |

### Reference Files
[For each file in references/ -- repeat this block per file, or write "No references/ directory":]

#### references/[filename]
| Item | Result | Evidence |
|------|--------|----------|
| No weak language | [+]/[-] | grep output or "no instances" |
| Acronym Rule | [+]/[-] | file:line or "no issues" |
| No absolute paths | [+]/[-] | "no instances" or file:line |
| No cross-skill path refs | [+]/[-] | "no instances" or file:line |
| Content matches SKILL.md pointer | [+]/[-] | note what was expected vs. found |
| Size | OK / SIZE ALERT | [N chars, ~N tokens] |

### Issues Found
[Each issue: file:line -- description]

### Qualitative Assessment

**Gating effectiveness:** [1-2 sentences]

**Alexandrian form gaps:** [up to 3 rules; file:line and what context/forces are missing]

**Rationalization table quality:** [note weak counters or unrealistic excuses]

**Improvement suggestions:**
1. [file:line -- problem -- example fix]
2. ...

### Verdict: PASS / NEEDS WORK
```

NEEDS WORK means the skill MUST be updated before production dispatch.
