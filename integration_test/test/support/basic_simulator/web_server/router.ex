defmodule MyApp.BasicSimulator.WebServer.Router do
  @moduledoc false

  use Plug.Router

  alias MyApp.BasicSimulator.Responses

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
