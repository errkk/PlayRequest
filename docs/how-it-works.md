# How PlayRequest Works

PlayRequest is a shared "social jukebox". People queue Spotify tracks from their
phones, and the tracks play out of a set of Sonos speakers. Neither Spotify nor
Sonos offers a single API for "play this list of track IDs on these speakers", so
the system stitches together three things that they *do* expose:

1. A local, database-backed queue (the source of truth).
2. A Spotify playlist (kept in sync with the unplayed part of the queue).
3. A Sonos "favourite" that points at that playlist, triggered to play via the
   Sonos Control API, with playback events fed back in over a webhook.

This document explains how those pieces fit together, with references to the code
and the actual API calls involved.

---

## The core idea

```
  Users (LiveView)                 PlayRequest (Elixir/Phoenix)                 Cloud APIs
  ----------------                 ----------------------------                 ----------
  queue a track  ───────────────▶  tracks table (DB queue)
                                          │
                                          │ sync unplayed tracks
                                          ▼
                                   Spotify playlist  ──── PUT /playlists/{id}/tracks ───▶ Spotify
                                          │
                                          │ playlist is saved as a Sonos "favourite"
                                          ▼
                                   trigger playback ──── POST /groups/{gid}/favorites ──▶ Sonos
                                          │
        update UI  ◀──── PubSub ◀──── webhook  ◀──── POST /sonos/callback ◀───────────── Sonos
                                   (mark track played in DB)
```

The **database queue is the source of truth.** The Spotify playlist is a derived,
disposable projection of it (only the unplayed tracks). Sonos is told to play that
playlist, and Sonos tells us back what it is actually playing so we can mark tracks
as played.

---

## 1. The database queue

**Schema:** `PR.Queue.Track` - `lib/pr/queue/track.ex`
**Context:** `PR.Queue` - `lib/pr/queue/queue.ex`

Each queued track is a row in the `tracks` table. The important fields:

```elixir
field(:spotify_id, :string)          # Spotify track id; unique
field(:playing_since, :utc_datetime) # set when Sonos starts playing it
field(:played_at, :utc_datetime)     # set when it has finished / been superseded
belongs_to(:user, User)              # who queued it
```

A track's lifecycle is expressed entirely by those two timestamps:

- `playing_since == nil` and `played_at == nil` -> waiting in the queue
- `playing_since` set, `played_at == nil` -> currently playing
- `played_at` set -> done

A unique constraint (`unique_constraint(:spotify_id, name: :already_queued)`)
stops the same track being queued twice.

The "unplayed queue", used to build the Spotify playlist, is just:

```elixir
def list_track_uris do
  Track
  |> query_unplayed()      # WHERE played_at IS NULL
  |> order()               # ORDER BY inserted_at ASC
  |> limit(100)
  |> select([t], {t.spotify_id})
  |> Repo.all()
end
```

---

## 2. Queueing a track

**Module:** `PR.Music.queue/2` - `lib/pr/music/music.ex:39`

When a user queues a track from the LiveView, the flow is:

1. Fetch full track metadata from Spotify: `SpotifyAPI.get_track(id)`
   -> `GET https://api.spotify.com/v1/tracks/{id}`
2. Insert it into the DB queue: `Queue.create_track/1`
3. Broadcast `queue_updated()` over PubSub so every connected browser refreshes.
4. Decide what to do next based on whether music is already playing:

```elixir
if PlayState.is_idle?() do
  trigger_playlist()   # nothing playing: sync + start Sonos playback
else
  sync_playlist()      # already playing: just update the Spotify playlist
end
```

So queueing while music is playing only re-syncs the playlist (the new track
appears at the end). Queueing while idle kicks off the full "start playing"
pipeline described in section 4.

Searching for tracks works the same way:
`SpotifyAPI.search(q)` -> `GET /v1/search/?q={q}&type=track&market=GB&limit=10`.

---

## 3. Syncing the queue to the Spotify playlist

**Module:** `PR.Music.sync_playlist/0` - `lib/pr/music/music.ex:61`

This is the heart of the workaround. Whenever the queue changes, the unplayed
tracks are pushed into a single Spotify playlist, **replacing** its entire
contents:

```elixir
def sync_playlist do
  Queue.list_track_uris()
  |> Enum.map(fn {id} -> "spotify:track:" <> id end)
  |> SpotifyAPI.replace_playlist()
  {:ok}
end
```

`SpotifyAPI.replace_playlist/1` (`lib/pr/apis/spotify_api.ex`) does:

```
PUT https://api.spotify.com/v1/playlists/{playlist_id}/tracks
body: { "uris": ["spotify:track:abc", "spotify:track:def", ...] }
```

