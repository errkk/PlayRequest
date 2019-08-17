defmodule E.PlayState do
  @moduledoc false

  @topic inspect(__MODULE__)

  def subscribe do
    Phoenix.PubSub.subscribe(EWeb.PubSub, @topic)
  end

  def handle_playstate(result) do
    result = E.SonosAPI.convert_result(result)
    Phoenix.PubSub.broadcast(EWeb.PubSub, @topic, {__MODULE__, result, :play_state})
  end

  def handle_metadata(result) do
    result = E.SonosAPI.convert_result(result)
    Phoenix.PubSub.broadcast(EWeb.PubSub, @topic, {__MODULE__, result, :metadata})
  end

end

