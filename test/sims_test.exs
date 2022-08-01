defmodule SimsTest do
  use ExUnit.Case
  doctest Sims

  test "greets the world" do
    assert Sims.hello() == :world
  end
end
