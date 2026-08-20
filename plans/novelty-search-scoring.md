# Fix: novelty scores attached to the wrong search results

Status: implemented, including the provider-aware follow-up.

## Symptom

Tracks that should score high novelty show a low score in the search results
list (and vice versa). The scores that appear are real values from the novelty
views, just bound to the wrong rows.

## Cause

`Queue.get_novelty_for_search_results/1` (`lib/pr/queue/queue.ex:155`) builds a
raw SQL `VALUES` list from the search results, left joins the two novelty views
onto it, selects only the two novelty columns, and then zips the returned rows
back onto the track list by position:

```elixir
tracks
|> Enum.with_index()
|> Enum.map(fn {track, index} -> Map.merge(track, Enum.at(novelty, index)) end)
```

The SQL has no `ORDER BY`, so Postgres is free to return rows in any order. It
does. Reproduced on Postgres 16 with the current view definitions, 400 played
tracks, and 20 search results interleaved as
`new-a, id-0, new-b, id-1, ...` (the `new-*` ids are absent from `tracks`, so
they should all score 100):

```
 actual_row_is_for | track_novelty | artist_novelty
-------------------+---------------+----------------
 id-8              |            16 |             16
 id-9              |            40 |             40
 id-1              |            22 |             22
 ...
 new-d             |           100 |            100
 new-a             |           100 |            100
```

The planner hashes the `VALUES` list and probes it from the view side, so all
the low scores come back first. Position 1 in the result is `id-8`'s score of
16, and `Enum.with_index` pastes it onto search result 1, which is `new-a`.
Every score in the list is wrong, and the brand new tracks systematically get
the low numbers. That is exactly the reported symptom.

Adding `ORDER BY` would not fix it either - there is no ordinal column to order
by, and the `VALUES` list can contain duplicates.

## Secondary problems in the same function

1. **Empty search results crash.** No matches means `search_results` is `""`,
   producing `VALUES  )`. Confirmed: `ERROR: syntax error at or near ")"`.
2. **Hand-rolled quoting.** `escape_quotes/1` doubling single quotes is the
   only thing between provider-supplied track titles/artist names and the
   query. It is also the function's only caller.
3. **`nil` artist crashes.** SoundCloud's artist comes from
   `Map.get(user, :username)` (`lib/pr/music/search_track.ex:32`), which can be
   `nil`. `String.replace(nil, ...)` raises.
4. **Novelty schemas have an implicit `id` primary key.** `TrackNovelty` and
   `ArtistNovelty` use the default `@primary_key`, but the views have no `id`
   column. Any query that selects the whole struct fails.

## Fix

Drop the raw SQL entirely. Look the two views up by key and merge in Elixir,
so the association is by id/artist rather than by row position.

`lib/pr/queue/queue.ex`, replacing `get_novelty_for_search_results/1` and
deleting `escape_quotes/1`:

```elixir
@default_novelty 100

@spec get_novelty_for_search_results([SearchTrack.t()]) :: [SearchTrack.t()]
def get_novelty_for_search_results(tracks) do
  track_novelty =
    TrackNovelty
    |> where([t], t.external_id in ^Enum.map(tracks, & &1.external_id))
    |> select([t], {t.external_id, t.track_novelty})
    |> Repo.all()
    |> Map.new()

  artist_novelty =
    ArtistNovelty
    |> where([a], a.artist in ^Enum.map(tracks, & &1.artist))
    |> select([a], {a.artist, a.artist_novelty})
    |> Repo.all()
    |> Map.new()

  Enum.map(tracks, fn track ->
    %{
      track
      | track_novelty: Map.get(track_novelty, track.external_id, @default_novelty),
        artist_novelty: Map.get(artist_novelty, track.artist, @default_novelty)
    }
  end)
end
```

This clears all five problems: keyed merge instead of positional zip,
parameterised instead of interpolated, `in ^[]` compiles to `false` rather than
a syntax error, a `nil` artist just misses the map and takes the default, and
`select` of a two-tuple never touches a primary key.

Use `@default_novelty` in `select_user_facing_fields/1`
(`queue.ex:506-507`) too, where the same 100 is hardcoded twice.

Add `@primary_key false` to `PR.Queue.TrackNovelty` and
`PR.Queue.ArtistNovelty`.

Two round trips instead of one. Both are small `IN` lookups against views over
three weeks of `tracks`, on a search path that has already made an HTTP call to
Spotify or SoundCloud, so it is not worth optimising.

## Test

There is no novelty coverage today. Add to `test/pr/queue_test.exs`, using the
existing `played_track` factory:

- A search result whose `external_id` is in `tracks` gets that track's score;
  a result absent from `tracks` gets 100. Assert per track, with the novel
  track placed *first* in the input list - that is the position the current
  code gets wrong.
- Artist novelty applies to a result matching on artist but not `external_id`.
- `get_novelty_for_search_results([])` returns `[]`.
- A result with `artist: nil` returns 100 rather than raising.

## Follow-up, also implemented: make novelty provider-aware

`track_novelty` groups by `external_id` alone, ignoring the `provider` column
that `recent_plays` already selects
(`priv/repo/migrations/20260622120000_add_provider_to_tracks.exs`), and both
join sites join on `external_id` alone. A Spotify and a SoundCloud track that
happen to share an id would pool their play counts. Spotify uses base62 and
SoundCloud numeric ids, so this is not currently reachable.

Fixing it means a migration to recreate `track_novelty` grouped by
`(external_id, provider)`, adding `provider` to the `TrackNovelty` schema, and
adding `provider` to the join in `query_novelty/1` and to the map key above.
Done in migration 20260820120000_provider_scoped_track_novelty.exs.
