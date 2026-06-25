# Plan: Mixed-provider queue (Spotify + SoundCloud)

Status: proposal. Not started.

Goal: let users queue both Spotify and SoundCloud tracks into the same live
session, played out of the same Sonos speakers. The DB queue stays the single
source of truth and remains globally ordered; the provider of each track is just
an attribute of the row.

This builds on the existing architecture described in `how-it-works.md`. Read that
first. The short version: PlayRequest does not stream audio. It mirrors the
unplayed queue into a streaming-service playlist, saves that playlist as a Sonos
"favourite", tells Sonos to play the favourite, and learns what is playing from
Sonos webhooks.

---

## 0. Open question / TODO (gating, not yet decided)

**SoundCloud API access requires a paid account.** Whether this feature is worth
building at all depends on:

- Can we register a SoundCloud app and obtain client credentials at all
  (registration has historically been closed/intermittent).
- Does the paid tier expose **playlist track replacement** (the equivalent of
  Spotify's `PUT /playlists/{id}/tracks`). Without it, the whole mirroring trick
  has nothing to write to and the feature is dead.
- Cost vs. value of the paid account.

This needs separate research and a go/no-go before any of the technical work
below is worth starting. Everything else in this document assumes the answer is
"yes, and it supports playlist editing".

**Second unknown (cheap to verify, do early):** the shape of a SoundCloud track in
the Sonos metadata webhook. We rely on `currentItem.track.id.object_id` to match
the playing track back to a queue row. For Spotify it is `spotify:track:{id}`
(`lib/pr/music/sonos_item.ex:9`). We need to capture what Sonos sends for a
SoundCloud track and confirm it carries a stable id we can store and match. This
can be checked by hand (save a SoundCloud playlist as a favourite, play it, log
the inbound webhook) before committing to the build.

---

## 1. Design: favourite swapping at provider boundaries

A Sonos favourite points at one service's playlist, and Sonos plays that one
playlist autonomously. There is no Sonos API to "play this arbitrary list of
mixed-service track ids". So we keep two favourites - one Spotify playlist, one
SoundCloud playlist - and play the queue as a sequence of single-provider
**runs**.

A run is a maximal contiguous block of same-provider tracks in queue order. For
the queue `S1 S2 C1 S3 C2 C3 S4` the runs are:

```
[S1 S2]  [C1]  [S3]  [C2 C3]  [S4]
```

At any moment we load only the **current run** into its provider's playlist and
trigger that provider's favourite. Sonos plays the run gaplessly, then reaches the
end of the (short) playlist and goes idle. Idle-with-tracks-remaining is the
existing re-trigger signal (`PR.PlayState.watch_play_state/1`,
`lib/pr/play_state.ex:153`); we reuse it to load and trigger the next run.

Important: we deliberately load only the current run, not all of a provider's
unplayed tracks. If the Spotify playlist held `[S1 S2 S3 S4]`, Sonos would play
straight through and never stop for `C1`. Loading just `[S1 S2]` makes Sonos go
idle exactly at the boundary, which is where we take back control.

### What this reuses (already in the codebase)

- **Boundary "mark played".** When the next run's first track starts, its metadata
  event marks any *other* still-playing track as played
  (`Queue.set_current_transaction/2`, `lib/pr/queue/queue.ex:255`, via
  `where external_id != ^id`). So the last track of the previous run is marked
  played when the next run starts; no special boundary handling needed. At the
  true end of the queue, the empty-metadata path (`Queue.set_current(%{})`) marks
  it played as it does today.
- **Skip across a boundary.** `Music.skip/1` already handles "nothing left in the
  Sonos queue" by bumping the current track and re-triggering, with rollback on
  failure (`lib/pr/music/music.ex:149`). Skipping the last track of a run lands in
  that path unchanged.
- **Idle re-trigger.** The boundary trigger is the existing idle handler, just
  firing more often.

### What this costs

- **A gap at every provider switch.** `set_favorite` reloads the Sonos group queue
  and restarts playback, plus the ~1s idle-retrigger delay
  (`lib/pr/play_state.ex:165`). Within a run, playback is gapless. Worst case is
  track-by-track alternation; clustered queues switch rarely.
- **More re-triggers, more race surface.** `trigger_playlist/1` is already flagged
  as slow and race-prone if called repeatedly before play state settles
  (`lib/pr/music/music.ex:77`). Each switch is several HTTP round-trips. Switching
  per run multiplies the desync window between DB and Sonos state. This is the
  main place runtime bugs will show up and where test/observability effort should
  go.

---

## 2. Data model

`tracks.spotify_id` becomes provider-qualified. Add a provider column; keep the id
column but rename its meaning to a generic external id.

```
provider     :string   # "spotify" | "soundcloud"
external_id  :string   # was spotify_id; provider-scoped track id
```

Migration work:

- Add `provider` (default `"spotify"` to backfill existing rows), rename
  `spotify_id` -> `external_id`.
- Unique constraint `already_queued` becomes a composite on
  `(provider, external_id)` instead of `spotify_id` alone
  (`lib/pr/queue/track.ex:49`).
- The novelty views join on `spotify_id`
  (`track_novelty`, `artist_novelty`; used in `lib/pr/queue/queue.ex:380` and the
  raw SQL in `get_novelty_for_search_results/1`, `queue.ex:113`). Decide whether
  novelty is per-provider or cross-provider. Simplest: keep novelty keyed on the
  external id and accept that the same song on two services counts separately.
  Update the views and the raw query to the renamed column either way.
- `SonosItem` (`lib/pr/music/sonos_item.ex`) and `SearchTrack`
  (`lib/pr/music/search_track.ex`) gain a `provider` field.

Matching in `set_current_transaction/2` currently compares `external_id` only.
Cross-provider ids will not collide in practice, but qualify the match by
`provider` as well to be safe.

---

## 3. Provider abstraction

Introduce a behaviour so `Music` is provider-agnostic and the Spotify-specific
code moves behind it. SoundCloud gets a parallel implementation.

```elixir
defmodule PR.Music.Provider do
  @callback search(query :: String.t()) :: {:ok, [SearchTrack.t()]} | {:error, term()}
  @callback get_track(id :: String.t()) :: {:ok, SearchTrack.t()} | {:error, term()}
  @callback replace_playlist(ids :: [String.t()]) :: {:ok, term()} | {:error, term()}
  @callback favourite_name() :: String.t()        # name of the Sonos favourite to match
  @callback object_id(external_id :: String.t()) :: String.t()  # e.g. "spotify:track:" <> id
  @callback match_object_id(object_id :: String.t()) :: {:ok, external_id :: String.t()} | :no_match
end
```

- `PR.Music.Provider.Spotify` wraps the current `PR.SpotifyAPI` calls
  (`search/1`, `get_track/1`, `replace_playlist/1`) and the `spotify:track:` URI
  shape.
- `PR.Music.Provider.SoundCloud` is the new module: a new OAuth client + HTTP
  layer (reuse `PR.Apis.TokenHelper` / `PR.Apis.EndpointHelper`), search, get
  track, and playlist replace against SoundCloud's API, plus its own object-id
  shape (to be confirmed - see section 0).

`provider_for/1` maps a provider atom/string to its module.

---

## 4. Search and queueing (per provider)

- Search needs to target a provider. Either a provider toggle in the search UI, or
  search both and tag results by provider. Simplest first cut: a toggle, default
  Spotify. `Music.search/1` -> `provider.search/1`.
- `Music.queue/2` already takes an id; extend it to take a provider too, fetch
  metadata via `provider.get_track/1`, and store `provider` + `external_id` on the
  row (`lib/pr/music/music.ex:39`).
- The idle-vs-playing branch in `queue/2` is unchanged in shape, but
  `sync_playlist` becomes run-aware (next section).

---

## 5. Run slicing and playlist sync

This is the core new logic. Replace the single "load all unplayed" sync with
"load the current run".

- `Queue.list_track_uris/0` currently returns all unplayed ids
  (`lib/pr/queue/queue.ex:71`). Add `Queue.current_run/0` returning the contiguous
  same-provider block at the head of the unplayed queue (ordered by `inserted_at`)
  as `{provider, [external_id]}`.
- `Music.sync_playlist/0` becomes: take the current run, call
  `provider.replace_playlist(ids)` for that provider, and remember which provider
  is "active" so triggering knows which favourite to use
  (`lib/pr/music/music.ex:61`).
- `find_playlist/1` matches the Sonos favourite by name
  (`lib/pr/music/music.ex:197`). Match against `provider.favourite_name/0` for the
  active run's provider. This means two favourites must exist in the Sonos app, one
  per provider, named to match.

Edge case - appending while a run plays: queueing another track of the
**currently active** provider can extend the current run's playlist (same as today
within a run). Queueing a different-provider track, or a same-provider track that
is not contiguous with the current run, just sits in the DB queue and gets loaded
when its run is reached. No live mutation needed for those.

