defmodule Sims do
  @moduledoc """
  `Sims` is a collection of test simulator generators.

  # Testing Philosophy

  Test simulators allow you to mock the outermost boundary of a system with a
  fake implementation that you control. This is an improvement over putting in a
  mock in front of the HTTP layer because:

  1. Your code is tested end to end. By making real HTTP requests, you can test
  handling real errors from your HTTP client instead of returning mock errors of
  what you think might be returned.
  2. We're now able to catch errors coming from HTTP client updates. If the HTTP client starts handling
  3. We're now able to switch the API client and ensure compatibility. We may
  have started off using an API client that worked, but has since gone
  unmaintained or there's a new better option available. By having tests
  exercise the API client so it makes real requests to your test simulator, you
  can swap the API client and ensure the actual requests being made don't
  change. Each API client has some differences, so this will also help you find
  things like how error handling is different between libraries.

  ## Comparison to stubbing individual HTTP reqeuests

  Althought stubbing individual HTTP requests with tools like Bypass may seem
  simpler at first, it quickly runs into problems.

  1. Many times your application make a series of requests to the external
  service, which sets up external state that your application relies up.
  Simulators let you build up that same state so you can ensure your application
  is sending requests in the correct order.
  2. Simulators allow us to write tests that tangentially require the external
  service without having to mock it in every case. Instead, our test environment
  can be configured to use the simulator by default and the test can be written
  assuming that external service is functioning. If you want to test the
  external system has an error, you can also trigger that via your simulator

  ## Testing against both simulators and the real service
  TODO

  # Components of testing with simulators

  ## Simulator

  The simulator a standalone module that creates a mock server that the main
  application can make real requests to. As a developer, you can implement as
  much or as little of the application logic that makes sense for your tests.

  Simulators should be started by the individual tests themselves, to ensure the
  each test has its own simulator with test specific state. This will prevent
  one test's state from leaking into another.

  Simulators can also contain an elixir level API for interacting with the
  simulator. This might include functions to create state in the simulator,
  trigger errors, or list requests that the simulator has received. The
  simulator shouldn't be written without knowledge of your application's code or
  testing patterns so it can be easily extracted or reused in other projects.

  ## Centralized Config
  It's critical to have a centralized application config module, so that
  application can be configured to connect to the simulator instead of the main
  service. In order to make this work with ExUnit's async tests, we should use
  [Mox](https://hexdocs.pm/mox/Mox.html) + [the adapter
  pattern](https://aaronrenner.io/2023/07/22/elixir-adapter-pattern.html).

  ## Test Helpers
  The test helpers module ties together your application's code with the
  underlying simulator. The test helper will take care of starting the simulator
  and updating the Application's config to point to the simulator. It may also
  have other niceities that adapt your application's testing patterns to the
  simulator's Elixir API.

  """
end
