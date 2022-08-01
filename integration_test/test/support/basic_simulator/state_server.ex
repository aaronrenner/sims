defmodule MyApp.BasicSimulator.StateServer do
  @moduledoc false

  use Agent

  alias MyApp.BasicSimulator.State

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> State.new() end)
  end

  def get_state(server) do
    Agent.get(server, & &1)
  end
end
