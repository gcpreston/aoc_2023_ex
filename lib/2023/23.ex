import AOC

aoc 2023, 23 do
  alias Common.{Graph, DWGraph, SemiDirectedGridGraph, UWGraph}

  def p1(input) do
    {g, start, finish} = parse_input(input)
    longest_distance(g, start, finish)
  end

  def p2(input) do
    {g, start, finish} = parse_undirected_input(input)
    undirected_longest_distance(g, start, finish)
  end

  def longest_distance(graph, start, finish) do
    topo_ordering = topological_ordering(graph, start)
    dists = longest_distances(graph, topo_ordering, MapSet.new(), %{start => 0})
    dists[finish]
  end

  def longest_distances(_graph, [], _visited, dists), do: dists

  def longest_distances(graph, topo_ordering, visited, dists) do
    [node | popped_topo_ordering] = topo_ordering

    neighbors =
      Common.Graph.neighbors(graph, node)
      |> Enum.filter(&(!MapSet.member?(visited, &1)))

    dists =
      Enum.reduce(neighbors, dists, fn neighbor, dists_acc ->
        node_distance = dists_acc[node]
        weight = graph.weights[{node, neighbor}]

        case Map.get(dists_acc, neighbor) do
          nil ->
            Map.put(dists_acc, neighbor, node_distance + weight)

          neighbor_distance ->
            if neighbor_distance < node_distance + weight do
              Map.put(dists_acc, neighbor, node_distance + weight)
            else
              dists_acc
            end
        end
      end)

    visited = MapSet.put(visited, node)

    longest_distances(graph, popped_topo_ordering, visited, dists)
  end

  def undirected_longest_distance(graph, start, finish) do
    # IDEA
    # 1. Start at start node
    # 2. Find neighbors
    # 3. Return max of longest distance from each neighbor with updated visited set
    undirected_longest_distance(graph, start, finish, MapSet.new(), 0)
  end

  defp undirected_longest_distance(graph, node, finish, visited, current_distance) when node == finish do
    current_distance
  end

  defp undirected_longest_distance(graph, node, finish, visited, current_distance) do
    distances =
      Graph.neighbors(graph, node)
      |> Enum.filter(&(!MapSet.member?(visited, &1)))
      |> Enum.map(fn neighbor ->
        undirected_longest_distance(
          graph,
          neighbor,
          finish,
          MapSet.put(visited, node),
          current_distance + graph.weights[{node, neighbor}]
        )
      end)
      |> Enum.reject(&is_nil/1)

    if length(distances) == 0 do
      nil
    else
      Enum.max(distances)
    end
  end

  def topological_ordering(graph, start) do
    topological_ordering(graph, MapSet.new(), [start], [])
  end

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

  defp parse_input(input) do
    {grid_graph, start, finish} = parse_semi_directed_grid(input)
    {nodes, edges} = find_nodes(grid_graph, start, finish)

    dw_graph = DWGraph.new()
    dw_graph = DWGraph.add_node(dw_graph, start)
    dw_graph = DWGraph.add_node(dw_graph, finish)

    dw_graph =
      Enum.reduce(nodes, dw_graph, fn node, dw_graph -> DWGraph.add_node(dw_graph, node) end)

    dw_graph =
      Enum.reduce(edges, dw_graph, fn {from, to, weight}, dw_graph ->
        DWGraph.add_edge(dw_graph, from, to, weight)
      end)

    {dw_graph, start, finish}
  end

  def find_nodes(grid, start, finish), do: find_nodes(grid, [{start, nil}], finish, [], [])

  defp find_nodes(_, [], _, nodes, edges), do: {nodes, edges}

  defp find_nodes(grid, [{current, prev} | to_visit], finish, nodes, edges) do
    neighbors = SemiDirectedGridGraph.neighbors(grid, current, prev)
    next_nodes_and_weights = Enum.map(neighbors, &find_next_node(grid, finish, &1, current, 1))
    nodes = (nodes ++ Enum.map(next_nodes_and_weights, fn {node, _weight, _prev} -> node end)) |> Enum.uniq()

    edges =
      (edges ++ Enum.map(next_nodes_and_weights, fn {node, weight, _prev} -> {current, node, weight} end))
      |> Enum.uniq()

    to_visit =
      to_visit ++ Enum.map(next_nodes_and_weights, fn {node, _weight, prev} -> {node, prev} end)

    find_nodes(grid, to_visit, finish, nodes, edges)
  end

  defp find_next_node(grid, finish, current, prev, len) do
    if current == finish || length(SemiDirectedGridGraph.all_neighbors(grid, current)) >= 3 do
      {current, len, prev}
    else
      next = next_cell(grid, current, prev)
      find_next_node(grid, finish, next, current, len + 1)
    end
  end

  defp next_cell(grid, current, prev) do
    SemiDirectedGridGraph.neighbors(grid, current, prev)
    |> List.first()
  end

  defp parse_undirected_input(input) do
    {grid_graph, start, finish} = parse_semi_directed_grid(input)
    {nodes, edges} = find_nodes(grid_graph, start, finish)

    uw_graph = UWGraph.new()
    uw_graph = UWGraph.add_node(uw_graph, start)
    uw_graph = UWGraph.add_node(uw_graph, finish)

    uw_graph =
      Enum.reduce(nodes, uw_graph, fn node, uw_graph -> UWGraph.add_node(uw_graph, node) end)

    uw_graph =
      Enum.reduce(edges, uw_graph, fn {from, to, weight}, uw_graph ->
        UWGraph.add_edge(uw_graph, from, to, weight)
      end)

    {uw_graph, start, finish}
  end

  defp parse_semi_directed_grid(input) do
    lines = String.split(input, "\n")

    height = length(lines)
    width = String.length(Enum.at(lines, 0))

    walls =
      Enum.with_index(lines)
      |> Enum.reduce([], fn {line, row}, acc ->
        line_walls =
          String.graphemes(line)
          |> all_indices(fn c -> c == "#" end)
          |> Enum.map(fn col -> {row, col} end)

        Enum.concat(acc, line_walls)
      end)

    directional_tiles =
      Enum.with_index(lines)
      |> Enum.reduce(%{}, fn {line, row}, acc ->
        line_slopes =
          String.graphemes(line)
          |> Enum.with_index()
          |> Enum.map(fn {char, col} ->
            case char do
              "^" -> {{row, col}, :up}
              "v" -> {{row, col}, :down}
              "<" -> {{row, col}, :left}
              ">" -> {{row, col}, :right}
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        for slope <- line_slopes, into: acc, do: slope
      end)

    start_row = 0

    start_col =
      lines
      |> Enum.at(start_row)
      |> String.graphemes()
      |> Enum.find_index(fn c -> c == "." end)

    finish_row = height - 1

    finish_col =
      lines
      |> Enum.at(finish_row)
      |> String.graphemes()
      |> Enum.find_index(fn c -> c == "." end)

    start = {start_row, start_col}
    finish = {finish_row, finish_col}

    {SemiDirectedGridGraph.new(height, width, walls, directional_tiles), start, finish}
  end

  defp all_indices(enum, func) do
    Enum.with_index(enum)
    |> Enum.reduce([], fn {e, i}, acc ->
      if func.(e) do
        [i | acc]
      else
        acc
      end
    end)
  end
end
