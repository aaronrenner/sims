# AGENTS.md

## Workflow

- Use `origin/master` as the comparison base for this workspace.
- Prefer `rg` / `rg --files` for code search.
- Keep generator changes aligned with the existing Igniter/template pattern:
  - task code in `lib/mix/tasks/`
  - templates in `priv/templates/sims.gen.<name>/`
  - generator tests in `test/mix/tasks/`
  - generated-app integration tests in `integration_test/test/sims/`

## Verification

- Run `mix deps.get` in the repo root if deps are missing.
- Run `mix deps.get` separately in `integration_test/` before integration tests if needed.
- For HTTP simulator generator template changes, verify both:
  - `mix test`
  - `cd integration_test && mix test`
- Use `mix format --check-formatted` before finishing.

## Generator Conventions

- When changing emitted simulator code, test through generated-app integration tests, not only generator diff assertions.
- When generated code starts relying on a library feature, update the generator's emitted dependency requirement to the minimum version that provides that feature, and add a generator test assertion for the emitted dependency.
- Match established simulator templates before introducing new abstractions.
- For generated Plug routers that need init opts, follow the current templates:
  `use Plug.Router, copy_opts_to_assign: :init_opts`, an early `:unpack_opts`
  plug, `Keyword.validate!`, and `merge_assigns/2`. Avoid custom `call/2`
  overrides for this.
