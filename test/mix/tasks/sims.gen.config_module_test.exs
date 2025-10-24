defmodule Mix.Tasks.Sims.Gen.ConfigModuleTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  test "generates a config module" do
    # generate a test project
    test_project(app_name: :my_app)
    # run our task
    |> Igniter.compose_task("sims.gen.config_module", [])
    |> assert_has_patch("lib/my_app/config.ex", """
      |  defp adapter do
      |    Application.get_env(:my_app, :config_adapter, DefaultAdapter)
      |  end
    """)
    |> assert_creates("lib/my_app/config/adapter.ex")
    |> assert_creates("lib/my_app/config/default_adapter.ex")
    |> assert_has_patch("test/test_helper.exs", """
    + |Mox.defmock(MyApp.Config.MockAdapter, for: MyApp.Config.Adapter)
    + |Application.put_env(:my_app, :config_adapter, MyApp.Config.MockAdapter)
    """)
    |> assert_has_patch("mix.exs", """
    + |     {:mox, "~> 1.0", only: :test}
    """)
  end

  test "allows overriding the test adapter module" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task("sims.gen.config_module", ~w(--test-config-adapter MyApp.ConfigMock))
    |> assert_has_patch("test/test_helper.exs", """
    + |Mox.defmock(MyApp.ConfigMock, for: MyApp.Config.Adapter)
    + |Application.put_env(:my_app, :config_adapter, MyApp.ConfigMock)
    """)
  end

  test "allows overriding the config module name" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task("sims.gen.config_module", ~w(--config-module MyApp.CustomConfig))
    |> assert_creates("lib/my_app/custom_config.ex", """
    defmodule MyApp.CustomConfig do
      @moduledoc \"""
      Main configuration module for the application
      \"""

      alias MyApp.CustomConfig.DefaultAdapter

      @behaviour MyApp.CustomConfig.Adapter

      defp adapter do
        Application.get_env(:my_app, :config_adapter, DefaultAdapter)
      end
    end
    """)
    |> assert_creates("lib/my_app/custom_config/adapter.ex", """
    defmodule MyApp.CustomConfig.Adapter do
      @moduledoc false
    end
    """)
    |> assert_creates("lib/my_app/custom_config/default_adapter.ex", """
    defmodule MyApp.CustomConfig.DefaultAdapter do
      @moduledoc false

      @behaviour MyApp.CustomConfig.Adapter
    end
    """)
  end

  test "allows disabling updates to test helper" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.config_module", ~w(--no-update-test-helper))

    diff = diff(igniter)

    refute diff =~ "Mox.defmock(MyApp.Config.MockAdapter, for: MyApp.Config.Adapter)"
    refute diff =~ "Application.put_env(:my_app, :config_adapter, MyApp.Config.MockAdapter)"
  end
end
