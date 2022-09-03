defmodule PRWeb.Fixtures.Sonos.Error do
  def no_content do
    %{
      "errorCode" => "ERROR_PLAYBACK_NO_CONTENT",
      "reason" => "ERROR_NO_CONTENT"
    }
    |> Jason.encode!()
  end

  def lost_connection do
    %{
      "errorCode" => "ERROR_PLAYBACK_FAILED",
      "reason" => "ERROR_LOST_CONNECTION"
    }
    |> Jason.encode!()
  end
end
