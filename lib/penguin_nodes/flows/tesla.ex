defmodule PenguinNodes.Flows.Tesla do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Simple
  alias PenguinNodes.Nodes.Tesla

  @spec payload_func(Mqtt.Message.t()) :: any()
  defp payload_func(%Mqtt.Message{payload: payload}), do: payload

  @spec geofence_to_message(Simple.Changed.Message.t()) :: String.t()
  defp geofence_to_message(%Simple.Changed.Message{old: "", new: new}),
    do: "The Tesla has arrived at #{new}"

  defp geofence_to_message(%Simple.Changed.Message{old: old, new: ""}),
    do: "The Tesla has left #{old}"

  defp geofence_to_message(%Simple.Changed.Message{old: old, new: new}),
    do: "The Tesla has left #{old} and arrived at #{new}"

  @spec plugged_in_to_message(Simple.Changed.Message.t()) :: String.t()
  defp plugged_in_to_message(%Simple.Changed.Message{new: true}),
    do: "The Tesla has been plugged in"

  defp plugged_in_to_message(%Simple.Changed.Message{new: false}),
    do: "The Tesla has been disconnected"

  defp plugged_in_to_message(%Simple.Changed.Message{}),
    do: "The Tesla plugged in status is unknown"

  @spec insecure_to_message(boolean()) :: String.t()
  defp insecure_to_message(true),
    do: "The tesla is feeling lonely and not secure"

  defp insecure_to_message(false),
    do: "The tesla is feeling secure"

  @spec generate_flow(integer(), id :: Id.t()) :: Nodes.t()
  def generate_flow(tesla, id) do
    nodes = Nodes.new()

    topic = ["teslamate", "cars", Integer.to_string(tesla), "geofence"]

    mqtt_in(topic, :raw, id(:geofence_mqtt))
    |> call_value(Simple.Map, %{func: &payload_func/1}, id(:geofence_payload))
    |> call_value(Simple.Changed, %{}, id(:geofence_changed))
    |> call_value(Simple.Map, %{func: &geofence_to_message/1}, id(:geofence_to_message))
    |> message(id(:geofence_message))
    |> terminate()

    topic = ["teslamate", "cars", Integer.to_string(tesla), "plugged_in"]

    mqtt_in(topic, :json, id(:plugged_in_mqtt))
    |> call_value(Simple.Map, %{func: &payload_func/1}, id(:plugged_in_payload))
    |> call_value(Simple.Changed, %{}, id(:plugged_in_changed))
    |> call_value(Simple.Map, %{func: &plugged_in_to_message/1}, id(:plugged_in_to_message))
    |> message(id(:plugged_in_message))
    |> terminate()

    topic = ["teslamate", "cars", Integer.to_string(tesla), "is_user_present"]

    is_user_present =
      mqtt_in(topic, :json, id(:is_user_present_mqtt))
      |> call_value(Simple.Map, %{func: &payload_func/1}, id(:is_user_present_payload))

    topic = ["teslamate", "cars", Integer.to_string(tesla), "locked"]

    locked =
      mqtt_in(topic, :json, id(:locked_mqtt))
      |> call_value(Simple.Map, %{func: &payload_func/1}, id(:locked_payload))

    %{is_user_present: is_user_present, locked: locked}
    |> call_value(Tesla.Insecure, %{}, id(:insecure))
    |> call_value(Simple.Map, %{func: &insecure_to_message/1}, id(:insecure_to_message))
    |> message(id(:message))
    |> terminate()

    nodes
  end
end
