---
name: ui-ux-principles
description: Foundational UI design principles (visual hierarchy, spacing, typography, component states) and efficient UX rules (fewer steps, immediate feedback, optimistic UI, sensible defaults). Use when designing, building, or reviewing any user interface or user flow.
---

# UI Principles & Efficient UX

## Visual Hierarchy

- One primary action per screen; it gets the strongest visual weight (filled primary button). Secondary = outline/ghost; destructive = separated and de-emphasized until confirmed.
- Size + weight + contrast + position signal importance — use them consistently, not decoratively.
- One `<h1>` per page; heading levels mirror content structure, not styling needs.
- Group related items by proximity; separation by whitespace before borders, borders before boxes.

## Spacing

- 4px base grid; scale: 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64.
- Related elements closer than unrelated ones (label near its field, far from the previous field).
- More breathing room beats denser layout; when a screen feels crowded, remove or group before shrinking.
- Consistent page gutters: `px-4 sm:px-6 lg:px-8`.

## Typography

- One typeface family is enough; two max (UI + mono/display).
- Scale with clear jumps: 12 (labels) / 14 (secondary) / 16 (body) / 18–20 (subheads) / 24–36 (headings).
- Body line-height ~1.5; headings ~1.2. Line length 45–75 characters.
- Weight over size for inline emphasis; never underline non-links.

## Component States — design all of them

Every interactive/data component ships with:

| State            | Requirement                                                                          |
| ---------------- | ------------------------------------------------------------------------------------ |
| Default          | Baseline                                                                             |
| Hover / Focus    | Visible change; focus meets contrast (see a11y-wcag)                                 |
| Active / Pressed | Tactile feedback                                                                     |
| Disabled         | Visually muted AND non-interactive; explain why when non-obvious                     |
| Loading          | Skeleton for content areas, spinner+label for actions; button disables during submit |
| Empty            | Message + the action that fills it ("No projects yet — Create one")                  |
| Error            | What failed + how to recover; never a dead end                                       |

## Efficient UX Rules

1. **Fewer steps**: every added click/field/screen loses users. Ask only for what the current task needs; defer the rest.
2. **Immediate feedback**: every action acknowledges within 100ms (visual state change), shows progress past 1s.
3. **Optimistic UI** for high-success actions (favorite, toggle, reorder): apply instantly, reconcile in background, roll back with a notice on failure.
4. **Sensible defaults**: preselect the choice 80% of users make; remember prior choices; never make users re-enter known data.
5. **Forgiving input**: accept paste with spaces, both date formats, trailing whitespace — normalize, don't reject.
6. **Undo over confirm** for reversible actions (toast with Undo); confirmation dialogs only for the irreversible, and make them specific ("Delete 'Q3 Report'?" not "Are you sure?").
7. **Progressive disclosure**: advanced options behind "More", not deleted and not all visible.
8. **Preserve work**: drafts survive navigation and reload; warn before discarding unsaved changes.
9. **Direct manipulation**: edit-in-place beats edit-page where feasible.
10. **Speed is UX**: skeletons over spinners, cached data shown immediately then revalidated.

## Layout Patterns

- Mobile-first; content determines breakpoints more than devices do.
- Cards for scannable heterogeneous collections; tables for comparable data; lists for simple sequences.
- Sticky primary action on long mobile forms.
- Max content width ~1280px; reading columns ~720px.

## Review Checklist

- [ ] Single clear primary action per screen
- [ ] All component states designed (7 above)
- [ ] Spacing on the scale, hierarchy by grouping
- [ ] Flows minimal: no step, field, or confirmation that can be removed
- [ ] Feedback within 100ms for every interaction
- [ ] Empty and error states actionable
