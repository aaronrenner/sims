defmodule Sims.Integration.BasicSimulatorTest do
  use ExUnit.Case, async: true

  alias MyApp.BasicSimulator

  test "simulator starts successfully" do
    sim = start_supervised!(MyApp.BasicSimulator)

    req = build_req(sim)

    response = Req.get!(req, url: "/hello")

    assert response.body == "It works!"
    assert response.status == 200
  end

  test "allows for closing and reopening a connection" do
    sim = start_supervised!(MyApp.BasicSimulator)

    req = build_req(sim)

    BasicSimulator.down(sim)

    assert {:error, %Req.TransportError{reason: :econnrefused}} =
             Req.request(req, url: "/hello", method: :get)

    BasicSimulator.up(sim)

    assert Req.get!(req, url: "/hello").status == 200
  end

  defp build_req(sim) do
    Req.new(base_url: BasicSimulator.base_url(sim), retry: false)
  end
end
