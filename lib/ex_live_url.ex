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
      ...>     :ok = ExLiveUrl.send_operation(fn url ->
      ...>       ExLiveUrl.Operation.push_patch(to: ExLiveUrl.Url.with_params(url, fn params ->
      ...>         Map.update(params, "direction", "asc", fn
      ...>           "asc" -> "desc"
      ...>           "desc" -> "asc"
      ...>         end)
      ...>       end))
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

  @doc false
  defdelegate on_mount(arg, params, session, socket), to: ExLiveUrl.Server

  @doc """
  > Tip: This function may only be called with the root live view's socket. If you need to, for example, call this from a live component, you should use `send_operation/2`.

  Synchronously build and apply an operation. The build function takes the current `ExLiveUrl.Url` as an argument and must return an `ExLiveUrl.Operation`. The given pid must be a root live view.

  This is an alias for `ExLiveUrl.Operation.apply/2`.
  """
  @doc since: "0.2.0"
  @spec apply_operation(Phoenix.LiveView.Socket.t(), ExLiveUrl.Operation.t()) ::
          Phoenix.LiveView.Socket.t()
  defdelegate apply_operation(socket, operation), to: ExLiveUrl.Operation, as: :apply

  @doc """
  A special case of `send_operation/2` which uses `self()` as the given pid.
  """
  @doc since: "0.2.0"
  @spec send_operation((ExLiveUrl.Url.t() -> ExLiveUrl.Operation.t())) :: :ok
  defdelegate send_operation(fun), to: ExLiveUrl.Client

  @doc """
  Asynchronously build and apply an operation. The build function takes the current `ExLiveUrl.Url` as an argument and must return an `ExLiveUrl.Operation`. The given pid must be a root live view.
  """
  @doc since: "0.2.0"
  @spec send_operation(pid(), (ExLiveUrl.Url.t() -> ExLiveUrl.Operation.t())) :: :ok
  defdelegate send_operation(pid, fun), to: ExLiveUrl.Client
end
