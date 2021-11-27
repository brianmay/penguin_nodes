defmodule PenguinNodes.Nodes.Id do
  @moduledoc """
  Generate guaranteed unique id values
  """
  @type t :: String.t()

  @spec get_next_id :: t()
  def get_next_id do
    UUID.uuid4()
  end
end
