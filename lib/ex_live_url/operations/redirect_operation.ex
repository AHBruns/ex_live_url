defmodule ExLiveUrl.RedirectOperation do
  @moduledoc false

  @enforce_keys [:fun, :mode]
  defstruct [:fun, :mode]

  @opaque t :: %__MODULE__{
            fun:
              (url_state :: ExLiveUrl.Url.t(), socket :: Phoenix.LiveView.Socket.t() ->
                 target :: String.t() | ExLiveUrl.Url.t()),
            mode: :to | :external
          }

  def new(to: fun), do: %__MODULE__{mode: :to, fun: fun}
  def new(external: fun), do: %__MODULE__{mode: :external, fun: fun}

  defimpl ExLiveUrl.Operable do
    def apply(
          %ExLiveUrl.RedirectOperation{mode: :to} = operation,
          %ExLiveUrl.Url{} = url_state,
          %Phoenix.LiveView.Socket{} = socket
        ) do
      target =
        case operation.fun.(url_state, socket) do
          %ExLiveUrl.Url{} = url_state -> ExLiveUrl.Url.to_relative_target(url_state)
          string_target when is_binary(string_target) -> string_target
        end

      Phoenix.LiveView.redirect(socket, to: target)
    end

    def apply(
          %ExLiveUrl.RedirectOperation{mode: :external} = operation,
          %ExLiveUrl.Url{} = url_state,
          %Phoenix.LiveView.Socket{} = socket
        ) do
      target =
        case operation.fun.(url_state, socket) do
          %ExLiveUrl.Url{} = url_state -> ExLiveUrl.Url.to_absolute_target(url_state)
          string_target when is_binary(string_target) -> string_target
        end

      Phoenix.LiveView.redirect(socket, external: target)
    end
  end
end
