defmodule Mix.Sims.SwappableConfig do
  @moduledoc false

  alias Mix.Sims.CodeGeneration

  defstruct namespace: nil,
            behaviour: nil,
            test_adapter: nil,
            default_adapter: nil,
            default_adapter_alias: nil,
            app_name: nil

  @type t :: %__MODULE__{
          namespace: atom,
          behaviour: atom,
          test_adapter: atom,
          default_adapter: atom,
          default_adapter_alias: atom,
          app_name: atom
        }

  @type new_opts :: [
          test_config_adapter: String.t(),
          behaviour: String.t(),
          default_adapter: String.t()
        ]

  @spec new(atom(), atom(), new_opts()) :: t
  def new(app_name, project_module_prefix, opts \\ [])
      when is_atom(project_module_prefix) and is_atom(app_name) do
    opts = Keyword.validate!(opts, test_config_adapter: nil, behaviour: nil, default_adapter: nil)

    default_adapter =
      if default_adapter_module_name = opts[:default_adapter] do
        CodeGeneration.parse_module_name(default_adapter_module_name)
      else
        Module.concat(project_module_prefix, DefaultAdapter)
      end

    behaviour =
      if behaviour_module_name = opts[:behaviour] do
        CodeGeneration.parse_module_name(behaviour_module_name)
      else
        Module.concat(project_module_prefix, Adapter)
      end

    test_adapter =
      if test_adapter_name = opts[:test_config_adapter] do
        CodeGeneration.parse_module_name(test_adapter_name)
      else
        Module.concat(project_module_prefix, MockAdapter)
      end

    %__MODULE__{
      app_name: app_name,
      namespace: project_module_prefix,
      behaviour: behaviour,
      default_adapter: default_adapter,
      default_adapter_alias: default_adapter |> Module.split() |> List.last(),
      test_adapter: test_adapter
    }
  end
end
