defmodule ExLiveUrl.Client do
  @moduledoc false

  @doc false
  def send_operation(pid \\ self(), build_fun) do
    send(pid, {__MODULE__, :build_and_apply_operation, build_fun})
    :ok
  end
end
