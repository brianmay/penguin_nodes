defmodule PenguinNodes.Mqtt.Message do
  @moduledoc """
  NQTT Message
  """
  @type t :: %__MODULE__{
          topic: list(String.t()),
          payload: any()
        }
  @enforce_keys [:topic, :payload]
  defstruct @enforce_keys
end
