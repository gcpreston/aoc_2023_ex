defmodule Common.DirectedGraph do
  @moduledoc """
  A directed, unweighted graph.
  """

  @type node_id() :: non_neg_integer()
  @type t() :: %__MODULE__{
    adjacencies: [[node_id()]]
  }

  defstruct [:adjacencies]

  @spec new([[node_id()]]) :: t()
  def new(adjacencies \\ []) do
    %__MODULE__{adjacencies: adjacencies}
  end
end

defimpl Common.Graph, for: Common.DirectedGraph do
  def neighbors(graph, node) do
    graph.adjacencies[node]
  end
end
