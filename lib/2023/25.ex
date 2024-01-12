import AOC

aoc 2023, 25 do
  @moduledoc """
  https://adventofcode.com/2023/day/25
  """

  alias Common.UUGraph

  @doc """
      iex> p1(example_string())
  """
  def p1(input) do
    g =
      parse_input(input)
      |> UUGraph.remove_edge("hcf", "lhn")
      |> UUGraph.remove_edge("nxk", "dfk")
      |> UUGraph.remove_edge("ldl", "fpg")

    # data =
    #   Enum.flat_map(g.adjacencies, fn {k, v} ->
    #     Enum.map(v, fn other -> "#{k},#{other}" end)
    #   end)
    #   |> Enum.join("\n")

    # File.write("test.txt", data)

    # hcf - lhn
    # nxk - dfk
    # ldl - fpg
    #
    # Node in cluster 1: zpz
    # Node in cluster 2: cjc

    n1 = "zpz"
    n2 = "cjc"
    n3 = "spg"

    s1 = UUGraph.cluster_size(g, n1) |> dbg()
    s2 = UUGraph.cluster_size(g, n2) |> dbg()
    UUGraph.cluster_size(g, n3) |> dbg()

    s1 * s2
  end

  @doc """
      iex> p2(example_string())
  """
  def p2(_input) do
  end

  @spec parse_input(String.t()) :: UUGraph.t()
  def parse_input(input) do
    data =
      for line <- String.split(input, "\n") do
        [first | [rest]] = String.split(line, ": ")
        connections = String.split(rest, " ")
        {first, connections}
      end

    Enum.reduce(data, UUGraph.new(), fn {first, conns}, outer_graph ->
      Enum.reduce(conns, outer_graph, fn node, inner_graph ->
        UUGraph.add_edge(inner_graph, first, node)
      end)
    end)
  end
end
