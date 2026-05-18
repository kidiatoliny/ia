# JavaScript / TypeScript

## Manifest
- `package.json`
- `version` field present (npm requires it)

## Test command
- Prefer `npm test` (or `pnpm test` / `yarn test` based on lockfile)
- Lockfile detection:
  - `pnpm-lock.yaml` → pnpm
  - `yarn.lock` → yarn
  - `package-lock.json` or none → npm

## Setup steps (workflow)
```yaml
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: '<pm>'

      - name: Install dependencies
        run: <pm> install --frozen-lockfile
```

Substitute `<pm>` with `npm`/`pnpm`/`yarn`.

Node version: read from `.nvmrc` / `package.json` `engines.node` / default 20.

## Version bump
Ask user. If on:

```yaml
      - name: Bump package.json version
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          node -e "const p=require('./package.json'); p.version='${VERSION}'; require('fs').writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n')"
```

## MANIFEST_FILES in commit
`package.json` (and lockfile if bumped versions changed it — typically no).
