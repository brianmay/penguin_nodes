defmodule PenguinNodes.Flows.Test do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow
  require PenguinNodes.Nodes.Id

  alias PenguinNodes.Life360.Circles
  alias PenguinNodes.Mqtt
  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire
  alias PenguinNodes.Simple

  @type power_status :: boolean() | :offline | :unknown

  @spec power_to_boolean(Mqtt.Message.t()) :: power_status()
  defp power_to_boolean(%Mqtt.Message{payload: "OFF"}), do: false
  defp power_to_boolean(%Mqtt.Message{payload: "HARD_OFF"}), do: :offline
  defp power_to_boolean(%Mqtt.Message{payload: "ON"}), do: true
  defp power_to_boolean(%Mqtt.Message{}), do: :unknown

  @spec power_status_to_message(Simple.Changed.Message.t()) :: String.t()
  defp power_status_to_message(%Simple.Changed.Message{new: true}),
    do: "The fan has been turned on"

  defp power_status_to_message(%Simple.Changed.Message{new: false}),
    do: "The fan has been turned off"

  defp power_status_to_message(%Simple.Changed.Message{new: :offline}),
    do: "The fan has been turned off at the power point"

  defp power_status_to_message(%Simple.Changed.Message{new: :unknown}),
    do: "The fan state is unknown"

  @spec string_to_command(String.t()) :: Mqtt.Message.t()
  defp string_to_command(message) do
    %Mqtt.Message{
      payload: [
        %{
          "locations" => ["Brian"],
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

  @spec life360_location_changed(person :: map(), acc :: map()) :: {person :: map(), acc :: map}
  defp life360_location_changed(person, acc) do
    data = person["data"]
    id = data["id"]
    location = data["location"]["name"]

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
          data: data
        }
      else
        nil
      end

    acc = Map.put(acc, id, location)
    {out, acc}
  end

  @spec message(wire :: Wire.t(), id :: Id.t()) :: Nodes.t()
  defp message(%Wire{} = wire, id) do
    wire
    |> call_with_value(Simple.Map, %{map_func: &string_to_command/1}, :string_to_command)
    |> call_with_value(Mqtt.Out, %{format: :json}, :out)
  end

  @spec generate_test_flow(id :: Id.t()) :: Nodes.t()
  def generate_test_flow(id) do
    nodes = Nodes.new()

    circles =
      call(Circles, %{}, :circles)
      |> call_with_value(
        Simple.Reduce,
        %{func: &life360_location_changed/2, acc: %{}},
        :location_changed
      )

    message =
      call(Mqtt.In, %{topic: ["state", "Brian", "Fan", "power"]}, :mqtt)
      |> call_with_value(Simple.Map, %{map_func: &power_to_boolean/1}, :power_to_boolean)
      |> call_with_value(Simple.Changed, %{}, :changed)
      |> call_with_value(Simple.Map, %{map_func: &power_status_to_message/1}, :power_to_string)

    circles
    |> call_with_value(Simple.Debug, %{}, :debug1)
    |> terminate()

    message
    |> message(id(id, :message))
    |> terminate()

    message
    |> call_with_value(Simple.Debug, %{}, :debug2)
    |> terminate()

    Nodes.build(nodes)
  end

  # @spec test_flow() :: Macro.t()
  # defmacro test_flow do
  #   Macro.escape(__MODULE__.generate_test_flow({}))
  # end
end
