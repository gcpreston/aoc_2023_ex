defmodule Aoc2023.Day22 do
  def run(1) do
    part1()
  end

  defmodule Coordinate do
    defstruct [:x, :y, :z]

    @type t() :: %__MODULE__{
      x: integer(),
      y: integer(),
      z: integer()
    }
  end

  defmodule FlatCoordinate do
    defstruct [:x, :y]

    @type t() :: %__MODULE__{
      x: integer(),
      y: integer()
    }
  end

  defp part1 do
    snapshot =
      read_input()
      |> parse_input()

    {_z_heights, supported_by} = fall(snapshot)

    initial_supported_by =
      for brick <- snapshot, into: %{} do
        {brick, []}
      end

    # This could probably be written more pragmatically as a comprehension
    supports =
      Enum.reduce(supported_by, initial_supported_by, fn {brick_id, bricks_underneath}, supports_acc ->
        Enum.reduce(bricks_underneath, supports_acc, fn supporting_brick_id, acc ->
          new_bricks_being_supported = [brick_id | acc[supporting_brick_id]]
          Map.put(acc, supporting_brick_id, new_bricks_being_supported)
        end)
      end)

    # IO.inspect(supported_by, label: "supported_by")
    # IO.inspect(supports, label: "supports")

    Enum.map(supports, fn {brick, being_supported} -> length(being_supported) end)
    |> Enum.sum()
    |> IO.inspect(label: "huh now")

    to_demolish =
      Enum.filter(snapshot, fn brick ->
        supports_nothing = length(supports[brick]) == 0
        has_backup_support = Enum.all?(supports[brick], fn supportee -> length(supported_by[supportee]) > 1 end)
        # IO.puts("brick #{Brick.to_string(brick)} supports nothing? #{supports_nothing} has backup support? #{has_backup_support}")

        supports_nothing || has_backup_support
      end)

    undemolishable =
      Enum.flat_map(snapshot, fn brick ->
        if length(supported_by[brick]) == 1 do
          supported_by[brick]
        else
          []
        end
      end)
    undemolishable = MapSet.new(undemolishable)

    IO.puts("total length #{length(snapshot)} demolishable #{length(to_demolish)} undemolishable #{MapSet.size(undemolishable)}")

    length(snapshot) - MapSet.size(undemolishable)
  end

  defp fall(snapshot) do
    # IDEA
    # 1. Initialize map of current Z value looking from above
    # 2. Iterate through snapshot by Z value small-large and "fall" them onto the map
    # 3. Add any overlaps to an overlap tracker, returned at the end

    sorted_snapshot =
      Enum.sort(snapshot, fn {_, _, z0_1.._}, {_, _, z0_2.._} ->
        z0_1 <= z0_2
      end)

    z_heights = for x <- 0..9, y <- 0..9, into: %{}, do: {{x, y}, %{z: 0, brick: nil}}
    Enum.reduce(sorted_snapshot, {z_heights, %{}}, fn brick, {z_heights_acc, supports_acc} ->
      {new_z_heights, brick_supports} = fall_brick(brick, z_heights_acc)
      {new_z_heights, Map.put_new(supports_acc, brick, brick_supports)}
    end)
  end

  defp fall_brick(brick, z_heights) do
    footprint = brick_footprint(brick)
    max_z = Enum.map(footprint, fn coord -> z_heights[coord][:z] end) |> Enum.max()
    new_z = max_z + brick_height(brick)

    Enum.reduce(footprint, {z_heights, []}, fn coord, {z_heights_acc, supported_by_acc} ->
      %{z: old_z, brick: old_brick} = z_heights_acc[coord]
      new_supported_by =
        if old_brick != nil && old_z == max_z do
          [old_brick | supported_by_acc]
        else
          supported_by_acc
        end

      new_z_heights = Map.put(z_heights_acc, coord, %{z: new_z, brick: brick})

      {new_z_heights, new_supported_by}
    end)
  end

  defp brick_footprint({x_range, y_range, _z_range}) do
    for x <- x_range, y <- y_range do
      {x, y}
    end
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
