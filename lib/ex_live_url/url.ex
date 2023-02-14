defmodule ExLiveUrl.Url do
  @moduledoc """
  `ExLiveUrl.Url` structs represent fully qualified urls. You can think of them as bespoke `URI` structs.
  """
  @moduledoc since: "0.2.0"

  @derive Inspect
  @enforce_keys [:scheme, :host, :port, :path, :params]
  defstruct [:scheme, :host, :port, :path, :params]

  @typedoc since: "0.2.0"
  @type t() :: %__MODULE__{
          scheme: :https | :http,
          host: String.t(),
          port: :inet.port_number(),
          path: String.t(),
          params: Phoenix.LiveView.unsigned_params()
        }

  defimpl String.Chars do
    @spec to_string(ExLiveUrl.Url.t()) :: <<_::32, _::_*8>>
    def to_string(%ExLiveUrl.Url{} = url) do
      "#{url.scheme}://#{url.host}:#{url.port}#{url.path}?#{Plug.Conn.Query.encode(url.params)}"
    end
  end

  @doc """
  This function serializes a `ExLiveUrl.Url` to a relative link, aka just the path and query params.

      iex> ExLiveUrl.Url.to_relative(
      ...>   %ExLiveUrl.Url{
      ...>     scheme: :https,
      ...>     host: "google.com",
      ...>     port: 443,
      ...>     path: "/abc",
      ...>     params: %{"a" => "b"}
      ...>   }
      ...> )
      "/abc?a=b"
  """
  @doc since: "0.2.0"
  @spec to_relative(t()) :: String.t()
  def to_relative(%__MODULE__{} = url) do
    "#{url.path}?#{Plug.Conn.Query.encode(url.params)}"
  end

  @doc """
  This function turns a `URI` into a `ExLiveUrl.Url`. The given `URI` must be absolute.

      iex> ExLiveUrl.Url.from_uri(
      ...>   %URI{
      ...>     scheme: "https",
      ...>     host: "google.com",
      ...>     port: 443,
      ...>     path: "/abc",
      ...>     query: "a[]=b&a[]=c",
      ...>   }
      ...> )
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{"a" => ["b", "c"]}
      }
  """
  @doc since: "0.2.0"
  @spec from_uri(URI.t()) :: t()
  def from_uri(%URI{} = uri)
      when uri.scheme in ["http", "https"] and
             not is_nil(uri.host) and
             not is_nil(uri.port) do
    scheme =
      case uri.scheme do
        "http" -> :http
        "https" -> :https
      end

    params = Plug.Conn.Query.decode(uri.query || "")
    path = uri.path || "/"

    %__MODULE__{
      scheme: scheme,
      host: uri.host,
      port: uri.port,
      path: path,
      params: params
    }
  end

  @doc """
  This function turns a string into a `ExLiveUrl.Url`. The given string must be absolute url.

      iex> ExLiveUrl.Url.from_string("https://google.com/abc?a[]=b&a[]=c")
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{"a" => ["b", "c"]}
      }
  """
  @doc since: "0.2.0"
  @spec from_string(String.t()) :: t()
  def from_string("" <> _ = string) do
    string
    |> URI.parse()
    |> from_uri()
  end

  @doc """
  This function sets the scheme of an `ExLiveUrl.Url` either directly or via an updater function.

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_scheme(:http)
      %ExLiveUrl.Url{
        scheme: :http,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{}
      }

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_scheme(fn :https -> :http end)
      %ExLiveUrl.Url{
        scheme: :http,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{}
      }
  """
  @doc since: "0.2.0"
  @spec with_scheme(t(), scheme_or_updater :: :http | :https | (:http | :https -> :http | :https)) ::
          t()
  def with_scheme(%__MODULE__{} = url, scheme) when scheme in [:http, :https] do
    %__MODULE__{url | scheme: scheme}
  end

  def with_scheme(%__MODULE__{} = url, scheme_fun) when is_function(scheme_fun, 1) do
    %__MODULE__{url | scheme: scheme_fun.(url.scheme)}
  end

  @doc ~S"""
  This function sets the host of an `ExLiveUrl.Url` either directly or via an updater function.

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_host("apple.com")
      %ExLiveUrl.Url{
        scheme: :https,
        host: "apple.com",
        port: 443,
        path: "/abc",
        params: %{}
      }

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_host(fn host -> "www.#{host}" end)
      %ExLiveUrl.Url{
        scheme: :https,
        host: "www.google.com",
        port: 443,
        path: "/abc",
        params: %{}
      }
  """
  @doc since: "0.2.0"
  @spec with_host(t(), host_or_updater :: String.t() | (String.t() -> String.t())) :: t()
  def with_host(%__MODULE__{} = url, "" <> _ = host) do
    %__MODULE__{url | host: host}
  end

  def with_host(%__MODULE__{} = url, host_fun) when is_function(host_fun, 1) do
    %__MODULE__{url | host: host_fun.(url.host)}
  end

  @doc """
  This function sets the port of an `ExLiveUrl.Url` either directly or via an updater function.

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_port(1234)
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 1234,
        path: "/abc",
        params: %{}
      }

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_port(fn port -> port + 1 end)
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 444,
        path: "/abc",
        params: %{}
      }
  """
  @doc since: "0.2.0"
  @spec with_port(
          t(),
          port_or_updater :: :inet.port_number() | (:inet.port_number() -> :inet.port_number())
        ) :: t()
  def with_port(%__MODULE__{} = url, port) when port in 0..65535 do
    %__MODULE__{url | port: port}
  end

  def with_port(%__MODULE__{} = url, port_fun) when is_function(port_fun, 1) do
    %__MODULE__{url | port: port_fun.(url.port)}
  end

  @doc """
  This function sets the path of an `ExLiveUrl.Url` either directly or via an updater function.

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_path("/")
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/",
        params: %{}
      }

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_path(fn path -> path <> "/efg" end)
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/abc/efg",
        params: %{}
      }
  """
  @doc since: "0.2.0"
  @spec with_path(t(), path_or_updater :: String.t() | (String.t() -> String.t())) :: t()
  def with_path(%__MODULE__{} = url, "/" <> _ = path) do
    %__MODULE__{url | path: path}
  end

  def with_path(%__MODULE__{} = url, path_fun) when is_function(path_fun, 1) do
    %__MODULE__{url | path: path_fun.(url.path)}
  end

  @doc """
  This function sets the params of an `ExLiveUrl.Url` either directly or via an updater function.

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_params(%{"a" => ["b", "c"]})
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{"a" => ["b", "c"]}
      }

      iex> "https://google.com/abc"
      ...> |> ExLiveUrl.Url.from_string()
      ...> |> ExLiveUrl.Url.with_params(fn params -> Map.put(params, "a", ["b", "c"]) end)
      %ExLiveUrl.Url{
        scheme: :https,
        host: "google.com",
        port: 443,
        path: "/abc",
        params: %{"a" => ["b", "c"]}
      }
  """
  @doc since: "0.2.0"
  @spec with_params(
          t(),
          params_or_updater ::
            Phoenix.LiveView.unsigned_params()
            | (Phoenix.LiveView.unsigned_params() -> Phoenix.LiveView.unsigned_params())
        ) :: t()
  def with_params(%__MODULE__{} = url, %{} = params) do
    %__MODULE__{url | params: params}
  end

  def with_params(%__MODULE__{} = url, params_fun) when is_function(params_fun, 1) do
    %__MODULE__{url | params: params_fun.(url.params)}
  end
end
