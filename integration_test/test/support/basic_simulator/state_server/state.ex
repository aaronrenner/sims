defmodule MyApp.BasicSimulator.StateServer.State do
  @moduledoc false

  @type t :: map()

  @spec new() :: t
  def new do
    %{}
  end
end