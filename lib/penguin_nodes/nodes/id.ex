defmodule PenguinNodes.Nodes.Id do
  @moduledoc """
  Generate guaranteed unique id values
  """
  @type t :: reference()

  @spec get_next_id :: t()
  def get_next_id do
    make_ref()
  end
end
