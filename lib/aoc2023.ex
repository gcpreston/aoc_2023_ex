defmodule Aoc2023 do
  @moduledoc """
  Module for running solutions.
  """

  @doc """
  Run the solution for a day and part.

  ## Examples

      iex> Aoc2023Ex.run(22, 1)
      5
  """
  def run(day, part) when is_integer(day) and is_integer(part) do
    module_name = :"Elixir.Aoc2023.Day#{day}"
    module_name.run(part)
  end
end
