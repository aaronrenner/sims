defmodule Mix.Sims.CodeGeneration do
  @moduledoc false

  def parse_module_name(module_name) when is_binary(module_name) do
    Igniter.Project.Module.parse(module_name)
  end

  def parse_module_name(module_name) when is_atom(module_name) do
    module_name
  end

  def find_template_path(namespace, template_path) do
    Enum.find_value(template_paths(), fn
      root ->
        path = Path.join(to_app_source(root, "priv/templates/#{namespace}"), template_path)

        if File.exists?(path), do: path, else: false
    end)
  end

  defp to_app_source(path, source_dir) when is_binary(path),
    do: Path.join(path, source_dir)

  defp to_app_source(app, source_dir) when is_atom(app),
    do: Application.app_dir(app, source_dir)

  defp template_paths, do: [".", :sims]
end
