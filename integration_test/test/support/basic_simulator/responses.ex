defmodule MyApp.BasicSimulator.Responses do
  @moduledoc false

  import Plug.Conn

  def hello_success(conn) do
    conn
    |> send_resp(200, "It works!")
  end
end
