defmodule Sims.Integration.HttpBasicTest do
  use ExUnit.Case, async: true

  import Sims.Integration.GeneratedAppHelpers

  @tag :tmp_dir
  test "works with a generated project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(~w(sims.gen.http_basic PaymentGateway --include-tests --yes), app_path)
    mix_run!(~w(sims.gen.http_basic Blog --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)

    paths = list_project_files(app_path)

    assert "test/support/blog_simulator.ex" in paths
    assert "test/sample_app/blog_simulator_test.exs" in paths
    assert "test/support/payment_gateway_simulator.ex" in paths
    assert "test/sample_app/payment_gateway_simulator_test.exs" in paths

    assert app_path
           |> Path.join("test/test_helper.exs")
           |> File.read!() == """
           ExUnit.start()
           Mox.defmock(SampleApp.Config.MockAdapter, for: SampleApp.Config.Adapter)
           Application.put_env(:sample_app, :config_adapter, SampleApp.Config.MockAdapter)
           """
  end

  @tag :tmp_dir
  test "works with --include-response-stubs", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(
      ~w(sims.gen.http_basic Blog --include-tests --include-response-stubs --yes),
      app_path
    )

    mix_run!(~w(test), app_path)
  end

  @tag :tmp_dir
  test "works with --no-include-app-config", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    mix_run!(
      ~w(sims.gen.http_basic Blog --include-tests --no-include-app-config --yes),
      app_path
    )

    mix_run!(~w(test), app_path)
  end

  @tag :tmp_dir
  test "uses templates from local project", %{tmp_dir: tmp_dir} do
    app_path = generate_project(tmp_dir)

    File.mkdir_p!(Path.join(app_path, "priv/templates/sims.gen.http_basic"))

    File.write!(
      Path.join(app_path, "priv/templates/sims.gen.http_basic/config_module_function.eex"),
      """
      @doc false
      def <%= @simulator.underscore_name %>_base_url do
        adapter().<%= @simulator.underscore_name %>_base_url()
      end
      """
    )

    File.mkdir_p!(Path.join(app_path, "priv/templates/sims.gen.config_module"))

    File.write!(Path.join(app_path, "priv/templates/sims.gen.config_module/config.ex.eex"), """
    defmodule <%= inspect @module %> do
      @moduledoc false

      alias <%= inspect @swappable_config.default_adapter %>

      @behaviour <%= inspect @swappable_config.behaviour %>

      defp adapter do
       Application.get_env(<%= inspect @swappable_config.app_name %>, :config_adapter, <%= @swappable_config.default_adapter_alias %>)
      end
    end
    """)

    mix_run!(~w(sims.gen.http_basic Blog --include-tests --yes), app_path)
    mix_run!(~w(test), app_path)

    assert File.read!(Path.join(app_path, "lib/sample_app/config.ex")) =~ """
           defmodule SampleApp.Config do
             @moduledoc false

             alias SampleApp.Config.DefaultAdapter

             @behaviour SampleApp.Config.Adapter

             @doc false
             def blog_base_url do
               adapter().blog_base_url()
             end

             defp adapter do
               Application.get_env(:sample_app, :config_adapter, DefaultAdapter)
             end
           end
           """
  end
end