Using `PUT .../tracks` (replace) rather than `POST` (append) is what keeps the
playlist an exact mirror of the unplayed queue - already-played tracks drop off,
and the order matches `inserted_at`. The playlist itself is created once via
`POST /v1/users/{spotify_id}/playlists` (`{name, public: false}`).

`sync_playlist/0` is called from several places, all of which represent "the queue
changed":

- when a track is queued while playing (`music.ex:52`)
- as the first step of `trigger_playlist/1` (`music.ex:80`)
- on skip (`Music.skip/1`)
- manually from the setup screen (`POST /setup/sync-playlist`)

---

## 4. Triggering playback on Sonos

**Module:** `PR.Music.trigger_playlist/1` - `lib/pr/music/music.ex:79`

To actually make sound come out, the Spotify playlist must be saved as a Sonos
"favourite" (done once, manually, in the Sonos app). PlayRequest then tells Sonos
to play that favourite. The pipeline:

```elixir
with {:ok} <- sync_playlist(),                                  # 1. refresh Spotify playlist
     {:ok} <- check_unplayed(),                                 # 2. anything to play?
     %Group{group_id: group_id} <- SonosHouseholds.get_active_group!(),
     {:ok, %{items: sonos_favorites}, _} <- SonosAPI.get_favorites(),  # 3. list favourites
     {:ok, fav_id} <- find_playlist(sonos_favorites),           # 4. find ours by name
     {:ok} <- check_current_playstate(PlayState.get(:play_state), force),
     %{} <- SonosAPI.set_favorite(fav_id, group_id) do          # 5. play it
  {:ok}
end
```

The two Sonos calls (`lib/pr/apis/sonos_api.ex`):

```
GET  https://api.ws.sonos.com/control/api/v1/households/{household_id}/favorites
POST https://api.ws.sonos.com/control/api/v1/groups/{group_id}/favorites
     body: { "favoriteId": <id>, "playOnCompletion": true }
```

`set_favorite/2` is the call that loads the playlist into the group's queue and
starts it (`playOnCompletion: true`). The favourite is matched by name via
`find_playlist/1`, so the Sonos favourite must be named to match
`get_playlist_name()`.

The `check_current_playstate/2` guard prevents clobbering music that is already
playing: normally it only proceeds when the player is `idle` or `paused`. Skips
pass `:force` to override this.

---

## 5. The Sonos webhook (feedback loop)

**Route:** `POST /sonos/callback` - `lib/pr_web/router.ex`
**Controller:** `PRWeb.Service.SonosWebhookController` - `lib/pr_web/controllers/service/sonos_webhook_controller.ex`
**Logic:** `PR.PlayState` - `lib/pr/play_state.ex`

PlayRequest never polls Sonos for "what's playing". Instead it subscribes to Sonos
event subscriptions and Sonos POSTs events back. Subscriptions are set up at
startup (`SonosAPI.subscribe_webhooks/0`):

```
POST .../groups/{group_id}/playback/subscription          # play/pause/idle changes
POST .../groups/{group_id}/playbackMetadata/subscription  # current-track changes
```

Each incoming event carries the group id in the `x-sonos-target-value` header, and
the controller dispatches on the JSON body shape:

| Body contains   | Handler                          | Meaning                       |
|-----------------|----------------------------------|-------------------------------|
| `playbackState` | `handle_play_state_webhook`      | playing / paused / idle       |
| `currentItem`   | `handle_metadata_webhook`        | the track changed             |
| `errorCode`     | `handle_error_webhook`           | playback error                |
| `groupStatus`   | `handle_group_status_webhook`    | group changed / players gone  |

The controller always replies `202` immediately and processes asynchronously.

### Marking a track as played

The key feedback is the **metadata** event ("the track changed"). When Sonos
reports a new current item, `PlayState.process_metadata/1` calls
`Queue.set_current/1` (`lib/pr/queue/queue.ex`), which runs a transaction:

```elixir
# any other track currently marked playing -> mark it played
Track
|> query_is_playing()
|> where([t], t.spotify_id != ^spotify_id)
|> Repo.update_all(set: [playing_since: nil, played_at: now])

# the new current track -> mark it playing
Track
|> where([t], t.spotify_id == ^spotify_id)
|> where([t], is_nil(t.played_at))
|> Repo.update_all(set: [playing_since: now])
```

So "track N started" is what marks "track N-1 finished". Because the queue has now
changed (a track moved from unplayed to played), the UI is re-broadcast.

### When the player goes idle

If a `playbackState` event reports the group has gone idle but there are still
unplayed tracks (e.g. Sonos reached the end of the favourite before the playlist
sync caught up), `PlayState` re-runs `trigger_playlist/1` to keep things going.

---

## 6. Authentication (both services)

Both Spotify and Sonos use OAuth2 authorization-code flow. The token-handling
logic is shared via a macro: `lib/pr/apis/macros/token_helper.ex`, and tokens are
stored in the `tokens` table (`PR.ExternalAuth` / `lib/pr/external_auth/`):

