defmodule PenguinNodesWeb.Live.Logs do
  @moduledoc "Live view for Tesla"
  use PenguinNodesWeb, :live_view
  alias PenguinNodesWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:nodes, %{})

    Endpoint.subscribe("logs")

    {:ok, socket}
  end

  @impl true
  def handle_info(%{topic: "logs", event: _, payload: payload}, socket) do
    nodes = socket.assigns.nodes
    key = {payload.module, payload.node_id}

    lines = Map.get(nodes, key, [])
    lines = [payload | lines]
    lines = Enum.take(lines, 10)
    nodes = Map.put(nodes, key, lines)

    socket = assign(socket, :nodes, nodes)
    {:noreply, socket}
  end
end
