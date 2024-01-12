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

    pairs(hailstones)
    |> Enum.map(fn {h1, h2} -> intersection_2d(h1, h2) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(fn {intersection, t1, t2} -> t1 > 0 && t2 > 0 && in_bounds?(intersection, bound_min, bound_max) end)
    |> length()
  end

  @doc """
      iex> p2(example_string())
  """
  def p2(input) do
    input
    |> parse_input()
    |> pairs()
    |> Enum.find(fn {h1, h2} ->
      match?({:ok, _plane}, maybe_plane(h1, h2))
    end)


    # IDEA
    # 1. Find 2 parallel lines
    # 2. Find the plane between them
    # 3. Solution will be the line on this plane:
    #    Find intersections of 2 different lines with this plane, and draw a line between these points
    #    This line is the rock line.
    #    Now need to find the velocity (scalar multiple of found direction) and starting point to modify the line
    #    - Set the direction as the unit vector for now, let that be called u
    # 4. We know where the rock line is at what value of t
    # 5. Let t1 be the intersection time of the first line, and t2 the second
    #    Let i1 be the intersection coordinate of the first line, and i2 the second
    # 6. Set rock line to be i1 + (i2 - i1)/(t2-t1)t
    # 7. Solve the rock line for t = -t1
    #    - Because rock line at t = 0 is i1, but we know i1 occurs at t = t1, so we reverse it that amount to solve the actual equation for t = 0
    # 8. Sum the components and that's the answer!!!
  end

  @type position() :: {integer(), integer(), integer()}
  @type vector() :: {integer(), integer(), integer()}
  @type hailstone() :: {position(), vector()}
  @type collision() :: {float(), float()} | nil
  @type time() :: float()
  @type plane() :: {integer(), integer(), integer(), integer()}

  @spec parallel?(hailstone(), hailstone()) :: boolean()
  def parallel?({_p1, v1}, {_p2, v2}) do
    cross_product(v1, v2) == {0, 0, 0}
  end

  @spec cross_product(vector(), vector()) :: vector()
  def cross_product({dx1, dy1, dz1}, {dx2, dy2, dz2}) do
    {(dy1 * dz2) - (dz1 * dy2), (dz1 * dx2) - (dx1 * dz2), (dx1 * dy2) - (dy1 * dx2)}
  end

  @doc """
  Calculate the equation of the plane which contains the 3 given non-colinear points.
  Returns a 4-tuple {a, b, c, d} representing the equation ax + by + cz + d = 0.
  """
  @spec plane_from_3_points(position(), position(), position()) :: plane()
  def plane_from_3_points({x1, y1, z1} = p1, p2, p3) do
    v_12 = position_subtract(p2, p1)
    v_23 = position_subtract(p3, p2)
    {a, b, c} = cross_product(v_12, v_23)
    d = -1 * ((a * x1) + (b * y1) + (c * z1))

    {a, b, c, d}
  end

  @doc """
  Check if a plane contains a point.
  """
  @spec contains_point?(plane(), position()) :: boolean()
  def contains_point?({a, b, c, d}, {x, y, z}), do: (a * x) + (b * y) + (c * z) + d |> dbg() == 0

  @doc """
  Check if two hailstones are on the same plane.
  If so, return {:ok, plane}, otherwise return :error.
  """
  @spec maybe_plane(hailstone(), hailstone()) :: {:ok, plane()} | :error
  def maybe_plane({p1, v1}, {p2, v2}) do
    p3 = vector_add(p1, v1)
    plane = plane_from_3_points(p1, p2, p3)
    p4 = vector_add(p2, v2)

    if contains_point?(plane, p4) do
      {:ok, plane}
    else
      :error
    end
  end

  @spec vector_add(position(), vector()) :: position()
  def vector_add({x, y, z}, {dx, dy, dz}), do: {x + dx, y + dy, z + dz}

  @spec position_subtract(position(), position()) :: vector()
  def position_subtract({x1, y1, z1}, {x2, y2, z2}), do: {x1 - x2, y1 - y2, z1 - z2}

  @spec pairs([hailstone()]) :: Enumerable.t({hailstone(), hailstone()})
  def pairs(hailstones) do
    Stream.flat_map(0..(length(hailstones) - 2), fn i ->
      for j <- (i + 1)..(length(hailstones) - 1) do
        {Enum.at(hailstones, i), Enum.at(hailstones, j)}
      end
    end)
  end

  @spec intersection_2d(hailstone(), hailstone()) :: {collision(), float(), float()}
  def intersection_2d(h1, h2) do
    {{x1, _y1, _z1}, {dx1, _dy1, _dz1}} = h1
    {{x2, _y2, _z2}, {dx2, _dy2, _dz2}} = h2

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
