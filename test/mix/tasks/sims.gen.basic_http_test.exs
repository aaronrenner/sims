defmodule Mix.Tasks.Sims.Gen.HttpCrudTest do
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
