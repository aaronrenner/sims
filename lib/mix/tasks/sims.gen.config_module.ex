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

  ## Generated Modules

  This task generates three modules and updates your test helper:

  ### Configuration Module

  The main configuration module (e.g., `YourApp.Config`) acts as the central
  configuration interface for your application. It delegates to the configured
  adapter, which can be swapped at runtime (particularly useful for testing).

  The adapter is retrieved from application config with a key `:config_adapter`,
  falling back to the default adapter in production.

  ### Adapter Behaviour

  The behaviour module (e.g., `YourApp.Config.Adapter`) defines the interface that
  all adapter implementations must follow. You can add callbacks to this module to
  define the functions your configuration needs to support.

  ### Default Adapter

  The default adapter module (e.g., `YourApp.Config.DefaultAdapter`) implements the
  adapter behaviour and is used in production. This is where you'll add your actual
  configuration logic.

  ### Test Mock

  A Mox mock (e.g., `YourApp.Config.MockAdapter`) is defined in `test/test_helper.exs`
  and automatically configured as the adapter for tests. This allows you to mock
  configuration behavior in your tests using Mox's `expect/3` and `stub/3` functions.

  ## Options

  * `--config-namespace` - The module name for the configuration namespace.
    If not provided, defaults to `YourApp.Config`.

  * `--config-behaviour` - The module name for the adapter behaviour that defines
    the interface that adapters must implement. If not provided, a default name
    will be generated based on the config namespace.

  * `--config-default-adapter` - The module name for the default adapter implementation.
    If not provided, a default name will be generated based on the config namespace.

  * `--config-test-adapter` - The module name for the test adapter mock.
    If not provided, a default name will be generated based on the config namespace.

  * `--update-test-helper` - Whether to automatically update `test/test_helper.exs`
    to add the Mox mock definition. Defaults to `true`. Set to `false` with
    `--no-update-test-helper` to skip this step.

  ## Setting Default Values in config/config.exs

  You can configure default values for the options in your `config/config.exs` file
  to avoid having to pass them on the command line every time. These defaults will
  be used when running any `sims.gen.*` tasks.

  Add a configuration block for your application under the `:sims` key:

  ```elixir
  # config/config.exs
  import Config

  config :your_app, :sims,
    config_namespace: "YourApp.Config",
    config_behaviour: "YourApp.Config.Adapter",
    config_default_adapter: "YourApp.Config.DefaultAdapter",
    config_test_adapter: "YourApp.Config.MockAdapter",
    update_test_helper: true
  ```

  Command-line options will override these configured defaults if provided.
  """

  @default_options [update_test_helper: true]

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
        config_namespace: :string,
        config_test_adapter: :string,
        config_behaviour: :string,
        config_default_adapter: :string,
        update_test_helper: :boolean
      ],
      # Don't set these defaults here so they can be overridden by project config. Use @default_options instead.
      defaults: [],
      # CLI aliases
      aliases: [],
      # A list of options in the schema that are required
      required: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    default_options_from_project_config =
      igniter
      |> Igniter.Project.Application.app_name()
      |> Application.get_env(:sims, [])

    # Define default options here so they can be overridden by project config
    options_with_project_defaults =
      @default_options
      |> Keyword.merge(default_options_from_project_config)
      |> Keyword.merge(igniter.args.options)

    config_module =
      if custom_config = options_with_project_defaults[:config_namespace] do
        CodeGeneration.parse_module_name(custom_config)
      else
        Igniter.Project.Module.module_name(igniter, "Config")
      end

    swappable_config =
      SwappableConfig.new(
        Igniter.Project.Application.app_name(igniter),
        config_module,
        test_config_adapter: options_with_project_defaults[:config_test_adapter],
        behaviour: options_with_project_defaults[:config_behaviour],
        default_adapter: options_with_project_defaults[:config_default_adapter]
      )

    igniter
    |> Igniter.assign(:swappable_config, swappable_config)
    |> Igniter.Project.Deps.add_dep({:mox, "~> 1.0", only: :test})
    |> copy_template("config.ex.eex", swappable_config.namespace)
    |> copy_template("config/adapter.ex.eex", swappable_config.behaviour)
    |> copy_template("config/default_adapter.ex.eex", swappable_config.default_adapter)
    |> then(fn igniter ->
      if options_with_project_defaults[:update_test_helper] do
        update_test_helper(igniter, swappable_config)
      else
        igniter
      end
    end)
  end

  defp update_test_helper(igniter, swappable_config) do
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
