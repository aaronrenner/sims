defmodule Mix.Tasks.Sims.Gen.S3Test do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task("sims.gen.s3")
    |> assert_creates("test/support/s3_simulator.ex")
  end

  test "generates tests with --include-tests option" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task("sims.gen.s3", ~w(--include-tests))
    |> assert_creates("test/my_app/s3_simulator_test.exs")
  end
end
