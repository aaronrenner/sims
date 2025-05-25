defmodule Sims.Integration.BasicHttpTest do
  use ExUnit.Case, async: true

  import Sims.Integration.GeneratedAppHelpers

  @tag :tmp_dir
  test "works with a generated project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(~w(sims.gen.basic_http MySimulator --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)

    paths = list_project_files(app_path)

    assert "test/support/my_simulator.ex" in paths
    assert "test/sample_app/my_simulator_test.exs" in paths
  end
end
