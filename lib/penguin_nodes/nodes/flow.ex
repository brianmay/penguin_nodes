defmodule PenguinNodes.Nodes.Flow do
  @moduledoc """
  Wrapper genserver for nodes
  """
  require Logger
  alias PenguinNodes.Nodes.Id
  alias PenguinNodes.Nodes.NodeModule
  alias PenguinNodes.Nodes.Nodes
  alias PenguinNodes.Nodes.Wire

  defmacro __using__(_opts) do
    quote do
      import PenguinNodes.Nodes.Flow
      require PenguinNodes.Nodes.Flow
      import PenguinNodes.Flows.Helpers
    end
  end

  defmacro id(this_id) do
    quote do
      new_id = id(var!(id), unquote(this_id))
    end
  end

  @type input_t :: NodeModule.input_value() | NodeModule.input_map() | nil

  @spec params_to_map(value :: input_t(), extra :: NodeModule.input_map()) ::
          NodeModule.input_map()
  def params_to_map(value, extra) do
    case value do
      nil -> %{}
      %Wire{} = value -> Map.put_new(extra, :value, value)
      value when is_list(value) -> Map.put_new(extra, :value, value)
      value when is_map(value) -> Map.merge(value, extra)
    end
  end

  @spec call_none(
          value :: input_t(),
          module :: module(),
          extra :: NodeModule.input_map(),
          opts :: map(),
          id :: Id.t()
        ) ::
          Nodes.t()
  def call_none(value \\ nil, module, extra \\ %{}, opts, id) do
    inputs = params_to_map(value, extra)
    module_options = Module.concat(module, Options)
    options = struct!(module_options, opts)
    {_, nodes} = NodeModule.call(module, inputs, options, id)
    nodes
  end

  @spec call_value(
          value :: input_t(),
          module :: module(),
          extra :: NodeModule.input_map(),
          opts :: map(),
          id :: Id.t()
        ) :: Wire.t()
  def call_value(value \\ nil, module, extra \\ %{}, opts, id) do
    inputs = params_to_map(value, extra)
    module_options = Module.concat(module, Options)
    options = struct!(module_options, opts)
    {%{value: %Wire{} = wire}, _} = NodeModule.call(module, inputs, options, id)
    wire
  end

  @spec call_map(
          value :: input_t(),
          module :: module(),
          extra :: NodeModule.input_map(),
          opts :: map(),
          id :: Id.t()
        ) :: %{atom() => Wire.t()}
  def call_map(value \\ nil, module, extra \\ %{}, opts, id) do
    inputs = params_to_map(value, extra)
    module_options = Module.concat(module, Options)
    options = struct!(module_options, opts)
    {map, _} = NodeModule.call(module, inputs, options, id)
    map
  end

  defmacro terminate(new_nodes) do
    quote do
      var!(nodes) = Nodes.merge(var!(nodes), unquote(new_nodes))
      :ok
    end
  end
end
