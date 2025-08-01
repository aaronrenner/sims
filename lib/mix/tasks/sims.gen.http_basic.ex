defmodule Mix.Tasks.Sims.Gen.HttpBasic do
  use Igniter.Mix.Task

  alias Mix.Sims.Simulator
  alias Mix.Sims.SimulatorHelpersModule

  @example "mix sims.gen.http_basic MySimulator"

  @shortdoc "Generates a basic HTTP simulator"
  @moduledoc """
  #{@shortdoc}

  Generate the boilerplate for a basic HTTP simulator.

  ## Example

  ```bash
  #{@example}
  ```

  ## Options

  * `--include-tests` - Generate tests for this simulator
  * `--include-response-stubs` - Generate helpers for stubbing responses like internal server errors
  * `--no-include-app-config` - Skip generating the app config modules and SimulatorHelpers module for
        pointing switching the app to talk to the simulator
  """

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      # Groups allow for overlapping arguments for tasks by the same author
      # See the generators guide for more.
      group: :sims,
      # *other* dependencies to add
      # i.e `{:foo, "~> 2.0"}`
      adds_deps: [],
      # *other* dependencies to add and call their associated installers, if they exist
      # i.e `{:foo, "~> 2.0"}`
      installs: [],
      # An example invocation
      example: @example,
      # a list of positional arguments, i.e `[:file]`
      positional: [:name],
      # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
      # This ensures your option schema includes options from nested tasks
      composes: [
        "sims.gen.config_module"
      ],
      # `OptionParser` schema
      schema: [
        include_tests: :boolean,
        include_response_stubs: :boolean,
        include_app_config: :boolean
      ],
      # Default values for the options in the `schema`
      defaults: [
        include_tests: false,
        include_response_stubs: false,
        include_app_config: true
      ],
      # CLI aliases
      aliases: [],
      # A list of options in the schema that are required
      required: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    validate_args!(igniter.args)

    simulator =
      Simulator.new(
        Igniter.Project.Module.module_name_prefix(igniter),
        igniter.args.positional.name,
        build_options(igniter.args)
      )

    igniter
    |> Igniter.Project.Test.ensure_test_support()
    |> Igniter.assign(:simulator, simulator)
    |> copy_simulator_template("simulator.ex.eex")
    |> copy_simulator_template("simulator/port_cache.ex.eex", PortCache)
    |> copy_simulator_template("simulator/state_server.ex.eex", StateServer)
    |> copy_simulator_template("simulator/state_server/state.ex.eex", StateServer.State)
    |> copy_simulator_template("simulator/web_server.ex.eex", WebServer)
    |> copy_simulator_template("simulator/web_server/router.ex.eex", WebServer.Router)
    |> copy_simulator_template("simulator/web_server/responses.ex.eex", WebServer.Responses)
    |> Igniter.Project.Deps.add_dep({:bandit, "~> 1.0", only: :test}, append?: true)
    |> Igniter.Project.Deps.add_dep({:plug, "~> 1.13", only: [:dev, :test]}, append?: true)
    |> Igniter.Project.Formatter.import_dep(:plug)
    |> then(fn igniter ->
      if igniter.args.options[:include_app_config],
        do: generate_app_config(igniter),
        else: igniter
    end)
    |> then(fn igniter ->
      if igniter.args.options[:include_tests] do
        module = :"#{igniter.assigns.simulator.namespace}Test"

        igniter
        |> Igniter.copy_template(
          Path.join(base_template_path(), "simulator_test.exs.eex"),
          Igniter.Project.Module.proper_location(igniter, module, :test),
          module: module,
          simulator: igniter.assigns.simulator,
          swappable_config: Map.get(igniter.assigns, :swappable_config),
          simulator_helpers_module: Map.get(igniter.assigns, :simulator_helpers_module)
        )
        |> Igniter.Project.Deps.add_dep({:req, "~> 0.5"}, append?: true)
      else
        igniter
      end
    end)
  end

  defp generate_app_config(igniter) do
    igniter
    |> Igniter.compose_task("sims.gen.config_module")
    |> then(fn igniter ->
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        igniter.assigns.swappable_config.namespace,
        fn zipper ->
          with {:ok, zipper} <-
                 Igniter.Code.Function.move_to_defp(zipper, :adapter, 0, target: :before) do
            {:ok,
             Igniter.Code.Common.add_code(
               zipper,
               EEx.eval_file(
                 Path.join(base_template_path(), "config_module_function.eex"),
                 assigns: [
                   simulator: igniter.assigns.simulator
                 ]
               ),
               placement: :before
             )}
          end
        end
      )
    end)
    |> then(fn igniter ->
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        igniter.assigns.swappable_config.behaviour,
        fn zipper ->
          {:ok,
           Igniter.Code.Common.add_code(
             zipper,
             EEx.eval_file(
               Path.join(base_template_path(), "config_behaviour_callback.eex"),
               assigns: [
                 simulator: igniter.assigns.simulator
               ]
             )
           )}
        end
      )
    end)
    |> then(fn igniter ->
      Igniter.Project.Module.find_and_update_module!(
        igniter,
        igniter.assigns.swappable_config.default_adapter,
        fn zipper ->
          {:ok,
           Igniter.Code.Common.add_code(
             zipper,
             EEx.eval_file(
               Path.join(base_template_path(), "config_default_adapter_function.eex"),
               assigns: [
                 simulator: igniter.assigns.simulator,
                 swappable_config: igniter.assigns.swappable_config
               ]
             )
           )}
        end
      )
    end)
    |> then(fn igniter ->
      module = Igniter.Project.Module.module_name(igniter, "SimulatorHelpers")

      igniter
      |> Igniter.assign(:simulator_helpers_module, SimulatorHelpersModule.new(module))
      |> Igniter.Project.Module.module_exists(module)
      |> case do
        {true, igniter} ->
          igniter

        {false, igniter} ->
          Igniter.copy_template(
            igniter,
            Path.join(base_template_path(), "simulator_helpers_module.ex.eex"),
            Igniter.Project.Module.proper_location(igniter, module, :test_support),
            module: module
          )
      end
      |> Igniter.Project.Module.find_and_update_module!(module, fn zipper ->
        {:ok,
         Igniter.Code.Common.add_code(
           zipper,
           EEx.eval_file(
             Path.join(base_template_path(), "simulator_helpers_functions.eex"),
             assigns: [
               simulator: igniter.assigns.simulator,
               swappable_config: igniter.assigns.swappable_config
             ]
           )
         )}
      end)
    end)
  end

  defp copy_simulator_template(
         igniter,
         template_path,
         child_module_name \\ nil
       ) do
    module = Module.concat(igniter.assigns.simulator.namespace, child_module_name)

    Igniter.copy_template(
      igniter,
      Path.join(base_template_path(), template_path),
      Igniter.Project.Module.proper_location(igniter, module, :test_support),
      module: module,
      simulator: igniter.assigns.simulator
    )
  end

  defp validate_args!(args) do
    simulator_name = args.positional.name

    if not Simulator.valid?(simulator_name) do
      Mix.raise("""
      Expected the simulator, #{inspect(simulator_name)} to be a valid module name
      """)
    end
  end

  defp base_template_path do
    Application.app_dir(:sims, "priv/templates/sims.gen.http_basic")
  end

  defp build_options(%{positional: _positional, options: options}) do
    [
      response_stubs?: Keyword.fetch!(options, :include_response_stubs)
    ]
  end
end
