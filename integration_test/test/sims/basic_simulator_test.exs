defmodule Sims.Integration.BasicSimulatorTest do
  use ExUnit.Case, async: true

  import Sims.Integration.GeneratedAppHelpers

  @tag :tmp_dir
  test "works with a generated project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(~w(sims.gen.basic_simulator MySimulator --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)
  end
end
