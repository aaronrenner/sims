defmodule Mix.Tasks.Sims.Gen.BasicHttpTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.basic_http", ~w(PaymentGateway))
      |> assert_creates("test/support/payment_gateway_simulator.ex")

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
      |> assert_creates("test/my_app/simulators/payment_gateway_simulator_test.exs")

    diff = diff(igniter)

    assert diff =~ "MyApp.Simulators.PaymentGatewaySimulator"
    assert diff =~ "A Payment Gateway simulator"
  end

  test "when generating with default arguments" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.basic_http",
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
        "sims.gen.basic_http",
        ~w(Simulators.PaymentGateway --include-tests --include-response-stubs)
      )

    diff = diff(igniter)

    assert diff =~ "def trigger_internal_server_errors"
  end

  test "errors when passing a simulator name with invalid characters" do
    assert_raise Mix.Error, ~r/to be a valid module name/, fn ->
      test_project()
      |> Igniter.compose_task("sims.gen.basic_http", ["Foo Bar"])
    end
  end
end
