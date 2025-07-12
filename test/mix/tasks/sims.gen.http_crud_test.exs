defmodule Mix.Tasks.Sims.Gen.HttpCrudTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  test "generates a simulator" do
    igniter =
      test_project(app_name: :my_app)
      |> Igniter.compose_task("sims.gen.http_crud", ~w(AddressBook contact contacts))
      |> assert_creates("test/support/address_book_simulator.ex")

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
