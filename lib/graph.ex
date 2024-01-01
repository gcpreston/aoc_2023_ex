defprotocol Graph do
  @type location() :: any()
  @type t() :: any()

  @spec neighbors(t(), location()) :: [location()]
  def neighbors(graph, location)
end
