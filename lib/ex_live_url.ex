defmodule ExLiveUrl do
  @moduledoc ~S'''
  `ExLiveUrl` is just some simple Phoenix LiveView lifecycle hooks and helper functions. It helps you store the live view's current query params and path in your assigns. Additionally, it exposes ways to work with those values both synchronously (only from the root live view) and asynchronously (from anywhere).

  # Installation

  You can install `ExLiveUrl` like so:

  ```elixir
  defp deps do
    [
      {:ex_live_url, "~> 0.2.0"}
    ]
  end
  ```

  To use `ExLiveUrl` you will need to call `Phoenix.LiveView.on_mount/1` with the module, `ExLiveUrl` in your live view. For example:

  ```elixir
  defmodule YourLiveView do
    use Phoenix.LiveView

    on_mount ExLiveUrl

    # your live view implementation
  end
  ```
  '''
  @moduledoc since: "0.1.0"

  @doc false
  def on_mount(key, _params, _session, socket) do
    {:cont,
     socket
     |> Phoenix.LiveView.attach_hook(__MODULE__, :handle_params, fn params, uri, socket ->
       {:cont, Phoenix.Component.assign(socket, key, ExLiveUrl.Url.new(params, uri))}
     end)
     |> Phoenix.LiveView.attach_hook(__MODULE__, :handle_info, fn maybe_operation, socket ->
       if ExLiveUrl.Operation.is_operation?(maybe_operation) do
         {:halt, ExLiveUrl.Operation.apply(maybe_operation, socket.assigns[key], socket)}
       else
         {:cont, socket}
       end
     end)}
  end

  @doc """
  Asynchronously annotates the socket for navigation within the current LiveView. Whenever this operation is eventually executed it calls `Phoenix.LiveView.push_navigate/2` internally.

  ## Options

  - `:to` - a function which takes the current `ExLiveUrl.Url` and must return either a new `ExLiveUrl.Url` or a relative url string.
  - `:replace` - the flag to replace the current history or push a new state. Defaults false.

  ## Examples

  ```elixir
  ExLiveUrl.push_patch(to: fn url -> %ExLiveUrl.Url{url | path: ExLiveUrl.Path.new("/")} end)
  ExLiveUrl.push_patch(to: fn _url -> "/"} end)
  ExLiveUrl.push_patch(
    to: fn url -> %ExLiveUrl.Url{url | path: ExLiveUrl.Path.new("/")} end,
    replace: true
  )
  ```
  """
  @doc since: "0.3.0"
  def push_patch(pid \\ self(), opts) do
    opts |> ExLiveUrl.PushPatchOperation.new() |> ExLiveUrl.Operation.send(pid)
  end

  @doc """
  Asynchronously annotates the socket for navigation to another LiveView. Whenever this operation is eventually executed it calls `Phoenix.LiveView.push_navigate/2` internally.

  ## Options

  - `:to` - a function which takes the current `ExLiveUrl.Url` and must return either a new `ExLiveUrl.Url` or a relative url string.
  - `:replace` - the flag to replace the current history or push a new state. Defaults false.

  ## Examples

  ```elixir
  ExLiveUrl.push_navigate(to: fn url -> %ExLiveUrl.Url{url | path: ExLiveUrl.Path.new("/")} end)
  ExLiveUrl.push_navigate(to: fn _url -> "/"} end)
  ExLiveUrl.push_navigate(
    to: fn url -> %ExLiveUrl.Url{url | path: ExLiveUrl.Path.new("/")} end,
    replace: true
  )
  ```
  """
  @doc since: "0.3.0"
  def push_navigate(pid \\ self(), opts) do
    opts |> ExLiveUrl.PushNavigateOperation.new() |> ExLiveUrl.Operation.send(pid)
  end

  @doc """
  Asynchronously annotates the socket for redirect to a destination path. Whenever this operation is eventually executed it calls `Phoenix.LiveView.redirect/2` internally.

  > Note: LiveView redirects rely on instructing client to perform a `window.location` update on the provided redirect location. The whole page will be reloaded and all state will be discarded.

  ## Options

  - `:to` - a function which takes the current `ExLiveUrl.Url` and must return either a new `ExLiveUrl.Url` or a relative url string. It must always be a local path.
  - `:external` - a function which takes the current `ExLiveUrl.Url` and must return either a new `ExLiveUrl.Url` or a fully qualified url string.

  ## Examples

  ```elixir
  ExLiveUrl.redirect(to: fn url -> %ExLiveUrl.Url{url | path: ExLiveUrl.Path.new("/")} end)
  ExLiveUrl.redirect(to: fn _url -> "/"} end)
  ExLiveUrl.redirect(external: fn _url -> "https://google.com"} end)
  ```
  """
  @doc since: "0.3.0"
  def redirect(pid \\ self(), opts) do
    opts |> ExLiveUrl.RedirectOperation.new() |> ExLiveUrl.Operation.send(pid)
  end
end
