defmodule PenguinNodesWeb.Nodes.IdsTest do
  use ExUnit.Case

  alias PenguinNodes.Nodes.Id

  test "allocate_id works" do
    {:ok, pid} = Id.start_link(name: __MODULE__)
    assert :ok == Id.allocate_id(pid, {:abc})
    assert :ok == Id.allocate_id(pid, {:def})
    assert :error == Id.allocate_id(pid, {:def})
  end
end
