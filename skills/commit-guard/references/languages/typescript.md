# TypeScript / JavaScript / React adapter

## Detection

- `package.json` present, OR staged `*.ts`, `*.tsx`, `*.js`, `*.jsx`.
- React: `react` in `package.json` dependencies.

## Required commands

Use scripts defined in `package.json` when present. Fallback defaults:

| Stage      | Command                              |
|------------|--------------------------------------|
| Lint       | `npm run lint` or `eslint .`          |
| Typecheck  | `npm run typecheck` or `tsc --noEmit` |
| Test       | `npm test` or `vitest` / `jest`       |
| Build      | `npm run build`                       |
| Dead code  | `npx knip` if installed, else `tsc --noUnusedLocals --noUnusedParameters` |

Pnpm and Yarn equivalents fall back automatically.

## Naming

- Types/Interfaces/Classes/Enums: `PascalCase`.
- Functions/Methods/Variables: `camelCase`.
- React components: `PascalCase` (function or class).
- Hooks: `useCamelCase`.
- Constants: `UPPER_SNAKE_CASE` for true compile-time constants; `camelCase` for runtime config.
- File names:
  - Components: `PascalCase.tsx`.
  - Hooks: `useCamelCase.ts`.
  - Libs/utils: `kebab-case.ts` or project consistent.
- Named exports only. Default exports forbidden except in files where the framework requires (Next.js page files, Vite entrypoints).

## Public API surface

- Anything `export`ed from a `package.json` `main`/`exports` entry.
- For apps: HTTP API routes, props of exported components consumed by other packages in a monorepo.
- Type declarations in `.d.ts` published as types.

## Test detection

For modified `foo.ts`, expect `foo.test.ts` or `foo.spec.ts` change in the same directory or under `__tests__/`. For components `Foo.tsx`, expect `Foo.test.tsx` or component-paired story update (if Storybook is part of the test contract).

## Common bad patterns to flag

- `any` in source (use `unknown` + narrowing).
- `// @ts-ignore` (use `// @ts-expect-error` with reason, or fix the type).
- `console.log` / `console.warn` / `console.error` in staged code unless it's an intentional logger.
- Default exports of components when project rule is named exports.
- React: inline arrow function props that recreate every render in hot paths (component renders → child re-renders cost > useCallback cost).
- React: `useEffect` with missing dependency array.
- React: state derived from props without memoization in heavy components.
- Tailwind v4 deprecated utilities: `bg-opacity-*`, `flex-shrink-*`, `overflow-ellipsis`.
- `as` casts that hide real type errors.
- Top-level `await` outside ESM contexts.
- Unused imports / variables (TS already detects with `noUnusedLocals`).
- Forms without Zod or RHF validation (project-dependent).
- Direct DOM manipulation in React components.

## React-specific

- Smart vs Dumb components; components ≤ 320 soft / 400 hard cap (TSX inflates fast due to JSX).
- **Always abstract reusable logic into custom hooks**. Patterns that MUST move into a hook:
  - Two or more components doing the same `useEffect` subscription (resize, scroll, online/offline, intersection, mutation observer, theme, idle, document visibility).
  - Any component owning local-storage / session-storage read+write+sync.
  - Any component that mixes async fetch + loading + error state inline.
  - Any component with a controllable form field used in more than one place (debounce, throttle, copy-to-clipboard, hover, focus, click-outside, hotkey).
  - Repeated `useState` + handler pair used in ≥ 2 sites.
- **Reference catalog: https://usehooks.com** — before writing a custom hook from scratch, check usehooks.com for a known-good implementation of the pattern (useDebounce, useClickOutside, useIntersectionObserver, useLocalStorage, useEventListener, useCopyToClipboard, useHover, useIdle, useKeyPress, useMediaQuery, useOnScreen, useScript, useThrottle, useToggle, useWindowSize, useDarkMode, useFetch). Adapt to project conventions; don't reinvent.
- Hook file convention: `src/hooks/useThing.ts`, named export `useThing`, return tuple `[value, setter]` or object — match React community idioms.
- Zustand for global state / localStorage; Context for shared per-tree data.
- shadcn/ui primitives.
- Lucide icons (no emoji icons).
- React 19 features: prefer `useEffectEvent`, `Activity`, `use`, ref cleanup over older patterns.
- Inertia (when present): lowercase page names, Wayfinder for navigation, minimal page props.

## File length

TS/JS plain: 250 soft / 300 hard. TSX/JSX: 320 soft / 400 hard. Component files frequently grow via inline subcomponents — split inline subcomponents into sibling files before the cap. Extract hook logic from the component as soon as the inline `useEffect` body grows past 12 lines or any logic block repeats in another component.

## Exempt directories (auto-detected)

Skip all rule checks on:

- **shadcn/ui scaffolds** — read `components.json` at repo root. The `aliases.ui` field resolves to a path (default `@/components/ui`). Everything under that resolved path is vendored from shadcn; do not enforce file-length, comments policy, or naming on them. Surface as info only if the user explicitly invokes `/commit-guard` against that path.
- **Codegen output** — `wailsjs/`, `__generated__/`, `*.gen.ts`, `*.generated.ts`, files with the header `/* eslint-disable */` followed by `// @generated`.
- **Lockfiles** — `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`.
- **Vite/Next build output** — `dist/`, `.next/`, `out/`, `build/`.

When `components.json` is absent, default to `src/components/ui/**` if it exists, otherwise no shadcn exemption.
