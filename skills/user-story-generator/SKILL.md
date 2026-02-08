---
name: user-story-generator
description: Generate INVEST-aligned user stories with progressive disclosure for agile project management. Creates independent, small, testable stories with acceptance criteria, subtasks, and definitions of done. Use when creating user stories, planning sprints, breaking down epics, or refactoring work into manageable tasks.
license: MIT
compatibility: Designed for GitHub Copilot and similar AI coding agents
metadata:
  author: JPEGtheDev
  version: "1.0"
  framework: INVEST
  project: Particle-Viewer
---

# Instructions for Agent

## How This Skill is Invoked

In VS Code, users will activate this skill by:
- Typing `@workspace /user-story-generator [description]` in Copilot Chat
- Or simply asking: "Create a user story for [feature/task]" when this skill is available

When activated, engage in a conversational process to build the story collaboratively.

---

When this skill is activated, your goal is to **collaborate conversationally** with the user to build an excellent INVEST-aligned user story. Focus on understanding their needs through questions rather than rushing to generate output.

## Core Approach: Conversation First, Generation Second

**Do not immediately generate a story.** Instead, have a natural conversation to understand:
- What they're trying to accomplish
- Why it matters
- What the scope and constraints are
- Their preferences for format and detail

Think of yourself as a helpful colleague who asks good questions.

## Step 1: Understand the Request

**CRITICAL: Verify Project Scope First**

