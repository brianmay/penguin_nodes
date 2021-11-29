defmodule PenguinNodes.Nodes.Flow do
  @moduledoc """
  Wrapper genserver for nodes
  """
  require Logger
  alias PenguinNodes.Nodes.Nodes

  defmacro __using__(_opts) do
    quote do
      import PenguinNodes.Nodes.Flow
      require PenguinNodes.Nodes.Flow
    end
  end

  defmacro call(module, opts, this_id) do
    quote do
      module = unquote(module)
      module_inputs = Module.concat(module, Inputs)
      module_options = Module.concat(module, Options)
      inputs = struct(module_inputs, %{})
      options = struct(module_options, unquote(opts))
      new_id = id(var!(id), unquote(this_id))
      module.call(inputs, options, new_id)
    end
  end

  defmacro call_with_value(value, module, opts, this_id) do
    quote do
      module = unquote(module)
      module_inputs = Module.concat(module, Inputs)
      module_options = Module.concat(module, Options)
      inputs = struct!(module_inputs, %{value: unquote(value)})
      options = struct!(module_options, unquote(opts))
      new_id = id(var!(id), unquote(this_id))
      module.call(inputs, options, new_id)
    end
  end

  defmacro terminate(new_nodes) do
    quote do
      var!(nodes) = Nodes.merge(var!(nodes), unquote(new_nodes))
      :ok
    end
  end
end
