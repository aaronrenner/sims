# Sims Codebase Guidelines

## Overview
Sims is a code generator for test simulators that mock external services. It provides Mix tasks to generate boilerplate code for HTTP simulators with basic or CRUD functionality.

## Development Conventions

### Project structure
1. Mix tasks used to generate simulators are defined in lib/mix/tasks/sims.gen.<simulator_name>.ex.
  - These mix tasks are created using elixir's igniter package.
2. Templates used with each mix task are stored in priv/templates/sims.gen.<simulator_name>/
  - These templates are written in EEX and used to generate modules and functions for each simulator
3. Shared struct modules used within the eex templates are in lib/mix/sims/*. When making changes, ensure the field on the struct exists.

### Testing
1. Basic unit tests are stored in tests/mix/tasks/<simulator_name>_test.exs
  - These tests use functions from Igniter.Test to verify the appropriate files are created with the desired output.
2. Integration tests are in a separate elixir project in the integration_tests folder.
  - These tests execute the code generators and run the tests using the `mix_run!/2` helper
  - These tests are stored in test/sims/<simulator_name>_test.exs
  - All commands to mix sims.gen.<simulator_name> should include the --include-tests option so tests are generated.

## AI Tooling
- Use the search_package_docs tool to lookup information about specific libraries
- Use the get_package_location tool to read the source code of specific files