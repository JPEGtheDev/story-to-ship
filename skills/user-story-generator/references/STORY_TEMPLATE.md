# Story Template

## Step 4: Generate the Story

Only after the user confirms, generate the story using this template:

```markdown
**Title:** [Story Name]

**Type:** Feature | Refactor | Spike | Bug
**Size:** S | M | L
**Epic/Component:** [e.g., Visual Regression Testing, Code Refactoring]
**Priority:** [High | Medium | Low]
**Depends On:** [Issue numbers or "None"]

---

## Effort Estimate

**Total Premium Requests:** [Range, e.g., 30-40]
**Recommended Model Tier:** [Small | Standard | Advanced]
**Reasoning:** [One sentence explaining complexity level and why this tier is appropriate]

---

## User Story

**As a** [role: developer, tester, user]  
**I want to** [action]  
**So that** [outcome/business value]

---

## Acceptance Criteria

- [ ] [Specific, measurable outcome]
- [ ] [Another measurable outcome]
- [ ] [Edge case or constraint]

---

## Technical Notes

**Dependencies:**
- [Other stories, external packages, or "None"]

**Constraints:**
- [Platform requirements, performance targets]

**Files to Create/Modify:**
- [List of modules with specific file paths]

**Architecture Notes:** [If applicable]
- [Design patterns, extensibility considerations]

---

## Definition of Done

- [ ] Code written and peer-reviewed
- [ ] Unit tests pass (min. 85% coverage on new code)
- [ ] No new linter/compiler warnings
- [ ] Documentation updated
- [ ] Integration tested
- [ ] Ready to merge to main branch

---

## Comments

[Optional: Next steps, related work, or important context]
```

**Make the story specific and actionable.** Use concrete metrics, file paths, and technical details where appropriate.

**If the story seems too large (L-sized or epic)**, mention this after generating and suggest breaking it down:
> "This is a larger effort that will take 2-3+ days. Would you like me to break it into 3-4 smaller, independent stories?"

## Estimating Effort and Model Selection

Load the `user-story-estimation` skill for S/M/L size breakdown, premium request ranges, model tier selection, and validated examples. Always include the Effort Estimate section in every generated story.
