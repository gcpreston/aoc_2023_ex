defmodule Common.UWGraph do
  @moduledoc """
  An undirected, weighted graph.
  """

  @type node_id() :: any()
  @type edge() :: {node_id(), node_id()}
  @type t() :: %__MODULE__{
          adjacencies: %{node_id() => [node_id()]},
          weights: %{edge() => integer()}
        }

  defstruct [:adjacencies, :weights]

  @spec new([[node_id()]], %{edge() => integer()}) :: t()
  def new(adjacencies \\ %{}, weights \\ %{}) do
    %__MODULE__{adjacencies: adjacencies, weights: weights}
  end

  @spec add_node(t(), node_id()) :: t()
  def add_node(graph, id) do
    new_adj = Map.put(graph.adjacencies, id, [])
    %__MODULE__{graph | adjacencies: new_adj}
  end

  @spec add_edge(t(), node_id(), node_id(), integer()) :: t()
  def add_edge(graph, from, to, weight) do
    new_from_adj = [to | Map.get(graph.adjacencies, from)]
    new_to_adj = [from | Map.get(graph.adjacencies, to)]

    new_adj =
      graph.adjacencies
      |> Map.put(from, new_from_adj)
      |> Map.put(to, new_to_adj)

    new_weights =
      graph.weights
      |> Map.put({from, to}, weight)
      |> Map.put({to, from}, weight)

    %__MODULE__{adjacencies: new_adj, weights: new_weights}
  end
end

defimpl Common.Graph, for: Common.UWGraph do
  def neighbors(graph, node) do
    graph.adjacencies[node]
  end
end
