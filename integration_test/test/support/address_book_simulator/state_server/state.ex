defmodule MyApp.AddressBookSimulator.StateServer.State do
  @moduledoc false

  @type t :: map()

  @spec new() :: t
  def new do
    %{
      accounts: [],
      contacts: %{},
      response_stubs: %{}
    }
  end

  def create_account(state) do
    account = %{
      id: random_id(),
      token: random_id()
    }

    {:ok,
     {account,
      %{
        state
        | accounts: [account | state.accounts],
          contacts: Map.put(state.contacts, account.id, %{})
      }}}
  end

  def fetch_account_from_credentials(state, account_id, token) do
    case Enum.find(state.accounts, &(&1.id == account_id && &1.token == token)) do
      %{} = account -> {:ok, account}
      nil -> {:error, :not_found}
    end
  end

  def create_contact(state, account_id, params) do
    contact =
      params
      |> Map.new()
      |> Map.take([:first_name, :last_name])
      |> Map.put_new(:first_name, nil)
      |> Map.put_new(:last_name, nil)
      |> Map.put(:id, random_id())
      |> Map.put(:account_id, account_id)
      |> Map.put(:created_at, DateTime.utc_now())

    {:ok,
     {contact,
      %{
        state
        | contacts:
            Map.update(
              state.contacts,
              account_id,
              %{contact.id => contact},
              &Map.put(&1, contact.id, contact)
            )
      }}}
  end

  def fetch_contact(state, account_id, id) do
    case get_in(state.contacts, [account_id, id]) do
      %{} = contact -> {:ok, contact}
      nil -> {:error, :not_found}
    end
  end

  def list_contacts(state, account_id) do
    state.contacts
    |> Map.get(account_id, %{})
    |> Map.values()
    |> Enum.sort_by(&DateTime.to_unix(&1.created_at, :native))
  end

  def update_contact(state, account_id, id, params) do
    {contact, updated_contacts} =
      get_and_update_in(state.contacts, [account_id, id], fn
        nil ->
          :pop

        contact ->
          updated_fields =
            params
            |> Map.new()
            |> Map.take([:first_name, :last_name])

          contact = Map.merge(contact, updated_fields)
          {contact, contact}
      end)

    case contact do
      nil -> {:error, :not_found}
      %{} -> {:ok, {contact, %{state | contacts: updated_contacts}}}
    end
  end

  def delete_contact(state, account_id, id) do
    {contact, updated_contacts} =
      get_and_update_in(state.contacts, [account_id, id], fn _contact -> :pop end)

    case contact do
      %{} -> {:ok, %{state | contacts: updated_contacts}}
      nil -> {:error, :not_found}
    end
  end

  def get_response_stub(state, route_id) do
    with nil <- state.response_stubs[:all] do
      state.response_stubs[route_id]
    end
  end

  def stub_response(state, route_id, response_id) do
    response_stubs = Map.put(state.response_stubs, route_id, response_id)

    %{state | response_stubs: response_stubs}
  end

  def clear_stubbed_responses(state) do
    %{state | response_stubs: %{}}
  end

  defp random_id, do: :crypto.strong_rand_bytes(10) |> Base.url_encode64(padding: false)
end
