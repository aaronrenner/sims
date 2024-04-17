defmodule MyApp.BasicSimulator do
  @moduledoc """
  Simulator for a basic HTTP Server
  """
  alias MyApp.BasicSimulator.PortCache
  alias MyApp.BasicSimulator.WebServer
  alias MyApp.BasicSimulator.StateServer

  @type t :: pid
  @type route_id :: atom

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
  def start_link(opts) do
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
