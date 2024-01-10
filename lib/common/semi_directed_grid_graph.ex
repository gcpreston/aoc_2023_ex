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
    dists = longest_distances(graph, topo_ordering, MapSet.new(), %{start => 0})
    dists[finish]
  end

  def longest_distances(_graph, [], _visited, dists), do: dists

  def longest_distances(graph, topo_ordering, visited, dists) do
    debug = {1, 2}

    [node | popped_topo_ordering] = topo_ordering

    neighbors =
      Common.Graph.neighbors(graph, node)
      |> Enum.filter(&(!MapSet.member?(visited, &1)))

    if node == debug do
      IO.puts("\nVisiting debug node #{inspect(node)}")
      IO.inspect(neighbors, label: "neighbors")
      IO.inspect(Enum.map(neighbors, &dists[&1]), label: "distances", charlists: :as_lists)
      IO.puts("node distance #{inspect(dists[node])}")
    end

    dists =
      Enum.reduce(neighbors, dists, fn neighbor, dists_acc ->
        node_distance = dists_acc[node]

        if neighbor == debug do
          IO.puts(
            "Evaluating neighbor #{inspect(neighbor)} from #{inspect(node)}: distances #{node_distance}, #{inspect(Map.get(dists_acc, neighbor))}"
          )
        end

        case Map.get(dists_acc, neighbor) do
          nil ->
            Map.put(dists_acc, neighbor, node_distance + 1)

          neighbor_distance ->
            if neighbor_distance < node_distance + 1 do
              Map.put(dists_acc, neighbor, node_distance + 1)
            else
              dists_acc
            end
        end
      end)

    visited = MapSet.put(visited, node)

    longest_distances(graph, popped_topo_ordering, visited, dists)
  end

  @spec topological_ordering(t(), grid_location()) :: [grid_location()]
  def topological_ordering(graph, start) do
    topological_ordering(graph, MapSet.new(), [start], [])
  end

  # This doesn't work because the graph has loops...
  defp topological_ordering(_graph, _visited, [], ordering), do: ordering

  defp topological_ordering(graph, visited, stack, ordering) do
    [visit | popped_stack] = stack
    visited = MapSet.put(visited, visit)

    neighbors =
      Common.Graph.neighbors(graph, visit)
      |> Enum.filter(&(!MapSet.member?(visited, &1)))

    if neighbors == [] do
      topological_ordering(graph, visited, popped_stack, [visit | ordering])
    else
      topological_ordering(graph, visited, neighbors ++ stack, ordering)
    end
  end

  def dfs_reduce(graph, initial, func), do: dfs_reduce(graph, initial, func, [])

  defp dfs_reduce(_graph, acc, _func, []), do: acc

  defp dfs_reduce(graph, acc, func, [{node, came_from} | stack_rest]) do
    acc = func.(node, acc)
    stack_ext = neighbors(graph, node, came_from) |> Enum.map(&{&1, node})
    stack = stack_ext ++ stack_rest
    dfs_reduce(graph, acc, func, stack)
  end

  ## Graph protocol but specialized...

  def all_neighbors(graph, {row, col}) do
    [{row + 1, col}, {row - 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(&in_bounds(graph, &1))
    |> Enum.filter(&passable(graph, &1))
  end

  def neighbors(graph, {row, col} = location, came_from) do
    [{row + 1, col}, {row - 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(&(&1 != came_from))
    |> Enum.filter(&follows_direction(graph, &1, location))
    |> Enum.filter(&in_bounds(graph, &1))
    |> Enum.filter(&passable(graph, &1))
    |> Enum.filter(&slope_passable(graph, &1, location))
  end

  # Does location follow the direction of came_from if came_from is a directional tile?
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

  # Can the directional tile be stepped on?
  defp slope_passable(graph, location, {came_from_row, came_from_col}) do
    direction = graph.directional_tiles[location]

    case direction do
      :up -> location == {came_from_row - 1, came_from_col}
      :down -> location == {came_from_row + 1, came_from_col}
      :left -> location == {came_from_row, came_from_col - 1}
      :right -> location == {came_from_row, came_from_col + 1}
      nil -> true
    end
  end
end
