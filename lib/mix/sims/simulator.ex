defmodule Mix.Sims.Simulator do
  @moduledoc false

  defstruct namespace: nil, alias: nil, human_name: nil, underscore_name: nil, options: %{}

  def valid?(simulator_name) do
    simulator_name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(project_module_name_prefix, simulator_name, options \\ []) when is_list(options) do
    namespace = Module.concat(project_module_name_prefix, "#{simulator_name}Simulator")
    alias_atom = namespace |> Module.split() |> List.last() |> Module.concat(nil)

    underscore_name =
      simulator_name
      |> String.split(".")
      |> List.last()
      |> Macro.underscore()

    human_name = humanize(underscore_name)

    %__MODULE__{
      namespace: namespace,
      human_name: human_name,
      alias: alias_atom,
      underscore_name: underscore_name,
      options: Map.new(options)
    }
  end

  defp humanize(string) when is_binary(string) do
    string |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
  end
end
