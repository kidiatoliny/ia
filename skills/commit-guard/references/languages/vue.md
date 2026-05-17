# Vue 3 / Vue SFC adapter

## Detection

- `vue` in `package.json` dependencies, OR staged `*.vue` files.
- TypeScript ≤ Vue: this adapter overrides the TS adapter for `.vue` files; `.ts` files still follow the TS adapter.

## Required commands

Use scripts from `package.json` when present. Fallback defaults:

| Stage      | Command                              |
|------------|--------------------------------------|
| Lint       | `npm run lint` or `eslint . --ext .vue,.ts,.js` |
| Typecheck  | `npm run typecheck` or `vue-tsc --noEmit` |
| Test       | `npm test` or `vitest`                |
| Build      | `npm run build`                       |
| Dead code  | `npx knip` if installed               |

Pnpm and Yarn equivalents fall back automatically.

## Naming

- Components: `PascalCase.vue` for the file. Multi-word names (Vue style guide rule A).
- Composables: `useCamelCase.ts` (e.g. `useUser.ts`, `useFetch.ts`). Always start with `use`.
- Props: `camelCase` in `<script>`, `kebab-case` in template (`<Comp my-prop />`).
- Events emitted: `kebab-case` (`emit('item-selected')`).
- Slots: `kebab-case`.
- Stores (Pinia): `useThingStore`.
- Refs / reactive variables: `camelCase`. Underscore prefix discouraged.

## Public API surface

- Anything `export`ed from `package.json` `main` / `exports`.
- Exported composables from a published package.
- Component public props/events/slots when used cross-package.

## Test detection

For modified `Foo.vue`, expect `Foo.spec.ts` or `Foo.test.ts` next to the file or under `__tests__/`. For composables, expect a matching test in the same dir.

## Common bad patterns to flag

- `<script>` block without `setup` (legacy Options API in new files when the project established `<script setup>` as the convention).
- Direct DOM manipulation inside templates; use refs + lifecycle hooks.
- Watchers that should be `computed`.
- `any` type in `<script lang="ts">`.
- Inline event handlers with heavy logic (move to method/composable).
- Multiple unrelated concerns in one SFC (data fetch + form + list + modal).
- Missing `<script setup lang="ts">` when project standard requires TS.
- Tailwind v4 deprecated utilities.

## Vue-specific composition rules

- **Always abstract reusable logic into composables.** Same triggers as React hooks:
  - Two or more components reading the same `window`/`document` event listener (resize, scroll, keydown, visibility).
  - Local-storage / session-storage sync.
  - Async fetch + loading + error state.
  - Debounce, throttle, copy-to-clipboard, hover, focus, click-outside, hotkey logic appearing in ≥ 2 components.
- **Reference catalogs (use in this order):**
  1. **VueUse** — https://vueuse.org — community-standard collection (`useDebounceFn`, `useEventListener`, `useLocalStorage`, `useIntersectionObserver`, `useClipboard`, `useMagicKeys`, `useMediaQuery`, `useFetch`, `useDark`, `useOnline`, `useScroll`, etc.). Prefer this before writing custom.
  2. **usehooks.com** — https://usehooks.com — when porting React patterns, use these implementations as the reference contract and adapt to Vue's Composition API.
- Composable file convention: `src/composables/useThing.ts`, named export `useThing`. Return a reactive object: `{ value, setValue, isLoading }` or a tuple. Match VueUse return-shape idioms.
- Pinia for global state; `provide`/`inject` for tree-scoped data.
- shadcn-vue primitives or Radix Vue.
- Lucide icons (no emoji icons).

## File length

Vue SFC: 320 soft / 400 hard. Templates inflate quickly with prop bindings and `v-for` blocks. Extract subcomponents into sibling `.vue` files and logic into composables before the cap.

## Exempt directories

- shadcn-vue / radix-vue vendored primitives (`src/components/ui/**` or `components.json` aliases.ui path).
- Codegen output (`__generated__/`, GraphQL codegen, OpenAPI codegen).
- Lockfiles, build artifacts.
