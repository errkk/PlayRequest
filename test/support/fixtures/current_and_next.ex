defmodule PRWeb.Fixtures.Sonos.CurrentAndNext do
  def json do
    %{
      "container" => %{
        "id" => %{
          "accountId" => "sn_1",
          "objectId" => "spotify:playlist:10BW8wAqc52G1eic70NSJr",
          "serviceId" => "9"
        },
        "name" => "PlayRequestDev",
        "service" => %{"id" => "9", "name" => "Spotify"},
        "type" => "playlist"
      },
      "currentItem" => %{
        "track" => %{
          "album" => %{"name" => "One Offs (Remixes & B Sides)"},
          "artist" => %{"name" => "Pilote"},
          "durationMillis" => 310_000,
          "id" => %{
            "accountId" => "sn_1",
            "objectId" => "spotify:track:0XhXnY0lBzbdEWktDHknsl",
            "serviceId" => "9"
          },
          "imageUrl" =>
            "http://192.168.86.118:1400/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a0XhXnY0lBzbdEWktDHknsl%3fsid%3d9%26flags%3d8224%26sn%3d1",
          "name" => "Turtle - Bonobo Mix",
          "service" => %{"id" => "9", "name" => "Spotify"},
          "type" => "track"
        }
      },
      "nextItem" => %{
        "track" => %{
          "album" => %{"name" => "Animal Magic"},
          "artist" => %{"name" => "Bonobo"},
          "durationMillis" => 324_000,
          "id" => %{
            "accountId" => "sn_1",
            "objectId" => "spotify:track:1hHswNRFdwR5HZSBKdVEOs",
            "serviceId" => "9"
          },
          "imageUrl" =>
            "http://192.168.86.118:1400/getaa?s=1&u=x-sonos-spotify%3aspotify%253atrack%253a1hHswNRFdwR5HZSBKdVEOs%3fsid%3d9%26flags%3d8224%26sn%3d1",
          "name" => "Kota",
          "service" => %{"id" => "9", "name" => "Spotify"},
          "type" => "track"
        }
      }
    }
    |> Jason.encode!()
  end
end
