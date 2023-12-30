defmodule Graph do
  @type location() :: any()
  @type t() :: any()

  @callback neighbors(t(), location()) :: [location()]
end