---

## 6. Triggering and the boundary loop

`trigger_playlist/1` (`lib/pr/music/music.ex:79`) stays structurally the same:

1. `sync_playlist` (now loads the current run).
2. `check_unplayed`.
3. get active group.
4. `get_favorites` -> `find_playlist` (now provider-specific name).
5. `check_current_playstate`.
6. `set_favorite`.

The boundary loop: run plays -> Sonos idle -> `watch_play_state(:idle)` sees
unplayed tracks remain -> `trigger_on_sonos_system` -> `trigger_playlist` ->
loads the next run (which may be the other provider) -> plays. Repeat until the
queue is empty, at which point idle with no unplayed tracks stops the loop
(`lib/pr/play_state.ex:160`).

---

## 7. Metadata feedback (both providers)

- `SonosItem.new/1` hard-matches `spotify:track:` (`lib/pr/music/sonos_item.ex:9`).
  Generalise: detect provider from the object-id shape, populate `provider` +
  `external_id`. Delegate the shape match to the provider modules
  (`match_object_id/1`).
- `cast_metadata/1` (`lib/pr/play_state.ex:294`) drops non-Spotify items to
  "playing something else". Once SoundCloud shapes are recognised, they flow
  through `update_playing/1` -> `Queue.set_current/1` like Spotify items.
