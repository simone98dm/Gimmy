# 3. Decoding FIT ourselves

Date: 2026-09-22

## Status

Accepted. Supersedes the original choice of `fit_dart_sdk`.

## Context

Garmin's FIT format is a binary protocol with definition records, local message types, base types
with reserved "invalid" values, subfields and scaled values. Writing a decoder is not the kind of
thing to do casually.

`fit_dart_sdk` is an auto-generated port of Garmin's official SDK and handled the reference file
perfectly, including the parts that are easy to get wrong. It was the right choice while the app
targeted only iOS and Android.

Adding web broke it. The package contains `int` literals larger than a JavaScript number can hold:

```
Error: The integer literal 9223372036854775807 can't be represented exactly in JavaScript.
```

This is a compile error, not a warning, on **both** dart2js and dart2wasm — `--wasm` still
produces a JavaScript fallback, so it fails either way. The alternative package, `fit_sdk`, has the
identical defect. `dart_fit_decoder` compiles but only returns raw fields, leaving the profile
logic to be written regardless.

The remaining option was to vendor a patched copy of the SDK: 356 generated files, 2.3 MB, to
change three lines, re-done on every upgrade.

## Decision

Write our own decoder, scoped to exactly what a workout file needs: the header and CRC, definition
and data records, the base types, and the `file_id`, `workout` and `workout_step` messages.

## Consequences

The existing 27 parser tests, written against the real sample file and the official SDK's output,
passed unchanged against the new decoder. That is the evidence this is correct — not a claim about
the code, but the same assertions producing the same 54 steps, the same repeat expansion, the same
millisecond-to-second conversions and the same non-ASCII notes.

One dependency removed, and the same decoder now runs on all three platforms.

We own FIT protocol handling. The decoder deliberately ignores what a workout file never uses —
64-bit integers, developer fields, compressed timestamp headers are read past rather than decoded.
A file using features outside that scope would need the decoder extended.
