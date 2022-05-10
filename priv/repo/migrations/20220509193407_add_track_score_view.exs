defmodule PR.Repo.Migrations.AddTrackScoreView do
  use Ecto.Migration

  def change do
    execute """
      CREATE VIEW recent_plays as (
        select
          t.spotify_id,
          t.name,
          t.artist,
          floor(
            (
              extract(
                epoch
                from
                  t.inserted_at - (now() - interval '3 week')
              )
            ) / 36000 -- 0 - 50 for recentness
          ) as recency
        from
          tracks t
        where
          t.inserted_at > now() - interval '3 week'
          and t.played_at is not null
        order by
          recency desc
      )
      """,
      """
        DROP VIEW recent_plays
      """

    execute """
      CREATE VIEW artist_novelty as (
        with artist_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            artist
          from
            recent_plays
          group by
            artist
        )
        select
          artist,
          floor(100 - (un_novelty / (
            select max(un_novelty) from artist_un_novelty
          ) * 100))::integer as artist_novelty
        from
          artist_un_novelty
        )
      """,
      """
        DROP VIEW artist_novelty
      """

    execute """
      CREATE VIEW track_novelty as (
        with track_un_novelty as (
          select
            count(1) * max(recency) as un_novelty,
            spotify_id
          from
            recent_plays
          group by
            spotify_id
        )
        select
          spotify_id,
          floor(100 - (un_novelty / (
            select max(un_novelty) from track_un_novelty
          ) * 100))::integer as track_novelty
        from
          track_un_novelty
      )
      """,
      """
        DROP VIEW track_novelty
      """
  end
end