```elixir
field(:access_token, :string)
field(:refresh_token, :string)
field(:service, :string)        # "Elixir.PR.SpotifyAPI" or "Elixir.PR.SonosAPI"
field(:activated_at, :utc_datetime)
```

| | Spotify | Sonos |
|---|---|---|
| Authorize URL | `accounts.spotify.com/authorize` | `api.sonos.com/login/v3/oauth` |
| Token URL | `accounts.spotify.com/api/token` | `api.sonos.com/login/v3/oauth/access` |
| Redirect route | `POST /authorized/spotify` | `GET /sonos/authorized` |
| Scopes | playback + playlist modify/read | `playback-control-all` |

The OAuth callback is handled by `PRWeb.Service.ServiceAuthController`, which calls
`<Api>.handle_auth_callback/1` to exchange the code for tokens and persist them.

Access tokens are cached in an Agent and refreshed automatically: the shared HTTP
layer (`lib/pr/apis/macros/endpoint_helper.ex`) detects a `401`, performs a refresh
(`grant_type=refresh_token` against the token URL), and retries the request. If the
refresh token itself is rejected, the stored token is discarded and the service
must be re-authorised from the setup screen.

---

## 7. Sonos households and groups

Sonos organises speakers into a **household** containing **groups** of players.
PlayRequest discovers and stores these (`PR.SonosHouseholds`,
`lib/pr/sonos_households/`):

```
GET .../households                        -> save household ids
GET .../households/{household_id}/groups  -> save groups (group_id, player_ids)
```

One group is marked active; that `group_id` is what all the playback calls target.
Groups are ephemeral on Sonos - if speakers are regrouped, the saved `group_id`
disappears. `PR.SonosHouseholds.GroupManager` (and the `GroupCheck` worker) checks
the active group still exists and, if not, recreates one spanning all available
players via `POST .../households/{household_id}/groups/createGroup`, then
re-subscribes the webhooks.

---

## 8. Background processes

Supervised in `PR.Application` (`lib/pr/application.ex`):

| Process | Kind | Role |
|---|---|---|
| `PR.PlayState` | Agent | Holds current play state / metadata / progress; receives webhooks; broadcasts to LiveViews over PubSub |
| `PR.Ticker` | GenServer | Every 5s, recomputes and broadcasts playback progress % |
| `PR.Scheduler` | Quantum (cron) | `@daily` clears the playlist; a morning job runs the group check |
| `PR.Worker.GetInitialState` | Task | On startup (prod), fetches initial state and subscribes to Sonos webhooks |
| `PR.Worker.GroupCheck` | GenServer | Verifies the active Sonos group, recreates it if gone |

All UI updates flow over `Phoenix.PubSub` (topics `PR.PlayState` and `PR.Music`).
The LiveView (`lib/pr_web/live/playback_live/playback_live.ex`) subscribes and
re-renders on `:play_state`, `:metadata`, `:progress`, and `:queue_updated`.

---

## API reference summary

**Spotify** (`lib/pr/apis/spotify_api.ex`, base `https://api.spotify.com`)

| Function | Call |
|---|---|
| `search/1` | `GET /v1/search/?q=&type=track&market=GB&limit=10` |
| `get_track/1` | `GET /v1/tracks/{id}` |
| `create_playlist/0` | `POST /v1/users/{spotify_id}/playlists` |
| `replace_playlist/1` | `PUT /v1/playlists/{playlist_id}/tracks` (body `{uris: [...]}`) |
| `get_current_user/0` | `GET /v1/me` |

**Sonos** (`lib/pr/apis/sonos_api.ex`, base `https://api.ws.sonos.com/control/api/v1`)

| Function | Call |
|---|---|
| `get_households/0` | `GET /households` |
| `get_groups/0` | `GET /households/{household_id}/groups` |
| `get_favorites/0` | `GET /households/{household_id}/favorites` |
| `set_favorite/2` | `POST /groups/{group_id}/favorites` (body `{favoriteId, playOnCompletion: true}`) |
| `subscribe_webhooks/0` | `POST /groups/{group_id}/playback/subscription` + `.../playbackMetadata/subscription` |
| `toggle_playback/0` | `POST /groups/{group_id}/playback/togglePlayPause` |
| `skip/0` | `POST /groups/{group_id}/playback/skipToNextTrack` |
| `set_volume/1` | `POST /groups/{group_id}/groupVolume` (body `{volume}`) |
| `create_group/1` | `POST /households/{household_id}/groups/createGroup` |

**Inbound webhook**

| Route | Handler |
|---|---|
| `POST /sonos/callback` | `SonosWebhookController.callback` -> `PR.PlayState` |
