defmodule ExLiveUrl.Operation do
  @moduledoc """
  `ExLiveUrl.Operation` structs represent url operations. An operation consists of a `:url` which the operation targets, a `:mode` which indicates how the server should get to the target (updating the current view, mounting a new view, or going to an external url), and a `:stack_operation` which indicates how applying the operation should update the browser's history stack (pushing a history entry, replacing the current history entry, or updating window.location entirely).
  """
  @moduledoc since: "0.2.0"

  @derive Inspect
  @enforce_keys [:url, :mode, :stack_operation]
  defstruct [:url, :mode, :stack_operation]

  @typedoc since: "0.2.0"
  @type t() :: %__MODULE__{
          url: ExLiveUrl.Url.t(),
          mode: :intra_view | :inter_view | :external,
          stack_operation: :push | :replace | :redirect
        }

  defimpl String.Chars do
    def to_string(operation), do: inspect(operation)
  end

  @doc """
  Build a push patch operation.

      iex> ExLiveUrl.Operation.push_patch(to: ExLiveUrl.Url.from_string("https://google.com"))
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :intra_view,
        stack_operation: :push
      }

      iex> ExLiveUrl.Operation.push_patch(to: ExLiveUrl.Url.from_string("https://google.com"), replace: true)
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :intra_view,
        stack_operation: :replace
      }
  """
  @doc since: "0.2.0"
  @spec push_patch([to: ExLiveUrl.Url.t()] | [to: ExLiveUrl.Url.t(), replace: true]) ::
          ExLiveUrl.Operation.t()
  def push_patch(opts) do
    url = Keyword.fetch!(opts, :to)

    stack_operation =
      if Keyword.get(opts, :replace, false) do
        :replace
      else
        :push
      end

    %__MODULE__{
      url: url,
      mode: :intra_view,
      stack_operation: stack_operation
    }
  end

  @doc """
  Build a push navigate operation.

      iex> ExLiveUrl.Operation.push_navigate(to: ExLiveUrl.Url.from_string("https://google.com"))
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :inter_view,
        stack_operation: :push
      }

      iex> ExLiveUrl.Operation.push_navigate(to: ExLiveUrl.Url.from_string("https://google.com"), replace: true)
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :inter_view,
        stack_operation: :replace
      }
  """
  @doc since: "0.2.0"
  @spec push_navigate([to: ExLiveUrl.Url.t()] | [to: ExLiveUrl.Url.t(), replace: true]) ::
          ExLiveUrl.Operation.t()
  def push_navigate(opts) do
    url = Keyword.fetch!(opts, :to)

    stack_operation =
      if Keyword.get(opts, :replace, false) do
        :replace
      else
        :push
      end

    %__MODULE__{
      url: url,
      mode: :inter_view,
      stack_operation: stack_operation
    }
  end

  @doc """
  Build a redirect operation.

      iex> ExLiveUrl.Operation.redirect(to: ExLiveUrl.Url.from_string("https://google.com"))
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :inter_view,
        stack_operation: :redirect
      }

      iex> ExLiveUrl.Operation.redirect(external: "https://google.com")
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :external,
        stack_operation: :redirect
      }

      iex> ExLiveUrl.Operation.redirect(external: ExLiveUrl.Url.from_string("https://google.com"))
      %ExLiveUrl.Operation{
        url: %ExLiveUrl.Url{
          scheme: :https,
          host: "google.com",
          port: 443,
          path: "/",
          params: %{}
        },
        mode: :external,
        stack_operation: :redirect
      }
  """
  @doc since: "0.2.0"
  @spec redirect([to: ExLiveUrl.Url.t()] | [external: String.t() | ExLiveUrl.Url.t()]) ::
          ExLiveUrl.Operation.t()
  def redirect([to: url] = _opts) do
    %__MODULE__{
      url: url,
      mode: :inter_view,
      stack_operation: :redirect
    }
  end

  def redirect([external: url] = _opts) when is_binary(url) do
    redirect(external: ExLiveUrl.Url.from_string("https://google.com"))
  end

  def redirect([external: url] = _opts) do
    %__MODULE__{
      url: url,
      mode: :external,
      stack_operation: :redirect
    }
  end

  @doc """
  Apply an operation to the given socket.

      iex> socket = %Phoenix.LiveView.Socket{
      ...>   assigns: %{
      ...>     :__changed__ => %{},
      ...>     ExLiveUrl => ExLiveUrl.Url.from_string("http://apple.com")
      ...>   }
      ...> }
      iex> ExLiveUrl.Operation.apply(socket, ExLiveUrl.Operation.redirect(external: "https://google.com"))
      %Phoenix.LiveView.Socket{
        assigns: %{
          :__changed__ => %{},
          ExLiveUrl => %ExLiveUrl.Url{
            scheme: :http,
            host: "apple.com",
            port: 80,
            path: "/",
            params: %{}
          }
        },
        redirected: {:redirect, %{external: "https://google.com:443/?"}}
      }
  """
  @doc since: "0.2.0"
  @spec apply(Phoenix.LiveView.Socket.t(), t()) :: Phoenix.LiveView.Socket.t()
  def apply(%Phoenix.LiveView.Socket{} = socket, %__MODULE__{} = operation) do
    relative_target = ExLiveUrl.Url.to_relative(operation.url)

    case {operation.mode, operation.stack_operation} do
      {:intra_view, :push} ->
        Phoenix.LiveView.push_patch(socket, to: relative_target)

      {:intra_view, :replace} ->
        Phoenix.LiveView.push_patch(socket, to: relative_target, replace: true)

      {:inter_view, :push} ->
        Phoenix.LiveView.push_navigate(socket, to: relative_target)

      {:inter_view, :replace} ->
        Phoenix.LiveView.push_navigate(socket, to: relative_target, replace: true)

      {:inter_view, :redirect} ->
        Phoenix.LiveView.redirect(socket, to: relative_target)

      {:external, :redirect} ->
        Phoenix.LiveView.redirect(socket, external: to_string(operation.url))
    end
  end
end
