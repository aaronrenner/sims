defmodule Mix.Tasks.Sims.Gen.BasicHttp do
  use Igniter.Mix.Task

  @example "mix sims.gen.basic_http MySimulator"

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
      composes: [],
      # `OptionParser` schema
      schema: [
        include_tests: :boolean
      ],
      # Default values for the options in the `schema`
      defaults: [
        include_tests: false
      ],
      # CLI aliases
      aliases: [],
      # A list of options in the schema that are required
      required: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    sim_base_name = igniter.args.positional.name
    sim_base_module_name = Igniter.Project.Module.module_name(igniter, sim_base_name)

    igniter
    |> Igniter.Project.Test.ensure_test_support()
    |> Igniter.assign(:sim_namespace, sim_base_module_name)
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
        sim_namespace = igniter.assigns.sim_namespace
        module = :"#{sim_base_module_name}Test"

        igniter
        |> Igniter.copy_template(
          Path.join(base_template_path(), "simulator_test.exs.eex"),
          Igniter.Project.Module.proper_location(igniter, module, :test),
          module: inspect(module),
          sim_namespace: inspect(sim_namespace),
          sim_namespace_basename: sim_namespace |> Module.split() |> List.last()
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
    sim_namespace = igniter.assigns.sim_namespace
    module = Module.concat(sim_namespace, child_module_name)

    Igniter.copy_template(
      igniter,
      Path.join(base_template_path(), template_path),
      Igniter.Project.Module.proper_location(igniter, module, :test_support),
      module: inspect(module),
      sim_namespace: inspect(sim_namespace)
    )
  end

  defp base_template_path do
    Application.app_dir(:sims, "priv/templates/sims.gen.basic_http")
  end
end
