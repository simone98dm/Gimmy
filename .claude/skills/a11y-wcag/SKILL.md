---
name: a11y-wcag
description: Operative WCAG 2.2 AA checklists per component type (forms, modals, navigation, tables, images), ARIA patterns, focus management, contrast values, and screen-reader testing steps. Use when building or auditing any UI for accessibility, WCAG, ARIA, or a11y.
---

# WCAG 2.2 AA — Operative Checklists

Target: WCAG 2.2 Level AA. Semantic HTML first; ARIA only where HTML can't express it.

## Universal (every component)

- [ ] Interactive = native element (`<button>`, `<a href>`, `<input>`) — never `<div @click>`
- [ ] Visible focus indicator, ≥ 3:1 contrast against adjacent colors, never `outline: none` without replacement
- [ ] Text contrast ≥ 4.5:1 (normal), ≥ 3:1 (≥24px or ≥18.7px bold, and UI components/graphics)
- [ ] Target size ≥ 24×24 CSS px (2.5.8); aim 44×44 on touch
- [ ] Information never conveyed by color alone
- [ ] Works at 200% zoom and 320px width without horizontal scroll
- [ ] Respects `prefers-reduced-motion` for non-essential animation
- [ ] Focus not obscured by sticky headers/footers (2.4.11)

## Forms

- [ ] Every input has a programmatic label (`<label for>`); placeholder is never the label
- [ ] Required state: `required` attribute + visible indication (not color-only)
- [ ] Errors: text message associated via `aria-describedby`, `aria-invalid="true"` on the field, focus moved to first invalid field or error summary
- [ ] Error text says how to fix, not just "invalid"
- [ ] Autocomplete attributes on identity fields (`autocomplete="email"`, …) — 1.3.5
- [ ] No cognitive-test CAPTCHA without alternative (3.3.8); don't require re-entering info already provided (3.3.7)
- [ ] Submission feedback announced: success/error in `aria-live` region

## Modals / Dialogs

- [ ] `role="dialog"` + `aria-modal="true"` + `aria-labelledby` pointing at the title
- [ ] Focus moves into the dialog on open (first focusable or the dialog itself)
- [ ] Focus trapped while open; `Escape` closes
- [ ] Focus returns to the triggering element on close
- [ ] Background inert (`inert` attribute or `aria-hidden` on siblings)
- Prefer native `<dialog>` + `showModal()` — trap, Escape, and backdrop come free

## Navigation

- [ ] Landmarks: `<header>`, `<nav aria-label>`, `<main>` (one per page), `<footer>`
- [ ] Skip link as first focusable element → `#main-content`
- [ ] Current page marked with `aria-current="page"`
- [ ] Dropdown menus: trigger has `aria-expanded` + `aria-haspopup`; arrow keys navigate items; Escape closes and returns focus
- [ ] Heading hierarchy: one `<h1>`, no skipped levels

## Tables

- [ ] `<caption>` describing the table
- [ ] `<th scope="col|row">` on all headers; `<thead>`/`<tbody>`
- [ ] Sortable columns: `<button>` inside `<th>`, `aria-sort="ascending|descending|none"` on the `<th>`
- [ ] Never layout-by-table; never data-by-divs

## Images & Icons

- [ ] Informative: descriptive `alt`
- [ ] Decorative: `alt=""` (and `aria-hidden="true"` for inline SVG)
- [ ] Icon-only buttons: `aria-label` on the button, `aria-hidden="true"` on the icon
- [ ] Complex charts: text alternative or data table nearby

## Dynamic Content (SPA)

- [ ] Route change: update `document.title` and announce (e.g. `useHead` + live region)
- [ ] Loading: `aria-busy` on the region or labeled spinner (`role="status"`)
- [ ] Toasts: `role="status"` (info/success) or `role="alert"` (errors); never focus-stealing
- [ ] Content injected on interaction appears in DOM order after its trigger, or focus is managed

## ARIA Rules of Thumb

1. No ARIA beats wrong ARIA — an unlabeled div is bad, a mislabeled one is worse.
2. Don't override native semantics (`role="button"` on `<button>` = noise).
3. Every `aria-labelledby`/`aria-describedby`/`aria-controls` ID must exist.
4. States must update: `aria-expanded`, `aria-selected`, `aria-checked` reflect reality, not initial render.
5. For composite widgets (combobox, tabs, tree, grid) follow the ARIA Authoring Practices Guide pattern exactly — keyboard behavior included.

## Screen-Reader Test Pass (minimum)

1. macOS VoiceOver (Cmd+F5) or NVDA: navigate the page by headings (H), landmarks (D), forms (F).
2. Complete the primary flow keyboard-only: Tab/Shift-Tab/Enter/Space/Arrows/Escape.
3. Verify every control announces name + role + state.
4. Trigger an error and confirm it is announced without hunting.
5. Open/close every modal; confirm focus goes in and comes back.
