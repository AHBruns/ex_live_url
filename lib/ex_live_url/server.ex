defmodule ExLiveUrl.Server do
  @moduledoc false

  @doc false
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> Phoenix.LiveView.attach_hook(
       __MODULE__,
       :handle_params,
       &ExLiveUrl.Server.handle_params_hook/3
     )
     |> Phoenix.LiveView.attach_hook(
       __MODULE__,
       :handle_info,
       &ExLiveUrl.Server.handle_info_hook/2
     )}
  end

  @doc false
  def handle_params_hook(params, uri, socket) do
    {:cont,
     Phoenix.Component.assign(
       socket,
       __MODULE__,
       uri
       |> ExLiveUrl.Url.from_string()
       |> ExLiveUrl.Url.with_params(params)
     )}
  end

  @doc false
  def handle_info_hook({__MODULE__, :build_and_apply_operation, build_fun}, socket) do
    {:halt, ExLiveUrl.Operation.apply(socket, build_fun.(socket.assigns[__MODULE__]))}
  end

  def handle_info_hook(_message, socket), do: {:cont, socket}
end
