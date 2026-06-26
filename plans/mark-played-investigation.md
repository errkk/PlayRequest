# Investigate: tracks marked played when they were not played

Status: parked, to analyse. Long-standing issue; several fixes already attempted
(see the commented-out `query_has_been_playing` calls in `lib/pr/queue/queue.ex`).

## Symptom

Queue rows get `played_at` set when the track was never actually played (or was
only partway through), so they drop out of the unplayed queue incorrectly.

## Where to look

- `Queue.set_current_transaction/3` (`lib/pr/queue/queue.ex:263`). When a track
  starts, every *currently-playing* row (`playing_since` set) with a different
  `(provider, external_id)` is marked played (`queue.ex:269`). Bounded to rows
  flagged playing, which is reasonable - but if a row was wrongly flagged
  playing, or boundary timing is off, the wrong row gets marked played.

- `Queue.set_current/1` no-match clause (`queue.ex:213-259`), used by `bump/0`
  and when Sonos reports empty/foreign metadata. This has a suspicious two-pass
  structure:
  1. First `update_all` over `query_is_playing` sets `played_at` from
     `datetime_add(playing_since, duration)` AND sets `playing_since: nil`.
  2. A second `update_all` over `query_is_playing` then tries to set
     `played_at: nil` - but pass 1 already cleared `playing_since`, so this
     query matches nothing. The first `case` result is also discarded.
  Looks like dead/contradictory code. The intent (only mark played if it had
  been playing long enough, else un-play) is not actually achieved. Prime
  suspect for premature played marking.

## Relevance to runs (step 5)

Run boundaries re-trigger far more often (idle -> re-trigger per run), so
`set_current` fires more frequently - wider exposure to whatever is wrong here.
Also, now that SoundCloud object_ids resolve (post `track->` fix), a track that
Sonos plays but that is NOT in our queue still resolves to a SonosItem, and
`set_current_transaction` will mark the previously-playing queued row as played
even though our track did not actually finish.

## Suggested approach

- Untangle the `set_current/1` two-pass logic; decide the real rule for
  "played vs un-played" based on `playing_since` + elapsed vs `duration`.
- Pin down the `playing_since` lifecycle (who sets/clears it, and when).
- Add tests around boundary transitions and foreign-track metadata before
  changing behaviour.
