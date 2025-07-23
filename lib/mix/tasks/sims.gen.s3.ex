defmodule Mix.Tasks.Sims.Gen.S3 do
  use Igniter.Mix.Task

  alias Mix.Sims.Simulator

  @example "mix sims.gen.s3"

  @shortdoc "Generates a S3 simulator"
  @moduledoc """
  #{@shortdoc}

  Generate the boilerplate for a S3 simulator.

  ## Example

  ```bash
  #{@example}
  ```
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
      positional: [],
      # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
      # This ensures your option schema includes options from nested tasks
      composes: [
        "sims.gen.config_module"
      ],
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
    simulator =
      Simulator.new(
        Igniter.Project.Module.module_name_prefix(igniter),
        "S3"
      )

    igniter
    |> Igniter.Project.Test.ensure_test_support()
    |> Igniter.assign(:simulator, simulator)
    |> copy_simulator_template("simulator.ex.eex")
    |> copy_simulator_template("simulator/port_cache.ex.eex", PortCache)
    |> copy_simulator_template("simulator/state_server.ex.eex", StateServer)
    |> copy_simulator_template("simulator/state_server/state.ex.eex", StateServer.State)
    |> copy_simulator_template(
      "simulator/state_server/state/bucket.ex.eex",
      StateServer.State.Bucket
    )
    |> copy_simulator_template(
      "simulator/state_server/state/object.ex.eex",
      StateServer.State.Object
    )
    |> copy_simulator_template(
      "simulator/state_server/state/multipart_upload.ex.eex",
      StateServer.State.MultipartUpload
    )
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
          simulator: igniter.assigns.simulator
        )
        |> Igniter.Project.Deps.add_dep({:ex_aws, "~> 2.0"}, append?: true)
        |> Igniter.Project.Deps.add_dep({:ex_aws_s3, "~> 2.0"}, append?: true)
        |> Igniter.Project.Deps.add_dep({:hackney, "~> 1.9"}, append?: true)
        |> Igniter.Project.Deps.add_dep({:sweet_xml, "~> 0.6"}, append?: true)
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
      simulator: igniter.assigns.simulator
    )
  end

  defp base_template_path do
    Application.app_dir(:sims, "priv/templates/sims.gen.s3")
  end
end
