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

  defmodule Brick do
    defstruct [:id, :start_coord, :end_coord]

    @type footprint() :: {integer(), integer()}

    @type t() :: %__MODULE__{
      start_coord: Coordinate.t(),
      end_coord: Coordinate.t()
    }

    @spec footprint(t()) :: footprint()
    def footprint(%__MODULE__{start_coord: s, end_coord: e}) do
      for x <- s.x..e.x, y <- s.y..e.y do
        {x, y}
      end
    end

    @spec min_z(t()) :: integer()
    def min_z(%__MODULE__{start_coord: s, end_coord: e}) do
      min(s.z, e.z)
    end

    @spec height(t()) :: integer()
    def height(%__MODULE__{start_coord: s, end_coord: e}) do
      e.z - s.z + 1
    end

    def debug(b) do
      "#{b.id}: #{b.start_coord.x},#{b.start_coord.y},#{b.start_coord.z}~#{b.end_coord.x},#{b.end_coord.y},#{b.end_coord.z}"
    end
  end

  defp part1 do
    snapshot =
      read_input()
      |> parse_input()

    sorted_snapshot =
      Enum.sort(snapshot, fn brick1, brick2 ->
        Brick.min_z(brick1) <= Brick.min_z(brick2)
      end)

    {_z_heights, supported_by} = fall(sorted_snapshot)

    initial_supported_by =
      for brick <- snapshot, into: %{} do
        {brick.id, []}
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

    to_demolish =
      Enum.filter(sorted_snapshot, fn brick ->
        supports_nothing = length(supports[brick.id]) == 0
        has_backup_support = Enum.all?(supports[brick.id], fn supportee -> length(supported_by[supportee]) > 1 end)
        # IO.puts("brick #{Brick.to_string(brick)} supports nothing? #{supports_nothing} has backup support? #{has_backup_support}")

        supports_nothing || has_backup_support
      end)

    length(to_demolish)
  end

  defp fall(snapshot) do
    # IDEA
    # 1. Initialize map of current Z value looking from above
    # 2. Iterate through snapshot by Z value small-large and "fall" them onto the map
    # 3. Add any overlaps to an overlap tracker, returned at the end

    z_heights = for x <- 0..9, y <- 0..9, into: %{}, do: {{x, y}, %{z: 0, brick: nil}}
    Enum.reduce(snapshot, {z_heights, %{}}, fn brick, {z_heights_acc, supports_acc} ->
      {new_z_heights, brick_supports} = fall_brick(brick, z_heights_acc)
      {new_z_heights, Map.put_new(supports_acc, brick.id, brick_supports)}
    end)
  end

  defp fall_brick(brick, z_heights) do
    footprint = Brick.footprint(brick)
    max_z = Enum.map(footprint, fn coord -> z_heights[coord][:z] end) |> Enum.max()
    new_z = max_z + Brick.height(brick)

    Enum.reduce(footprint, {z_heights, []}, fn coord, {z_heights_acc, supported_by_acc} ->
      %{z: old_z, brick: old_brick_id} = z_heights_acc[coord]
      new_supported_by =
        if old_brick_id != nil && old_z == max_z do
          [old_brick_id | supported_by_acc]
        else
          supported_by_acc
        end

      new_z_heights = Map.put(z_heights_acc, coord, %{z: new_z, brick: brick.id})

      {new_z_heights, new_supported_by}
    end)
  end

  defp read_input do
    path = "input/day_22.txt"

    File.read!(path)
    |> String.trim()
  end

  defp parse_input(input) when is_binary(input) do
    for {line, index} <- Enum.with_index(String.split(input, "\n")) do
      [coord1, coord2] =
        for coord <- String.split(line, "~") do
          [x, y, z] = String.split(coord, ",") |> Enum.map(&String.to_integer/1)
          %Coordinate{x: x, y: y, z: z}
        end

      %Brick{id: index, start_coord: coord1, end_coord: coord2}
    end
  end
end
