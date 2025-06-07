defmodule Mix.Tasks.Sims.Gen.BasicHttpTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.basic_http", ~w(PaymentGateway))
      |> assert_creates("test/support/payment_gateway_simulator.ex")
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
        "sims.gen.basic_http",
        ~w(Simulators.PaymentGateway --include-tests)
      )
      |> assert_creates("test/support/simulators/payment_gateway_simulator.ex")

    diff = diff(igniter)

    assert diff =~ "MyApp.Simulators.PaymentGatewaySimulator"
    assert diff =~ "A Payment Gateway simulator"
  end

  test "errors when passing a simulator name with invalid characters" do
    assert_raise Mix.Error, ~r/to be a valid module name/, fn ->
      test_project()
      |> Igniter.compose_task("sims.gen.basic_http", ["Foo Bar"])
    end
  end
end
