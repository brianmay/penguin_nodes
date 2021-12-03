defmodule PenguinNodes.Flows.Tesla do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  alias PenguinNodes.Mqtt
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Simple

  @spec geofence_to_message(Simple.Changed.Message.t()) :: String.t()
  defp geofence_to_message(%Simple.Changed.Message{old: nil, new: new}),
    do: "The Tesla has arrived at #{new}"

  defp geofence_to_message(%Simple.Changed.Message{old: old, new: nil}),
    do: "The Tesla has left #{old}"

  defp geofence_to_message(%Simple.Changed.Message{old: old, new: new}),
    do: "The Tesla has left #{old} and arrived at #{new}"

  @spec plugged_in_changed(Simple.Changed.Message.t()) :: String.t()
  defp plugged_in_changed(%Simple.Changed.Message{new: true}),
    do: "The Tesla has been plugged in"

  defp plugged_in_changed(%Simple.Changed.Message{new: false}),
    do: "The Tesla has been disconnected"

  defp plugged_in_changed(%Simple.Changed.Message{}),
    do: "The Tesla plugged in status is unknown"

  @spec generate_flow(integer(), id :: Id.t()) :: Nodes.t()
  def generate_flow(tesla, id) do
    nodes = Nodes.new()

    call_none_value(
      Mqtt.In,
      %{topic: ["teslamate", "cars", Integer.to_string(tesla), "geofence"]},
      id(:mqtt)
    )
    |> call_value_value(Simple.Changed, %{}, id(:geofence_changed))
    |> call_value_value(Simple.Map, %{func: &geofence_to_message/1}, id(:geofence_to_message))
    |> message(id(:message))
    |> terminate()

    call_none_value(
      Mqtt.In,
      %{topic: ["teslamate", "cars", Integer.to_string(tesla), "plugged_in"], format: :json},
      id(:mqtt)
    )
    |> call_value_value(Simple.Changed, %{}, id(:plugged_in_changed))
    |> call_value_value(Simple.Map, %{func: &plugged_in_changed/1}, id(:plugged_in_changed))
    |> message(id(:message))
    |> terminate()

    nodes
  end
end
