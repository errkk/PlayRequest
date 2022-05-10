defmodule PR.Repo.Migrations.AddTrackScoreView do
  use Ecto.Migration

  def change do
    execute """
      CREATE MATERIALIZED VIEW track_scores as 
        with tracks_and_age as (
          select
            t.spotify_id,
            t.name,
            t.artist,
            floor(
              extract(
                epoch
                from
                  now() - t.inserted_at
              ) / 36000
            ) as age
          from
            tracks t
          where
            t.inserted_at > now() - interval '3 week'
        ),
        artist_novelty as (
          select
            artist,
            floor(sum(60 - age) * count(1) * 0.05) as artist_score,
            count(1)
          from
            tracks_and_age
          group by
            artist
        ),
        track_novelty as (
          select
            artist,
            name,
            spotify_id,
            floor(sum(60 - age) * count(1) * 0.01) as track_score,
            count(1) as track_count
          from
            tracks_and_age
          group by
            name,
            spotify_id,
            artist
        ),
        scores as (
          select
            tn.spotify_id,
            tn.artist,
            tn.name,
            tn.track_score,
            an.artist_score,
            tn.track_score * an.artist_score as score
          from
            track_novelty tn
            join artist_novelty an on tn.artist = an.artist
        )
        select
          spotify_id,
          artist,
          name,
          floor(
            (
              score / (
                select
                  max(score)
                from
                  scores
              ) + 0.0001
            ) * 100
          ) as score,
          floor(
            (
              artist_score / (
                select
                  max(artist_score)
                from
                  scores
              ) + 0.0001
            ) * 100
          ) as artist_score
        from
          scores
    """,
    """
    DROP MATERIALIZED VIEW track_scores
    """

  end
end