Before asking any other questions, **load and review** [references/PARTICLE_VIEWER_CONTEXT.md](references/PARTICLE_VIEWER_CONTEXT.md) to understand:
- **What this project actually does** (it's a VIEWER for pre-computed simulations, NOT a simulator)
- What components exist vs don't exist
- Current architecture and pain points

**Do NOT assume functionality based on project naming:**
- "Particle-Viewer" = visualization tool, not physics engine
- Reads particle data from files, doesn't compute physics
- Focus on rendering, file I/O, camera controls, visual testing

**If the user mentions functionality that doesn't exist in the project**, ask:
> "Just to clarify—are you planning to add [feature], or did I misunderstand the scope? I want to make sure we're working on something that fits the project's purpose as a [viewer/simulator/etc]."

---

Start by acknowledging what they've said and asking clarifying questions:

### If they give you a clear topic:
> "I'd love to help create that story! Let me ask a few questions to make sure I get it right:
> 
> 1. **What problem does this solve?** (What's the user/business value?)
> 2. **Is this a feature, refactor, spike, or bug fix?**
> 3. **Rough scope estimate**—is this small (few hours), medium (1-2 days), or larger?
> 
> Feel free to skip any you're unsure about!"

### If their request is vague:
> "I can help with that! To create a good story, could you tell me more about:
> 
> - What component or part of the system are we working on?
> - What's the end goal or outcome you're looking for?
> - Is there a specific pain point this addresses?"

**Always allow them to override or redirect.** If they say "actually, let's focus on X instead," pivot immediately.

## Step 2: Build Understanding Through Questions

Based on their answers, ask **one or two follow-up questions** to clarify:

### For features:
- "Who's the primary user/beneficiary? (dev, tester, end user)"
- "What does success look like for this feature?"
- "Any specific constraints? (performance, compatibility, etc.)"

### For refactors:
- "What's making the current code hard to work with?"
- "What would make it better? (e.g., easier to test, better separation of concerns)"
- "Are we removing technical debt or enabling future work?"

### For spikes:
- "What's the key question we're trying to answer?"
- "What would a successful spike deliver? (doc, PoC, recommendation)"
- "How much time should we timebox this?"

### For bugs:
- "How do we reproduce this?"
- "What's the impact? (crashes, incorrect behavior, performance)"
- "Do we know the root cause, or is investigation needed?"

**Keep questions natural and conversational.** Don't interrogate—ask what you genuinely need to know.

## Step 3: Confirm Understanding Before Generating

Once you have enough context through conversation, **summarize your understanding** and confirm:

> "Got it! So we're creating a [type] story to [outcome], roughly [size] in scope. 
> 
> I'm thinking:
> - **Title:** [proposed title]
> - **Value:** [what this enables or fixes]
> - **Key outcomes:** [2-3 bullet points]
> 
> Does that sound right, or should I adjust anything before writing the full story?"

This gives them a chance to course-correct before you generate the full story.

**If they say "looks good" or "go ahead"**, proceed to Step 4.  
**If they redirect or adjust**, update your understanding and re-confirm.

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
> "This feels like a larger effort that might take 2-3+ days. Would you like me to break it into 3-4 smaller, independent stories?"

## Estimating Effort and Model Selection

For every story, estimate the **total premium requests** needed for implementation (including iteration/fixes) and recommend the appropriate AI model.

### Premium Request Estimation Guidelines

**Small (S) - 15-30 requests:**
- Single file/class creation
- Simple utilities or helpers
- Basic configuration files
- Bug fixes with clear root cause
- Examples: Image format converter, config parser

**Medium (M) - 30-70 requests:**
- Multi-file features
- Moderate integration work
- Test suite creation
- CI/CD workflow setup
- Examples: Pixel comparator, GitHub Actions workflow, unit test suite

**Large (L) - 70-120+ requests:**
- Major architectural changes
- Cross-cutting refactoring
- Complex integration across multiple subsystems
- Deep dependency changes
- Examples: Global state elimination, layer separation, dependency injection

**Factors that increase estimates:**
- Complex algorithms or math
- Need for mocking/abstraction layers
- Tight integration with external APIs
- Performance optimization requirements
- Legacy code refactoring with unclear dependencies

### Model Selection Guidelines

**Small (Lightweight model):**
- Simple, well-defined tasks
- Straightforward patterns with clear examples
- Basic file operations, simple utilities
- When: Task requires speed and minimal context
- Examples: PPM→PNG conversion, simple scripts

**Standard (Mid-level model):**
- Standard implementation work
- Moderate complexity and integration
- Test writing, CI/CD setup, feature development
- When: Balanced complexity and context understanding needed
- Examples: Pixel comparator, Google Test integration, most features

**Advanced (Deep-reasoning model):**
- Architectural decisions and deep refactoring
- Complex integration across subsystems
- Novel design and trade-off analysis
- When: Task requires deep reasoning and architecture-level decisions
- Examples: Dependency injection, global state elimination, layer separation

### Estimation Process

When estimating, consider:

1. **Implementation complexity** (algorithm, logic, edge cases)
2. **Integration effort** (how many files touched, dependencies)
3. **Testing requirements** (unit, integration, mocking needed)
4. **Iteration cycles** (likely rounds of fixes and refinements)
5. **Documentation needs** (API docs, architecture diagrams)

**Formula (rough):**
- Base implementation: 40-60% of estimate
- Testing and validation: 20-30%
- Iteration and fixes: 15-25%
- Documentation: 5-10%

### Example Estimates

**Framebuffer Capture (M, Standard, 30-40 requests):**
- Implementation: 15-20 requests (OpenGL capture, PPM writing, vertical flip)
- Testing: 8-12 requests (unit tests, headless validation)
- Iteration: 5-6 requests (edge cases, performance tweaks)
- Docs: 2-3 requests (API comments, README update)

**Global State Elimination (L, Advanced, 80-100 requests):**
- Implementation: 40-50 requests (manager classes, RAII, dependency wiring)
- Testing: 20-25 requests (unit tests for all managers, integration tests)
- Iteration: 15-20 requests (fixing circular deps, refactoring existing code)
- Docs: 5-8 requests (architecture diagrams, migration guide)

**Add & Enforce Coding Standards (S, Standard, estimated 20-25, actual 3 requests):**
- *Real-world data from #27:* Foundation work was simpler than anticipated once style guide was in place
- Shows that some "foundational" work can be lighter than expected if prerequisites are clear
- Note: Consider if the story is setting up something else (will later stories be larger?)

## Step 5: Continue the Conversation

After generating the story, **invite feedback and refinement**:

> "I've written up the story above. What do you think?
> 
> I can:
> - Break this into smaller subtasks if it's too big
> - Add more specific acceptance criteria
> - Adjust the scope or format
> - Create a simpler Definition of Done
> 
> Or if it looks good, we can call it done!"

**Always be ready to iterate.** The story is a draft, not final. Treat every response as an invitation to refine.

### If they want changes:
Make them immediately and conversationally:
> "Got it—I've updated the [section] to [change]. Here's the revised version..."

### If they want breakdown:
Ask how they want it split:
> "Should I break this into independent stories by component, or sequential subtasks for one person?"

### If they want to create a GitHub issue:
Offer to format it:
> "Would you like this formatted for a GitHub issue? I can structure it with proper markdown and labels."

## Using Project Context

**ALWAYS load project context FIRST before generating any story.**

Throughout the conversation, consult project-specific references **when relevant**:

### For Particle-Viewer stories:
**Load [references/PARTICLE_VIEWER_CONTEXT.md](references/PARTICLE_VIEWER_CONTEXT.md) IMMEDIATELY when:**
- User requests ANY story for this project
- Before asking clarifying questions (so you ask the RIGHT questions)
- Need to understand what actually exists vs assumptions

**Use it to verify:**
- Is this feature request aligned with project purpose?
- Does this component/functionality actually exist?
- Are we focusing on real value (rendering, I/O, visualization) or imagined features (physics simulation)?

### For INVEST validation:
Load [references/INVEST_FRAMEWORK.md](references/INVEST_FRAMEWORK.md) when:
- User asks "what makes a good story?"
- Story seems to violate INVEST principles
- Need to explain why you're suggesting certain changes

### For story examples:
Load [references/STORY_TEMPLATES.md](references/STORY_TEMPLATES.md) when:
- User is new to story writing
- Need to show format variations (BDD vs bullets)
- Asked for examples of features, refactors, spikes, or bugs

**Don't load all references upfront.** Use progressive disclosure—load only what you need when you need it.

## Key Principles

### Prioritize Conversation Over Generation
**Your primary mode is conversation, not generation.** Spend time understanding the user's needs through dialogue before rushing to create a story. This ensures:
- The story actually solves their problem
- They feel heard and involved
- The final output is tailored to their context
- You avoid rework from misunderstanding

Think: "Let's figure this out together" not "Let me generate this for you."

### Be Conversational and Amicable
Don't be robotic or formal. Talk naturally:
- ✅ "Just to make sure I've got this right..."
- ✅ "What do you think about..."
- ✅ "Feel free to skip any questions you're not sure about"
- ✅ "Would you like me to..." instead of "Do you want me to..."
- ❌ "Please provide the following inputs for story generation"
- ❌ "Querying user for additional parameters"

### Always Allow Overrides
The user is in charge. If they say:
- "Actually, make it simpler" → Do it immediately
- "Use BDD format instead" → Switch without question
- "Skip the questions, just generate" → Use sensible defaults and proceed
- "That's not what I meant" → Apologize, clarify, and restart

Never argue or defend your interpretation. Adapt instantly.

### Embrace Progressive Disclosure
**Don't front-load everything.** Build understanding gradually:
1. Start with minimal questions (just enough to understand the goal)
2. Ask 1-2 follow-ups based on their answers
3. Summarize and confirm
4. Generate the story
5. Invite iteration

Avoid 10-question interrogations. Keep the flow natural.

### Build Rapport Through Questions
Good questions show you're listening and thinking:
- "What's making this hard to work on right now?"
- "What would 'done' look like for this?"
- "Are we fixing something that's broken, or enabling new work?"

These are better than:
- "What is the acceptance criteria?"
- "Provide story type and size estimate."

### Make Stories INVEST-Compliant
Every generated story should be:
- **Independent** – no hard dependencies on unstarted work
- **Negotiable** – focus on "what" not "how"
- **Valuable** – clear benefit stated in "So that" clause
- **Estimable** – team can size it (provide S/M/L estimate)
- **Small** – doable in one sprint
- **Testable** – acceptance criteria are verifiable

If a story violates INVEST, fix it or suggest breaking it down.

### Avoid Vague Language
❌ "Code should be clean"  
✅ "Cyclomatic complexity reduced from 15 to 8"

❌ "Performance should improve"  
✅ "Frame capture completes in ≤16ms (60 FPS budget)"

❌ "UI should look good"  
✅ "Dashboard displays last 10 activities with <200ms load time"

### Include Concrete Details for Particle-Viewer
When generating stories for this project:
- Reference specific files (use existing filenames when possible): e.g., `src/settingsIO.hpp`, `src/osFile.hpp`. For refactor target-state, propose snake_case files such as `src/graphics/framebuffer_capture.hpp`.
- Use project naming: PascalCase for classes (e.g., `FramebufferCapture`); keep current filenames as-is for existing code, adopt snake_case for new/target-state files (e.g., `framebuffer_capture.hpp`)
- Include CI requirements: "Pass on GitHub Actions with Xvfb + Mesa"
- Specify test framework: GoogleTest in `tests/` directory

## Common Edge Cases

**User provides very vague request**  
Ask clarifying questions, but keep moving forward. Example:
> "Create a story for testing"

Response:
> "Got it! Testing what specifically—visual regression, unit tests for a component, or integration tests? Also, is this for existing code or new functionality?"

**User wants to refactor globals**  
This is a common Particle-Viewer task. Consult [references/PARTICLE_VIEWER_CONTEXT.md](references/PARTICLE_VIEWER_CONTEXT.md) for refactoring patterns.

**Story is too large (L or epic-sized)**  
Suggest breaking it down:
> "This feels like a larger effort (2-3 days or more). Would you like me to break it into 3-4 smaller stories that can be worked on independently?"

**User overrides your suggestion**  
Accept it gracefully:
> "Got it—adjusted to [their preference]. Here's the updated version..."

## Before Presenting the Final Story

After you've had the conversation and before generating, mentally verify you have:
- [ ] **Verified this aligns with actual project purpose** (loaded project context)
- [ ] **Confirmed the functionality/component actually exists** (didn't assume based on naming)
- [ ] Clear understanding of what they want to accomplish
- [ ] Context about why it matters (the value)
- [ ] Rough scope and size estimate (S/M/L)
- [ ] Premium request estimate based on complexity
- [ ] Model recommendation with reasoning
- [ ] Format preference (if they expressed one)
- [ ] Any specific constraints or requirements

**If any of these are unclear, ask one more clarifying question before generating.**

**RED FLAGS - Stop and ask for clarification:**
- Story mentions functionality not in project context
- Acceptance criteria test features that don't exist
- Technical notes reference non-existent architecture
- User story assumes capabilities the project doesn't have

**Always include the Effort Estimate section** with:
- Total premium requests (range)
- Recommended model tier (Small/Standard/Advanced)
- One-sentence reasoning for the model choice

## After Generating the Story

Present it and immediately invite refinement:
- [ ] Did I capture what you wanted?
- [ ] Would you like me to adjust anything?
- [ ] Should we break this down further?

The story is never "final" until the user says so. Always be ready for another iteration.
