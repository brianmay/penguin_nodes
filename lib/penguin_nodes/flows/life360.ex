defmodule PenguinNodes.Flows.Life360 do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  alias PenguinNodes.Life360.Circles
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Simple

  @spec life360_location_changed(person :: map(), acc :: map()) :: {person :: map(), acc :: map}
  defp life360_location_changed(person, acc) do
    id = person["id"]
    location = person["location"]["name"]

    out =
      case Map.fetch(acc, id) do
        {:ok, old_location} ->
          if location != old_location do
            %{
              old_location: old_location,
              location: location,
              person: person
            }
          else
            nil
          end

        :error ->
          nil
      end

    acc = Map.put(acc, id, location)
    {out, acc}
  end

  @spec changed_to_message(changed :: map()) :: String.t()
  def changed_to_message(changed) do
    name = "#{changed.person["firstName"]} #{changed.person["lastName"]}"

    case changed do
      %{old_location: nil, location: location} -> "#{name} has arrived at #{location}"
      %{old_location: location, location: nil} -> "#{name} has left #{location}"
      %{old_location: old, location: new} -> "#{name} has left #{old} and arrived at #{new}"
    end
  end

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    call_none_value(Circles, %{}, id(:circles))
    |> call_value_value(
      Simple.Reduce,
      %{func: &life360_location_changed/2, acc: %{}},
      id(:location_changed)
    )
    |> filter_nils(id(:filter_nils))
    |> call_value_value(Simple.Map, %{func: &changed_to_message/1}, id(:changed_to_message))
    |> message(id(:message))
    |> terminate()

    nodes
  end
end
