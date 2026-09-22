# 6. One active plan, not a library

Date: 2026-09-22

## Status

Accepted.

## Context

Importing a plan could either replace whatever is there or add to a saved collection. A library
implies a plan list, a way to choose between them, rename and delete — and a screen for all of it
that the design does not have.

## Decision

An import replaces the active plan. One plan is stored at a time.

## Consequences

The storage layer holds a single document rather than a collection, the Dashboard has one Start
button with no ambiguity about what it starts, and no screen had to be invented.

`AppSettings.activePlanId` exists and is kept in step with the stored plan, so it is already there
if a library is added later. Turning the plan document into a list is the only structural change
that would need.

Re-importing a plan loses the old one. Session history keeps a snapshot of the plan's name, so
past workouts stay readable afterwards.
