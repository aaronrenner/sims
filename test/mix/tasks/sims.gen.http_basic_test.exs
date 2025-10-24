defmodule Mix.Tasks.Sims.Gen.HttpBasicTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.http_basic", ~w(PaymentGateway))
      |> assert_creates("test/support/payment_gateway_simulator.ex")
      |> assert_creates("test/support/simulator_helpers.ex")
      |> assert_creates("lib/my_app/config.ex", """
      defmodule MyApp.Config do
        @moduledoc \"""
        Main configuration module for the application
        \"""

        alias MyApp.Config.DefaultAdapter

        @behaviour MyApp.Config.Adapter

        @doc \"""
        Base url for the Payment Gateway server
        \"""
        @impl true
        def payment_gateway_base_url do
          adapter().payment_gateway_base_url()
        end

        defp adapter do
          Application.get_env(:my_app, :config_adapter, DefaultAdapter)
        end
      end
      """)
      |> assert_creates("lib/my_app/config/adapter.ex", """
      defmodule MyApp.Config.Adapter do
        @moduledoc false
        @callback payment_gateway_base_url() :: String.t()
      end
      """)
      |> assert_creates("lib/my_app/config/default_adapter.ex", """
      defmodule MyApp.Config.DefaultAdapter do
        @moduledoc false

        @behaviour MyApp.Config.Adapter
        @impl true
        def payment_gateway_base_url do
          # TODO Configure this in config/config.exs or config/runtime.exs
          Application.fetch_env!(:my_app, :payment_gateway_base_url)
        end
      end
      """)
      |> assert_creates("test/support/simulator_helpers.ex", """
      defmodule MyApp.SimulatorHelpers do
        @moduledoc \"""
        Helper functions for configuring the application to work with test simulators.
        \"""

        import ExUnit.Callbacks

        @doc \"""
        Configure the application to use the Payment Gateway simulator.
        \"""
        def configure_for_payment_gateway_simulator(_tags) do
          sim = start_supervised!(MyApp.PaymentGatewaySimulator)

          base_url = MyApp.PaymentGatewaySimulator.base_url(sim)
          Mox.stub(MyApp.Config.MockAdapter, :payment_gateway_base_url, fn -> base_url end)

          [payment_gateway_simulator: sim]
        end
      end
      """)
      |> assert_has_patch("test/test_helper.exs", """
      + |Mox.defmock(MyApp.Config.MockAdapter, for: MyApp.Config.Adapter)
      + |Application.put_env(:my_app, :config_adapter, MyApp.Config.MockAdapter)
      """)

    diff = diff(igniter)

    assert diff =~ "MyApp.PaymentGatewaySimulator"
    assert diff =~ "A Payment Gateway simulator"
  end

  test "handles namespaced simulator names" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.http_basic",
        ~w(Simulators.PaymentGateway --include-tests)
      )
      |> assert_creates("test/support/simulators/payment_gateway_simulator.ex")
      |> assert_creates("test/my_app/simulators/payment_gateway_simulator_test.exs")

    diff = diff(igniter)

    assert diff =~ "MyApp.Simulators.PaymentGatewaySimulator"
    assert diff =~ "A Payment Gateway simulator"
  end

  test "when generating with default arguments" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.http_basic",
        ~w(Simulators.PaymentGateway)
      )
      |> refute_creates("test/my_app/simulators/payment_gateway_test.exs")

    diff = diff(igniter)

    refute diff =~ "def trigger_internal_server_errors"
    refute diff =~ "response_stubs"
  end

  test "includes response stub functions and tests with --include-response-stubs" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.http_basic",
        ~w(Simulators.PaymentGateway --include-tests --include-response-stubs)
      )

    diff = diff(igniter)

    assert diff =~ "def trigger_internal_server_errors"
  end

  test "does not generate config with --no-include-app-config" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task("sims.gen.http_basic", ~w(PaymentGateway --no-include-app-config))
    |> refute_creates("lib/my_app/config.ex")
    |> refute_creates("lib/my_app/config/adapter.ex")
    |> refute_creates("lib/my_app/config/default_adapter.ex")
  end

  test "allows overriding the test adapter module" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task(
      "sims.gen.http_basic",
      ~w(PaymentGateway --config-test-adapter MyApp.ConfigMock)
    )
    |> assert_has_patch("test/test_helper.exs", """
    + |Mox.defmock(MyApp.ConfigMock, for: MyApp.Config.Adapter)
    + |Application.put_env(:my_app, :config_adapter, MyApp.ConfigMock)
    """)
    |> assert_creates("test/support/simulator_helpers.ex", """
    defmodule MyApp.SimulatorHelpers do
      @moduledoc \"""
      Helper functions for configuring the application to work with test simulators.
      \"""

      import ExUnit.Callbacks

      @doc \"""
      Configure the application to use the Payment Gateway simulator.
      \"""
      def configure_for_payment_gateway_simulator(_tags) do
        sim = start_supervised!(MyApp.PaymentGatewaySimulator)

        base_url = MyApp.PaymentGatewaySimulator.base_url(sim)
        Mox.stub(MyApp.ConfigMock, :payment_gateway_base_url, fn -> base_url end)

        [payment_gateway_simulator: sim]
      end
    end
    """)
  end

  test "errors when passing a simulator name with invalid characters" do
    assert_raise Mix.Error, ~r/to be a valid module name/, fn ->
      test_project()
      |> Igniter.compose_task("sims.gen.http_basic", ["Foo Bar"])
    end
  end
end
