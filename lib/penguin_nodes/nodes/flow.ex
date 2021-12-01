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

  @spec call_none_none(module :: module(), opts :: map(), id :: Id.t()) :: Nodes.t()
  def call_none_none(module, opts, id) do
    module_options = Module.concat(module, Options)
    inputs = %{}
    options = struct(module_options, opts)
    {_, nodes} = NodeModule.call(module, inputs, options, id)
    nodes
  end

  @spec call_value_none(value :: any(), module :: module(), opts :: map(), id :: Id.t()) ::
          Nodes.t()
  def call_value_none(value, module, opts, id) do
    module_options = Module.concat(module, Options)
    inputs = %{value: value}
    options = struct!(module_options, opts)
    {_, nodes} = NodeModule.call(module, inputs, options, id)
    nodes
  end

  @spec call_none_value(module :: module(), opts :: map(), id :: Id.t()) :: Wire.t()
  def call_none_value(module, opts, id) do
    module_options = Module.concat(module, Options)
    inputs = %{}
    options = struct(module_options, opts)
    {%{value: wire}, _} = NodeModule.call(module, inputs, options, id)
    wire
  end

  @spec call_value_value(value :: any(), module :: module(), opts :: map(), id :: Id.t()) ::
          Nodes.t() | Wire.t()
  def call_value_value(value, module, opts, id) do
    module_options = Module.concat(module, Options)
    inputs = %{value: value}
    options = struct!(module_options, opts)
    {%{value: wire}, _} = NodeModule.call(module, inputs, options, id)
    wire
  end

  defmacro terminate(new_nodes) do
    quote do
      var!(nodes) = Nodes.merge(var!(nodes), unquote(new_nodes))
      :ok
    end
  end
end
