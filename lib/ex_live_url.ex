defmodule ExLiveUrl do
  @moduledoc ~S'''
  `ExLiveUrl` is just some simple Phoenix LiveView lifecycle hooks and helper functions. It helps you store the live view's current query params and path in your assigns. Additionally, it exposes ways to work with those values both synchronously (only from the root live view) and asynchronously (from anywhere).

  # Installation

  You can install `ExLiveUrl` like so:

  ```elixir
  defp deps do
    [
      {:ex_live_url, "~> 0.1.0"}
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

  # Example

  A common use case for url state in live views is to store sorting and filtering information. Here's a working example of how you can implement such a use case with `ExLiveUrl`.

      iex> defmodule Example.SortControl do
      ...>   use Phoenix.LiveComponent
      ...>
      ...>   @impl Phoenix.LiveComponent
      ...>   def render(assigns) do
      ...>     ~H"""
      ...>     <button phx-click="toggle" phx-target={@myself}>
      ...>       <%= @direction || "sort" %>
      ...>     </button>
      ...>     """
      ...>   end
      ...>
      ...>   @impl Phoenix.LiveComponent
      ...>   def handle_event("toggle", _payload, socket) do
      ...>     :ok = ExLiveUrl.send_push_patch(fn url ->
      ...>       Map.update!(
      ...>         url,
      ...>         :params,
      ...>         &Map.update(
      ...>           &1,
      ...>           "direction",
      ...>           "asc",
      ...>           fn
      ...>             "asc" -> "desc"
      ...>             "desc" -> "asc"
      ...>           end
      ...>         )
      ...>       )
      ...>     end)
      ...>
      ...>     {:noreply, socket}
      ...>   end
      ...> end

      iex> defmodule Example.LiveView do
      ...>   use Phoenix.LiveView
      ...>   on_mount ExLiveUrl
      ...>
      ...>   @impl Phoenix.LiveView
      ...>   def render(assigns) do
      ...>     ~H"""
      ...>     <.live_component module={Example.SortControl} id="Example.SortControl" direction={@direction} />
      ...>     <p :for={name <- @names}><%= name %></p>
      ...>     """
      ...>   end
      ...>
      ...>   @impl Phoenix.LiveView
      ...>   def mount(_params, _session, socket) do
      ...>     {:ok, assign(socket, :names, ["John", "Jimmy", "Jack", "Joe"])}
      ...>   end
      ...>
      ...>   @impl Phoenix.LiveView
      ...>   def handle_params(params, _uri, socket) do
      ...>     {:ok,
      ...>      socket
      ...>      |> assign(:direction, params["direction"])
      ...>      |> update(
      ...>        :names,
      ...>        fn names ->
      ...>          case params["direction"] do
      ...>            "desc" -> Enum.sort(names, fn name_1, name_2 -> name_1 <= name_2 end)
      ...>            "asc" -> Enum.sort(names, fn name_1, name_2 -> name_1 >= name_2 end)
      ...>            nil -> names
      ...>          end
      ...>        end
      ...>      )}
      ...>   end
      ...> end
  '''
  @moduledoc since: "0.1.0"

  @typedoc """
  Must begin with `/` and not contain `//` or `\\`
  """
  @typedoc since: "0.1.0"
  @type path :: String.t()

  @typedoc """
  These are raw params, aka user input, so don't trust them. You should treat them just like you would params that you got directly from `c:Phoenix.LiveView.handle_params/3`.
  """
  @typedoc since: "0.1.0"
  @type params :: Phoenix.LiveView.unsigned_params()

  @typedoc """
  A relative url consisting of a path and query params. The scheme, domain, and port are all omitted.
  """
  @typedoc since: "0.1.0"
  @type url :: String.t()

  @typedoc """
  A fully qualified external url. E.g. https://google.com
  """
  @typedoc since: "0.1.0"
  @type external_url :: String.t()

  @typedoc since: "0.1.0"
  @type t :: %{
          required(:path) => path(),
          required(:params) => params()
        }

  @typedoc since: "0.1.0"
  @type push_patch_transformer ::
          (t() ->
             %{
               required(:path) => path(),
               required(:params) => params(),
               optional(:replace) => boolean()
             })

  @typedoc since: "0.1.0"
  @type push_navigate_transformer ::
          (t() ->
             %{
               required(:path) => path(),
               required(:params) => params(),
               optional(:replace) => boolean()
             })

  @typedoc since: "0.1.0"
  @type redirect_transformer :: (t() -> t() | external_url())

  @doc false
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> Phoenix.LiveView.attach_hook(__MODULE__, :handle_params, &handle_params_hook/3)
     |> Phoenix.LiveView.attach_hook(__MODULE__, :handle_info, &handle_info_hook/2)}
  end

  @doc false
  def handle_params_hook(params, uri, socket) do
    {:cont,
     Phoenix.Component.assign(
       socket,
       __MODULE__,
       %{params: params, path: URI.parse(uri).path}
     )}
  end

  @doc false
  def handle_info_hook({__MODULE__, method, transform_fun}, socket) do
    case method do
      :do_push_patch -> {:halt, push_patch(socket, transform_fun)}
      :do_push_navigate -> {:halt, push_navigate(socket, transform_fun)}
      :do_redirect -> {:halt, redirect(socket, transform_fun)}
    end
  end

  def handle_info_hook(_message, socket), do: {:cont, socket}

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider passing down this state via assigns.

  This function returns the live view's current path.

  ```elixir
  "/users/" <> id = ExLiveUrl.get_path(socket)
  ```
  """
  @doc since: "0.1.0"
  @spec get_path(Phoenix.LiveView.Socket.t()) :: path()
  def get_path(socket), do: socket.assigns[__MODULE__].path

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider passing down this state via assigns.

  This function returns the live view's current params.

  ```elixir
  %{"a" => a} = ExLiveUrl.get_params(socket)
  ```
  """
  @doc since: "0.1.0"
  @spec get_params(Phoenix.LiveView.Socket.t()) :: params()
  def get_params(socket), do: socket.assigns[__MODULE__].params

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider passing down this state via assigns.

  This function returns the live view's current url without the scheme, domain, or port.

  ```elixir
  the_current_url = ExLiveUrl.get_url(socket)
  ```
  """
  @doc since: "0.1.0"
  @spec get_url(Phoenix.LiveView.Socket.t()) :: url()
  def get_url(socket), do: build_url(socket.assigns[__MODULE__])

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider using `send_push_patch/1`.

  This function allows you to transform the current live view's path and params then, using `Phoenix.LiveView.push_patch/2`, navigate to the new path and params.

  ```elixir
  socket = ExLiveUrl.push_patch(socket, fn url ->
    %{path: url.path, params: Map.put(url.params, "example", "provided")}
  end)
  ```

  ```elixir
  socket = ExLiveUrl.push_patch(socket, fn _url ->
    %{path: url.path, params: Map.put(url.params, "example", "provided"), replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec push_patch(Phoenix.LiveView.Socket.t(), push_patch_transformer()) ::
          Phoenix.LiveView.Socket.t()
  def push_patch(socket, transform_fun) do
    result = transform_fun.(socket.assigns[__MODULE__])

    Phoenix.LiveView.push_patch(socket,
      to: build_url(result),
      replace: Map.get(result, :replace, false)
    )
  end

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider using `send_push_navigate/1`.

  This function allows you to transform the current live view's path and params then, using `Phoenix.LiveView.push_navigate/2`, navigate to the new path and params.

  ```elixir
  socket = ExLiveUrl.push_navigate(socket, fn _url ->
    %{path: "/some/other/live-view", params: %{}}
  end)
  ```

  ```elixir
  socket = ExLiveUrl.push_navigate(socket, fn _url ->
    %{path: "/some/other/live-view", params: %{}, replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec push_navigate(Phoenix.LiveView.Socket.t(), push_navigate_transformer()) ::
          Phoenix.LiveView.Socket.t()
  def push_navigate(socket, transform_fun) do
    result = transform_fun.(socket.assigns[__MODULE__])

    Phoenix.LiveView.push_navigate(socket,
      to: build_url(result),
      replace: Map.get(result, :replace, false)
    )
  end

  @doc """
  > #### Tip {: .tip}
  >
  > This function may only be called with the root live view's socket. If you need to call this function from a context without the root live view's socket, such as a live component, consider using `send_redirect/1`.

  This function allows you to transform the current live view's path and params into either an external url or a new path and params then, using `Phoenix.LiveView.redirect/2`, navigate to the either the external url or the new path and params.

  ```elixir
  socket = ExLiveUrl.redirect(socket, fn _url -> "https://google.com" end)
  ```

  ```elixir
  socket = ExLiveUrl.redirect(socket, fn _url ->
    %{path: "/some/internal/path", params: %{}}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec redirect(Phoenix.LiveView.Socket.t(), redirect_transformer()) ::
          Phoenix.LiveView.Socket.t()
  def redirect(socket, transform_fun) do
    Phoenix.LiveView.redirect(
      socket,
      case transform_fun.(socket.assigns[__MODULE__]) do
        result when is_binary(result) -> [external: result]
        result -> [to: build_url(result)]
      end
    )
  end

  @doc """
  Special case of `send_push_patch/2` which uses `self()` for the pid.

  ```elixir
  :ok = ExLiveUrl.send_push_patch(fn url ->
    %{url | params: Map.put(url, "example", "provided")}
  end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_push_patch(fn url ->
    %{path: url.path, params: Map.put(url, "example", "provided"), replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_push_patch(push_patch_transformer()) :: :ok
  def send_push_patch(transform_fun) do
    send_push_patch(self(), transform_fun)
  end

  @doc """
  This function allows you to asynchronously transform the current live view's path and params then, using `Phoenix.LiveView.push_patch/2`, navigate to the new path and params. The pid provided must be for a root live view process.

  ```elixir
  :ok = ExLiveUrl.send_push_patch(pid, fn url ->
    %{url | params: Map.put(url.params, "example", "provided")}
  end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_push_patch(pid, fn url ->
    %{path: url.path, params: Map.put(url.params, "example", "provided"), replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_push_patch(pid(), push_patch_transformer()) :: :ok
  def send_push_patch(pid, transform_fun) do
    exec(pid, :do_push_patch, transform_fun)
  end

  @doc """
  Special case of `send_push_navigate/2` which uses `self()` for the pid.

  ```elixir
  :ok = ExLiveUrl.send_push_navigate(fn _url ->
    %{path: "/some/other/live-view", params: %{}}
  end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_push_navigate(fn _url ->
    %{path: "/some/other/live-view", params: %{}, replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_push_navigate(push_navigate_transformer()) :: :ok
  def send_push_navigate(transform_fun) do
    send_push_navigate(self(), transform_fun)
  end

  @doc """
  This function allows you to asynchronously transform the a live view's path and params then, using `Phoenix.LiveView.push_navigate/2`, navigate to the new path and params. The pid provided must be for a root live view process.

  ```elixir
  :ok = ExLiveUrl.send_push_navigate(pid, fn _url ->
    %{path: "/some/other/live-view", params: %{}}
  end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_push_navigate(pid, fn _url ->
    %{path: "/some/other/live-view", params: %{}, replace: true}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_push_navigate(pid(), push_navigate_transformer()) :: :ok
  def send_push_navigate(pid, transform_fun) do
    exec(pid, :do_push_navigate, transform_fun)
  end

  @doc """
  Special case of `send_redirect/2` which uses `self()` for the pid.

  ```elixir
  :ok = ExLiveUrl.send_redirect(fn _url -> "https://google.com" end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_redirect(fn _url ->
    %{path: "/some/internal/path", params: %{}}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_redirect(redirect_transformer()) :: :ok
  def send_redirect(transform_fun) do
    send_redirect(self(), transform_fun)
  end

  @doc """
  This function allows you to asynchronously transform the a live view's path and params into either an external url or a new path and params then, using `Phoenix.LiveView.redirect/2`, navigate to the either the external url or the new path and params. The pid provided must be for a root live live process.

  ```elixir
  :ok = ExLiveUrl.send_redirect(pid, fn _url -> "https://google.com" end)
  ```

  ```elixir
  :ok = ExLiveUrl.send_redirect(pid, fn _url ->
    %{path: "/some/internal/path", params: %{}}
  end)
  ```
  """
  @doc since: "0.1.0"
  @spec send_redirect(pid(), redirect_transformer()) :: :ok
  def send_redirect(pid, transform_fun) do
    exec(pid, :do_redirect, transform_fun)
  end

  defp exec(pid, method, arg) do
    send(pid, {__MODULE__, method, arg})
    :ok
  end

  defp build_url(%{path: path, params: params}) do
    "#{path}?#{Plug.Conn.Query.encode(params)}"
  end
end
