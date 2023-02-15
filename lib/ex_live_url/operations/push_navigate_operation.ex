defmodule ExLiveUrl.PushNavigateOperation do
  @moduledoc false

  @enforce_keys [:fun, :is_redirect]
  defstruct [:fun, :is_redirect]

  @opaque t :: %__MODULE__{
            fun:
              (url_state :: ExLiveUrl.Url.t(), socket :: Phoenix.LiveView.Socket.t() ->
                 target :: String.t() | ExLiveUrl.Url.t()),
            is_redirect: boolean()
          }

  def new(opts) do
    %__MODULE__{
      fun: Access.fetch!(opts, :to),
      is_redirect: Access.get(opts, :redirect, false)
    }
  end

  defimpl ExLiveUrl.Operable do
    def apply(
          operation,
          %ExLiveUrl.Url{} = url_state,
          %Phoenix.LiveView.Socket{} = socket
        ) do
      target =
        case operation.fun.(url_state, socket) do
          %ExLiveUrl.Url{} = url_state -> ExLiveUrl.Url.to_relative_target(url_state)
          string_target when is_binary(string_target) -> string_target
        end

      Phoenix.LiveView.push_navigate(socket, to: target, redirect: operation.is_redirect)
    end
  end
end