- `Queue.set_current/1` matching is by external id (qualified by provider per
  section 2).

If the SoundCloud object-id does not carry a stable, matchable id, this is a hard
blocker for SoundCloud playback feedback - resolve in the section 0 spike before
building.

---

## 8. Auth

SoundCloud is a second OAuth2 authorization-code service, same pattern as Spotify
and Sonos (`how-it-works.md` section 6). Reuse `PR.Apis.TokenHelper` and the
`tokens` table keyed by `service` (`Elixir.PR.Music.Provider.SoundCloud`). Add:

- A `client/0` with SoundCloud authorize/token URLs and scopes.
- A redirect route and handling in `PRWeb.Service.ServiceAuthController` (mirror
  the Spotify case).
- A SoundCloud section on the setup screen to authorise and to create/verify the
  SoundCloud playlist (mirror `create_playlist`).

---

## 9. Setup / operational

- Two Sonos favourites must exist, one per provider, named to match each
  provider's `favourite_name/0`. Document this in setup; `find_playlist` already
  errors clearly if a favourite is missing.
- The `@daily` playlist clear (`PR.Scheduler`) must clear both playlists.
- Per-provider playlist creation on the setup screen.

---

## 10. Risks (ordered)

1. **SoundCloud API access + playlist editing (paid, unverified).** Section 0.
   Go/no-go gate.
2. **SoundCloud Sonos metadata id shape (unverified).** Section 0 spike. If
   unmatchable, feedback loop breaks.
3. **Switch-boundary races.** More frequent triggering widens the existing
   DB-vs-Sonos desync window (`music.ex:77`). Needs careful logging and probably
   integration testing around boundaries.
4. **Gap on provider switch.** Inherent to favourite reloading. Product-acceptable
   or not is a call to make.
5. **Live append assumption.** Mutating a playlist Sonos is mid-playing is a
   pre-existing assumption; in this design it is scoped to within the active run.

---

## 11. Suggested order of work

1. (Gate) Research SoundCloud paid API access + playlist edit support. Go/no-go.
2. (Spike) Save a SoundCloud playlist as a Sonos favourite, play it, capture the
   metadata webhook. Confirm a matchable id. Go/no-go.
3. Data model: `provider` + `external_id` migration, constraint, novelty views,
   structs.
4. Provider behaviour + extract `Provider.Spotify` from current code. No behaviour
   change yet (Spotify-only, still works end to end).
5. Run slicing: `Queue.current_run/0`, run-aware `sync_playlist`, provider-aware
   `find_playlist`. Still Spotify-only - verify the boundary loop works with an
   all-Spotify queue split into artificial runs.
6. `Provider.SoundCloud`: auth, search, get track, replace playlist, object-id.
7. Metadata: generalise `SonosItem` / `cast_metadata`.
8. UI: provider toggle in search; setup screen for SoundCloud auth + playlist.
9. Integration testing focused on boundary transitions and skips across providers.

Steps 4 and 5 are valuable on their own: they make the system provider-agnostic
and exercise the run-boundary loop using only Spotify, so the riskiest mechanics
are proven before SoundCloud is added.
