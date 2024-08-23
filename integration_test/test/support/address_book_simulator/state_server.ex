defmodule MyApp.AddressBookSimulator.StateServer do
  @moduledoc false

  use Agent

  alias MyApp.AddressBookSimulator.StateServer.State

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> State.new() end)
  end

  def get_state(state_server) do
    Agent.get(state_server, & &1)
  end

  def create_account(state_server) do
    Agent.get_and_update(state_server, fn state ->
      case State.create_account(state) do
        {:ok, {account, state}} -> {{:ok, account}, state}
      end
    end)
  end

  def fetch_account_from_credentials(server, account_id, auth_token) do
    server
    |> get_state()
    |> State.fetch_account_from_credentials(account_id, auth_token)
  end

  def create_contact(state_server, account_id, fields) do
    Agent.get_and_update(state_server, fn state ->
      case State.create_contact(state, account_id, fields) do
        {:ok, {contact, state}} -> {{:ok, contact}, state}
      end
    end)
  end

  def fetch_contact(server, account_id, contact_id) do
    server
    |> get_state()
    |> State.fetch_contact(account_id, contact_id)
  end

  def list_contacts(server, account_id) do
    server
    |> get_state()
    |> State.list_contacts(account_id)
  end

  def update_contact(state_server, account_id, contact_id, fields) do
    Agent.get_and_update(state_server, fn state ->
      case State.update_contact(state, account_id, contact_id, fields) do
        {:ok, {contact, state}} -> {{:ok, contact}, state}
        {:error, :not_found} -> {{:error, :not_found}, state}
      end
    end)
  end

  def delete_contact(state_server, account_id, contact_id) do
    Agent.get_and_update(state_server, fn state ->
      case State.delete_contact(state, account_id, contact_id) do
        {:ok, state} -> {:ok, state}
        {:error, :not_found} -> {{:error, :not_found}, state}
      end
    end)
  end

  def get_response_stub(server, route_id) do
    server
    |> get_state()
    |> State.get_response_stub(route_id)
  end

  def stub_response(server, route_id, response_id) do
    Agent.update(server, &State.stub_response(&1, route_id, response_id))
  end

  def clear_stubbed_responses(server) do
    Agent.update(server, &State.clear_stubbed_responses(&1))
  end
end
