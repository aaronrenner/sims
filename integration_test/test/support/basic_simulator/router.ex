defmodule MyApp.BasicSimulator.Router do
  @moduledoc false

  use Plug.Router

  alias MyApp.BasicSimulator.Responses

  # This is needed until https://github.com/PSPDFKit-labs/bypass/pull/125 is merged
  @dialyzer {:nowarn_function, stub_responses: 1}

  def stub_responses(simulator) do
    Bypass.stub(simulator.bypass, :any, :any, fn conn ->
      conn
      |> Plug.Conn.assign(:state_server, simulator.state_server)
      |> call(init([]))
    end)
  end

  plug :match
  plug :fetch_query_params

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :dispatch

  get "/hello" do
    Responses.hello_success(conn)
  end
end
