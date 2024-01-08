defmodule Aoc2023.Day22 do
  def run(1) do
    part1()
  end

  def run(2) do
    part2()
  end

  defp part1 do
    read_input()
    |> parse_input()
    |> fall()
    |> supporting_bricks()
    |> demolishable()
    |> length()
  end

  defp part2 do
    fallen_bricks =
      read_input()
      |> parse_input()
      |> fall()

    supported_by = supported_by(fallen_bricks) |> dbg()
    supporting_bricks = supporting_bricks(fallen_bricks) |> dbg()

    would_cause_falls = undemolishable(supporting_bricks)

    would_cause_falls
    |> Enum.map(&(simulate_demolish(supported_by, supporting_bricks, &1)))
    |> Enum.sum()
  end

  defp fall(snapshot) do
    sorted_snapshot =
      Enum.sort(snapshot, fn {_, _, z0_1.._}, {_, _, z0_2.._} ->
        z0_1 <= z0_2
      end)

    initial_z_heights = for x <- 0..9, y <- 0..9, into: %{}, do: {{x, y}, %{z: 0, brick: nil}}
    initial_fallen_bricks = []

    fall(sorted_snapshot, initial_fallen_bricks, initial_z_heights)
  end

  defp fall([], fallen_bricks, _z_heights), do: fallen_bricks

  defp fall([brick | remaining_bricks], fallen_bricks, z_heights) do
    # IDEA
    # 1. Initialize map of current Z value looking from above
    # 2. Iterate through snapshot by Z value small-large and "fall" them onto the map
    # 3. ~~Add any overlaps to an overlap tracker, returned at the end~~

    {new_fallen_bricks, new_z_heights} = fall_brick(brick, fallen_bricks, z_heights)
    fall(remaining_bricks, new_fallen_bricks, new_z_heights)
  end

  defp fall_brick({x_range, y_range, _z_range} = brick, fallen_bricks, z_heights) do
    footprint = brick_footprint(brick)
    max_z = Enum.map(footprint, fn coord -> z_heights[coord][:z] end) |> Enum.max()
    brick_height = brick_height(brick)
    new_z = max_z + brick_height

    new_z_heights =
      Enum.reduce(footprint, z_heights, fn coord, z_heights_acc ->
        Map.put(z_heights_acc, coord, %{z: new_z, brick: brick})
      end)

    new_z0 = max_z + 1
    new_z1 = new_z0 + brick_height - 1
    fallen_brick = {x_range, y_range, new_z0..new_z1}

    {[fallen_brick | fallen_bricks], new_z_heights}
  end

  # Create a map of brick => bricks supported by that brick
  defp supported_by(fallen_bricks) do
    for b1 <- fallen_bricks, into: %{} do
      bricks_being_supported = Enum.filter(fallen_bricks, fn b2 -> supports?(b1, b2) end)
      {b1, bricks_being_supported}
    end
  end

  # Create a map of brick => bricks supporting that brick
  defp supporting_bricks(fallen_bricks) do
    for b1 <- fallen_bricks, into: %{} do
      supporting_bricks = Enum.filter(fallen_bricks, fn b2 -> supports?(b2, b1) end)
      {b1, supporting_bricks}
    end
  end

  # Does the first brick support the second brick?
  defp supports?({x1, y1, _..top1}, {x2, y2, bottom2.._}) do
    top1 + 1 == bottom2 && !Range.disjoint?(x1, x2) && !Range.disjoint?(y1, y2)
  end

  # Find a list of demolishable bricks.
  defp demolishable(supported_by) do
    # a brick is undemolishable if it is the only support for another brick
    undemolishable = undemolishable(supported_by)

    supported_by
    |> Map.keys()
    |> Enum.filter(&(!(&1 in undemolishable)))
  end

  # Find a set of bricks that would cause other bricks to fall if demolished.
  defp undemolishable(supporting) do
    Enum.flat_map(supporting, fn {_brick, supporting_bricks} ->
      case length(supporting_bricks) do
        1 -> supporting_bricks
        _ -> []
      end
    end)
    |> MapSet.new()
  end

  defp simulate_demolish(supported_by, supporting, brick) when is_tuple(brick) do
    simulate_demolish(supported_by, supporting, :queue.from_list([brick]), 0)
  end

  # Find the bricks that would fall if the given bricks were demolished
  defp simulate_demolish(supported_by, supporting, queue, fall_total) do
    case :queue.out(queue) do
      {:empty, _} -> fall_total
      {{:value, to_demolish}, queue} ->
        potential_falls = Map.get(supported_by, to_demolish, [])

        would_fall =
          Enum.filter(potential_falls, fn brick ->
            supporters = supporting[brick]
            remaining_supporters = List.delete(supporters, to_demolish)
            length(remaining_supporters) == 0
          end)

        supporting = Enum.reduce(potential_falls, supporting, fn brick, acc ->
          Map.put(acc, brick, List.delete(acc[brick], to_demolish) -- would_fall)
        end)

        simulate_demolish(supported_by, supporting, :queue.join(queue, :queue.from_list(would_fall)), fall_total + length(would_fall))
      end
  end

  defp brick_footprint({x_range, y_range, _z_range}) do
    for x <- x_range, y <- y_range, do: {x, y}
  end

  defp brick_height({_, _, z0..z1}) do
    z1 - z0 + 1
  end

  defp read_input do
    path = "input/day_22.txt"

    File.read!(path)
    |> String.trim()
  end

  defp parse_input(input) when is_binary(input) do
    for line <- String.split(input, "\n") do
      ~r/(\d),(\d),(\d+)~(\d),(\d),(\d+)/
      |> Regex.run(line, capture: :all_but_first)
      |> Enum.map(&String.to_integer/1)
      |> then(fn [x0, y0, z0, x1, y1, z1] -> {x0..x1, y0..y1, z0..z1} end)
    end
  end
end
