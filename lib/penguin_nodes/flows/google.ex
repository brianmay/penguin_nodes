defmodule PenguinNodes.Flows.Google do
  @moduledoc """
  Simple flows for testing nodes
  """
  use PenguinNodes.Nodes.Flow

  import PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.Mqtt
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Robotica
  alias PenguinNodes.Nodes.Simple

  @type power_status :: boolean() | :offline | :unknown

  @spec light_google_to_robotica(Mqtt.Message.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def light_google_to_robotica(message, location, device) do
    input = message.payload

    color = %{
      "hue" => 0,
      "saturation" => 0,
      "brightness" => 100,
      "kelvin" => 3500
    }

    color =
      if Map.has_key?(input, "hue") do
        Map.put(color, "hue", input["hue"])
      else
        color
      end

    color =
      if Map.has_key?(input, "saturation") do
        Map.put(color, "saturation", input["saturation"])
      else
        color
      end

    color =
      if Map.has_key?(input, "brightness") do
        Map.put(color, "brightness", input["brightness"])
      else
        color
      end

    color =
      if Map.has_key?(input, "temperature") do
        Map.put(color, "kelvin", input["temperature"])
      else
        color
      end

    action = if input["on"], do: "turn_on", else: "turn_off"

    payload = %{
      "action" => action,
      "color" => color,
      "scene" => "default"
    }

    %Mqtt.Message{
      payload: payload,
      topic: ["command", location, device]
    }
  end

  @spec light_robotica_to_google(String.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def light_robotica_to_google(data, location, device) do
    payload =
      case data do
        "ON" -> %{"on" => true, "online" => true}
        "OFF" -> %{"on" => false, "online" => true}
        "HARD_OFF" -> %{"on" => false, "online" => false}
      end

    %Mqtt.Message{
      payload: payload,
      topic: ["google", location, device, "in"]
    }
  end

  @spec device_google_to_robotica(Mqtt.Message.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def device_google_to_robotica(message, location, device) do
    input = message.payload

    action = if input["on"], do: "turn_on", else: "turn_off"

    payload = %{
      "action" => action
    }

    %Mqtt.Message{
      payload: payload,
      topic: ["command", location, device]
    }
  end

  @spec device_robotica_to_google(String.t(), String.t(), String.t()) :: Mqtt.Message.t()
  def device_robotica_to_google(data, location, device) do
    payload =
      case data do
        "ON" -> %{"on" => true, "online" => true}
        "OFF" -> %{"on" => false, "online" => true}
        "HARD_OFF" -> %{"on" => false, "online" => false}
      end

    %Mqtt.Message{
      payload: payload,
      topic: ["google", location, device, "in"]
    }
  end

  @spec light(location :: String.t(), device :: String.t(), id :: Id.t()) :: Nodes.t()
  def light(location, device, id) do
    nodes = Nodes.new()

    mqtt_in(["google", location, device, "out"], :json, id(:google_in))
    |> call_value(
      Simple.Map,
      %{func: &light_google_to_robotica(&1, location, device)},
      id(:google_to_robotica)
    )
    |> mqtt_out(id(:robotica_out))
    |> terminate()

    # night =
    #   mqtt_in(["state", light, "Night", "power"], :raw, id(:night_in))
    #   |> payload(id(:night_in_payload))

    power =
      mqtt_in(["state", location, device, "power"], :raw, id(:power_in))
      |> payload(id(:power_payload))

    scenes =
      mqtt_in(["state", location, device, "scenes"], :json, id(:scenes_in))
      |> payload(id(:scenes_payload))

    %{power: power, scenes: scenes}
    |> call_value(Robotica.Power, %{}, id(:get_power))
    |> call_value(
      Simple.Map,
      %{func: &light_robotica_to_google(&1, location, device)},
      id(:robotica_to_google)
    )
    |> mqtt_out(id(:google_out))
    |> terminate()

    nodes
  end

  @spec device(location :: String.t(), device :: String.t(), id :: Id.t()) :: Nodes.t()
  def device(location, device, id) do
    nodes = Nodes.new()

    mqtt_in(["google", location, device, "out"], :json, id(:google_in))
    |> call_value(
      Simple.Map,
      %{func: &device_google_to_robotica(&1, location, device)},
      id(:google_to_robotica)
    )
    |> mqtt_out(id(:robotica_out))
    |> terminate()

    mqtt_in(["state", location, device, "power"], :raw, id(:power_in))
    |> payload(id(:power_payload))
    |> call_value(
      Simple.Map,
      %{func: &device_robotica_to_google(&1, location, device)},
      id(:robotica_to_google)
    )
    |> mqtt_out(id(:google_out))
    |> terminate()

    nodes
  end

  @spec generate_flow(id :: Id.t()) :: Nodes.t()
  def generate_flow(id) do
    nodes = Nodes.new()

    light("Brian", "Light", id(:brian_light))
    |> terminate()

    light("Twins", "Light", id(:twins_light))
    |> terminate()

    light("Dining", "Light", id(:dining_light))
    |> terminate()

    light("Jan", "Light", id(:jan_light))
    |> terminate()

    device("Brian", "Fan", id(:brian_fan))
    |> terminate()

    device("Dining", "TvSwitch", id(:dining_tv_switch))
    |> terminate()

    nodes
  end
end
