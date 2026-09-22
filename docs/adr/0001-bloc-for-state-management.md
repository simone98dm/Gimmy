# 1. Bloc for state management

Date: 2026-09-22

## Status

Accepted.

## Context

The app has three kinds of state: settings that must survive a relaunch, an imported plan shared
by every screen, and a workout in progress with rules complex enough to be worth testing on their
own — a timer that must not auto-start, a −10s control, skip counting separately from completion.

Flutter offers no single answer here, and mixing several approaches in one codebase is how
codebases become hard to follow.

## Decision

Use Bloc (`flutter_bloc`) throughout, and nothing else.

`AppBloc` holds what the tabs share: settings, the active plan, the session history. Feature blocs
— `ImportBloc`, `ExecutionBloc` — own their own flows. Repositories are provided with
`RepositoryProvider` and injected into blocs, never constructed inside them.

## Consequences

The execution rules became a pure state machine testable without a widget tree: 24 tests drive it
through play, pause, auto-advance, skip and abandon with a fake ticker, in milliseconds.

Blocs need their dependencies injected to be testable, which pushed the file picker and the clock
behind parameters — `pickFile`, `now`, `ticker`. That plumbing also made the whole first-launch
flow testable end to end.

Every page is alive at once inside the `IndexedStack`, so `context.watch` on `AppBloc` rebuilds all
three tabs on any change. Pages use `context.select` and take only what they draw.
