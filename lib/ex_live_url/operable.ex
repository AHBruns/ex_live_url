defprotocol ExLiveUrl.Operable do
  @moduledoc false

  def apply(operation, url_state, socket)
end
