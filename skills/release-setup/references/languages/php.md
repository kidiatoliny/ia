# PHP

## Manifest
- `composer.json`
- No `version` field by convention; Composer reads tags

## Test command
- Prefer `composer test` if defined in `composer.json` scripts
- Fallback: `vendor/bin/pest` or `vendor/bin/phpunit`

## Defaults

- **PHP version**: read from `composer.json` `require.php` constraint. Default `8.4`.
- **Coverage driver**: always `pcov` (PHP standard for fast coverage; required by `pest --coverage`). Do not use `none`.
- **System packages**: always install `aspell` (peck/typo checkers use it; presence is harmless when not needed).
- **Redis service**: provision automatically when any of:
  - composer test scripts include `--parallel` or cache-dependent tests
  - `CACHE_STORE` / `REDIS_HOST` env appears in `phpunit.xml`, `phpunit.xml.dist`, or test setup
  - any observer/model uses `Cache::tags()` (grep `tags(` under `app/`, `src/`)
  - Laravel project (composer require has `laravel/framework`)

## Setup steps (workflow)

```yaml
      - name: Install system dependencies
        run: sudo apt-get update && sudo apt-get install -y aspell

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          coverage: pcov
          tools: composer:v2

      - name: Install dependencies
        run: composer install --no-interaction --prefer-dist --no-progress
```

## Optional Redis service block

When the detection above triggers, prepend to the job:

```yaml
    services:
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

And inject env on the test step:

```yaml
        env:
          CACHE_STORE: redis
          REDIS_HOST: 127.0.0.1
          REDIS_PORT: 6379
```

## Version bump
None. Tags are source of truth.

## MANIFEST_FILES in commit
Empty.
