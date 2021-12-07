defmodule PenguinNodes.Flows.Helpers do
  @moduledoc """
  Simple flows for testing nodes
  """
  require PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  import PenguinNodes.Nodes.Flow
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Simple
  alias PenguinNodes.Nodes.Wire

  @dry_run Application.compile_env!(:penguin_nodes, :dry_run)

  @spec power_to_boolean_func(Mqtt.Message.t()) :: boolean() | nil
  defp power_to_boolean_func(%Mqtt.Message{payload: "OFF"}), do: false
  defp power_to_boolean_func(%Mqtt.Message{payload: "HARD_OFF"}), do: false
  defp power_to_boolean_func(%Mqtt.Message{payload: "ON"}), do: true
  defp power_to_boolean_func(%Mqtt.Message{}), do: nil

  @spec power_to_boolean(wire :: Wire.t(), id :: Id.t()) :: Wire.t()
  def power_to_boolean(%Wire{} = wire, id) do
    call_value(wire, Simple.Map, %{func: &power_to_boolean_func/1}, id)
  end

  @spec filter_nils(any()) :: boolean()
  defp filter_nils(nil), do: false
  defp filter_nils(_), do: true

  @spec mqtt_in(topic :: list(String.t()), format :: :raw | :json, id :: Id.t()) :: Wire.t()
  def mqtt_in(topic, format \\ :raw, id) do
    call_value(nil, Mqtt.In, %{topic: topic, format: format}, id)
  end

  @spec mqtt_out(wire :: Wire.t(), retain :: boolean(), id :: Id.t()) :: Nodes.t()
  if @dry_run do
    def mqtt_out(%Wire{} = wire, _retain \\ false, _id) do
      wire.nodes
    end
  else
    def mqtt_out(%Wire{} = wire, retain \\ false, id) do
      wire
      |> call_none(Mqtt.Out, %{format: :json, retain: retain}, id)
    end
  end

  @spec message_func(String.t(), String.t()) :: Mqtt.Message.t()
  defp message_func(message, location) do
    %Mqtt.Message{
      payload: [
        %{
          "locations" => [location],
          "devices" => ["Robotica"],
          "command" => %{
            "message" => %{
              text: message
            }
          }
        }
      ],
      topic: ["execute"]
    }
  end

  @spec payload_func(Mqtt.Message.t()) :: any()
  defp payload_func(%Mqtt.Message{payload: payload}), do: payload

  @spec changed_to_func(Simple.Changed.Message.t()) :: any()
  defp changed_to_func(%Simple.Changed.Message{new: new}), do: new

  @spec message_for_location(wire :: Wire.t(), location :: String.t(), id :: Id.t()) :: Nodes.t()
  def message_for_location(%Wire{} = wire, location, id) do
    func = &message_func(&1, location)

    mqtt =
      mqtt_in(["state", location, "Messages", "power"], id(:mqtt_in))
      |> power_to_boolean(id(:switch_boolean))
      |> call_value(Simple.Debug, %{message: "Switch state"}, id(:switch_debug))

    nodes = Nodes.new()

    wire
    |> call_value(Simple.Switch, %{switch: mqtt}, %{}, id(:switch))
    |> call_value(Simple.Debug, %{message: "Sending message"}, id(:string_debug))
    |> call_value(Simple.Map, %{func: func}, id(:string_to_command))
    |> mqtt_out(id(:mqtt_out))
    |> terminate()

    nodes
  end

  @spec message(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  def message(%Wire{} = wire, id) do
    nodes = Nodes.new()

    wire = call_value(wire, Simple.Debug, %{message: "Sending message"}, id(:debug))

    wire
    |> message_for_location("Brian", id(:brian))
    |> terminate()

    wire
    |> message_for_location("Dining", id(:dining))
    |> terminate()

    nodes
  end

  @spec filter_nils(wire :: Wire.t(), id :: Id.t()) :: Wire.t()
  def filter_nils(%Wire{} = wire, id) do
    wire
    |> call_value(Simple.Filter, %{func: &filter_nils/1}, id)
  end

  @spec payload(wire :: Wire.t(), id :: Id.t()) :: Wire.t()
  def payload(%Wire{} = wire, id) do
    call_value(wire, Simple.Map, %{func: &payload_func/1}, id)
  end

  @spec changed_to(wire :: Wire.t(), id :: Id.t()) :: Wire.t()
  def changed_to(%Wire{} = wire, id) do
    call_value(wire, Simple.Map, %{func: &changed_to_func/1}, id)
  end
end
