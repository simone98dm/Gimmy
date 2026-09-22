---
name: unit-testing-vitest
description: Patterns and suite structure for unit testing with Vitest and Vue Test Utils in Vue 3 / Nuxt / TypeScript projects. Use when writing or reviewing unit tests for Pinia stores, composables, Vue components, or utilities — triggers on Vitest, Vue Test Utils, spec.ts, mount, vi.mock, unit test.
---

# Unit Testing with Vitest

## Suite Structure

```
tests/
  unit/
    stores/       ← Pinia store tests
    composables/  ← API composable tests
    components/   ← Vue component tests
    utils/        ← utility function tests
```

File naming: `{name}.spec.ts` (e.g., `useItemStore.spec.ts`). Mirror the source structure.

## Testing Types

| Type | Target | Tooling |
| ---- | ------ | ------- |
| State testing | Pinia stores: initial state, mutations, getters | `setActivePinia(createPinia())` |
| Behavior testing | Components: rendering, events, slots | `mount` from Vue Test Utils |
| Contract testing | Composables: input → output shape, error propagation | mocked `$fetch` |
| Pure-function testing | Utils: input/output tables, edge cases | plain `expect`, `it.each` for tables |

## Pattern: Pinia Store

```ts
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useItemStore } from '~/stores/useItemStore'
import * as itemsApi from '~/composables/useItemsApi'

describe('useItemStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('initializes with empty state', () => {
    const store = useItemStore()
    expect(store.items).toEqual([])
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('loadItems sets loading then populates state', async () => {
    const mockItems = [{ id: '1', name: 'Test Item' }]
    vi.spyOn(itemsApi, 'getItems').mockResolvedValue(mockItems)

    const store = useItemStore()
    const promise = store.loadItems()
    expect(store.loading).toBe(true)

    await promise
    expect(store.items).toEqual(mockItems)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('loadItems sets error on failure', async () => {
    vi.spyOn(itemsApi, 'getItems').mockRejectedValue(new Error('Network error'))

    const store = useItemStore()
    await store.loadItems()

    expect(store.items).toEqual([])
    expect(store.loading).toBe(false)
    expect(store.error).toBeTruthy()
  })
})
```

Cover: initial state, every action's success path, every action's error path, computed/getters.

## Pattern: Composable

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getItems } from '~/composables/useItemsApi'

// Mock $fetch globally
vi.stubGlobal('$fetch', vi.fn())

describe('useItemsApi', () => {
  beforeEach(() => vi.clearAllMocks())

  it('getItems returns typed array', async () => {
    const mockData = [{ id: '1', name: 'Item' }]
    vi.mocked($fetch).mockResolvedValue(mockData)

    const result = await getItems()
    expect(result).toEqual(mockData)
    expect($fetch).toHaveBeenCalledWith('/api/items')
  })

  it('getItems throws on API error', async () => {
    vi.mocked($fetch).mockRejectedValue(new Error('500'))
    await expect(getItems()).rejects.toThrow()
  })
})
```

Cover: happy path with mocked `$fetch`, error propagation, DTO mapping (input → output shape), edge cases (empty arrays, null values).

## Pattern: Vue Component

```ts
import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import ItemCard from '~/components/shared/ItemCard.vue'

const mockItem = { id: '1', name: 'Test Item', subtitle: 'Subtitle' }

describe('ItemCard', () => {
  it('renders name and subtitle', () => {
    const wrapper = mount(ItemCard, { props: { item: mockItem } })
    expect(wrapper.text()).toContain('Test Item')
    expect(wrapper.text()).toContain('Subtitle')
  })

  it('emits favorite event on button click', async () => {
    const wrapper = mount(ItemCard, { props: { item: mockItem } })
    await wrapper.find('[data-testid="favorite-btn"]').trigger('click')
    expect(wrapper.emitted('favorite')).toBeTruthy()
    expect(wrapper.emitted('favorite')![0]).toEqual([mockItem.id])
  })
})
```

Cover: renders with required props, optional props, emits on interaction, conditional rendering (`v-if` states), slot content, prop edge cases.

## Mocking Methods

- `vi.stubGlobal('$fetch', vi.fn())` — Nuxt's global fetch; never make real HTTP calls
- `vi.spyOn(module, 'fn')` — mock composables when testing stores
- `vi.mock('~/module')` — hoisted module mock when the whole module is a dependency
- `vi.useFakeTimers()` — anything time-dependent (debounce, polling, timestamps)
- `vi.mocked(fn)` — typed access to a mock

## Rules

- Use `data-testid` attributes for reliable element selection
- Test behavior, not implementation details
- Each `it()` tests one thing only; the name states the expected behavior
- Always `vi.clearAllMocks()` in `beforeEach`
- `it.each` for input/output tables instead of copy-pasted cases
- Run the suite (`npx vitest run`) after writing tests and report actual results
