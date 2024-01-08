defmodule Aoc2023.Day23 do
  alias Common.SemiDirectedGridGraph

  def run(1) do
    part1()
  end

  def part1 do
    {graph, start, finish} = parse_input("input/test.txt")
  end

  defp parse_input(path) do
    lines =
      path
      |> File.read!()
      |> String.trim()
      |> String.split("\n")

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
