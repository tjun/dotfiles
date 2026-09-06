---
name: hard-tasks
description: |
  A method for working on hard, multi-step tasks: how to decompose them, how to
  verify your own work before claiming it is done, and how to decide what to do
  next when results surprise you. Use this whenever a task will take more than a
  few steps, spans multiple files or systems, has real uncertainty about the
  right approach, or when you catch yourself about to write a plan before
  reading the code. Also use it mid-task when you are stuck, when a fix has
  failed twice, or when you are about to report "done".
---

# Working on Hard Tasks

Distilled from how Claude Fable 5 approaches work that takes sustained effort.
The three sections mirror the three loops you are always running: shaping the
work (decompose), grounding your claims (verify), and steering (decide what's
next). None of these are phases — you revisit all three continuously.

## Part 1: Decomposition

### Define "done" before defining steps

Restate the task as an observable outcome: what will be true, and how would
anyone check it? If you cannot state the check, that is your first subtask —
not a detail to defer. Every later decision quietly depends on this, and a
vague target lets every subtask drift a little until the sum is off-target.

### Read reality before planning

A plan written before contact with the actual code, data, or system is fiction
with confident formatting. Spend the opening budget on reconnaissance: read the
files you will touch, run the thing, look at real inputs. Most "hard" tasks get
easier here — half the imagined difficulty turns out not to exist, and the real
difficulty is usually something you did not imagine.

### Decompose by uncertainty, not by deliverable structure

The natural instinct is to split a task by its visible parts (backend, frontend,
tests; section 1, 2, 3). Resist it. Instead, list what you don't know, and sort
by how much the answer would reshape the plan. Attack the biggest unknown first,
as cheaply as possible — a spike, a 10-line experiment, a targeted read. The
reason: a plan is cheapest to change when the least of it is built. Discovering
a wrong assumption on step 2 costs minutes; discovering it after building the
deliverable-shaped steps costs everything downstream of it.

Corollary: identify the one or two **load-bearing decisions** — usually a data
model, an interface boundary, or an algorithm choice — that constrain
everything else. Settle those with evidence. Most of the rest is mechanical and
any reasonable order works.

### Build a thin vertical slice first

Get a skeleton running end-to-end — ugly, hardcoded, minimal — before widening
any single layer. Integration points are where hard tasks actually fail, and a
running skeleton surfaces those failures while they are cheap. Three polished
components that have never met each other is the classic shape of a task that
is "90% done" for a long time.

### Externalize state early

Once there are more than about three live subtasks, keep a written list (task
tracker, notes file) and update it as you learn. The realistic failure mode on
long tasks is not doing a subtask badly — it is silently forgetting one, or
forgetting *why* you deferred it. Write down not just what remains but what you
have ruled out and why, so future-you doesn't re-litigate it.

### Match step size to risk

Mechanical, well-understood work: take it in large chunks; fine-grained
checkpointing is overhead. Risky or irreversible work: small steps, verify
after each, checkpoint before anything hard to undo. If everything in your plan
is the same step size, you haven't thought about where the risk is.

### Delegate the self-contained parts

Searches, surveys, and independent sub-problems with a crisp question and a
crisp answer format go to subagents. Keep the main thread for decisions and
integration — a context full of raw search output crowds out judgment.

## Part 2: Verification

### Verify behavior, not intention

The question is never "does this look right?" — it is "what did I observe when
I exercised it?" You wrote the code, so reading it back mostly confirms what
you meant, not what it does. Run the actual flow the change affects.

### Know your level of evidence

There is a hierarchy, and claims must not outrank their evidence:

1. Observed the end-to-end behavior with realistic input
2. A targeted test that exercises the change passed
3. The full existing suite passed
4. It typechecks / lints / compiles
5. It reads correctly

"Done" means level 1 or 2. Saying "done" while holding level 4 evidence is the
fake-done that erodes trust — say instead exactly what was checked: "compiles
and existing tests pass; I have not exercised the new path."

### Ask the two questions before reporting done

- *What is the strongest claim my evidence actually supports?*
- *How could this be broken while every check I ran still passes?*

The second one is the productive one. It surfaces the untested error path, the
edge case at the boundary, the config that differs in production. Whatever it
surfaces, run that check — or name it explicitly as unverified in your report.

### Distrust first-try passes

A test that passes immediately after you write it has proven nothing yet —
confirm it *can* fail: break the code, watch the test go red, restore. Tests
that cannot fail are verification theater, and they are common.

### For bugs: reproduce before fixing

A fix without a reproduction is a guess wearing confidence. Reproduce first,
then fix, then re-run the same reproduction. This also hands you the exact
verification for free, and it is the only defense against "fixed" bugs that
were never the actual bug.

### Review your own diff as an adversary

Before finishing, read the full diff as a hostile reviewer hunting specifically
for: boundary conditions, error and early-return paths, things you touched but
didn't mean to, and behavior removed accidentally. Reading for "is this good"
finds nothing; reading for a specific failure class finds things.

### Report faithfully

Failing tests, skipped steps, and unverified paths are findings — state them
plainly with the output. A truthful "X works, Y is unverified" is far more
useful than a smooth "done", because the reader will act on your claim.

## Part 3: Deciding What to Do Next

### Predict, act, compare

Before each significant action, know what result you expect. When the result
matches, proceed. When it surprises you, **stop building** — a surprise means
your model of the system is wrong somewhere, and every step taken on a wrong
model multiplies rework. Understanding the surprise is not a detour from the
task; it is the task.

### Two failed fixes means wrong diagnosis

If you have attempted the same fix twice and it hasn't worked, the problem is
not your execution — it is your theory of the problem. Do not try a third
variation. Zoom out: return to the last observation you are certain of, and
re-derive the diagnosis from evidence (add instrumentation, bisect, reproduce
minimally). Variations on a wrong theory can consume unlimited time; this rule
is the circuit breaker.

### Audit sunk cost explicitly

Periodically ask: *knowing what I know now, would I choose this approach from
scratch?* If no, switch — work already invested is not an argument for
continuing. Salvage the knowledge (write down what the dead end taught you),
discard the code without ceremony.

### Classify every blockage before reacting

- **Missing information you can obtain** → go obtain it. Read the source, run
  the experiment, check the docs. Never ask a question you can answer yourself.
- **A genuine user decision** — scope changes, irreversible or outward-facing
  actions, taste calls with no recoverable right answer → stop and ask. These
  are the only legitimate stopping points short of completion.
- **Discomfort dressed as blockage** — the task is long, tedious, or the next
  step is unglamorous → not a blockage. Continue.

### Know when the turn ends

End only when the outcome defined at the start is achieved *and verified*, or
when blocked on a genuine user decision. Before stopping, read your own last
paragraph: if it is a plan, a list of next steps, or a promise ("I'll then…"),
that is not a conclusion — it is your next action. Do it.

## Failure Modes — Quick Reference

| Symptom | What went wrong | Correction |
|---|---|---|
| Detailed plan, code unread | Planning fiction | Reconnaissance first |
| One layer polished, nothing connected | Horizontal decomposition | Thin vertical slice |
| A subtask quietly vanished | State kept in your head | Written, updated task list |
| "Done" but only typechecked | Claim outranks evidence | Exercise the behavior, or scope the claim |
| Test passed on first try, unquestioned | Verification theater | Prove the test can fail |
| Third variation of the same fix | Wrong diagnosis, right effort | Re-derive from last certain observation |
| Continuing because much is invested | Sunk cost | "Would I choose this now?" |
| Ends with "next, I will…" | Stopped at a plan | The plan is the next action |
