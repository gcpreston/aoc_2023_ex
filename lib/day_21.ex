defmodule Day21 do
  def part1 do
    part1(false)
  end

  def part2 do
    part2(false, 26501365)
  end

  def part1(test) when is_boolean(test) do
    input = read_input(test)
    {height, width, walls, start} = parse_graph_data(input)
    g = GridGraph.new(height, width, walls)

    %{frontier: frontier} = possible_locations(g, start, 64)
    IO.puts("Day 21 part 1: #{length(frontier)}")
  end

  def part2(test, step_count) do
    input = read_input(test)
    {height, width, walls, start} = parse_graph_data(input)
    g = RepeatingGridGraph.new(height, width, walls)

    %{frontier: frontier} = possible_locations(g, start, step_count)
    IO.puts("Day 21 part 2: #{length(frontier)}")
  end

  defp read_input(test) when is_boolean(test) do
    test_input = "input/test.txt"
    real_input = "input/day_21.txt"

    file_path = if test, do: test_input, else: real_input
    String.trim(File.read!(file_path))
  end

  defp possible_locations(graph, start, max_depth) do
    Enum.reduce(
      1..max_depth,
      %{frontier: [start], visited: MapSet.new()},
      fn _, %{frontier: frontier, visited: visited} ->
        new_frontier = Enum.uniq(Enum.flat_map(frontier, &(Graph.neighbors(graph, &1))))
        new_visited = Enum.reduce(new_frontier, visited, &(MapSet.put(&2, &1)))
        %{frontier: new_frontier, visited: new_visited}
      end
    )
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

  defp parse_graph_data(input) when is_binary(input) do
    lines = String.split(input, "\n")
    dbg(lines)
    height = length(lines)
    width = String.length(Enum.at(lines, 0))
    dbg({width, height})

    walls =
      Enum.with_index(lines)
      |> Enum.reduce([], fn {line, row}, acc ->
        line_walls =
          String.graphemes(line)
          |> all_indices(fn c -> c == "#" end)
          |> Enum.map(fn col -> {row, col} end)

        Enum.concat(acc, line_walls)
      end)

    start =
      Enum.with_index(lines)
      |> Enum.find_value(fn {line, row} ->
        col =
          String.graphemes(line)
          |> Enum.find_index(fn c -> c == "S" end)

        if is_number(col) do
          {row, col}
        else
          nil
        end
      end)

      {height, width, walls, start}
  end

  defp print_graph(g, start) do
    IO.puts("graph height #{g.height} and width #{g.width}")

    for row <- 0..(g.height - 1) do
      for col <- 0..(g.width - 1) do
        location = {row, col}

        char =
          cond do
            MapSet.member?(g.walls, location) -> "#"
            location == start -> "S"
            true -> "."
          end

        IO.write(char)
      end

      IO.write("\n")
    end

    nil
  end
end
