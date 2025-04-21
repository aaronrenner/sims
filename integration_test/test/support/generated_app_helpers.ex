defmodule Sims.Integration.GeneratedAppHelpers do
  @moduledoc """
  Test helpers for working with generated apps
  """

  def generate_project(tmp_dir) do
    app_root_path = tmp_dir
    integration_test_root_path = Path.expand("../../", __DIR__)

    Path.join(__DIR__, "../../fixtures/sample_app")
    |> File.cp_r!(app_root_path)

    for path <- ~w(mix.lock deps _build) do
      File.cp_r!(
        Path.join(integration_test_root_path, path),
        Path.join(app_root_path, path)
      )
    end

    app_root_path
  end

  def mix_run!(args, app_path, opts \\ [])
      when is_list(args) and is_binary(app_path) and is_list(opts) do
    case mix_run(args, app_path, opts) do
      {output, 0} ->
        output

      {output, exit_code} ->
        raise """
        mix command failed with exit code: #{inspect(exit_code)}

        mix #{Enum.join(args, " ")}

        #{output}

        Options
        cd: #{Path.expand(app_path)}
        env: #{opts |> Keyword.get(:env, []) |> inspect()}
        """
    end
  end

  def mix_run(args, app_path, opts \\ [])
      when is_list(args) and is_binary(app_path) and is_list(opts) do
    System.cmd("mix", args, [stderr_to_stdout: true, cd: Path.expand(app_path)] ++ opts)
  end

  def list_project_files(app_path) do
    app_path
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.map(&String.trim_leading(&1, app_path <> "/"))
    |> Enum.reject(&(String.starts_with?(&1, "_build") || String.starts_with?(&1, "deps")))
  end
end
