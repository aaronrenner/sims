defmodule MyApp.AddressBookSimulator do
  @moduledoc """
  Simulator for an Address Book server
  """
  alias MyApp.AddressBookSimulator.PortCache
  alias MyApp.AddressBookSimulator.StateServer
  alias MyApp.AddressBookSimulator.WebServer

  @type t :: pid

  @type route_id ::
          :all
          | :list_contacts
          | :create_contact
          | :show_contact
          | :update_contact
          | :delete_contact
          | :status

  @type account_id :: String.t()
  @type contact_id :: String.t()
  @type api_key :: String.t()
  @type account :: %{id: account_id, api_key: api_key}
  @type contact :: %{id: contact_id, first_name: String.t(), last_name: String.t()}

  @doc false
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      type: :supervisor
    }
  end

  @doc """
  Start up a instance, linked to the current test process
  """
  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(_opts) do
    with {:ok, sup} <- Supervisor.start_link([], strategy: :rest_for_one) do
      {:ok, _} = Application.ensure_all_started(:bandit)

      {:ok, port_cache} = Supervisor.start_child(sup, PortCache)
      {:ok, state_server} = Supervisor.start_child(sup, StateServer)

      {:ok, _web_server} =
        Supervisor.start_child(
          sup,
          {WebServer, port_cache: port_cache, state_server: state_server}
        )

      {:ok, sup}
    end
  end

  @doc """
  Close the simulator's TCP socket.
  """
  @spec down(t) :: :ok
  def down(sim) do
    sim
    |> lookup_child_process!(WebServer)
    |> ThousandIsland.stop()
  end

  @doc """
  Reopen the simulator's TCP socket.
  """
  @spec up(t) :: :ok
  def up(sim) do
    port_cache = lookup_child_process!(sim, PortCache)
    state_server = lookup_child_process!(sim, StateServer)

    case Supervisor.start_child(
           sim,
           {WebServer, port_cache: port_cache, state_server: state_server}
         ) do
      {:ok, _web_server} -> :ok
      {:error, :already_present} -> Supervisor.restart_child(sim, WebServer)
    end

    :ok
  end

  @doc """
  Creates a new account and API token
  """
  @spec create_account(t) :: {:ok, account}
  def create_account(sim) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.create_account()
  end

  @doc """
  Creates a new contact
  """
  @spec create_contact(t, account_id, keyword) :: {:ok, contact}
  def create_contact(sim, account_id, fields) when is_list(fields) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.create_contact(account_id, fields)
  end

  @doc """
  Causes the server to return internal server errors
  """
  @spec trigger_internal_server_errors(t, route_id) :: :ok
  def trigger_internal_server_errors(sim, route_id \\ :all) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.stub_response(route_id, :internal_server_error)
  end

  @doc """
  Causes the server to return invalid responses
  """
  @spec trigger_invalid_responses(t, route_id) :: :ok
  def trigger_invalid_responses(sim, route_id \\ :all) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.stub_response(route_id, :invalid_response)
  end

  @doc """
  Removes stubbed responses from the server
  """
  @spec clear_triggered_responses(t) :: :ok
  def clear_triggered_responses(sim) do
    sim
    |> lookup_child_process!(StateServer)
    |> StateServer.clear_stubbed_responses()
  end

  @doc """
  Gets the base_url for this instance.
  """
  @spec base_url(t) :: String.t()
  def base_url(sim) do
    port =
      sim
      |> lookup_child_process!(PortCache)
      |> PortCache.get()

    "http://localhost:#{port}"
  end

  defp lookup_child_process!(sup, id) do
    {^id, pid, _, _} =
      sup
      |> Supervisor.which_children()
      |> List.keyfind!(id, 0)

    pid
  end
end
