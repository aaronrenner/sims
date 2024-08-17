defmodule MyApp.BasicSimulator.WebServer.Router do
  @moduledoc false

  use Plug.Router

  alias MyApp.BasicSimulator.WebServer.Responses

  plug :match
  plug :fetch_query_params

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :dispatch

  def call(conn, opts) do
    {state_server, opts} = Keyword.pop!(opts, :state_server)

    conn
    |> assign(:state_server, state_server)
    |> super(opts)
  end

  get "/hello" do
    Responses.hello_success(conn)
  end
end
