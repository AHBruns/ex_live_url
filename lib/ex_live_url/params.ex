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

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(String.t() | map()) :: t()
  def new(entries) when is_map(entries), do: %__MODULE__{entries: validate!(entries)}
  def new(query_string), do: %__MODULE__{entries: Plug.Conn.Query.decode(query_string)}

  @behaviour Access

  @impl Access
  def fetch(params, key), do: Map.fetch(params.entries, key)

  @impl Access
  def get_and_update(params, key, fun) do
    {current_value, new_entries} = Map.get_and_update(params.entries, key, fun)
    {current_value, %__MODULE__{entries: validate!(new_entries)}}
  end

  @impl Access
  def pop(params, key, default \\ nil) do
    {val, updated_entries} = Map.pop(params.entries, key, default)
    {val, %__MODULE__{entries: updated_entries}}
  end

  defimpl String.Chars do
    def to_string(params), do: Plug.Conn.Query.encode(params.entries)
  end

  defimpl Inspect do
    def inspect(path, opts) do
      Inspect.Algebra.concat([
        "ExLiveUrl.Params.new(",
        Inspect.Map.inspect(path.entries, opts),
        ")"
      ])
    end
  end

  defimpl Enumerable do
    def count(params), do: Enumerable.count(params.entries)
    def member?(params, maybe_entry), do: Enumerable.member?(params.entries, maybe_entry)
    def reduce(params, command, fun), do: Enumerable.reduce(params.entries, command, fun)
    def slice(params), do: Enumerable.slice(params.entries)
  end

  defimpl Collectable do
    def into(initial_params) do
      {initial_entries, collector} = Collectable.Map.into(initial_params.entries)

      {initial_entries,
       fn
         entries, :done -> ExLiveUrl.Params.new(entries)
         entries, command -> collector.(entries, command)
       end}
    end
  end

  defp validate!(value) when is_binary(value) do
    value
  end

  defp validate!(value) when is_list(value) do
    Enum.map(value, &validate!/1)
  end

  defp validate!(map_value) when is_map(map_value) do
    map_value
    |> Enum.map(fn {key, value} ->
      if is_binary(key) do
        {key, validate!(value)}
      else
        raise "Invalid params key, #{inspect(key)}. Binary expected."
      end
    end)
    |> Map.new()
  end

  defp validate!(value) do
    raise "Invalid params value, #{inspect(value)}. Map, List, or Binary expected."
  end
end
