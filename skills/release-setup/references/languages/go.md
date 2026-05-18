# Go

## Manifest
- `go.mod`
- No version field; Go modules resolve from tags

## Test command
- `go test ./...`

## Setup steps (workflow)
```yaml
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
```

## Version bump
None. Tags are source of truth.

## MANIFEST_FILES in commit
Empty.
