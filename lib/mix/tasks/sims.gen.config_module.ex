defmodule Mix.Tasks.Sims.Gen.ConfigModule do
  use Igniter.Mix.Task

  alias Mix.Sims.CodeGeneration
  alias Mix.Sims.SwappableConfig

  @example "mix sims.gen.config_module"

  @shortdoc "Generate a swappable configuation module"
  @moduledoc """
  #{@shortdoc}

  A centeralized configuration module is helpful so configuration can be swapped
  during async tests via mox.

  ## Example

  ```sh
  #{@example}
  ```
  """

  @template_namespace "sims.gen.config_module"

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
      composes: [],
      # `OptionParser` schema
      schema: [
        config_module: :string,
        test_config_adapter: :string,
        behaviour_module: :string,
        update_test_helper: :boolean
      ],
      # Default values for the options in the `schema`
      defaults: [update_test_helper: true],
      # CLI aliases
      aliases: [],
      # A list of options in the schema that are required
      required: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    config_module =
      if custom_config = igniter.args.options[:config_module] do
        Igniter.Project.Module.parse(custom_config)
      else
        Igniter.Project.Module.module_name(igniter, "Config")
      end

    swappable_config =
      SwappableConfig.new(
        Igniter.Project.Application.app_name(igniter),
        config_module,
        test_config_adapter: igniter.args.options[:test_config_adapter],
        behaviour: igniter.args.options[:behaviour_module]
      )

    igniter
    |> Igniter.assign(:swappable_config, swappable_config)
    |> Igniter.Project.Deps.add_dep({:mox, "~> 1.0", only: :test})
    |> copy_template("config.ex.eex", swappable_config.namespace)
    |> copy_template("config/adapter.ex.eex", swappable_config.behaviour)
    |> copy_template("config/default_adapter.ex.eex", swappable_config.default_adapter)
    |> then(fn igniter ->
      if igniter.args.options[:update_test_helper] do
        Igniter.update_elixir_file(igniter, "test/test_helper.exs", fn zipper ->
          case Igniter.Code.Function.move_to_function_call_in_current_scope(
                 zipper,
                 {Mox, :defmock},
                 2,
                 &Igniter.Code.Function.argument_equals?(&1, 0, swappable_config.test_adapter)
               ) do
            {:ok, _} ->
              {:ok, zipper}

            _ ->
              {:ok,
               Igniter.Code.Common.add_code(
                 zipper,
                 EEx.eval_file(
                   CodeGeneration.find_template_path(@template_namespace, "test_helper.exs.eex"),
                   assigns: [swappable_config: swappable_config]
                 )
               )}
          end
        end)
      else
        igniter
      end
    end)
  end

  defp copy_template(
         igniter,
         template_path,
         module
       )
       when is_atom(module) do
    case Igniter.Project.Module.module_exists(igniter, module) do
      {true, igniter} ->
        igniter

      {false, igniter} ->
        Igniter.copy_template(
          igniter,
          CodeGeneration.find_template_path(@template_namespace, template_path),
          Igniter.Project.Module.proper_location(igniter, module),
          module: module,
          swappable_config: igniter.assigns.swappable_config
        )
    end
  end
end
