defmodule PenguinNodes.Flows.Helpers do
  @moduledoc """
  Simple flows for testing nodes
  """
  require PenguinNodes.Nodes.Flow

  alias PenguinNodes.Mqtt
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  import PenguinNodes.Nodes.Flow
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire
  alias PenguinNodes.Simple

  @dry_run Application.compile_env!(:penguin_nodes, :dry_run)

  @spec power_to_boolean_func(Mqtt.Message.t()) :: boolean() | nil
  defp power_to_boolean_func(%Mqtt.Message{payload: "OFF"}), do: false
  defp power_to_boolean_func(%Mqtt.Message{payload: "HARD_OFF"}), do: false
  defp power_to_boolean_func(%Mqtt.Message{payload: "ON"}), do: true
  defp power_to_boolean_func(%Mqtt.Message{}), do: nil

  @spec power_to_boolean(wire :: Wire.t(), id :: Id.t()) :: Wire.t()
  def power_to_boolean(%Wire{} = wire, id) do
    call_value_value(wire, Simple.Map, %{func: &power_to_boolean_func/1}, id)
  end

  @spec filter_nils(any()) :: boolean()
  defp filter_nils(nil), do: false
  defp filter_nils(_), do: true

  @spec mqtt_in(topic :: list(String.t()), id :: Id.t()) :: Wire.t()
  def mqtt_in(topic, id) do
    call_none_value(Mqtt.In, %{topic: topic}, id)
  end

  @spec mqtt_out(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  if @dry_run do
    def mqtt_out(%Wire{} = wire, id) do
      wire
      |> call_value_none(Simple.Debug, %{}, id)
    end
  else
    def mqtt_out(%Wire{} = wire, id) do
      wire
      |> call_value_none(Mqtt.Out, %{format: :json}, id)
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

  @spec message_for_location(wire :: Wire.t(), location :: String.t(), id :: Id.t()) :: Nodes.t()
  def message_for_location(%Wire{} = wire, location, id) do
    func = &message_func(&1, location)

    mqtt =
      mqtt_in(["state", location, "Messages", "power"], id(:mqtt_in))
      |> power_to_boolean(id(:boolean))

    %{value: wire, inverted: debug} =
      call_value_map(wire, Simple.Switch, %{switch: mqtt}, %{}, id(:switch))

    nodes = Nodes.new()

    wire
    |> call_value_value(Simple.Map, %{func: func}, id(:string_to_command))
    |> mqtt_out(id(:mqtt_out))
    |> terminate()

    debug
    |> call_value_none(Simple.Debug, %{message: "MSG disabled for message"}, id(:debug))
    |> terminate()

    nodes
  end

  @spec message(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  def message(%Wire{} = wire, id) do
    nodes = Nodes.new()

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
    |> call_value_value(Simple.Filter, %{func: &filter_nils/1}, id)
  end
end
