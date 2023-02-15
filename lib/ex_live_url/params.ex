defmodule ExLiveUrl.Params do
  @moduledoc """
  TODO
  """
  @moduledoc since: "0.3.0"
  @enforce_keys [:entries]
  defstruct [:entries]

  @typedoc since: "0.3.0"
  @opaque t :: %__MODULE__{
            entries: map()
          }

  defimpl String.Chars do
    def to_string(params), do: params |> ExLiveUrl.Params.entries() |> Plug.Conn.Query.encode()
  end

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(String.t() | map()) :: t()
  def new(entries) when is_map(entries), do: %__MODULE__{entries: entries}
  def new(query_string), do: %__MODULE__{entries: Plug.Conn.Query.decode(query_string)}

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec entries(t()) :: map()
  def entries(%__MODULE__{} = params), do: params.entries

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec update_entries(t(), (entries :: map() -> entries :: map())) :: t()
  def update_entries(%__MODULE__{} = params, update_fun) do
    params |> entries() |> then(update_fun) |> new()
  end
end
