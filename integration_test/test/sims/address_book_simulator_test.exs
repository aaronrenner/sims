defmodule Sims.Integration.AddressBookSimulatorTest do
  use ExUnit.Case, async: true

  alias MyApp.AddressBookSimulator

  test "simulator starts successfully" do
    sim = AddressBookSimulator.open()
    req = build_req(sim)

    response = Req.get!(req, url: "/status")

    assert response.body == "Up!"
    assert response.status == 200
  end

  test "allows for closing and reopening a connection" do
    sim = AddressBookSimulator.open()
    req = build_req(sim)

    AddressBookSimulator.down(sim)

    assert {:error, %Req.TransportError{reason: :econnrefused}} =
             Req.request(req, url: "/status")

    AddressBookSimulator.up(sim)

    assert Req.get!(req, url: "/status").status == 200
  end

  test "requires an API token" do
    sim = AddressBookSimulator.open()
    {:ok, account} = AddressBookSimulator.create_account(sim)
    req = build_req(sim)

    assert Req.get!(req, url: "/contacts").status == 401

    resp = req |> attach_account_auth(account) |> Req.get!(url: "/contacts")

    assert resp.status == 200
    assert %{"contacts" => []} = resp.body
  end

  describe "simulator business logic" do
    test "contact crud" do
      sim = AddressBookSimulator.open()
      {:ok, account} = AddressBookSimulator.create_account(sim)
      req = sim |> build_req() |> attach_account_auth(account)

      assert resp =
               Req.post!(req,
                 url: "/contacts",
                 json: %{"first_name" => "Joe", "last_name" => "Smith"}
               )

      assert resp.status == 201
      assert %{"id" => id, "first_name" => "Joe", "last_name" => "Smith"} = resp.body

      assert %{status: 200, body: body} = Req.get!(req, url: "/contacts/#{id}")
      assert %{"id" => ^id, "first_name" => "Joe", "last_name" => "Smith"} = body

      assert %{status: 200, body: body} = Req.get!(req, url: "/contacts")

      assert %{"contacts" => [%{"id" => ^id, "first_name" => "Joe", "last_name" => "Smith"}]} =
               body

      assert %{status: 200, body: body} =
               Req.patch!(req, url: "/contacts/#{id}", json: %{"first_name" => "Jim"})

      assert %{"id" => ^id, "first_name" => "Jim", "last_name" => "Smith"} = body

      assert %{status: 204} = Req.delete!(req, url: "/contacts/#{id}")

      assert %{status: 404} = Req.get!(req, url: "/contacts/#{id}")

      assert %{status: 404} =
               Req.patch!(req, url: "/contacts/#{id}", json: %{"first_name" => "Jim"})

      assert %{status: 404} = Req.delete!(req, url: "/contacts/#{id}")

      assert %{status: 200, body: %{"contacts" => []}} = Req.get!(req, url: "/contacts")
    end

    test "contacts are returned in the order they are inserted" do
      sim = AddressBookSimulator.open()
      {:ok, account} = AddressBookSimulator.create_account(sim)
      req = sim |> build_req() |> attach_account_auth(account)

      AddressBookSimulator.create_contact(sim, account.id, first_name: "Contact 1")
      AddressBookSimulator.create_contact(sim, account.id, first_name: "Contact 2")
      AddressBookSimulator.create_contact(sim, account.id, first_name: "Contact 3")

      assert %{status: 200, body: body} = Req.get!(req, url: "/contacts")

      assert get_in(body, ["contacts", Access.all(), "first_name"]) ==
               ["Contact 1", "Contact 2", "Contact 3"]
    end

    test "contacts are separated by account" do
      sim = AddressBookSimulator.open()
      {:ok, account_1} = AddressBookSimulator.create_account(sim)
      AddressBookSimulator.create_contact(sim, account_1.id, first_name: "Contact")
      account_1_req = sim |> build_req() |> attach_account_auth(account_1)

      {:ok, account_2} = AddressBookSimulator.create_account(sim)
      account_2_req = sim |> build_req() |> attach_account_auth(account_2)

      assert %{status: 200, body: %{"contacts" => [_]}} =
               Req.get!(account_1_req, url: "/contacts")

      assert %{status: 200, body: %{"contacts" => []}} = Req.get!(account_2_req, url: "/contacts")
    end
  end

  describe "triggering errors" do
    test "globally" do
      sim = AddressBookSimulator.open()
      req = build_req(sim)

      AddressBookSimulator.trigger_internal_server_errors(sim, :all)

      assert Req.get!(req, url: "/contacts").status == 500
      assert Req.get!(req, url: "/status").status == 500
      assert Req.get!(req, url: "/contacts/abc123").status == 500

      AddressBookSimulator.clear_triggered_responses(sim)

      assert Req.get!(req, url: "/status").status == 200
      assert Req.get!(req, url: "/contacts").status == 401
    end

    test "per endpoint" do
      sim = AddressBookSimulator.open()
      {:ok, account} = AddressBookSimulator.create_account(sim)
      req = sim |> build_req() |> attach_account_auth(account)

      AddressBookSimulator.trigger_internal_server_errors(sim, :create_contact)

      assert %{status: 500} =
               Req.post!(req,
                 url: "/contacts",
                 json: %{"first_name" => "Joe", "last_name" => "Smith"}
               )

      assert %{status: 200, body: %{"contacts" => []}} = Req.get!(req, url: "/contacts")

      AddressBookSimulator.trigger_invalid_responses(sim, :list_contacts)

      assert %{status: 200, body: "Invalid"} = Req.get!(req, url: "/contacts")
    end
  end

  defp build_req(sim) do
    Req.new(base_url: AddressBookSimulator.base_url(sim), retry: false)
  end

  defp attach_account_auth(req, account) do
    Req.Request.merge_options(req, auth: {:basic, "#{account.id}:#{account.token}"})
  end
end
