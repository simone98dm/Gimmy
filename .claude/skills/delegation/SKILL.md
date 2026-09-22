---
name: delegation
description: How to distribute work across sub-agents efficiently and effectively. Use when orchestrating multi-step development work, deciding which agent handles which task, or sequencing/parallelizing agent dispatches — triggers on orchestrate, delegate, dispatch, sub-agent, pipeline, coordinate, distribute work.
---

# Delegation

Rules for splitting work across specialist agents. Generic: applies to any pipeline, any set of agents. The orchestrator-agent uses this to plan every dispatch.

## Core Principle: Multi-Agent by Default

Development work is **always multi-agent when the task permits it**. A single agent doing implementation + tests + review + docs produces worse results than specialists doing each: the implementer is biased toward its own code, the reviewer is not. Delegate to a single agent only when the task is genuinely atomic (one-line fix, typo, single mechanical rename) — and say explicitly why the pipeline was skipped.

## Decomposition

1. Break the request into tasks with **one owner and one deliverable** each. A task that needs two specialists is two tasks.
2. Assign each task to the **most specialized agent available**. Never send generic work to a specialist or specialist work to a generalist.
3. Every task gets a **done-criterion** checkable from the agent's report (tests pass, file exists, audit clean) — never "looks good".
4. If no agent fits a task, flag the gap; do not silently absorb the work into the orchestrator-agent.

## Sequencing vs Parallelizing

Default to parallel; serialize only when forced:

- **Serialize** when there is a hard data dependency (tests need the implementation; review needs the tests) or when two agents would edit the same files.
- **Parallelize** everything else: independent features, disjoint layers (API endpoint + UI component on separate files), audits on already-written code (a11y + i18n can run together), research/analysis tasks.
- Quality gates are serialization points: nothing downstream of a gate starts until the gate passes.

Wrong: implement → a11y audit → i18n audit → security audit (serial, 3× slower).
Right: implement → [a11y ∥ i18n ∥ security] → fix findings → tests.

## Dispatch Contract

Every dispatch passes exactly:

- The relevant spec/task excerpt — never the whole conversation
- The list of files created/modified so far (prevents duplicate work and edit collisions)
- Done-criterion for the task
- Feedback from previous failed attempts, verbatim (error output, review findings)

Context is expensive: an agent that receives everything reads nothing carefully.

## Verifying Results

- Advance only on the agent's **actual report** — never assume a dispatch succeeded.
- Check the report against the done-criterion, not against plausibility.
- Failure → redispatch to the **same agent** with the failure output attached; max 3 attempts, then stop and escalate to the user with the full history.
- Conflicting reports from parallel agents (both edited the same file, contradictory findings) → serialize a reconciliation pass before proceeding.

## Anti-patterns

- ❌ Orchestrator implementing code itself "because it's faster"
- ❌ One mega-dispatch ("build the whole feature") to a single agent
- ❌ Serial chains of independent tasks
- ❌ Re-dispatching a failed task without the failure output
- ❌ Passing the full conversation as context
- ❌ Skipping a specialist because its domain "probably doesn't apply" — state why a stage is not applicable, explicitly, in the final report
