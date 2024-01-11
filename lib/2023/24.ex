import AOC

aoc 2023, 24 do
  @moduledoc """
  https://adventofcode.com/2023/day/24
  """

  @doc """
      iex> p1(example_string())
  """
  def p1(input) do
    hailstones = parse_input(input)
    bound_min = 200000000000000
    bound_max = 400000000000000
    # bound_min = 7
    # bound_max = 27

    pairs =
      Enum.flat_map(0..(length(hailstones) - 2), fn i ->
        for j <- (i + 1)..(length(hailstones) - 1) do
          {Enum.at(hailstones, i), Enum.at(hailstones, j)}
        end
      end)

    pairs
    |> Enum.map(fn {h1, h2} -> intersection_2d(h1, h2) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn {intersection, t1, t2} -> t1 > 0 && t2 > 0 && in_bounds?(intersection, bound_min, bound_max) end)
    |> length()
  end

  @doc """
      iex> p2(example_string())
  """
  def p2(_input) do
  end

  @type position() :: {integer(), integer(), integer()}
  @type velocity() :: {integer(), integer(), integer()}
  @type hailstone() :: {position(), velocity()}
  @type collision() :: {float(), float()} | nil
  @type time() :: float()

  @spec intersection_2d(hailstone(), hailstone()) :: {collision(), float(), float()}
  def intersection_2d(h1, h2) do
    {{x1, y1, _z1}, {dx1, dy1, _dz1}} = h1
    {{x2, y2, _z2}, {dx2, dy2, _dz2}} = h2

    # Hailstone A: 19, 13, 30 @ -2, 1, -2
    # Hailstone B: 18, 19, 22 @ -1, -1, -2
    # Hailstones' paths will cross inside the test area (at x=14.333, y=15.333)
    # 14.333 = 19 + (-2 * t)
    # t = (ix - x) / dx
    #
    # y = (dy/dx)x + I
    # => 13 = (1/-2)(19) + I
    # => 13 = -9.5 + I
    # => I = 22.5
    #
    # => 19 = (-1/-1)(18) + I
    # => I = 1
    #
    # -(1/2)x + 22.5 = x + 1
    # => 21.5 = (43/2) = (3/2)x
    # => 43 = 3x
    # => x = 43/3 = 14.3333
    #
    # m1(x) + b1 = m2(x) + b2
    # (m1 - m2)x = b2 - b1
    # x = (b2 - b1) / (m1 - m2)
    # y = m1(x) + b1
    #
    # y = 14.333 + 1 = 15.333
    {m1, b1} = equation_2d(h1)
    {m2, b2} = equation_2d(h2)

    if m1 == m2 do
      nil
    else
      intersect_x = (b2 - b1) / (m1 - m2)
      intersect_y = (m1 * intersect_x) + b1
      intersect_time_a = (intersect_x - x1) / dx1
      intersect_time_b = (intersect_x - x2) / dx2

      {{intersect_x, intersect_y}, intersect_time_a, intersect_time_b}
    end
  end

  @doc """
  Find the slope and y-intersection of the hailstone.
  """
  @spec equation_2d(hailstone()) :: {float(), float()}
  def equation_2d({{x, y, _z}, {dx, dy, _dz}}) do
    m = dy / dx
    b = y - (m * x)
    {m, b}
  end

  @spec in_bounds?(collision(), integer(), integer()) :: boolean()
  def in_bounds?(nil, _, _), do: false
  def in_bounds?({x, y}, bound_min, bound_max), do: (bound_min < x) && (x < bound_max) && (bound_min < y) && (y < bound_max)

  @spec parse_input(String.t()) :: [hailstone()]
  def parse_input(input) do
    for line <- String.split(input, "\n") do
      ~r/(\d+),\s+(\d+),\s+(\d+)\s+@\s+(-?\d+),\s+(-?\d+),\s+(-?\d+)/
      |> Regex.run(line, capture: :all_but_first)
      |> Enum.map(&String.to_integer/1)
      |> then(fn [x, y, z, dx, dy, dz] -> {{x, y, z}, {dx, dy, dz}} end)
    end
  end
end
