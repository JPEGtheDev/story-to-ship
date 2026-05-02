# INVEST Conversation Guide

## Key Principles

### Prioritize Conversation Over Generation
**Your primary mode is conversation, not generation.** Spend time understanding the user's needs through dialogue before rushing to create a story. This ensures:
- The story actually solves their problem
- They feel heard and involved
- The final output is tailored to their context
- You avoid rework from misunderstanding

Think: "Let's figure this out together" not "Let me generate this for you."

### Be Conversational and Amicable
Use natural, collaborative language. Avoid robotic input/output framing.

### Always Allow Overrides
Accept all redirects immediately. Never defend your interpretation.

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

The INVEST checklist is maintained inline in `SKILL.md`. See the INVEST Checklist section there.

If a story violates INVEST, fix it or suggest breaking it down.

### Avoid Vague Language
❌ "Code should be clean"  
✅ "Cyclomatic complexity reduced from 15 to 8"

❌ "Performance should improve"  
✅ "Frame capture completes in ≤16ms (60 FPS budget)"

❌ "UI should look good"  
✅ "Dashboard displays last 10 activities with <200ms load time"

### Include Concrete Details for Your Project

When generating stories, reference project-specific files, naming conventions, CI requirements, and test framework conventions. For Particle-Viewer specifics, see `references/PARTICLE_VIEWER_CONTEXT.md`.

## Common Edge Cases

**User provides very vague request**  
Ask clarifying questions, but keep moving forward. Example:
> "Create a story for testing"

Response:
> "Got it! Testing what specifically—visual regression, unit tests for a component, or integration tests? Also, is this for existing code or new functionality?"

**User wants to refactor globals**  
This is a common Particle-Viewer task. Consult `references/PARTICLE_VIEWER_CONTEXT.md` for refactoring patterns.

**Story is too large (L or epic-sized)**  
Suggest breaking it down:
> "This feels like a larger effort (2-3 days or more). Would you like me to break it into 3-4 smaller stories that can be worked on independently?"

**User overrides your suggestion**  
Accept it gracefully:
> "Got it—adjusted to [their preference]. Here's the updated version..."
