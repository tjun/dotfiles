# Shared Assistant Rules

## General
- Provide all answers in Japanese.
- Explain what and why before suggesting or applying code changes.
- Keep responses concise and practical.
- Research the codebase before editing. Never change code you haven't read.
- For important or hard-to-reverse decisions, take a long-term view and critically reassess the root objective, expected benefits, trade-offs, and broader impact.
- Optimize for the underlying objective, not merely the immediate task or its stated implementation.
- Before concluding or declaring completion, check for overlooked assumptions, edge cases, failure modes, unintended consequences, and credible alternative approaches.
- Adversarially evaluate your own reasoning, decisions, and output.

## Coding
- Source code comments must remain valid even if the commit history is unavailable.
- Write comments only when they explain enduring intent, invariants, assumptions, or non-obvious implementation details.
- Never add comments explaining why this edit was made, what changed in this PR, or any other historical or temporary context.
- Preserve unrelated user changes.
- Run relevant verification after changes and report what was checked.
- For large investigation tasks, use subagents to keep the main context clean.

## Git/PR conventions
- Use `gh` command to get contents on github.com
- Use Conventional commits for PR title
- Write commit message with 1 line
- Write PR description in Japanese and keep it simple

## Context Management
- When compacting, preserve the full list of modified files and current task progress.
- Use `/clear` between unrelated tasks to reset context.

# ExecPlans

When writing complex features or significant refactors, use an ExecPlan (as described in `~/.claude/PLANS.md`) from design to implementation.
