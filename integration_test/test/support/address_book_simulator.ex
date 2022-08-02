defmodule MyApp.AddressBookSimulator do
  @moduledoc """
  Simulator for a basic HTTP Server
  """
  @opaque t :: %{bypass: Bypass.t(), state_server: pid}

  @type route_id :: :all

  @type account_id :: String.t()
  @type contact_id :: String.t()
  @type api_key :: String.t()
  @type account :: %{id: account_id, api_key: api_key}
  @type contact :: %{id: contact_id, first_name: String.t(), last_name: String.t()}

  alias MyApp.AddressBookSimulator.{Router, StateServer}

  @doc """
  Start up a instance, linked to the current test process
  """
  @spec open() :: t
  def open do
    {:ok, state_server} = StateServer.start_link()

    simulator = %{bypass: Bypass.open(), state_server: state_server}

    Router.stub_responses(simulator)

    simulator
  end

  @doc """
  Close the simulator's TCP socket.
  """
  @spec down(t) :: :ok
  def down(%{bypass: bypass}) do
    Bypass.down(bypass)

    :ok
  end

  @doc """
  Reopen the simulator's TCP socket.
  """
  @spec up(t) :: :ok
  def up(%{bypass: bypass}) do
    Bypass.up(bypass)

    :ok
  end

  @doc """
  Creates a new account and API token
  """
  @spec create_account(t) :: {:ok, account}
  def create_account(sim) do
    StateServer.create_account(sim.state_server)
  end

  @doc """
  Creates a new contact
  """
  @spec create_contact(t, account_id, keyword) :: {:ok, contact}
  def create_contact(sim, account_id, fields) when is_list(fields) do
    StateServer.create_contact(sim.state_server, account_id, fields)
  end

  @doc """
  Causes the server to return internal server errors
  """
  @spec trigger_internal_server_errors(t, route_id) :: :ok
  def trigger_internal_server_errors(sim, route_id \\ :all) do
    StateServer.stub_response(sim.state_server, route_id, :internal_server_error)
  end

  @doc """
  Causes the server to return invalid responses
  """
  @spec trigger_invalid_responses(t, route_id) :: :ok
  def trigger_invalid_responses(sim, route_id \\ :all) do
    StateServer.stub_response(sim.state_server, route_id, :invalid_response)
  end

  @doc """
  Removes stubbed responses from the server
  """
  @spec clear_triggered_responses(t) :: :ok
  def clear_triggered_responses(sim) do
    StateServer.clear_stubbed_responses(sim.state_server)
  end

  @doc """
  Gets the base_url for this instance.
  """
  @spec base_url(t) :: String.t()
  def base_url(sim) do
    "http://localhost:#{sim.bypass.port}"
  end
end
