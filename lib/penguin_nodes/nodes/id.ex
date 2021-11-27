defmodule PenguinNodes.Nodes.Id do
  @moduledoc """
  Generate guaranteed unique id values
  """
  @type t :: tuple()

  @spec id(root_id :: t(), id :: atom()) :: t()
  def id(root_id, id) do
    Tuple.append(root_id, id)
  end
end
