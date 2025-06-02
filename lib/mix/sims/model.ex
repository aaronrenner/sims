defmodule Mix.Sims.Model do
  @moduledoc false

  defstruct name: nil, plural: nil

  def valid?(model_name) do
    model_name =~ ~r/^\w*$/
  end

  def new(name, plural_name) do
    %__MODULE__{
      name: name,
      plural: plural_name
    }
  end
end
