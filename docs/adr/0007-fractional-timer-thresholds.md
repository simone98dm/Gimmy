# 7. Fractional timer colour thresholds

Date: 2026-09-22

## Status

Accepted.

## Context

The countdown ring shifts colour as a step runs down. The design prototype implements this with
absolute times: amber at 25 seconds remaining, red at 5.

Those numbers are tuned for the 60-second hold in the prototype. The reference plan opens with a
ten-minute treadmill warmup, where they would mean green for nine and a half minutes and then a
sudden scramble through amber and red in the last half minute.

## Decision

Use fractions of the step's own duration: green above 50% remaining, amber from 50% down to 20%,
red below 20%.

The prototype's changing caption is kept, driven by the same thresholds — `HOLD TIME`, then
`HOLD INTENSITY`, then `FINAL PUSH!`.

## Consequences

The ring means the same thing on a 30-second plank and a 10-minute warmup: how much of *this* step
is left.

The thresholds live on `GimmyTokens` as named constants with the colour lookup beside them, and are
tested at every boundary, including the case where a step has no duration at all.

A step long enough that 20% is still several minutes will sit on red for a while. That is the
correct trade: the colour tracks proportion, and proportion is what the user is pacing against.
