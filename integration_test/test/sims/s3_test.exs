defmodule Sims.Integration.S3Test do
  use ExUnit.Case, async: true

  import Sims.Integration.GeneratedAppHelpers

  @tag :tmp_dir
  test "works with a generated project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(~w(sims.gen.s3 --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)

    paths = list_project_files(app_path)

    assert "test/support/s3_simulator.ex" in paths
    assert "test/sample_app/s3_simulator_test.exs" in paths
  end
end
