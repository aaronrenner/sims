defmodule MyApp.BasicSimulator do
  @moduledoc """
  Simulator for a basic HTTP Server
  """
  @opaque t :: %{bypass: Bypass.t(), state_server: pid}

  alias MyApp.BasicSimulator.{Router, StateServer}

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
  Gets the base_url for this instance.
  """
  @spec base_url(t) :: String.t()
  def base_url(sim) do
    "http://localhost:#{sim.bypass.port}"
  end
end
