defmodule Sims.Integration.BasicHttpTest do
  use ExUnit.Case, async: true

  import Sims.Integration.GeneratedAppHelpers

  @tag :tmp_dir
  test "works with a generated project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(~w(sims.gen.basic_http PaymentGateway --include-tests --yes), app_path)
    mix_run!(~w(sims.gen.basic_http Blog --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)

    paths = list_project_files(app_path)

    assert "test/support/blog_simulator.ex" in paths
    assert "test/sample_app/blog_simulator_test.exs" in paths
    assert "test/support/payment_gateway_simulator.ex" in paths
    assert "test/sample_app/payment_gateway_simulator_test.exs" in paths

    assert app_path
           |> Path.join("test/test_helper.exs")
           |> File.read!() == """
           ExUnit.start()
           Mox.defmock(SampleApp.Config.MockAdapter, for: SampleApp.Config.Adapter)
           Application.put_env(:sample_app, :config_adapter, SampleApp.Config.MockAdapter)
           """
  end

  @tag :tmp_dir
  test "works with --include-response-stubs", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(
      ~w(sims.gen.basic_http Blog --include-tests --include-response-stubs --yes),
      app_path
    )

    mix_run!(~w(test), app_path)
  end

  @tag :tmp_dir
  test "works with --no-include-app-config", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(
      ~w(sims.gen.basic_http Blog --include-tests --no-include-app-config --yes),
      app_path
    )

    mix_run!(~w(test), app_path)
  end
end
