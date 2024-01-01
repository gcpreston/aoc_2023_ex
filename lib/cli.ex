defmodule CLI do
  def main(args \\ []) do
    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args(args) when is_list(args) and length(args) == 2 do
    [day, part] = Enum.map(args, &String.to_integer/1)
    {day, part}
  end

  defp response({day, part}) do
    Aoc2023.run(day, part)
  end
end
