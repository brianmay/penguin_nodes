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

  @spec power_status_to_message(:start | :timer | :end) :: String.t()
  defp power_status_to_message(:start),
    do: "The fan has been turned on"

  defp power_status_to_message(:end),
    do: "The fan has been turned off"

  defp power_status_to_message(:timer),
    do: "The fan state is on"

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    call_value(nil, Mqtt.In, %{topic: ["state", "Brian", "Fan", "power"]}, id(:mqtt))
    |> power_to_boolean(id(:power_to_boolean))
    |> call_value(Simple.Changed, %{}, id(:changed))
    |> changed_to(id(:changed_to))
    |> call_value(Simple.Timer, %{initial: :stop, interval: 10_000}, id(:timer))
    |> call_value(Simple.Map, %{func: &power_status_to_message/1}, id(:power_to_string))
    |> call_none(Simple.Debug, %{}, id(:message))
    |> terminate()

    nodes
  end
end
