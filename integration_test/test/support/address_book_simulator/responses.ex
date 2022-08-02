defmodule MyApp.AddressBookSimulator.Responses do
  @moduledoc false

  def render_contacts(contacts) when is_list(contacts) do
    %{"contacts" => Enum.map(contacts, &render_contact/1)}
  end

  def render_contact(contact) do
    %{
      "id" => contact.id,
      "first_name" => contact.first_name,
      "last_name" => contact.last_name
    }
  end

  def render_unauthenticated, do: %{"error" => "Unauthenticated"}

  def render_not_found, do: %{"error" => "Not found"}
end
