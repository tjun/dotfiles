# Shared Assistant Rules

## General
- Provide all answers in Japanese.
- Explain what and why before suggesting or applying code changes.
- Keep responses concise and practical.
- When working with OpenAI APIs, ChatGPT, or Codex, prefer the OpenAI developer documentation MCP server if available.
- Research the codebase before editing. Never change code you haven't read.

## Coding
- Write comments only when they explain intent or non-obvious rationale.
- Do not write comments that only describe the code or explain the change itself.
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
