defmodule MyApp.BasicSimulator.State do
  @moduledoc false

  @type t :: map()

  @spec new() :: t
  def new do
    %{}
  end
end
