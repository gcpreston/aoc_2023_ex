defmodule Common.UUGraph do
  @moduledoc """
  An undirected, unweighted graph.
  """

  @type node_id() :: any()
  @type edge() :: {node_id(), node_id()}
  @type t() :: %__MODULE__{
          adjacencies: %{node_id() => [node_id()]},
        }

  defstruct [:adjacencies]

  @spec new(%{node_id() => [node_id()]}) :: t()
  def new(adjacencies \\ %{}) do
    %__MODULE__{adjacencies: adjacencies}
  end

  @spec add_node(t(), node_id()) :: t()
  def add_node(graph, id) do
    new_adj = Map.put(graph.adjacencies, id, [])
    %__MODULE__{graph | adjacencies: new_adj}
  end

  @spec add_edge(t(), node_id(), node_id()) :: t()
  def add_edge(graph, from, to) do
    new_from_adj = [to | Map.get(graph.adjacencies, from, [])]
    new_to_adj = [from | Map.get(graph.adjacencies, to, [])]

    new_adj =
      graph.adjacencies
      |> Map.put(from, new_from_adj)
      |> Map.put(to, new_to_adj)

    %__MODULE__{adjacencies: new_adj}
  end

  @spec remove_edge(t(), node_id(), node_id()) :: t()
  def remove_edge(graph, from, to) do
    new_adj =
      for {node, neighbors} <- graph.adjacencies, into: %{} do
        if node != from && node != to do
          {node, neighbors}
        else
          {node, Enum.reject(neighbors, fn neighbor -> neighbor == to || neighbor == from end)}
        end
      end

    %__MODULE__{adjacencies: new_adj}
  end

  @doc """
  Find the number of nodes which can be reached from the start node.
  """
  @spec cluster_size(t(), node_id()) :: integer()
  def cluster_size(graph, start), do: cluster_size(graph, :queue.from_list([start]), MapSet.new(), 0)

  defp cluster_size(graph, queue, visited, count) do
    case :queue.out(queue) do
      {:empty, _} ->
        count

      {{:value, node}, queue} ->
        if MapSet.member?(visited, node) do
          cluster_size(graph, queue, visited, count)
        else
          to_visit = Common.Graph.neighbors(graph, node) |> Enum.reject(&MapSet.member?(visited, &1))
          queue = :queue.join(queue, :queue.from_list(to_visit))
          cluster_size(graph, queue, MapSet.put(visited, node), count + 1)
        end
    end
  end
end

defimpl Common.Graph, for: Common.UUGraph do
  def neighbors(graph, node) do
    graph.adjacencies[node]
  end
end
