defmodule Mix.Tasks.Sims.Gen.HttpCrudTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.http_crud", ~w(AddressBook contact contacts))
      |> assert_creates("test/support/address_book_simulator.ex")
      |> assert_creates("test/support/simulator_helpers.ex")
      |> assert_creates("lib/my_app/config.ex", """
      defmodule MyApp.Config do
        @moduledoc \"""
        Main configuration module for the application
        \"""

        alias MyApp.Config.DefaultAdapter

        @behaviour MyApp.Config.Adapter

        @doc \"""
        Base url for the Address Book server
        \"""
        @impl true
        def address_book_base_url do
          adapter().address_book_base_url()
        end

        defp adapter do
          Application.get_env(:my_app, :config_adapter, DefaultAdapter)
        end
      end
      """)
      |> assert_creates("lib/my_app/config/adapter.ex", """
      defmodule MyApp.Config.Adapter do
        @moduledoc false
        @callback address_book_base_url() :: String.t()
      end
      """)
      |> assert_creates("lib/my_app/config/default_adapter.ex", """
      defmodule MyApp.Config.DefaultAdapter do
        @moduledoc false

        @behaviour MyApp.Config.Adapter
        @impl true
        def address_book_base_url do
          # TODO Configure this in config/config.exs or config/runtime.exs
          Application.fetch_env!(:my_app, :address_book_base_url)
        end
      end
      """)
      |> assert_creates("test/support/simulator_helpers.ex", """
      defmodule MyApp.SimulatorHelpers do
        @moduledoc \"""
        Helper functions for configuring the application to work with test simulators.
        \"""

        import ExUnit.Callbacks

        @doc \"""
        Configure the application to use the Address Book simulator.
        \"""
        def configure_for_address_book_simulator(_tags) do
          sim = start_supervised!(MyApp.AddressBookSimulator)

          base_url = MyApp.AddressBookSimulator.base_url(sim)
          Mox.stub(MyApp.Config.MockAdapter, :address_book_base_url, fn -> base_url end)

          [address_book_simulator: sim]
        end
      end
      """)
      |> assert_has_patch("test/test_helper.exs", """
      + |Mox.defmock(MyApp.Config.MockAdapter, for: MyApp.Config.Adapter)
      + |Application.put_env(:my_app, :config_adapter, MyApp.Config.MockAdapter)
      """)

    diff = diff(igniter)

    assert diff =~ "MyApp.AddressBookSimulator"
    assert diff =~ "A Address Book simulator"
  end

  test "handles namespaced simulator names" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.http_crud",
        ~w(Simulators.Blog post posts --include-tests)
      )
      |> assert_creates("test/support/simulators/blog_simulator.ex")

    diff = diff(igniter)

    assert diff =~ "MyApp.Simulators.BlogSimulator"
    assert diff =~ "A Blog simulator"

    # Does not generate response stubs
    refute diff =~ "def trigger_internal_server_errors"
    refute diff =~ "response_stubs"
  end

  test "includes response stubs with --include-response-stubs" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task(
        "sims.gen.http_crud",
        ~w(AddressBook contact contacts --include-response-stubs)
      )
      |> assert_creates("test/support/address_book_simulator.ex")

    diff = diff(igniter)

    assert diff =~ "def trigger_internal_server_errors"
  end

  test "does not generate config with --no-include-app-config" do
    test_project(app_name: :my_app)
    |> Igniter.compose_task(
      "sims.gen.http_crud",
      ~w(AddressBook contact contacts --no-include-app-config)
    )
    |> refute_creates("lib/my_app/config.ex")
    |> refute_creates("lib/my_app/config/adapter.ex")
    |> refute_creates("lib/my_app/config/default_adapter.ex")
  end

  test "errors when passing a simulator name with invalid characters" do
    assert_raise Mix.Error, ~r/to be a valid module name/, fn ->
      test_project()
      |> Igniter.compose_task("sims.gen.http_crud", ["Foo Bar", "bar", "bars"])
    end
  end

  test "errors when passing a model name with invalid characters" do
    assert_raise Mix.Error, ~r/to be a valid module name/, fn ->
      test_project()
      |> Igniter.compose_task("sims.gen.http_crud", [
        "AddressBook",
        "personal contact",
        "personal contacts"
      ])
    end
  end
end
