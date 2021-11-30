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

    old_location =
      case Map.fetch(acc, id) do
        {:ok, location} -> location
        :error -> nil
      end

    out =
      if location != old_location do
        %{
          old_location: old_location,
          location: location,
          person: person
        }
      else
        nil
      end

    acc = Map.put(acc, id, location)
    {out, acc}
  end

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    circles =
      call(Circles, %{}, id(:circles))
      |> call_with_value(
        Simple.Reduce,
        %{func: &life360_location_changed/2, acc: %{}},
        id(:location_changed)
      )

    circles
    |> call_with_value(Simple.Debug, %{}, id(:debug1))
    |> terminate()

    nodes
  end
end
