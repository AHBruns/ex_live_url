defmodule ExLiveUrl.Operation do
  @moduledoc false

  @type t :: ExLiveUrl.Operable.t()

  def is_operation?(maybe_operation) do
    case ExLiveUrl.Operable.impl_for(maybe_operation) do
      nil -> false
      _impl -> true
    end
  end

  def send(operation, pid \\ self()), do: Kernel.send(pid, operation)

  def apply(operation, url_state, socket) do
    ExLiveUrl.Operable.apply(operation, url_state, socket)
  end
end
