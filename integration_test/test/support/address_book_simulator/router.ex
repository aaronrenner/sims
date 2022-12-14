defmodule MyApp.AddressBookSimulator.Router do
  @moduledoc false

  use Plug.Router

  alias MyApp.AddressBookSimulator.{Responses, StateServer}

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

  plug :return_stubbed_responses
  plug :assign_account_id_from_basic_auth
  plug :require_authentication

  plug :dispatch

  get "/contacts", assigns: %{endpoint_id: :list_contacts} do
    contacts = StateServer.list_contacts(conn.assigns.state_server, conn.assigns.account_id)

    send_json_resp(conn, 200, Responses.render_contacts(contacts))
  end

  post "/contacts", assigns: %{endpoint_id: :create_contact} do
    params = parse_contact_params(conn.params)

    case StateServer.create_contact(conn.assigns.state_server, conn.assigns.account_id, params) do
      {:ok, contact} ->
        send_json_resp(conn, 201, Responses.render_contact(contact))
    end
  end

  get "/contacts/:id", assigns: %{endpoint_id: :show_contact} do
    case StateServer.fetch_contact(
           conn.assigns.state_server,
           conn.assigns.account_id,
           conn.path_params["id"]
         ) do
      {:ok, contact} ->
        send_json_resp(conn, 200, Responses.render_contact(contact))

      {:error, :not_found} ->
        send_json_resp(conn, 404)
    end
  end

  patch "/contacts/:id", assigns: %{endpoint_id: :update_contact} do
    params = parse_contact_params(conn.params)

    case StateServer.update_contact(
           conn.assigns.state_server,
           conn.assigns.account_id,
           conn.path_params["id"],
           params
         ) do
      {:ok, contact} ->
        send_json_resp(conn, 200, Responses.render_contact(contact))

      {:error, :not_found} ->
        send_json_resp(conn, 404)
    end
  end

  delete "/contacts/:id", assigns: %{endpoint_id: :delete_contact} do
    case StateServer.delete_contact(
           conn.assigns.state_server,
           conn.assigns.account_id,
           conn.path_params["id"]
         ) do
      :ok ->
        send_resp(conn, 204, "")

      {:error, :not_found} ->
        send_json_resp(conn, 404)
    end
  end

  get "/status", assigns: %{endpoint_id: :status, min_auth_level: :public} do
    send_resp(conn, 200, "Up!")
  end

  defp parse_contact_params(params) do
    Enum.flat_map(params, fn
      {"first_name", val} -> [{:first_name, val}]
      {"last_name", val} -> [{:last_name, val}]
      _ -> []
    end)
  end

  defp assign_account_id_from_basic_auth(conn, _opts) do
    with {account_id, token} <- Plug.BasicAuth.parse_basic_auth(conn),
         {:ok, _account} <-
           StateServer.fetch_account_from_credentials(
             conn.assigns.state_server,
             account_id,
             token
           ) do
      Plug.Conn.assign(conn, :account_id, account_id)
    else
      _ -> conn
    end
  end

  defp require_authentication(%{assigns: %{min_auth_level: :public}} = conn, _opts), do: conn

  defp require_authentication(%{assigns: %{account_id: account_id}} = conn, _opts)
       when not is_nil(account_id),
       do: conn

  defp require_authentication(conn, _opts) do
    conn
    |> send_json_resp(401)
    |> Plug.Conn.halt()
  end

  defp return_stubbed_responses(conn, _opts) do
    endpoint_id = fetch_endpoint_id_from_assigns!(conn)

    case StateServer.get_response_stub(conn.assigns.state_server, endpoint_id) do
      nil ->
        conn

      :internal_server_error ->
        conn
        |> send_json_resp(500, %{"error" => "Internal Server Error"})
        |> halt()

      :invalid_response ->
        conn
        |> send_resp(200, "Invalid")
        |> halt()
    end
  end

  defp fetch_endpoint_id_from_assigns!(conn) do
    case Map.fetch(conn.assigns, :endpoint_id) do
      {:ok, endpoint_id} when is_atom(endpoint_id) ->
        endpoint_id

      _ ->
        path = Plug.Router.match_path(conn)
        method = conn.method |> to_string() |> String.downcase()

        raise """
        endpoint_id must be added to the assigns of the route definition

            #{method} #{inspect(path)}, assigns: %{endpoint_id: :my_endpoint_id} do
              #...
            end
        """
    end
  end

  defp send_json_resp(conn, 404) do
    send_json_resp(conn, 404, Responses.render_not_found())
  end

  defp send_json_resp(conn, 401) do
    send_json_resp(conn, 401, Responses.render_unauthenticated())
  end

  defp send_json_resp(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, encode_json(data))
  end

  defp encode_json(data), do: Jason.encode!(data)
end
