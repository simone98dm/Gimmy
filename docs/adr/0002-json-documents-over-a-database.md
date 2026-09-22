# 2. JSON documents instead of a database

Date: 2026-09-22

## Status

Accepted. Extended by [ADR-0009](0009-platform-split-storage.md) when web support was added.

## Context

The app stores one active plan and a list of workout sessions. A year of daily training is a few
hundred small records. The calendar needs to group sessions by day and the streak needs to walk
backwards through them — both trivial over an in-memory list.

The obvious options were `drift` (SQLite with typed queries and migrations, plus a code generator
in the build loop) or `hive`, whose original package is unmaintained.

## Decision

Store each collection as a single JSON document. No database, no code generation, no migrations.

Writes go to a temporary file which is then renamed over the target, so an interrupted write
cannot destroy the previous version — losing a training history to a badly timed app switch is not
an acceptable failure.

A stored document that cannot be parsed is reported and discarded, and the app recovers into its
empty state rather than refusing to start.

## Consequences

No build_runner, no schema, no migration code. The repositories are about fifty lines each and
their tests run against a real temporary directory rather than a mock.

Everything is loaded into memory at launch, which is fine at this scale and would not be at a much
larger one. If the calendar ever needs real queries, `drift` slots in behind the repository
interfaces without the rest of the app noticing.
