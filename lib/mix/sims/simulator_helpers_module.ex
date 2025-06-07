defmodule Mix.Sims.SimulatorHelpersModule do
  @moduledoc false

  defstruct module: nil

  def new(module) when is_atom(module) do
    %__MODULE__{module: module}
  end
end
