defmodule ExLiveUrl.Url do
  @moduledoc """
  TODO
  """
  @moduledoc since: "0.2.0"
  @enforce_keys [:scheme, :host, :port, :path, :params]
  defstruct [:scheme, :host, :port, :path, :params]

  @typedoc since: "0.2.0"
  @type t :: %__MODULE__{
          scheme: :http | :https,
          host: String.t(),
          port: :inet.port_number(),
          path: ExLiveUrl.Path.t(),
          params: ExLiveUrl.Params.t()
        }

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(String.t()) :: t()
  def new(uri) when is_binary(uri) do
    uri = URI.parse(uri)

    %__MODULE__{
      scheme:
        case uri.scheme do
          "https" -> :https
          "http" -> :http
        end,
      host: uri.host,
      port: uri.port,
      path: ExLiveUrl.Path.new(uri.path || "/"),
      params: ExLiveUrl.Params.new(uri.query || "")
    }
  end

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec new(map(), String.t()) :: t()
  def new(params, uri) when is_map(params) and is_binary(uri) do
    uri = URI.parse(uri)

    %__MODULE__{
      scheme:
        case uri.scheme do
          "https" -> :https
          "http" -> :http
        end,
      host: uri.host,
      port: uri.port,
      path: ExLiveUrl.Path.new(uri.path || "/"),
      params: ExLiveUrl.Params.new(params)
    }
  end

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec to_relative_target(t()) :: String.t()
  def to_relative_target(%__MODULE__{} = url_state) do
    "#{url_state.path}?#{url_state.params}"
  end

  @doc """
  TODO
  """
  @doc since: "0.3.0"
  @spec to_absolute_target(t()) :: String.t()
  def to_absolute_target(%__MODULE__{} = url_state) do
    "#{url_state.scheme}://#{url_state.host}:#{url_state.port}#{to_relative_target(url_state)}"
  end
end
