defmodule PenguinNodesWeb.Live.Logs do
  @moduledoc "Live view for Tesla"
  use PenguinNodesWeb, :live_view

  alias PenguinNodesWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:lines, [])

    Endpoint.subscribe("logs")

    {:ok, socket}
  end

  @impl true
  def handle_info(%{topic: "logs", event: "meow", payload: payload}, socket) do
    lines = [payload | socket.assigns.lines]
    lines = Enum.take(lines, 100)
    socket = assign(socket, :lines, lines)
    {:noreply, socket}
  end
end
