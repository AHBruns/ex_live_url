defmodule ExLiveUrl.Path do
  @moduledoc """
  TODO
  """
  @moduledoc since: "0.3.0"
  @enforce_keys [:segments]
  defstruct [:segments]

  @typedoc since: "0.3.0"
  @opaque t :: %__MODULE__{
            segments: [String.t()]
          }

  @doc false
  def sigil_P(string, []), do: new(string)

  @doc """
  TODO
  """
  @doc since: "0.3.2"
  @spec new :: t()
  def new, do: new([])

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(String.t() | [String.t()]) :: t()
  def new("/"), do: new([])
  def new("/" <> path), do: path |> String.split("/") |> new()
  def new(segments) when is_list(segments), do: %__MODULE__{segments: segments}

  defimpl String.Chars do
    def to_string(path) do
      "/" <> Enum.join(path, "/")
    end
  end

  defimpl Inspect do
    def inspect(path, _opts) do
      Inspect.Algebra.concat(["ExLiveUrl.Path.new(", "\"" <> to_string(path) <> "\"", ")"])
    end
  end

  defimpl Enumerable do
    def count(path), do: Enumerable.count(path.segments)
    def member?(path, maybe_segment), do: Enumerable.member?(path.segments, maybe_segment)
    def reduce(path, command, fun), do: Enumerable.reduce(path.segments, command, fun)
    def slice(path), do: Enumerable.slice(path.segments)
  end

  defimpl Collectable do
    def into(path) do
      {path.segments,
       fn
         segments, :done -> %ExLiveUrl.Path{segments: segments}
         segments, {:cont, segment} -> Enum.reverse([segment | Enum.reverse(segments)])
         _segments, :halt -> :ok
       end}
    end
  end
end
