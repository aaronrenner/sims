defmodule Sims.IntegrationTest do
  use ExUnit.Case, async: true
  doctest Sims.Integration

  test "greets the world" do
    assert Sims.Integration.hello() == :world
  end
end
