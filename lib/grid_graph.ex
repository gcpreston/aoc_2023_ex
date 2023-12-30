defmodule GridGraph do
  defstruct [:height, :width, :walls]

  @behaviour Graph

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

  @impl true
  def neighbors(graph, {row, col}) do
    [{row + 1, col}, {row - 1, col}, {row, col - 1}, {row, col + 1}]
    |> Enum.filter(fn location -> in_bounds(graph, location) end)
    |> Enum.filter(fn location -> passable(graph, location) end)
  end

  defp in_bounds(graph, {row, col}) do
    row >= 0 && row < graph.height && col >= 0 && col < graph.width
  end

  defp passable(graph, location) do
    !MapSet.member?(graph.walls, location)
  end
end
