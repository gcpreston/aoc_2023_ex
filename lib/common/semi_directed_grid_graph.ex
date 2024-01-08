defmodule Common.SemiDirectedGridGraph do
  defstruct [:height, :width, :walls, :directional_tiles]

  @type grid_location() :: {integer(), integer()}
  @type direction :: :up | :down | :left | :right
  @type t() :: %__MODULE__{
          height: integer(),
          width: integer(),
          walls: Enumerable.t(grid_location()),
          directional_tiles: %{grid_location() => direction()}
        }

  @spec new(
          integer(),
          integer(),
          Enumerable.t(grid_location()),
          %{grid_location() => direction()}
        ) :: t()
  def new(height, width, walls, directional_tiles) do
    %__MODULE__{
      height: height,
      width: width,
      walls: MapSet.new(walls),
      directional_tiles: directional_tiles
    }
  end

  # TODO: Generalize

  @spec longest_distance(t(), grid_location(), grid_location()) :: integer()
  def longest_distance(graph, start, finish) do
    topo_ordering = topological_ordering(graph, start)
    dists = longest_distances(graph, topo_ordering, %{start => 0})
    dists[finish]
  end

  def longest_distances(_graph, [], dists), do: dists
  def longest_distances(graph, topo_ordering, dists) do
    [node | popped_topo_ordering] = topo_ordering
    neighbors = Common.Graph.neighbors(graph, node)

    dists =
      Enum.reduce(neighbors, dists, fn neighbor, dists ->
        if !Map.has_key?(dists, neighbor) do
          Map.put(dists, neighbor, dists[node] + 1)
        else
          dists
        end
      end)

    longest_distances(graph, popped_topo_ordering, dists)
  end

  @spec topological_ordering(t(), grid_location()) :: [grid_location()]
  def topological_ordering(graph, start) do
    topological_ordering(graph, MapSet.new(), [start], [])
  end

  defp topological_ordering(_graph, _visited, [], ordering), do: ordering
  defp topological_ordering(graph, visited, stack, ordering) do
    [visit | popped_stack] = stack
    visited = MapSet.put(visited, visit)

    neighbors =
      Common.Graph.neighbors(graph, visit)
      |> Enum.filter(&!MapSet.member?(visited, &1))

    if neighbors == [] do
      topological_ordering(graph, visited, popped_stack, [visit | ordering])
    else
      topological_ordering(graph, visited, neighbors ++ stack, ordering)
    end
  end
end

defimpl Common.Graph, for: Common.SemiDirectedGridGraph do
  def neighbors(graph, {row, col} = location) do
    [{row + 1, col}, {row - 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(&follows_direction(graph, &1, location))
    |> Enum.filter(&in_bounds(graph, &1))
    |> Enum.filter(&passable(graph, &1))
  end

  defp follows_direction(graph, location, {came_from_row, came_from_col} = came_from) do
    direction = graph.directional_tiles[came_from]

    case direction do
      :up -> location == {came_from_row - 1, came_from_col}
      :down -> location == {came_from_row + 1, came_from_col}
      :left -> location == {came_from_row, came_from_col - 1}
      :right -> location == {came_from_row, came_from_col + 1}
      nil -> true
    end
  end

  defp in_bounds(graph, {row, col}) do
    row >= 0 && row < graph.height && col >= 0 && col < graph.width
  end

  defp passable(graph, location) do
    !MapSet.member?(graph.walls, location)
  end
end
