defmodule PenguinNodes.Nodes.Flow do
  @moduledoc """
  Wrapper genserver for nodes
  """
  require Logger
  alias PenguinNodes.Nodes.Id
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

  @spec call(module :: module(), opts :: map(), id :: Id.t()) :: Nodes.t() | Wire.t()
  def call(module, opts, id) do
    module_inputs = Module.concat(module, Inputs)
    module_options = Module.concat(module, Options)
    inputs = struct(module_inputs, %{})
    options = struct(module_options, opts)
    module.call(inputs, options, id)
  end

  @spec call_with_value(value :: any(), module :: module(), opts :: map(), id :: Id.t()) ::
          Nodes.t() | Wire.t()
  def call_with_value(value, module, opts, id) do
    module_inputs = Module.concat(module, Inputs)
    module_options = Module.concat(module, Options)
    inputs = struct!(module_inputs, %{value: value})
    options = struct!(module_options, opts)
    module.call(inputs, options, id)
  end

  defmacro terminate(new_nodes) do
    quote do
      var!(nodes) = Nodes.merge(var!(nodes), unquote(new_nodes))
      :ok
    end
  end
end
