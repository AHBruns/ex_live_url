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

  defimpl String.Chars do
    def to_string(path) do
      "/" <> (path |> ExLiveUrl.Path.segments() |> Enum.reverse() |> Enum.join("/"))
    end
  end

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(String.t() | [String.t()]) :: t()
  def new("/" <> path), do: %__MODULE__{segments: path |> String.split("/") |> Enum.reverse()}
  def new(segments) when is_list(segments), do: %__MODULE__{segments: segments}

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec segments(t()) :: [String.t()]
  def segments(%__MODULE__{} = path), do: path.segments

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec update_segments(t(), (segments :: [String.t()] -> segments :: [String.t()])) :: t()
  def update_segments(%__MODULE__{} = path, update_fun) do
    path |> segments() |> then(update_fun) |> new()
  end
end
