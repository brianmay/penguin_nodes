defmodule PenguinNodes.Nodes.Meta do
  @moduledoc """
  Define a node's meta information
  """
  defmodule Input do
    @moduledoc """
    Defines a Node Input
    """
    alias PenguinNodes.Nodes.Types

    @type t :: %__MODULE__{
            description: String.t(),
            type: Types.data_type()
          }
    @enforce_keys [:description, :type]
    defstruct @enforce_keys
  end

  defmodule Output do
    @moduledoc """
    Defines a Node Output
    """
    alias PenguinNodes.Nodes.Types

    @type t :: %__MODULE__{
            description: String.t(),
            type: Types.data_type()
          }
    @enforce_keys [:description, :type]
    defstruct @enforce_keys
  end

  @type t :: %__MODULE__{
          description: String.t(),
          inputs: %{atom() => Input.t()},
          outputs: %{atom() => Output.t()}
        }
  @enforce_keys [:description, :inputs, :outputs]
  defstruct @enforce_keys
end
