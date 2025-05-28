defmodule Mix.Sims.Simulator do
  @moduledoc false

  defstruct namespace: nil, alias: nil, human_name: nil

  def valid?(simulator_name) do
    simulator_name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(project_module_name_prefix, simulator_name) do
    namespace = Module.concat(project_module_name_prefix, "#{simulator_name}Simulator")
    alias_atom = namespace |> Module.split() |> List.last() |> Module.concat(nil)

    human_name =
      simulator_name
      |> String.split(".")
      |> List.last()
      |> Macro.underscore()
      |> humanize()

    %__MODULE__{
      namespace: namespace,
      human_name: human_name,
      alias: alias_atom
    }
  end

  defp humanize(string) when is_binary(string) do
    string |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
  end
end
