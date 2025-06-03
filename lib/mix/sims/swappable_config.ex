defmodule Mix.Sims.SwappableConfig do
  @moduledoc false

  defstruct namespace: nil,
            behaviour: nil,
            test_adapter: nil,
            default_adapter: nil,
            default_adapter_alias: nil,
            app_name: nil

  def new(app_name, project_module_prefix)
      when is_atom(project_module_prefix) and is_atom(app_name) do
    %__MODULE__{
      app_name: app_name,
      namespace: project_module_prefix,
      behaviour: Module.concat(project_module_prefix, Adapter),
      default_adapter: Module.concat(project_module_prefix, DefaultAdapter),
      default_adapter_alias: DefaultAdapter,
      test_adapter: Module.concat(project_module_prefix, MockAdapter)
    }
  end
end
