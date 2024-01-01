defmodule RepeatingGridGraph do
  defstruct [:height, :width, :walls]

  @type grid_location() :: {integer(), integer()}
  @type t() :: %__MODULE__{
          height: integer(),
          width: integer(),
          walls: Enumerable.t(grid_location())
        }

  @spec new(integer(), integer(), Enumerable.t(grid_location())) :: t()
  def new(height, width, walls) do
    %__MODULE__{height: height, width: width, walls: MapSet.new(walls)}
  end
end

defimpl Graph, for: RepeatingGridGraph do
  use Memoize

  defmemo neighbors(graph, {row, col}) do
    [{row + 1, col}, {row - 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(fn location -> passable(graph, location) end)
  end

  defmemop passable(graph, {row, col}) do
    check_location = {Integer.mod(row, graph.height), Integer.mod(col, graph.width)}
    in_bounds_passable(graph, check_location)
  end

  defmemop in_bounds_passable(graph, location) do
    !MapSet.member?(graph.walls, location)
  end
end
