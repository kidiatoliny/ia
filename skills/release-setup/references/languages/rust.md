# Rust

## Manifest
- `Cargo.toml`
- `version` field required

## Test command
- `cargo test --all-features`

## Setup steps (workflow)
```yaml
      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable

      - name: Cache cargo
        uses: Swatinem/rust-cache@v2
```

## Version bump
Ask user. If on:

```yaml
      - name: Bump Cargo.toml version
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          sed -i.bak -E "0,/^version = \".*\"/{s/^version = \".*\"/version = \"${VERSION}\"/}" Cargo.toml
          rm Cargo.toml.bak
          cargo update --workspace --offline 2>/dev/null || true
```

For workspace projects, bump root + all members — ask user which members.

## MANIFEST_FILES in commit
`Cargo.toml Cargo.lock`
