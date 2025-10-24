defmodule Mix.Sims.SwappableConfig do
  @moduledoc false

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
          test_config_adapter: String.t()
        ]

  @spec new(atom(), atom(), new_opts()) :: t
  def new(app_name, project_module_prefix, opts \\ [])
      when is_atom(project_module_prefix) and is_atom(app_name) do
    opts = Keyword.validate!(opts, test_config_adapter: nil)

    test_adapter =
      if test_adapter_name = opts[:test_config_adapter] do
        Igniter.Project.Module.parse(test_adapter_name)
      else
        Module.concat(project_module_prefix, MockAdapter)
      end

    %__MODULE__{
      app_name: app_name,
      namespace: project_module_prefix,
      behaviour: Module.concat(project_module_prefix, Adapter),
      default_adapter: Module.concat(project_module_prefix, DefaultAdapter),
      default_adapter_alias: DefaultAdapter,
      test_adapter: test_adapter
    }
  end
end
