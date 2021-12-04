defmodule PenguinNodes.Flows.Test do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Simple

  @type power_status :: boolean() | :offline | :unknown

  @spec power_func(Mqtt.Message.t()) :: power_status()
  defp power_func(%Mqtt.Message{payload: "OFF"}), do: false
  defp power_func(%Mqtt.Message{payload: "HARD_OFF"}), do: :offline
  defp power_func(%Mqtt.Message{payload: "ON"}), do: true
  defp power_func(%Mqtt.Message{}), do: :unknown

  @spec power_status_to_message(Simple.Changed.Message.t()) :: String.t()
  defp power_status_to_message(%Simple.Changed.Message{new: true}),
    do: "The fan has been turned on"

  defp power_status_to_message(%Simple.Changed.Message{new: false}),
    do: "The fan has been turned off"

  defp power_status_to_message(%Simple.Changed.Message{new: :offline}),
    do: "The fan has been turned off at the power point"

  defp power_status_to_message(%Simple.Changed.Message{new: :unknown}),
    do: "The fan state is unknown"

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    call_value(nil, Mqtt.In, %{topic: ["state", "Brian", "Fan", "power"]}, id(:mqtt))
    |> call_value(Simple.Map, %{func: &power_func/1}, id(:power_to_boolean))
    |> call_value(Simple.Changed, %{}, id(:changed))
    |> call_value(Simple.Map, %{func: &power_status_to_message/1}, id(:power_to_string))
    |> message(id(:message))
    |> terminate()

    nodes
  end
end
