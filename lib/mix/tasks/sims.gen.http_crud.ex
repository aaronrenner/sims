defmodule Mix.Tasks.Sims.Gen.HttpCrud do
  use Igniter.Mix.Task

  alias Mix.Sims.Model
  alias Mix.Sims.Simulator

  @example "mix sims.gen.http_crud AddressBook contact contacts"

  @shortdoc "Generates a HTTP simulator with CRUD functionality"
  @moduledoc """
  #{@shortdoc}

  Generate the boilerplate for a HTTP simulator with CRUD functionality.

  ## Example

  ```bash
  #{@example}
  ```

  ## Options

  * `--include-tests` - Generate tests for this simulator
  * `--include-response-stubs` - Generate helpers for stubbing responses like internal server errors
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
      positional: [:name, :model_name, :plural_model_name],
      # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
      # This ensures your option schema includes options from nested tasks
      composes: [],
      # `OptionParser` schema
      schema: [
        include_tests: :boolean,
        include_response_stubs: :boolean
      ],
      # Default values for the options in the `schema`
      defaults: [
        include_tests: false,
        include_response_stubs: false
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

    model =
      Model.new(
        igniter.args.positional.model_name,
        igniter.args.positional.plural_model_name
      )

    igniter
    |> Igniter.Project.Test.ensure_test_support()
    |> Igniter.assign(:simulator, simulator)
    |> Igniter.assign(:model, model)
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
      if igniter.args.options[:include_tests] do
        module = :"#{igniter.assigns.simulator.namespace}Test"

        igniter
        |> Igniter.copy_template(
          Path.join(base_template_path(), "simulator_test.exs.eex"),
          Igniter.Project.Module.proper_location(igniter, module, :test),
          module: module,
          simulator: igniter.assigns.simulator,
          model: igniter.assigns.model
        )
        |> Igniter.Project.Deps.add_dep({:req, "~> 0.5"}, append?: true)
      else
        igniter
      end
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
      simulator: igniter.assigns.simulator,
      model: igniter.assigns.model
    )
  end

  defp validate_args!(args) do
    simulator_name = args.positional.name

    if not Simulator.valid?(simulator_name) do
      Mix.raise("""
      Expected the simulator, #{inspect(simulator_name)} to be a valid module name
      """)
    end

    model_name = args.positional.model_name

    if not Model.valid?(model_name) do
      Mix.raise("""
      Expected the simulator, #{inspect(model_name)}, to be a valid module name
      """)
    end
  end

  defp build_options(%{positional: _positional, options: options}) do
    [
      response_stubs?: Keyword.fetch!(options, :include_response_stubs)
    ]
  end

  defp base_template_path do
    Application.app_dir(:sims, "priv/templates/sims.gen.http_crud")
  end
end
